# SP12 Linux — Version connue FONCTIONNELLE (référence)

> Instantané de la configuration qui **a marché** sur le Surface Pro 12" (Snapdragon X Plus **x1p42100**, ARM64) : bureau KDE affiché à l'écran, clavier, WiFi et SSH opérationnels. À utiliser comme point de retour / base de reconstruction.

## ✅ TL;DR — ce qui fonctionnait
- **Boot** du noyau custom → système complet.
- **Écran interne + clavier** : le bureau **KDE** s'est affiché sur la tablette (au moins une fois, avant que les reboots répétés dégradent l'ext4).
- **WiFi** : `wlan0` associé à `<REDACTED>` (prouvé par `RSN: Group rekeying completed`), **IP DHCP `192.168.X.Y`**.
- **SSH** : `sshd` en écoute sur `:22`, **connexion root réussie** (`Accepted password for root from 192.168.X.Y`).

## 🧩 Configuration exacte
| Élément | Valeur |
|---|---|
| Noyau | **linux-next `7.1.0-next-20260626`** compilé maison (support x1p42100) |
| Fichiers boot | `/boot/Image` (48,7 Mo) + `/boot/initramfs-sp12.img` (~163 Mo) + `/boot/sp12.dtb` (196 Ko) |
| Bootloader | GRUB autonome `BOOTAA64.EFI` (ESP `SP12ESP`, FAT) → `configfile` → `/boot/grub/grub.cfg` sur l'ext4 |
| Entrée GRUB | `linux /boot/Image` + `initrd /boot/initramfs-sp12.img` + `devicetree /boot/sp12.dtb` |
| **Cmdline (stable)** | `root=LABEL=SP12ROOT rw rootwait clk_ignore_unused pd_ignore_unused console=tty0 loglevel=7 usbcore.autosuspend=-1` |
| Rootfs | Arch Linux ARM aarch64, label **`SP12ROOT`** (ext4), + bureau **KDE** installé |
| Réseau | **`wpa_supplicant@wlan0` + `dhcpcd` + `sshd`** activés (⚠️ **pas** NetworkManager) |
| Config WiFi | `/etc/wpa_supplicant/wpa_supplicant-wlan0.conf` : `ssid="<REDACTED>"`, `psk="<REDACTED>"` (WPA2 suffit, pas besoin de SAE) |
| Firmware WiFi | `ath12k/WCN7850/hw2.0/` : `amss.bin`, `board-2.bin`, **`board.bin`** (repli custom board-id 255), `m3.bin` |
| root pw | `sp12` ; hostname `sp12` ; joignable `sp12.local` |
| Passerelle | `192.168.X.Y` (FRITZ!Box) |

## 🕕 Date de compilation du noyau (RÉFÉRENCE — ne pas confondre)
- **Noyau `Image` / `vmlinux` compilé le : `2026-06-26` à `18:28:20` (CEST, +0200).** C'est LA version de référence (support x1p42100).
- `.config` finalisé : `2026-06-26 18:31:20` — `Image` copiée dans le rootfs : `2026-06-26 18:32:51`.
- Build : `root@FranzSurface12`, **gcc 13.3.0** (Ubuntu 24.04 / WSL), GNU ld 2.42. La chaîne de version ne contient pas d'horodatage embarqué (`KBUILD_BUILD_TIMESTAMP` non renseigné) → **la date de référence est celle du fichier produit**.

> ⚠️ **NE PAS CONFONDRE avec des dates du 30 juin 2026.** Le **noyau** est bien du **26/06**. Ce qui date du **30/06** :
> - `initramfs-sp12.img` a été **régénéré le 2026-06-30** (normal — on a changé les hooks mkinitcpio) ; le **noyau reste celui du 26/06**.
> - La mise à jour `pacman` du **2026-06-30** a installé un **noyau *stock* `linux-aarch64` 7.1.2** (+ `initramfs-linux.img`) — **NON utilisé** : notre GRUB boote `/boot/Image` (le nôtre, 26/06), pas le stock.
> - ➡️ Si un autre outil/ordi propose « une version du 30 », il regarde le **noyau stock** ou l'**initramfs**, pas notre noyau. **La bonne référence = 26 juin 2026, 18:28.**

## 🔧 Correctifs de stabilité appliqués (à conserver)
Ajoutés APRÈS la première réussite pour supprimer les instabilités (veille + USB) :
1. **`usbcore.autosuspend=-1`** dans la cmdline (voir ci-dessus).
2. **Anti-veille** (le Snapdragon ne se réveille pas d'une mise en veille → écran noir définitif) :
   - cibles masquées : `ln -sf /dev/null /etc/systemd/system/{sleep,suspend,hibernate,hybrid-sleep}.target`
   - `/etc/systemd/logind.conf.d/10-nosleep.conf` : `IdleAction=ignore`, `HandleLidSwitch=ignore`, `HandleSuspendKey=ignore`.

## ⚠️ Pièges connus (ce qui a cassé la stabilité)
- **Reboots répétés = corruption de l'ext4.** Le contrôleur USB du SP12 lâche sous charge → `EXT4-fs … error -EIO` + journal systemd corrompu. **Ne PAS rebooter en boucle.** Démarrer **une fois**, attendre, se connecter en SSH. (Un `fsck.ext4 -y /dev/sdX2` depuis une autre machine répare l'ext4 sale.)
- **Écran interne capricieux.** Le panneau via `msm` ne se réinitialise pas de façon fiable (kwin : « Applying output configuration failed »). Il a marché une fois, mais **prévoir le headless + SSH** comme mode normal. Écran noir ≠ plantage (le système tourne : WiFi + SSH répondent).
- **Bus USB saturable = le point clé.** L'USB du SP12 est fragile :
  - **`usbcore.autosuspend=-1`** empêche la mise en veille des périphériques USB (le SSD décrochait → `-EIO`). C'est le « mode plus lent / moins agressif » côté USB.
  - **Jamais d'I/O lourde entre 2 SSD USB en même temps** (la copie SHARGE→SanDisk gelait tout le bus).
  - Éviter de brancher trop de périphériques USB au boot ; câble/port USB 3 correct (un lien dégradé donne du 35 Mo/s ≈ USB 2 et provoque des erreurs).
- **Audio KO** (inoffensif) : firmware codec `qcvss8380_pa.mbn` manquant → erreurs `qcom-iris … -2` dans `dmesg`. **Ne pas blacklister `iris`** (fige le boot via sync_state).

## ♻️ Reconstruire / restaurer cet état
- **Image complète** : `C:\sp12-linux\sp12.img` (12 Go, sur le Windows du SP12) — contient noyau + initramfs + DTB + rootfs + GRUB. La réécrire en RAW sur un disque redonne cet état. ⚠️ Après écriture d'une petite image sur un grand disque : **réparer la GPT** (`repair-gpt.ps1`, ou `sgdisk -e /dev/sdX` sous Linux) sinon l'UEFI ne boote pas.
- **Artefacts noyau** (dans WSL Ubuntu-24.04 sur le SP12) :
  - source : `/root/linux-next` (5 Go), `.config` : `/root/linux-next/.config`
  - `Image` : `/root/linux-next/arch/arm64/boot/Image`
  - rootfs monté : `/root/sp12/rootfs` (modules dans `usr/lib/modules/7.1.0-next-20260626/`)
- **Scripts** (Windows) : `C:\sp12-linux\` — `write-linux-sandisk.ps1`, `repair-gpt.ps1`, `patch-cmdline.sh`, `patch-nosleep.sh`, `build-stage*.sh`.

## 🔌 Accès (rappel)
Depuis une autre machine du réseau (CachyOS / téléphone) :
```bash
ssh root@sp12.local        # ou ssh root@192.168.X.Y ; mot de passe : sp12
```
Voir `README.md` à la racine du dépôt.
