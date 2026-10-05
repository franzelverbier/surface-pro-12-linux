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
