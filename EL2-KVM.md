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
réessaie trois fois.

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

**ADSP/CDSP ne démarrent pas** — `error -22 initializing firmware`. TrustZone refuse le
service PAS dès que Linux possède EL2. Donc pas d'audio ni de décodage vidéo matériel.
[qebspil](https://github.com/stephan-gh/qebspil) démarre les co-processeurs en EL1 avant
`ExitBootServices` ; il reconnaît nos compatibles (`qcom,x1e80100-adsp-pas` et
`-cdsp-pas`) sans modification, mais réclame des patchs noyau hors-arbre pour que Linux
reprenne la main sur un DSP déjà démarré. Non résolu ici.

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
