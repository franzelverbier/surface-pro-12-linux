# Pile 7.3 du SP12 — ordre d'application

Sur `v7.3-rc3` (fd73f4a66), dans cet ordre :

1. `base/0001-0004` — commits de base de `/data/linux-7.3`, exportés le 05/10/2026 :
   ath12k CSA + RTC SAM (6f67ce221), puis trois commits DTS du SP12.
2. `0001-0011` — la pile 7.3.

Au rebase :

| Patch | Sort de la pile | Raison |
|---|---|---|
| `0001` revert QoS interconnect | à partir de v7.3-rc6 | en mainline (2cc67425a97e) |
| `0002` handover q6v5_pas | à partir de v7.3-rc5 | en mainline |
| `0003-0009` SMP2P / attach | — | hors arbre en rc6 |
| `0010` camss x1p42100 | — | hors arbre en rc6 |
| `0011` PDC + KEY_WAKEUP | — | hors arbre ; la partie PDC ne sert plus (passage direct, DTB corrigé), KEY_WAKEUP oui |
| `base/0001` ath12k CSA (Baochen Qiang) + RTC SAM | — | hors arbre en rc6 |

`abandonnes/0012` (PDC x1p42100) : remplacé par `dts/pdc-x1e80100.dtso`.
Toujours rebâtir avec `make LOCALVERSION=` (sinon « + » et modules introuvables).

## Rebase sur v7.3-rc7 — 17/10/2026

Branche `cameras-73-rc7` de `/data/linux-7.3`, partie de `v7.3-rc7` (12/10) :
`base/0001-0004` puis `0003-0011`, reportés par `cherry-pick -x` sans conflit.
`0001` et `0002` retirés (en mainline). Ajout de `0012` pwrseq « power off WLAN at
probe » : la v2 appliquée par Bartosz Golaszewski le 12/10 (brgl `dbd674ccf30f`),
gardée ici jusqu'à son arrivée en mainline.

Rapatrier rc7 dans l'arbre superficiel : `git fetch --shallow-exclude=v7.3-rc3 origin
refs/tags/v7.3-rc7:refs/tags/v7.3-rc7` (un fetch de tag simple traîne des heures).
Bâti en 37 min (`nice -n 19 make -j3 LOCALVERSION= Image modules`) :
`/boot/Image-7.3rc7-el2`, `/lib/modules/7.3.0-rc7-mainline`, `/boot/initramfs-7.3rc7.img`.
Entrée GRUB `mainline-73rc7` (n° 2), même DTB que le défaut.
