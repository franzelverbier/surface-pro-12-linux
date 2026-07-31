# Linux sur Surface Pro 12" (Snapdragon X Plus, X1P42100)

Notes de portage, recette de compilation du noyau, patchs et scripts pour faire tourner
Arch Linux ARM sur le **Microsoft Surface Pro 12 pouces 1ʳᵉ édition** (SoC Qualcomm
`x1p42100`, ARM64).

Ce dépôt contient de la **méthode, pas des binaires**. Les firmwares propriétaires
Qualcomm et `tcblaunch.exe` ne sont pas redistribuables : ils s'extraient de la partition
Windows de votre propre machine (voir [Binaires propriétaires](#binaires-propriétaires)).

## État

| | |
|---|---|
| Écran, GPU (Adreno/mesa) | ✅ |
| Clavier & touchpad Type Cover, tactile, stylet | ✅ |
| WiFi interne (WCN7850) | ✅ |
| Bluetooth | ✅ |
| Audio | ✅ (en EL2 : voir ci-dessous) |
| UFS interne, batterie, veille | ✅ |
| **EL2 + KVM** | ✅ voir ci-dessous |

### EL2 et KVM

La machine démarre **en EL2 avec `/dev/kvm` fonctionnel**, via
[slbounce](https://github.com/TravMurav/slbounce) (Secure Launch). À notre connaissance
c'est le premier Surface Pro 12 documenté dans cet état — le seul autre rapport public sur
X1P42100 concerne une carte de référence.

Les deux limitations qui rendaient l'EL2 pénible sont résolues. Elles méritent d'être
racontées, parce que dans les deux cas la cause n'était pas là où elle en avait l'air.

- **WiFi interne** — les MSI ne parvenaient jamais : tous les compteurs `ITS-PCI-MSI`
  restaient à zéro, PME du root port compris. La cause était dans **notre propre DTS** :
  le SMMUv3 du PCIe (`iommu@15400000`) était laissé en `status = "reserved"`. Le passer à
  `"okay"` suffit. Attention au faux négatif qui nous a coûté des jours :
  `arm-smmu.force_stage=1` ne concerne que le SMMUv1/v2 (`apps_smmu`) et **ne touche pas**
  le SMMUv3 — un test avec ce paramètre n'écarte rien.
- **Audio (ADSP/CDSP)** — `error -22 initializing firmware` : TrustZone refuse le
  chargement de firmware PAS dès que Linux possède EL2. La solution ne consiste pas à
  forcer le chargement, mais à **démarrer les DSP avant** que Linux ne prenne EL2, puis à
  s'y rattacher : [qebspil](https://github.com/stephan-gh/qebspil) les lance depuis l'UEFI
  avant `ExitBootServices`, et une série de patchs remoteproc hors-arbre permet au noyau
  de faire `attach` au lieu de `start`. Détail complet dans [`EL2-KVM.md`](EL2-KVM.md).

Deux modifications de slbounce sont nécessaires sur ce firmware, dont la suppression du
balayage de cache global qui fait tomber la machine. Mode d'emploi complet, diagnostic et
limitations : **[`EL2-KVM.md`](EL2-KVM.md)**.

## Contenu

| Chemin | Contenu |
|---|---|
| [`EL2-KVM.md`](EL2-KVM.md) | démarrer en EL2 avec KVM : prérequis, correctifs slbounce, limites |
| `kernel/` | recette de reconstruction, `.config`, DTS sources et DTB |
| `patches/` | patchs SP12 sur linux-next (SAM, panel eDP, ASoC, qcom-scm, DTS) — voir [`patches/README.md`](patches/README.md) |
| `iso/` | construction de l'ISO live et de l'installateur |
| `build-scripts/` | étapes de construction du rootfs |
| `scripts/` | sauvegarde, vérification d'artefacts, outils Windows (GPT, écriture disque) |
| `systeme/` | `grub.cfg` de référence, config du noyau en cours, `modprobe.d` |
| `docs/` | journaux de portage, état des pilotes, guides |

Points d'entrée : **[`kernel/RECETTE-REBUILD.md`](kernel/RECETTE-REBUILD.md)** pour
reconstruire le noyau, **[`EL2-KVM.md`](EL2-KVM.md)** pour l'accès EL2,
**[`docs/DRIVERS-STATUS.md`](docs/DRIVERS-STATUS.md)** pour l'état détaillé du matériel.

## Binaires propriétaires

Ne sont **pas** dans ce dépôt, et doivent être récupérés depuis votre propre installation
Windows :

- firmwares Qualcomm ADSP/CDSP/GPU (`qcadsp8380.mbn`, `qccdsp8380.mbn`, `gen71500_*`, …)
- le binaire GRUB `BOOTAA64.EFI` utilisé par l'installateur — à prendre dans votre
  distribution plutôt qu'ici : redistribuer un binaire GPL impose d'en fournir les sources
- blobs DSP sous `usr/share/qcom/x1p42100/…`
- `tcblaunch.exe` pour slbounce — à extraire de `sources/install.wim` d'une ISO Windows 11
  ARM64, chemin `Windows/System32/tcblaunch.exe`

⚠️ **La version de `tcblaunch.exe` est déterminante.** Ici, seule la **24H2 RTM 26100.1742**
(sha256 `5dfcd025…d03d`) fonctionne ; une 23H2 22621.2715 et un build Canary échouent tous
les deux, avec pour seul symptôme l'absence de ligne verte sous `sltest`. Valider le
binaire avec `sltest.efi <chemin>` **avant** de chercher un problème ailleurs — c'est le
seul critère fiable.

## Mot de passe par défaut

Les scripts de construction créent un compte root avec le mot de passe **`sp12`**
(`build-scripts/build-stage4d.sh`). C'est un défaut d'installation assumé, pratique pour
un premier accès SSH sur une machine sans écran.

🔒 **À changer dès le premier démarrage** — `passwd` — ou avant toute exposition réseau.

## Crédits

- [harrisonvanderbyl/surface-pro-12-inch-linux](https://github.com/harrisonvanderbyl/surface-pro-12-inch-linux)
  — DTS, patchs noyau et le gros du portage matériel
- [TravMurav/slbounce](https://github.com/TravMurav/slbounce) — Secure Launch et accès EL2
- [stephan-gh/qebspil](https://github.com/stephan-gh/qebspil) — démarrage des
  co-processeurs avant `ExitBootServices`

Les patchs sous `patches/` conservent leurs métadonnées d'auteur d'origine.

## Licence

GPL-2.0 (voir [`LICENSE`](LICENSE)), en cohérence avec le noyau et les patchs amont dont
ce travail dérive. Les fichiers sous `patches/` restent sous la licence et la paternité de
leurs auteurs d'origine.
