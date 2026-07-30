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

## Limitations connues en EL2

**Aucune MSI n'est délivrée.** Tous les compteurs `ITS-PCI-MSI` restent à zéro, PME du
root port PCIe compris ; les interruptions filaires fonctionnent. Le WiFi en est la
victime visible : `ath12k` attend l'interruption `bhi`, expire au bout de ~90 s et
réessaie trois fois. Contournement complet plus bas : **une clé WiFi USB fonctionne**.

Vérifié et écarté : SMMU stage-2 (`arm-smmu.force_stage=1`), traduction du doorbell MSI
(`iommu.passthrough=1`), GICv4.1 (masquage de `VLPIS`/`VMAPP` dans `GITS_TYPER`),
chargement tardif du module. Registres relus sur machine vivante : `GITS_CTLR=1`,
`GICR_CTLR` `EnableLPIs=1`, tables installées, endpoint programmé sur le bon
`GITS_TRANSLATER` — toute la chaîne est correcte et rien n'arrive.

Différence établie : en EL1, Gunyah présentait un GIC **synthétique** (`GICD_CTLR.DS=1`,
DirectLPI, 988 SPI, 16 PPI) ; en EL2, Linux voit le matériel réel (`DS=0`,
`SCR_EL3.FIQ=1`, pas de DirectLPI, 960 SPI, 1024 ESPI, 48 PPI, GICv4.1). Remonté en amont.

**Effet de bord à connaître** : les timeouts d'`ath12k` sérialisent le sondage du Surface
Aggregator, et le clavier Type Cover n'apparaît qu'à ~327 s au lieu de ~13 s. Avec
`modprobe.blacklist=ath12k_wifi7`, il revient en quelques secondes.

### Contournement : une clé WiFi USB

**Le WiFi n'est plus une impasse.** Un adaptateur USB fonctionne en EL2, parce qu'il passe
par le contrôleur xHCI et non par le PCIe : ses interruptions sont filaires, et celles-là
sont bien délivrées — les compteurs `xhci-hcd` s'accumulent normalement.

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

**ADSP/CDSP ne démarrent pas** — `error -22 initializing firmware`. TrustZone refuse le
service PAS dès que Linux possède EL2. Donc pas d'audio ni de décodage vidéo matériel.

### qebspil : la moitié amont fonctionne

[qebspil](https://github.com/stephan-gh/qebspil) démarre les co-processeurs en EL1, juste
avant `ExitBootServices`. **Il fonctionne sur x1p42100**, ce que sa liste de plateformes
ne laissait pas espérer — elle ne mentionne que SC7180, SC8280XP et X1E. Aucune
modification de code n'a été nécessaire : le X1P42100 réutilise les compatibles X1E
(`qcom,x1e80100-adsp-pas` et `-cdsp-pas`), déjà présents dans sa table `pil-types.c`.

Il faut le compiler avec `QEBSPIL_ALWAYS_START=1`, notre device tree ne portant pas la
propriété `qcom,broken-reset` sur laquelle il se restreint par défaut. Les firmwares vont
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

### Ce qui manque encore : le côté noyau

Les DSP tournent, mais Linux l'ignore et tente quand même le chargement PAS, qui échoue.
`drivers/remoteproc/qcom_q6v5_pas.c` ne connaît qu'un seul scénario — charger le firmware
lui-même. Il n'expose pas d'opération `.attach` et ne place jamais le rproc dans l'état
`RPROC_DETACHED`, alors que le cœur de remoteproc sait le faire (`rproc_attach()`,
`RPROC_DETACHED`, utilisés par les pilotes i.MX, STM32 et TI).

Un `.attach` devrait reprendre `qcom_pas_start()` en sautant l'authentification PAS :

```
1. qcom_q6v5_prepare()          handshake / IRQ
2. domaines de puissance proxy  } inoffensifs, votes comptés en référence,
3. horloges (xo, aggre2)        } qebspil les a déjà posés
4. régulateurs (cx, px)
5. qcom_scm_pas_prepare_and_auth_reset()   <- à sauter, échoue en EL2
6. attente du signal SMP2P "ready"          <- déjà émis avant que Linux n'existe
```

L'étape 6 est le vrai point dur : le DSP a signalé son démarrage bien avant que Linux ne
soit là. qebspil le reconnaît d'ailleurs dans son propre code — *« Wait a bit to let
remoteprocs finish handover. FIXME: Wait for the SMP2P signals instead »*.

À noter : **qebspil ne modifie pas le device tree** (aucun `fdt_setprop` dans ses
sources). Il n'existe donc aucun signal en bande — le noyau doit être informé autrement
qu'un DSP tourne déjà : propriété DT ajoutée à la main, paramètre de module, ou détection
matérielle.

Le README de qebspil renvoie vers des branches de patchs noyau sur
`git.codelinaro.org/stephan.gerhold/linux` (`wip/x1e80100-6.16-el2`,
`wip/qcom-laptops-6.17-el2`) qui ne sont plus accessibles — cet utilisateur n'existe plus
dans l'API du service. Non résolu ici.

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
