# Session 2026-07-02 soir — vérifications à distance + rapatriement des fichiers

Session menée depuis CachyOS en SSH (`root@192.168.X.Y` — **nouvelle IP DHCP**, était `.57` avant ; le nom `sp12` répond aussi).

## 1. Diagnostic « écran noir » — verdict : PAS un crash

Reconstitution depuis `journalctl --list-boots` :

| Boot | Durée | Verdict |
|---|---|---|
| 20:51 → 21:21 | 30 min | **Extinction PROPRE** (séquence systemd complète jusqu'à « System Power Off »). Aucun appui power enregistré. Cause probable : **batterie vide** (ce noyau n'expose aucune télémétrie batterie → aucun avertissement possible) |
| 21:21 (×2) | ~0 s | **2 cold boots morts** à ~920 lignes de journal — signature connue (cf. DRIVERS-STATUS) |
| 22:13 → … | OK | 3ᵉ essai réussi, tout fonctionnel |

**Leçons :**
- Écran noir ≠ forcément crash : penser **batterie** d'abord (brancher, attendre, insister 2-3 fois sur power).
- Le cover/touchpad n'apparaît que **~40 s après le boot** (chargement SAM) — ne pas conclure « clavier mort » avant ~45 s.
- L'horloge dérive fortement en début de boot (pas de RTC) : les horodatages du journal sont faux jusqu'à la synchro NTP (des sauts de ±2 h observés à l'intérieur d'un même boot).
- 2 fonctions secondaires du cover échouent en `-71` (`01:15:01:06:00`, `01:15:02:02:00`) — sans impact clavier/touchpad.

## 2. Accélération graphique — VÉRIFIÉE COMPLÈTE

- Firmwares `gen71500_sqe.fw` + `gmu.bin` chargés (GMU v4.6.4) — fix `.zst` en place.
- `/dev/dri/card0` + `renderD128` présents, devfreq actif (280 MHz au repos).
- Mesa : `freedreno` → renderer **« Adreno X1-45 »** (GL core/compat/ES) — **pas de llvmpipe**.
- KWin Wayland (Plasma) + plasmashell + Xwayland tiennent le nœud de rendu ouvert → composition accélérée.
- ⚠️ **Deux sessions Plasma simultanées** tournent : `alarm` (autologin tty1) + `franz` (tty4). Double consommation — désactiver l'autologin `alarm` ou fermer sa session.

## 3. Fichiers rapatriés dans ce dépôt (ce soir)

| Dossier | Contenu | Provenance |
|---|---|---|
| `build-scripts/` | les 73 scripts/docs de build (`build-stage1→18.sh`, `apply-*`, `assess-*`, HANDOFF.md, LIRE-MOI, logs) | `C:\sp12-linux\` (partition Windows montée en RO via ntfs-3g) |
| `graft/` | le greffon complet appliqué au rootfs : `autoexec-sp12.sh`, `wireupcameras.sh`, sources topologie audio (`vendor/audioreach-topology/`), arborescence firmware/confs | `C:\sp12-linux\graft\` |
| `systeme/` | `grub.cfg` réel, les 3 confs `modprobe.d` (blacklist-uas, uas-quirk, blacklist-surface-sam), **les 7 modules SAM patchés** (`modules-updates/*.ko`, dont le `surface_aggregator_registry.ko` au vermagic hacké), **`config-running-7.1.0-next-20260626.gz`** (config exacte du noyau qui tourne, via `/proc/config.gz`) | système live |
| `firmware/` | `board.bin-custom-boardid255` (88 Ko) — l'artefact ath12k **unique**, introuvable ailleurs | `/usr/lib/firmware/ath12k/WCN7850/hw2.0/board.bin` |

**Exclus volontairement** (gros, récupérables — liste dans `EXCLUS-gros-blobs.txt`) :
`amss.bin`/`board-2.bin` (linux-firmware), `qcadsp8380.mbn`/`qccdsp8380.mbn`/`libc++.so.1`/`fastrpc_shell_0` (ré-extractibles des pilotes de la partition Windows, intacte).

## 4. État des lieux dual boot (relevé, RIEN modifié)

Disque interne `sda` (476,7 Go) — **Windows intact** :

```
sda1   260M  vfat   SYSTEM            ← ESP Windows
sda2    16M  (MSR)
sda3 415.8G  ntfs   Local Disk        ← C:
sda4   793M  ntfs                     ← (env. récup)
sda5   1.3G  ntfs   Windows RE tools
```

Linux tourne sur `sdb` (SSD USB SanDisk 1,8 To : `sdb1` ESP `SP12ESP` 512M + `sdb2` ext4 `SP12ROOT`).

**Relevés faits ce soir (tout est vert) :**
- **BitLocker : état vérifié le 2026-07-02** avec `manage-bde -status C:` et `-protectors -get C:` — résultat conservé hors dépôt. Redimensionnement de `sda3` possible sans risque de verrouillage. Revérifier avant toute opération sur les partitions, l'état a pu changer.
- **efivars : monté en LECTURE-ÉCRITURE**, variables Boot lisibles. `efibootmgr` est simplement **non installé** (à installer — pacman SUPERVISÉ uniquement, cf. règle IgnorePkg).
- **Table de boot UEFI décodée à la main** :
  - `Boot0000` Internal Storage · `Boot0001` USB Storage · `Boot0002` PXE · `Boot0003` MsTemp (**entrée courante** — temporaire firmware) · `Boot0004` Windows Boot Manager
  - `BootOrder = 0001, 0004, 0000, 0002` → **USB d'abord, Windows ensuite** : le dual boot « de fait » existe déjà (SSD USB branché → Linux ; débranché → Windows).

**Plan dual boot interne (à exécuter plus tard, RIEN modifié ce soir) :**
1. Sauvegarde fraîche de la référence v11 AVANT tout (cf. DRIVERS-STATUS §« figer cette référence »).
2. Rétrécir `sda3` (~60-100 Go à libérer) — depuis Windows (`diskmgmt`/`diskpart`) ou `ntfsresize`. Prérequis : NTFS sain, et BitLocker suspendu ou absent — à vérifier au moment de l'opération.
3. Créer `sda6` ext4 `SP12ROOT-INT`, y copier le rootfs de référence (rsync depuis `sdb2`), adapter `fstab` + label.
4. GRUB aarch64 sur l'**ESP interne** (`sda1`, 260 Mo — vérifier la place, sinon la ré-agrandir) avec la cmdline validée **sans** le quirk UAS (inutile hors USB SanDisk) + DTB.
5. Entrée NVRAM « SP12 Linux » via `efibootmgr` + chainload « Windows Boot Manager » dans le menu GRUB.
6. Filet de sécurité : le fallback `\EFI\BOOT\BOOTAA64.EFI` de l'ESP interne reste celui de Windows tant que tout n'est pas validé.
