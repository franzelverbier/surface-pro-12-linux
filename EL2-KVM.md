# Démarrer en EL2 avec KVM sur Surface Pro 12

Le SP12 démarre normalement en **EL1**, l'hyperviseur Qualcomm Gunyah occupant EL2 — donc
pas de `/dev/kvm`. [slbounce](https://github.com/TravMurav/slbounce) utilise le **Secure
Launch** (DRTM) de Qualcomm, via un `tcblaunch.exe` signé par Microsoft, pour rendre EL2 à
Linux.

Résultat obtenu ici : `CPU: All CPU(s) started at EL2`, `/dev/kvm` présent, KVM avec
virtualisation imbriquée, bureau KDE complet.

## Prérequis

- **Secure Boot désactivé** (sans quoi aucun driver EFI ne se charge)
- Un DTB préparé pour EL2 — l'overlay `x1-el2.dtso` du noyau (≥ 6.16) appliqué au DTS
  Surface Pro 12. slbounce refuse de basculer si le zap-shader n'est pas désactivé dans
  le DTB chargé.
- `id_aa64mmfr0.ecv=1` sur la ligne de commande noyau — **obligatoire** sur x1p42100,
  sans quoi le lancement d'une VM redémarre la machine.

## 1. Obtenir le bon `tcblaunch.exe`

**C'est l'étape qui décide de tout.** Extraire depuis une ISO Windows 11 ARM64 :

```bash
7z e Win11_24H2_English_Arm64.iso sources/install.wim
wimextract install.wim 1 Windows/System32/tcblaunch.exe --dest-dir=.
```

Version validée ici : **10.0.26100.1742** (24H2 RTM), 887 432 octets,
sha256 `5dfcd0253b6ee99499ab33cac221e8a9cea47f3fdf6d4e11de9a9f3c4770d03d`.

Deux autres versions ont été testées et **échouent** sur cette machine : 23H2 22621.2715
et un build Canary 27943. Microsoft a retiré des versions récentes la gestion d'erreur
dont slbounce dépend.

### Valider avant d'aller plus loin

`sltest.efi` bascule en EL2, dessine un bandeau vert en haut de l'écran, puis **fige
volontairement**. C'est le seul critère fiable.

```
FSxx:\> sltest.efi \tcblaunch.exe
```

⚠️ `sltest.efi` **exige** le chemin en argument. Sans argument il affiche son usage et
rend la main — ce qui ressemble à s'y méprendre à un échec de bascule.

- **bandeau vert** → le binaire est bon
- **freeze ou reboot sans vert** → mauvais `tcblaunch.exe`, en essayer un autre

Faire un **arrêt complet** entre deux essais, pas un redémarrage : un Secure Launch raté
laisse de la mémoire mappée en EL2 et fausse les tentatives suivantes.

## 2. Corriger slbounce

Deux modifications sont nécessaires sur ce firmware (testé contre `c090a8c`) :

**Supprimer le balayage de cache global** dans `sl_ExitBootServices()` — la boucle qui
appelle `clear_dcache_range()` sur chaque plage Loader/BootServices. Elle fait tomber la
machine à l'intérieur de `clear_dcache_range()` sur une plage `EfiBootServicesData`
ordinaire (`0xA7F19000`, 231 pages), **avant même que l'AUTH ne s'exécute**. La retirer
n'a aucun effet néfaste : les tampons qui doivent atteindre la RAM sont flushés
individuellement ailleurs, et `sltest` n'a jamais eu ce balayage.

**Durcir `sl_GetMemoryMap()`** — il mémorise `*MemoryMapSize` même quand l'appel a renvoyé
`EFI_BUFFER_TOO_SMALL`, ce qui associe une grande taille à un petit tampon :

```c
if (EFI_ERROR(status) || !MemoryMap || !MemoryMapSize || !DescriptorSize)
        return status;
```

L'ordre d'amont (`SL_CMD_AUTH` **après** `ExitBootServices`) est correct et ne demande
aucun changement — vérifié.

## 3. Installer

```bash
cp slbounce.efi   /boot/efi/slbounce/
cp tcblaunch.exe  /boot/efi/            # à la RACINE de l'ESP, slbounce l'y cherche en dur
```

Enregistrer slbounce comme driver UEFI (GRUB ne sait pas charger un driver) :

```bash
efibootmgr -r -c -d /dev/sda -p 1 -L "slbounce-el2" -l '\slbounce\slbounce.efi'
```

Entrée GRUB :

```
menuentry "SP12 - EL2 / KVM" {
    search --no-floppy --set=root --label VOTRE-LABEL
    linux /boot/Image-el2 root=LABEL=VOTRE-LABEL rw rootwait \
          clk_ignore_unused pd_ignore_unused console=tty0 \
          id_aa64mmfr0.ecv=1 modprobe.blacklist=ath12k_wifi7
    initrd /boot/initramfs.img
    devicetree /boot/sp12-el2.dtb
}
```

## 4. Vérifier

```bash
dmesg | grep -o "started at EL[12]"     # attendu : started at EL2
ls -l /dev/kvm
dmesg | grep "kvm \[1\]"                # trap handlers nested
```

## Le WiFi interne : un SMMUv3 laissé en « reserved »

Pendant longtemps, **aucune MSI n'était délivrée** en EL2 : tous les compteurs
`ITS-PCI-MSI` restaient à zéro, PME du root port PCIe compris, alors que les interruptions
filaires fonctionnaient. `ath12k` attendait l'interruption `bhi`, expirait au bout de ~90 s
et réessayait trois fois.

**La cause était dans notre propre DTS** : le SMMUv3 du PCIe, `iommu@15400000`, était laissé
en `status = "reserved"`. Il suffit de le passer à `"okay"` :

```
pcie_smmu: iommu@15400000 {
        status = "okay";        /* etait "reserved" */
};
```

Les compteurs passent de 0 à plusieurs milliers, et le WiFi interne fonctionne normalement.

### Le faux négatif qui a coûté des jours

Nous avions « écarté » le SMMU en testant `arm-smmu.force_stage=1` — sans effet, donc
conclusion : ce n'est pas le SMMU. **C'était faux.** Ce paramètre appartient au pilote
SMMUv1/v2 (`arm-smmu.c`, l'`apps_smmu`) ; le PCIe passe par le SMMUv3 (`arm-smmu-v3.c`),
qui n'a pas ce paramètre du tout. Le test ne touchait jamais le composant incriminé.

Morale, valable bien au-delà d'ici : une hypothèse n'est écartée que si l'on a vérifié que
le levier actionné agit réellement sur le composant visé. Le reste du temps, on ne fait
qu'ajouter une fausse certitude à la liste.

Restent vraies, et utiles à qui compare EL1 et EL2 : en EL1, Gunyah présentait un GIC
**synthétique** (`GICD_CTLR.DS=1`, DirectLPI, 988 SPI, 16 PPI) ; en EL2, Linux voit le
matériel réel (`DS=0`, `SCR_EL3.FIQ=1`, pas de DirectLPI, 960 SPI, 1024 ESPI, 48 PPI,
GICv4.1). Cette différence est réelle mais n'était pas la cause.

**Effet de bord observé à l'époque** : les timeouts d'`ath12k` sérialisaient le sondage du
Surface Aggregator, et le clavier Type Cover n'apparaissait qu'à ~327 s au lieu de ~13 s.

### Repli : une clé WiFi USB

Plus nécessaire depuis le correctif ci-dessus, mais conservé — c'est le repli si le PCIe
pose problème, et le piège de chargement tardif vaut pour n'importe quelle clé Realtek.

Un adaptateur USB passe par le contrôleur xHCI et non par le PCIe : ses interruptions sont
filaires, et celles-là étaient délivrées même quand les MSI ne l'étaient pas.

Validé ici avec un **RTL8192CU** (`0586:341f`, ZyXEL/Realtek 802.11n) : association,
DHCP et trafic normaux en EL2, avec `ath12k` en liste noire.

Ce qu'il faut côté noyau :

```
CONFIG_RTL8XXXU=m
CONFIG_RTL8XXXU_UNTESTED=y      # ce chip est derrière ce #ifdef
```

Le firmware (`rtlwifi/rtl8192cufw_{A,B,TMSC}.bin`) vient de `linux-firmware`, rien à
extraire de Windows.

#### Le piège : charger le module tard

L'initialisation de l'étage RF **échoue si le module est chargé tôt dans le boot** :

```
usb 1-1: Firmware revision 88.2 (signature 0x88c1)
usb 1-1: Failed to initialize RF
usb 1-1: Failed to initialize RF
```

Chargé à 3,3 s par udev, l'init RF échoue et l'interface reste sans porteuse. Rechargé
machine calme, elle réussit du premier coup et scanne. Ce n'est ni l'EL2 ni le chip : à
titre de comparaison, en EL1 le module se chargeait tard, à la main, et n'a jamais sorti
cette erreur.

La parade : interdire l'autoload et charger tard, avec réessai.

```
# /etc/modprobe.d/rtl8xxxu-late.conf
blacklist rtl8xxxu
```

```ini
# /etc/systemd/system/usbwifi.service
[Unit]
Description=Charger la clé WiFi USB après le boot
After=multi-user.target            # ordonné APRÈS la cible qui le veut,
                                   # donc elle ne l'attend pas
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/usbwifi-load

[Install]
WantedBy=multi-user.target
```

Le script compte les `Failed to initialize RF` avant et après le `modprobe`, et recharge
jusqu'à trois fois si l'init a échoué — plus fiable qu'une temporisation fixe.

À noter : c'est le même motif que la liste noire des modules Surface Aggregator, dont la
raison d'être n'était plus documentée. Sur cette plateforme, plusieurs pilotes supportent
mal d'être sondés pendant la tempête d'initialisation.

#### Piège de compilation

Pour construire ce seul module dans un arbre déjà compilé, `make M=<dir> modules` **ne
régénère pas** `include/generated/autoconf.h` quand `.config` a changé. Le module se relie
sans erreur mais sans l'option — ici 33 alias au lieu de 121, notre chip absent, échec
totalement silencieux. Il faut `make syncconfig` d'abord, et un `make modules` complet au
moins une fois pour obtenir `Module.symvers`.

## Audio en EL2 : démarrer les DSP avant Linux, puis s'y rattacher

Symptôme de départ : `error -22 initializing firmware`, ADSP et CDSP `offline`, pas
d'audio ni de décodage vidéo matériel. TrustZone refuse le service PAS dès que Linux
possède EL2 — et il n'y a rien à négocier de ce côté.

La solution ne consiste donc pas à faire aboutir le chargement, mais à **démarrer les DSP
pendant qu'on est encore en EL1**, avant la bascule, puis à demander au noyau de s'y
rattacher au lieu de les démarrer. Deux moitiés : qebspil côté UEFI, une série de patchs
remoteproc côté noyau.

### Première moitié : qebspil

[qebspil](https://github.com/stephan-gh/qebspil) démarre les co-processeurs en EL1, juste
avant `ExitBootServices`. **Il fonctionne sur x1p42100**, ce que sa liste de plateformes
ne laissait pas espérer — elle ne mentionne que SC7180, SC8280XP et X1E. Aucune
modification de code n'a été nécessaire : le X1P42100 réutilise les compatibles X1E
(`qcom,x1e80100-adsp-pas` et `-cdsp-pas`), déjà présents dans sa table `pil-types.c`.

Il faut le compiler avec `QEBSPIL_ALWAYS_START=1`. Par défaut, qebspil ne démarre que les
remoteprocs portant `qcom,broken-reset` — et cette propriété, nous l'ajoutons au DTB que
GRUB charge, donc **bien après** que qebspil se soit exécuté : il ne la voit jamais. Les
deux moitiés ont besoin de l'information, chacune par son propre canal. Les firmwares vont
dans `/firmware/` à la racine de la même partition que le binaire, sous le chemin donné
par `firmware-name` dans le DT.

Vérifié en instrumentant qebspil pour qu'il écrive sur l'ESP (sa sortie console passe
avant que GRUB ne dessine son menu, donc invisible en pratique) :

```
--- qebspil chargé ---
scm_init: Success
trouvé: qcom,x1e80100-adsp-pas
trouvé: qcom,x1e80100-cdsp-pas
dtb_enumerate_rprocs: Success
démarrage: qcom,x1e80100-adsp-pas
démarrage: qcom,x1e80100-cdsp-pas
pil_finish_all: Success
```

### Seconde moitié : les patchs noyau

Les DSP tournent, mais Linux l'ignore et tente quand même le chargement PAS, qui échoue.
`qcom_q6v5_pas.c` d'origine ne connaît qu'un seul scénario — charger le firmware lui-même.

**qebspil ne modifie pas le device tree** (aucun `fdt_setprop` dans ses sources) : il
n'existe aucun signal en bande, le noyau doit être informé autrement.

Le README de qebspil renvoie vers `git.codelinaro.org/stephan.gerhold/linux`
(`wip/x1e80100-6.16-el2`, `wip/qcom-laptops-6.17-el2`), qui n'est plus accessible — cet
utilisateur n'existe plus dans l'API du service. Les patchs se retrouvent dans le miroir
[`jglathe/linux_ms_dev_kit`](https://github.com/jglathe/linux_ms_dev_kit).

Série de 14 patchs, dans l'ordre : six sur `soc/qcom/smp2p` (dont *Take over outgoing SMEM
items from boot firmware* et *Add support for `irq_get_irqchip_state()`*), un sur le cœur
remoteproc (*Allow restarting detached remoteprocs*), et sept sur `qcom_q6v5*` (`.attach`,
détection de l'état détaché au boot, `qcom,broken-reset`).

Le mécanisme tient en deux points :

- la propriété DT **`qcom,broken-reset`** sur les nœuds remoteproc fait choisir
  `qcom_pas_ops_no_reset`, qui possède `.attach` mais **ni `.start` ni `.load` ni
  `.parse_fw`** — le SMC PAS qui renvoie `-22` n'est donc jamais appelé ;
- l'état « déjà démarré » est détecté en lisant le niveau des lignes d'interruption SMP2P
  via `qcom_q6v5_read_smp2p_state()`. C'était le point dur : le DSP a signalé son
  démarrage bien avant que Linux n'existe, donc attendre l'interruption ne pouvait pas
  marcher — il faut lire son **niveau**, pas son front.

### Trois pièges rencontrés

**Le patch DTS amont ne suffit pas si vous gardez votre propre DTB.** Le patch
`arm64: dts: qcom: x1-el2: Add qcom,broken-reset` ne touche que l'overlay `x1-el2.dtso`.
Avec un DTS fait main, il faut ajouter la propriété soi-même sur les deux nœuds :

```
remoteproc_adsp: remoteproc@6800000  { qcom,broken-reset; ... };
remoteproc_cdsp: remoteproc@32300000 { qcom,broken-reset; ... };
```

**Le patch `Set correct owner for SCM SHM bridge` est à écarter** dans ce contexte : il
ajoute `#include <dt-bindings/firmware/qcom,scm.h>` pour `QCOM_SCM_VMID_SELF_OWNER`, une
constante qui n'existe pas dans linux-next et dont le code consommateur
(`shm-bridge-vmid`) est absent. Il dépend d'autres correctifs de la même série. Le
reporter dans un DTS aplati casse simplement la compilation.

**⚠️ ABI des modules — le piège silencieux.** Le patch sur le cœur remoteproc change
`bool auto_boot` en `enum rproc_auto_boot` dans `struct rproc`. Le champ passe de 1 à
4 octets alignés : la structure **grandit de 8 octets** et tout ce qui suit est décalé.
`CONFIG_REMOTEPROC=y` étant intégré au noyau, un module `qcom_q6v5_pas.ko` neuf chargé par
une **ancienne** `Image` écrit alors au-delà de la structure allouée. Sans
`CONFIG_MODVERSIONS`, rien ne l'empêche et aucun message n'apparaît.

Or plusieurs `Image` partageant la même version de noyau partagent aussi `/lib/modules` :
il n'existe aucune sélection de modules par image. Deux issues seulement — changer
`CONFIG_LOCALVERSION` pour obtenir un arbre de modules distinct, ou ajouter
`modprobe.blacklist=qcom_q6v5_pas` à **toutes** les autres entrées du menu. Ici la seconde,
les modules Surface Aggregator hors-arbre étant figés sur la version courante.

### Vérifier

```bash
cat /sys/class/remoteproc/remoteproc*/state    # attendu : attached
cat /proc/asound/cards
dmesg | grep -c "error -22 initializing firmware"   # attendu : 0
```

Résultat obtenu ici, en EL2 avec KVM :

```
remoteproc remoteproc0: attaching to adsp
remoteproc remoteproc0: remote processor adsp is now attached
remoteproc remoteproc1: attaching to cdsp
remoteproc remoteproc1: remote processor cdsp is now attached

 0 [X1P42100Microso]: x1e80100 - X1P42100-Microsoft-Surface-Pro-
```

## Diagnostiquer après `ExitBootServices`

La console UEFI disparaît et les échecs sont trop rapides pour être filmés. Deux
techniques ont porté toute l'enquête :

- **Bandeaux dans le framebuffer** — capturer la base GOP et `PixelsPerScanLine` dans
  `efi_main`, puis peindre une bande de 80 px par étape franchie. La progression devient
  une pile de couleurs lisible sur une photo, et ça continue de fonctionner après EBS.
- **Journal sur l'ESP, flushé à chaque ligne** — valable uniquement **avant** EBS : une
  fois `ExitBootServices` revenu, le pilote FAT est mort et les écritures en attente sont
  perdues.

Pour du code exécuté MMU coupée, ni `.data` ni rien qui puisse être encore sale en cache
n'est lisible de façon fiable. Passer une adresse par `.data` échoue silencieusement ;
la ranger après les emplacements de registres de `tb_jmp_buf` — notre propre mémoire,
explicitement flushée — fonctionne.
