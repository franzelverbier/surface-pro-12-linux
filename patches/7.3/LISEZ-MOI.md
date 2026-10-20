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

## Allègement de la pile — 18/10/2026

`0011` ne garde que la partie bouton marche (KEY_WAKEUP), reformulée pour l'amont
(`Input: pm8941-pwrkey - report the press that woke the system as KEY_WAKEUP`) ; la
partie PDC (effacement du statut au démasquage en mode secondaire) était du code mort
depuis le DTB PDC du 04/10 (passage direct) et part dans `abandonnes/`. linux-next du
16/10 ajoute d'ailleurs un compatible Purwa au pilote PDC (`086eac130a`) et retire le
contournement Hamoa du DTS Purwa (`13ca1c0b7d`) : l'amont a suivi le même diagnostic.

État amont (linux-next 20261016) :

| Patch | Amont |
|---|---|
| `0012` pwrseq power off WLAN at probe | ✅ dans linux-next (`dbd674ccf3`) : sortira de la pile à son arrivée en mainline |
| rfkill ath12k Surface (SP11) | ✅ dans linux-next (`5949d1910f`) |
| `0011` KEY_WAKEUP | prêt à l'envoi : `patches/envoi-amont/0001-Input-pm8941-pwrkey-…` (checkpatch propre) |
| `0003-0009` attach PAS + SMP2P (Stephan Gerhold) | pas dans linux-next |
| `0010` camss SP12 (CyberMyth) | pas dans linux-next |
| `base/0001` ath12k CSA (diagnostic de Baochen Qiang) + RTC SAM | pas dans linux-next |

Branche `cameras-73-rc7` réécrite (sauvegarde : étiquette `sauvegarde/cameras-73-rc7-avant-pdc`) ;
l'Image en service est encore bâtie avec l'ancienne 0011 (le code PDC y est inerte).

## 0013 — PDC Purwa (20/10/2026)

`0013` = linux-next `086eac130a` (Maulik Shah) : compatible `qcom,x1p42100-pdc` → PDC remis en
mode direct par SCM, **sans** `x1e_quirk` (le défaut matériel du X1E est corrigé dans le
silicium de Purwa). Le défaut reprend le DTB de juin d'origine (`sp12-el2-cam.dtb`, qui porte
déjà ce compatible) au lieu de `sp12-el2-cam-pdc.dtb` (overlay du 04/10, compatible X1E).
Effet mesuré : le capteur du couvercle (TLMM 2) ne levait d'interruption qu'à l'ouverture,
jamais à la fermeture, donc SW_LID ne changeait jamais et rabattre le cache ne mettait pas en
veille. Avec 0013 : « Lid closed », veille, réveil à l'ouverture ; tactile calme (0 IRQ/s).
L'ancien overlay `dts/pdc-x1e80100.dtso` n'est plus utilisé par le défaut.
