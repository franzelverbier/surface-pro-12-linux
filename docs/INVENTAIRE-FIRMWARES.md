# Inventaire des firmwares et binaires propriétaires — 17/10/2026

But : savoir ce qu'une ISO du portage pourrait embarquer, et ce qu'un script devrait
aller chercher sur la machine de l'utilisateur. Relevé sur le SP12 en service (7.3-rc3,
EL2), paquets `linux-firmware-*` 20260916, en croisant les fichiers sur disque, les
paquets qui les possèdent et ce que le noyau charge réellement.

## Redistribuables (dans les dépôts Arch, ou dérivés d'un fichier qui l'est)

| Fichier | Rôle | Source |
|---|---|---|
| `ath12k/WCN7850/hw2.0/{amss,m3,board-2}.bin` | Wi-Fi | `linux-firmware-atheros` |
| `ath12k/WCN7850/hw2.0/board.bin` | Wi-Fi : la carte du SP12 (`00ab/1414`, board-id 255) n'est pas dans `board-2.bin` | **extrait de `board-2.bin`** (entrée de référence Qualcomm `17cb/3378/255`, `build-scripts/fix-discover.sh`) |
| `qca/hmtbtfw20.tlv`, `qca/hmtnv20.bin` | Bluetooth | `linux-firmware-atheros` |
| `qcom/gen71500_sqe.fw`, `qcom/gen71500_gmu.bin` | GPU Adreno | `linux-firmware-qcom` (pas installé ici : copies posées à la main le 02/07) |
| `qcom/x1e80100/X1P42100-Microsoft-Surface-Pro-12in-tplg.bin` | topologie audio | `linux-firmware-qcom` (même empreinte que la copie installée à la main) |
| `alsa/ucm2/Qualcomm/x1e80100/Surface12in-HiFi.conf` | profil audio | `alsa-ucm-conf` |

## Non redistribuables (Microsoft / Qualcomm, signés pour cette machine)

| Fichier | Rôle | Indispensable ? |
|---|---|---|
| `tcblaunch.exe` (Windows 11 24H2 RTM 26100.1742) | slbounce → **EL2, KVM** | Oui pour l'EL2. Licence Windows. Source : `sources/install.wim` d'une ISO Windows 11 ARM64 |
| `qcom/x1p42100/Microsoft/Surface12/qcadsp8380.mbn`, `adsp_dtbs.elf` | ADSP : son, batterie, USB-C | **En EL2 : non au démarrage** (l'ADSP est démarré par l'UEFI, Linux s'y rattache : `state=attached`, `firmware=unknown`). Oui pour la **reprise après plantage du DSP** (`recovery=enabled`) et pour l'**EL1** |
| `…/qccdsp8380.mbn`, `cdsp_dtbs.elf` | CDSP | Idem |
| `…/qcdxkmsucpurwa.mbn` (= `qcdxkmsuc8380.mbn`) | zap shader du GPU | **EL1 seulement** : en EL2 le zap est désactivé (« using SECVID_TRUST_CNTL instead ») |
| `…/qcvss8380_pa.mbn` | décodage vidéo matériel (iris) | Non : confort |
| `/usr/share/qcom/x1p42100/Surface/surface-pro-12in/` (1 149 fichiers, 19 Mo : bibliothèques DSP, registre capteurs) | capteurs via `hexagonrpcd` (rotation automatique) | Non : confort |
| `…/*.jsn`, `qcdxkmbase8380*.bin`, `qcadsprpc8380.cat` | — | Non : le pd-mapper est dans le noyau (`qcom_pd_mapper`), les `.jsn` ne sont pas lus |

Aucun firmware Microsoft (ni SP12, ni SP11, ni Laptop 7) n'est dans `linux-firmware-qcom`,
alors que Lenovo et Dell y ont publié les leurs (`x1e80100/LENOVO/21N1/qcadsp8380.mbn`,
`dell/xps13-9345/…`). C'est à Microsoft de le faire : la voie amont existe.

## Conséquences pour une ISO

- **Sans aucun fichier Microsoft, en EL1** : écran (sans accélération GPU sûre : pas de
  zap), clavier, tactile, Wi-Fi, Bluetooth, UFS. Ni son, ni batterie, ni USB-C (l'ADSP ne
  démarre pas sans `qcadsp8380.mbn`).
- **Avec le seul `tcblaunch.exe`, en EL2** : l'UEFI démarre lui-même ADSP et CDSP, donc son,
  batterie, USB-C, GPU et KVM marchent sans firmware DSP sur le disque. Reste fragile :
  un plantage du DSP ne se rattrape pas sans les `.mbn`.
- Le script d'extraction doit donc viser, par ordre d'importance : `tcblaunch.exe` (ISO
  Windows 11 24H2), puis le dossier `Surface12` et `/usr/share/qcom` (partition Windows,
  ou paquet de pilotes Microsoft pour le SP12 si Windows a été effacé).
- **À vérifier avant d'en faire une promesse** : que l'UEFI démarre bien l'ADSP sur une
  machine dont la partition Windows a été effacée (d'où lit-il l'image ?).
