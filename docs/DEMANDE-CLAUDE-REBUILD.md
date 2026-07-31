# Demande à Claude — Reconstruire une image Linux SAINE pour le Surface Pro 12

> **À coller comme premier message** dans une session `claude` sur la machine de build (Windows du SP12 → **WSL Ubuntu-24.04**, `wsl -d Ubuntu-24.04 -u root`). Réponds en français. Ce fichier contient tout le contexte + le plan validé après une longue session de diagnostic depuis CachyOS.

---

## 🎯 Objectif
Reconstruire une **image disque bootable et STABLE** pour le Surface Pro 12" (Snapdragon X Plus **x1p42100**, ARM64), à écrire sur clé/SSD USB. But final : la tablette boote **headless**, se connecte en **WiFi**, et répond en **SSH** depuis une autre machine. Puis installer **Tailscale** pour ne plus jamais chasser l'IP.

---

## 🔴 Racine du problème (diagnostic établi le 2026-07-01)
Deux couches de dégâts, cumulées :

1. **Build v5 bâclé (cause profonde).** La version **v4** (build-stage9) bootait bien. **STAGE10a ("v5 stack")** a fait un `pacman -Sy openssh nodejs npm git` qui a **échoué en plein milieu** (voir `build.log`) :
   - `Could not resolve host: mirror.archlinuxarm.org` (DNS KO dans le chroot)
   - `failed to commit transaction (not enough free disk space)` (image trop petite)
   - `required key missing from keyring / keyring is not writable`
   → Système **partiellement installé + partial-upgrade** (`-Sy` sans `-u`) → incohérence de librairies → `dbus`/`logind`/`sshd`/`user-sessions` échouent au boot.

2. **Update pacman du 30/06 (dégâts ajoutés).** Un `pacman -Syu` a ensuite :
   - **écrasé `/boot/Image`** (noyau `-next`) par le noyau **stock `linux-aarch64 7.1.2`** (aucun support x1p42100 → boot mort, écran noir, aucun log) ;
   - fait passer **systemd 260 → 261**, qui **casse `logind`/sessions** sur ce montage.

**Conséquence :** les deux disques physiques disponibles (SSD 1,8 To + clé 114 Go) sont des builds v5 bancals. On ne peut pas les réparer proprement en aveugle. → **On rebâtit à partir d'une base saine.**

---

## ✅ Plan de reconstruction (faire dans l'ordre)

### 0. Point de départ
- **Idéal :** partir d'une **sauvegarde v4** si elle existe (chercher sur le Windows du SP12 : `C:\sp12-linux\` et disques de backup — image ~12 Go d'avant le 30/06, ou artefact "stage9"). v4 bootait ; on ajoute juste openssh/Claude proprement par-dessus.
- **Sinon :** rebâtir le rootfs Arch ARM depuis zéro (les scripts `build-stage*.sh` sont dans `C:\sp12-linux\`), en **corrigeant les 3 conditions qui ont manqué** (ci-dessous).

### 1. Les 3 conditions qui DOIVENT être réunies avant tout `pacman` en chroot
1. **DNS fonctionnel** dans le chroot : `printf 'nameserver 10.255.255.254\n' > /etc/resolv.conf` (IP passerelle WSL ; vérifier avec `getent hosts mirror.archlinuxarm.org`).
2. **Espace disque suffisant** : agrandir l'image AVANT (au moins 16–20 Go d'image, ou `resize2fs` après agrandissement de la partition). Vérifier `df -h /` dans le chroot.
3. **Keyring initialisé** : `pacman-key --init && pacman-key --populate archlinuxarm` (ou, à défaut et en connaissance de cause, `SigLevel = Never` dans `/etc/pacman.conf`).

### 2. Installer les paquets — JAMAIS `-Sy` seul
- Toujours **`pacman -Syu <paquets>`** (upgrade complet, évite le partial-upgrade).
- Paquets cibles : `openssh nodejs npm git` (+ `base-devel` si besoin). Puis Claude Code via `npm install -g @anthropic-ai/claude-code` + son `install.cjs`.
- **Vérifier** après coup : `pacman -Qkk systemd dbus openssh` (intégrité), `ldd /usr/bin/sshd` (pas de lib manquante).

### 3. Config à graver dans l'image (acquis validés aujourd'hui)

**Noyau (NE PAS utiliser le stock) :**
- `/boot/Image` = noyau **`7.1.0-next-20260626`** = `~/linux-next/arch/arm64/boot/Image` (48,7 Mo).
- `/boot/initramfs-sp12.img` (~163 Mo) + `/boot/sp12.dtb` (196 Ko).
- Modules `usr/lib/modules/7.1.0-next-20260626/` présents.

**GRUB `/boot/grub/grub.cfg` — cmdline exacte :**
```
linux /boot/Image root=LABEL=SP12ROOT rw rootwait clk_ignore_unused pd_ignore_unused console=tty0 loglevel=7 usbcore.autosuspend=-1 usb-storage.quirks=0781:55bb:u
initrd /boot/initramfs-sp12.img
devicetree /boot/sp12.dtb
```
- ⚠️ **`usb-storage.quirks=0781:55bb:u`** = **désactive l'UAS** pour le SSD **1,8 To (SanDisk Portable, VID:PID `0781:55bb`)**. L'UAS provoquait des **`EXT4-fs -EIO`** sous charge → boot noyé. Le mode BOT (forcé par ce quirk) est plus lent mais **stable**.
  - Si tu écris sur la **clé 114 Go (SanDisk 3.2Gen1, `0781:55a9`)** : quirk **inutile** (clé flash = BOT natif, déjà stable).
  - Filet complémentaire : `/etc/modprobe.d/uas-quirk.conf` → `options usb-storage quirks=0781:55bb:u`.

**Anti-régression update :** dans `/etc/pacman.conf`, section `[options]` :
```
IgnorePkg = linux-aarch64 linux-aarch64-headers systemd systemd-libs systemd-resolvconf systemd-sysvcompat
```
(empêche un futur `-Syu` de ré-écraser le noyau `-next` et de casser systemd. À retirer seulement pour une migration maîtrisée — voir "Futur : Linux 7.2".)

**Anti-veille (le Snapdragon ne se réveille pas d'une veille) :**
- `ln -sf /dev/null /etc/systemd/system/{sleep,suspend,hibernate,hybrid-sleep}.target`
- `/etc/systemd/logind.conf.d/10-nosleep.conf` : `IdleAction=ignore`, `HandleLidSwitch=ignore`, `HandleSuspendKey=ignore`, `HandleHibernateKey=ignore`.

**Réseau (⚠️ PAS NetworkManager, PAS iwd) :**
- Activer : `sshd.service`, `dhcpcd.service`, `wpa_supplicant@wlan0.service`.
- `/etc/wpa_supplicant/wpa_supplicant-wlan0.conf` :
```
ctrl_interface=/run/wpa_supplicant
update_config=1
country=FR

network={
    ssid="<REDACTED>"
    psk="<REDACTED>"
}
```
  - **Un seul SSID `<REDACTED>`** (2.4 GHz + 5 GHz regroupés dessous). Le second bloc réseau, `<REDACTED-OBSOLETE>`, est **obsolète → à supprimer.**
  - WPA2-`psk` suffit. Option WPA3 si besoin : ajouter `key_mgmt=WPA-PSK SAE` + `ieee80211w=1`.

**Firmware WiFi ath12k** (sinon `wlan0` ne monte pas) :
- `usr/lib/firmware/ath12k/WCN7850/hw2.0/` doit contenir : `amss.bin`, `board-2.bin`, **`board.bin`** (repli custom, board-id 255), `m3.bin`.

**SSH :**
- `/etc/ssh/sshd_config.d/10-sp12.conf` : `PermitRootLogin yes` + `PasswordAuthentication yes`.
- Clés d'hôte présentes (`ssh-keygen -A` si absentes).
- root pw = `sp12` ; hostname = `sp12`.

### 4. Écrire l'image + réparer la GPT (impératif)
```bash
sudo dd if=sp12.img of=/dev/sdX bs=4M status=progress conv=fsync
sudo sgdisk -e /dev/sdX      # replace l'en-tête GPT de secours en fin de disque — SANS ça l'UEFI SP12 refuse de booter
sudo partprobe /dev/sdX
sudo parted /dev/sdX resizepart 2 100%
sudo e2fsck -f /dev/sdX2 && sudo resize2fs /dev/sdX2
```
(Côté Windows : `write-linux-sandisk.ps1` + `repair-gpt.ps1`.)

---

## 🔬 Vérifications post-build (avant de crier victoire)
Monter le rootfs et vérifier :
- `strings /boot/Image | grep 'Linux version'` → doit dire **`7.1.0-next-20260626`** (PAS `-aarch64-ARCH`).
- `grep usb-storage.quirks /boot/grub/grub.cfg` (si SSD 1,8 To).
- `ls -d var/lib/pacman/local/systemd-[0-9]*` → **260.2-2** (ou un 261+ **testé bon**).
- `pacman -Qkk systemd dbus openssh` → 0 fichier manquant/altéré.
- Services : `ls etc/systemd/system/multi-user.target.wants/ | grep -E 'sshd|dhcpcd|wpa'`.

---

## ⚠️ Pièges matériels & discipline de boot (SP12)
- **USB fragile = cause n°1.** `usbcore.autosuspend=-1` + **quirk anti-UAS** (ci-dessus). Éviter les hubs. Brancher le disque **en direct** sur un port du SP12. Câble/port USB-3 correct.
- **Ne PAS rebooter en boucle** → ça corrompt l'ext4 via `-EIO` (`fsck.ext4 -y /dev/sdX2` depuis une autre machine pour réparer). Démarrer **une fois**, attendre ~2-3 min.
- **WiFi capricieux** : après des reboots à chaud, le chip WCN7850 peut rester bloqué → faire un **cold boot complet** (power ~10 s, attendre 30 s, chargeur branché).
- **Écran interne noir = normal** (`msm` capricieux) → headless + SSH par défaut.
- **Audio KO** (inoffensif) : firmware codec manquant → erreurs `qcom-iris -2` ; **ne pas blacklister `iris`** (fige le boot).

---

## 🧯 Ce qui a été réparé le 2026-07-01 (depuis CachyOS, sur le SSD 1,8 To)
Contexte pour comprendre l'état actuel des disques :
- Noyau `-next` **restauré** dans `/boot/Image` (récupéré des images maîtres Ventoy).
- systemd **rétrogradé 261 → 260**.
- **Quirk UAS** ajouté à la cmdline + `modprobe.d`.
- `IgnorePkg` posé (noyau + systemd).
- `fsck.ext4` + `fsck.fat` (fs propres).
- **MAIS** : la base v5 reste incohérente (install pacman bâclée) → `sshd`/`dbus`/`logind` échouent encore. D'où ce rebuild propre.

## 🔭 Futur (fin août 2026) : Linux 7.2 stable
Le **DTS du SP12 (x1p42100) est en mainline dans Linux 7.2** (rc1 = 28/06/2026 ; stable attendu ~fin août). Quand Arch ARM packagera `linux-aarch64` en 7.2 : plus besoin du noyau maison ni du DTB harrison → **retirer `linux-aarch64` de l'`IgnorePkg`**, laisser l'update passer, vérifier que le DTB in-tree boote, et abandonner le build custom. C'est la sortie propre définitive.

---

## 📌 Repères
| | |
|---|---|
| Modèle | Surface Pro 12" 1st Ed, Snapdragon X Plus **x1p42100**, ARM64 |
| Noyau | `7.1.0-next-20260626` (source WSL `/root/linux-next`, `.config` là) |
| SSD 1,8 To | SanDisk Portable SSD — VID:PID **`0781:55bb`** — UAS → quirk requis |
| Clé 114 Go | SanDisk 3.2Gen1 — VID:PID **`0781:55a9`** — flash BOT, stable |
| WiFi | Qualcomm WCN7850 / FastConnect 7800 — SSID `<REDACTED>` / `<REDACTED>` |
| root pw | `sp12` — hostname `sp12` — joignable `sp12.local` |
| Build (Windows) | `C:\sp12-linux\` : `sp12.img`, `build-stage*.sh`, `graft/`, scripts PS1 |
