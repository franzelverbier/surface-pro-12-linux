# Guide CachyOS — piloter le Surface Pro 12 sous Linux

Playbook complet à utiliser **depuis la machine CachyOS** pour se connecter au Surface Pro 12" (Snapdragon **x1p42100**, ARM64) qui tourne sous Linux **headless**, et pour le réparer/reconstruire si besoin.

> 🔑 **Accès** — le compte root est créé avec le mot de passe par défaut `sp12`
> (voir le README). Le WiFi se configure dans
> `/etc/wpa_supplicant/wpa_supplicant-wlan0.conf`.

---

## 0. À comprendre d'abord
- **Une seule machine physique** = le SP12. Soit il tourne **Windows** (interne), soit **Linux** (SSD USB) — jamais les deux. On le pilote en **SSH depuis CachyOS** (3e machine sur le même WiFi).
- **Écran interne noir = normal** (pilote `msm` capricieux). Le système tourne quand même : WiFi + SSH répondent. **Ne PAS rebooter en boucle** (ça corrompt l'ext4 via des `-EIO` USB). Démarrer **une fois**, attendre ~2 min, se connecter.

---

## 1. Se connecter (cas nominal)
SP12 démarré (~2 min), depuis CachyOS (même WiFi `<REDACTED>`) :
```bash
ssh root@sp12.local          # la FRITZ!Box résout le nom -> pas besoin de l'IP
# si le nom ne répond pas, le script qui cherche tout seul :
ssh root@sp12.local   # ou l'IP relevee sur le routeur
# dernier recours, l'IP directe (a déjà été 192.168.X.Y) :
ssh root@192.168.X.Y
```
Puis, pour ne plus jamais chasser l'IP :
```bash
curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up
```

### Messages d'erreur SSH → cause
| Message | Cause probable | Action |
|---|---|---|
| `Could not resolve hostname` | la box ne connaît pas encore `sp12` | attendre le DHCP, ou `ssh root@sp12.local   # ou l'IP relevee sur le routeur`, ou l'IP |
| `Connection refused` | sshd pas encore prêt / pas fini de booter | attendre 30 s, réessayer |
| `Connection timed out` | SP12 pas sur le réseau (pas booté / WiFi KO) | vérifier le boot ; voir §2 |
| `REMOTE HOST IDENTIFICATION CHANGED` | clé d'hôte changée (réinstall) | `ssh-keygen -R sp12.local` puis réessayer |

---

## 2. Si le SP12 ne répond pas — inspecter/réparer la clé depuis CachyOS
Éteindre le SP12, **brancher le SanDisk sur CachyOS**, puis :
```bash
lsblk -o NAME,SIZE,LABEL,FSTYPE,MOUNTPOINTS      # repérer sda2 = label SP12ROOT
# si pas monté auto (fs "sale" après reboots) :
sudo fsck.ext4 -y /dev/sdX2                        # remplace X : répare l'ext4
sudo mkdir -p /mnt/sp12 && sudo mount /dev/sdX2 /mnt/sp12
set M /mnt/sp12                                    # (fish) ; en bash : M=/mnt/sp12
```
**Lire les logs du dernier boot** (WiFi, erreurs) :
```bash
sudo journalctl -D $M/var/log/journal --list-boots | tail
sudo journalctl -D $M/var/log/journal -b -1 --no-pager | grep -iE 'ath12k|wlan0|wpa|dhcpcd|leased|sshd|error' | tail -60
```
**Démonter proprement avant de rebrancher sur le SP12** :
```bash
sync && sudo umount /mnt/sp12
```

---

## 3. Réseau — vérifier / corriger le WiFi
> ⚠️ **CHANGEMENT 2026-07-02 : la pile réseau est désormais NetworkManager** (bascule propre faite avec l'install KDE — l'applet plasma-nm gère le WiFi graphiquement). `wpa_supplicant@wlan0` et `dhcpcd` sont **désactivés**. L'ancien interdit « pas de NetworkManager » ne visait que la cohabitation des deux piles — NM seul est OK.

Sur la clé montée (`$M`) :
```bash
# services réseau activés (doit voir NetworkManager + sshd ; wpa_supplicant@wlan0/dhcpcd DÉSACTIVÉS)
ls $M/etc/systemd/system/multi-user.target.wants/ | grep -iE 'wpa|dhcpcd|sshd|NetworkManager'
# profil WiFi NM (psk en clair, chmod 600)
sudo cat "$M/etc/NetworkManager/system-connections/<REDACTED>.nmconnection"
# ancienne config wpa (référence, plus utilisée)
sudo cat $M/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
# firmware ath12k (doit contenir amss.bin, board-2.bin, board.bin[repli], m3.bin)
ls $M/usr/lib/firmware/ath12k/WCN7850/hw2.0/
```
> ✅ Le WiFi fonctionne en WPA2 `psk=`. Firmware ath12k + `board.bin` de repli présents. En cas de souci NM : le script `/usr/local/bin/switch-to-nm.sh` sur la machine contient la logique de bascule/rollback (réactiver `wpa_supplicant@wlan0`+`dhcpcd` et désactiver NM pour revenir en arrière). NM utilise la vraie MAC → l'IP DHCP peut différer de l'ancienne (ex. `.60` au lieu de `.68`) ; passer par `sp12.local` ou Tailscale.

---

## 4. Le noyau custom
- **Version : `7.1.0-next-20260626`** — **compilé le 2026-06-26 à 18:28:20 (CEST)**. (Voir `SP12-VERSION-FONCTIONNELLE.md` : ne pas confondre avec les artefacts du 30/06.)
- Dans ce dossier :
  - `kernel/config-7.1.0-next-20260626` — la `.config` exacte utilisée.
  - `kernel/sp12.dtb` — le Device Tree du SP12 (board pas encore upstream).
- **Gros artefacts (NON versionnés, trop lourds pour git)** — sur le SP12 :
  - `Image` (48,7 Mo) : WSL `/root/linux-next/arch/arm64/boot/Image` (et rootfs `/boot/Image`)
  - `initramfs-sp12.img` (~163 Mo), modules `7.1.0-next-20260626/` (~250 Mo) : dans le rootfs
  - source complet (5 Go) : WSL `/root/linux-next`
- **Recompiler** (dans WSL Ubuntu-24.04, aarch64) :
  ```bash
  cd /root/linux-next
  cp .config .config.bak            # la config est déjà bonne
  make -j$(nproc) Image modules      # ~1h sur le SP12
  ```

---

## 5. Réécrire l'image / réparer la table GPT
L'image complète est sur le Windows du SP12 : `C:\sp12-linux\sp12.img` (12 Go). Équivalents **depuis Linux** (CachyOS) si tu écris sur un disque :
```bash
sudo dd if=sp12.img of=/dev/sdX bs=4M status=progress conv=fsync
# IMPÉRATIF après avoir écrit une petite image sur un grand disque :
sudo sgdisk -e /dev/sdX            # replace l'en-tête GPT de secours en fin de disque
sudo partprobe /dev/sdX
# agrandir la racine pour occuper tout le disque :
sudo parted /dev/sdX resizepart 2 100%
sudo e2fsck -f /dev/sdX2 && sudo resize2fs /dev/sdX2
```
> Côté Windows, les équivalents sont dans `scripts/` : `write-linux-sandisk.ps1` (écriture RAW), `repair-gpt.ps1` (réparation GPT sans Linux). Sans `sgdisk -e`, **l'UEFI du SP12 refuse de booter** (table GPT jugée corrompue).

---

## 6. Pièges connus
- **USB fragile** = la cause n°1 des galères. Mesures :
  - `usbcore.autosuspend=-1` dans la cmdline (empêche le décrochage du SSD → `-EIO`). C'est le « mode moins agressif » côté USB.
  - **jamais d'I/O lourde entre 2 SSD USB en même temps** (la copie inter-SSD gèle le bus — la faire depuis CachyOS, pas depuis le SP12).
  - câble/port **USB 3** correct (un lien à 35 Mo/s ≈ USB 2 provoque des erreurs).
- **Veille** : le Snapdragon ne se réveille pas → cibles `sleep/suspend/hibernate` masquées + `logind IdleAction=ignore` (déjà en place ; voir `scripts/patch-nosleep.sh`).
- **Écran** : `msm` capricieux → headless + SSH par défaut.
- **Audio** : firmware codec manquant → erreurs `qcom-iris -2` inoffensives ; **ne pas blacklister `iris`**.
- **Reboots — RÈGLE D'OR : COLD BOOT UNIQUEMENT, JAMAIS `systemctl reboot`.** Un reboot à chaud laisse le contrôleur USB + le chip WiFi WCN7850 **coincés** → flot d'`EXT4-fs error -EIO` et/ou `wlan0` absent (machine muette 8-20 min). **Récupération** : extinction **forcée** (bouton power maintenu **15-20 s** jusqu'à écran totalement noir) → attendre **30 s** → rallumer. Le cold boot reset l'USB → disque stable (0 `-EIO`), WiFi remonte, Tailscale se reconnecte seul. Si l'ext4 reste sale après le flot de `-EIO` → `fsck.ext4 -y` (§2).
- **UAS instable sur le SSD 1,8 To** (`SanDisk Portable`, `0781:55bb`) : ajouter **`usb-storage.quirks=0781:55bb:u`** à la cmdline (force le mode BOT stable). La clé flash 114 Go (`0781:55a9`) n'en a pas besoin (BOT natif).
- **Accès permanent = Tailscale** (installé en **binaire statique**, pas via pacman qui clobberait le noyau) : `tailscale ssh root@sp12` de partout, ou `ssh root@sp12.local` en LAN.

---

## 8. Politique de mises à jour (gel anti-casse, posé le 2026-07-02)

Le boot repose sur des composants **sur-mesure** (noyau -next maison, DTB harrison, firmwares décompressés/custom, module SAM patché). Tout ce qui peut les toucher est gelé dans `/etc/pacman.conf` :

```
IgnorePkg = linux-aarch64 linux-aarch64-headers linux-firmware* systemd systemd-libs systemd-resolvconf systemd-sysvcompat mkinitcpio mesa vulkan-freedreno
NoUpgrade = boot/Image boot/Image.gz boot/initramfs-sp12.img boot/sp12.dtb boot/grub/grub.cfg usr/lib/firmware/ath12k/WCN7850/hw2.0/board.bin usr/lib/firmware/qcom/gen71500_sqe.fw usr/lib/firmware/qcom/gen71500_gmu.bin usr/lib/firmware/qcom/gen71500_zap.mbn
```

- **IgnorePkg** : noyau (écrasait /boot/Image), systemd (le 261 cassait logind), firmware (écraserait board.bin ath12k custom + firmwares GPU), mkinitcpio (régénère l'initramfs), mesa/vulkan (le userspace GPU doit rester aligné sur le noyau gelé).
- **NoUpgrade** : ceinture supplémentaire fichier par fichier — même si un paquet gelé était réinstallé un jour, pacman poserait un `.pacnew` au lieu d'écraser.
- **Reste librement updatable** : KDE/Plasma, applis, bibliothèques générales — `pacman -Syu` les prendra sans toucher au gel (toujours `-Syu` complet, jamais `-Sy` seul, et de préférence supervisé).
- **Dégel prévu** : à la migration **Linux 7.2 stable** (~fin août 2026, support SP12 mainline) — retirer délibérément le gel, migrer noyau+firmware d'un bloc, re-tester.
