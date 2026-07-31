# Reconstruction du noyau SP12 (7.1.0-next-20260626)

## ⚠️ Source perdue (2026-07-27)
L'arbre source `/root/linux-next` (build WSL d'origine) a été SUPPRIMÉ. Il n'existe plus
d'arbre source complet (vérifié : /root, /data/git, disque de backup Sharge).
**Tout le nécessaire pour reconstruire est DANS CE DÉPÔT :**
- `patches/0001`..`0006` : les 6 patches SP12 de la série d'origine (SAM, panel eDP
  NE120DRM, ASoC speaker, qcom-scm, DTS `x1p42100-microsoft-sp12`, makefile)
  + `patches/registry-next20260626.c`
- `kernel/config-7.1.0-next-20260626` : le `.config`
- `kernel/sp12.dtb`    : DTB compilé de référence
- `build-scripts/`     : scripts de build par étapes (référence)

## Recette re-clone + build
1. `git clone --depth 1 -b next-20260626 https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git linux-next`
   (si le tag `next-20260626` est élagué de kernel.org : prendre le commit le plus proche)
2. `cd linux-next && git apply ../patches/000[1-6]-*.patch`
   (borne `[1-6]` volontaire : `patches/0007-drm-panel-edp-Add-Sharp-SHP-…` ne fait PAS
   partie de la série qui a produit ce noyau. `patches/serie-complete/` non plus — c'est
   la série EL2/remoteproc, à part.)
3. `cp ../kernel/config-7.1.0-next-20260626 .config && make olddefconfig`
4. `make -j$(nproc) Image modules dtbs`
5. Installer : `Image` → `/boot/Image` ; `make modules_install` ; DTB → `/boot/sp12.dtb`

## Debug EL2 / ramoops
Pour capturer un hang au boot EL2 (via slbounce), activer AVANT le build :
`scripts/config -e PSTORE -e PSTORE_RAM -e PSTORE_CONSOLE -e PSTORE_PMSG && make olddefconfig`
puis réserver une région ramoops (nœud `reserved-memory` dans le DTS, ou cmdline
`ramoops.mem_address=.../mem_size=...`). Après un boot EL2 figé + reset, relire `/sys/fs/pstore`.
