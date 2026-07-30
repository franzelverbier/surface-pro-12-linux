#!/bin/bash
set -e
ROOT=/root/sp12/rootfs
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE13 v8 regdom+diag start $(date -u +%H:%M:%S) ==="
mount -t proc proc "$ROOT/proc"; mount --rbind /sys "$ROOT/sys"; mount --make-rslave "$ROOT/sys"; mount --rbind /dev "$ROOT/dev"; mount --make-rslave "$ROOT/dev"
cleanup(){ umount -R "$ROOT/proc" 2>/dev/null||true; umount -R "$ROOT/sys" 2>/dev/null||true; umount -R "$ROOT/dev" 2>/dev/null||true; }
trap cleanup EXIT
chroot "$ROOT" /bin/bash -ec '
rm -f /etc/resolv.conf; printf "nameserver 10.255.255.254\n" > /etc/resolv.conf
sed -i "s/^SigLevel.*/SigLevel = Never/" /etc/pacman.conf
pacman -Sy --noconfirm wireless-regdb iw 2>&1 | tail -2
# regdom systeme
echo "WIRELESS_REGDOM=\"FR\"" > /etc/conf.d/wireless-regdom 2>/dev/null || true
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
'
# --- service de log enrichi (reseau) ---
cat > "$ROOT/etc/systemd/system/sp12-log.service" <<'EOF'
[Unit]
Description=SP12 diag log to ESP
[Service]
Type=oneshot
ExecStart=/bin/sh -c 'mkdir -p /boot/efi/sp12-logs; dmesg >/boot/efi/sp12-logs/dmesg.log 2>&1; journalctl -b --no-pager >/boot/efi/sp12-logs/journal.log 2>&1; { echo "## ip addr"; ip addr; echo "## iw dev wlan0 link"; iw dev wlan0 link; echo "## iw reg get"; iw reg get; echo "## wpa_cli status"; wpa_cli -i wlan0 status; echo "## wpa_cli scan_results"; wpa_cli -i wlan0 scan_results; echo "## wpa service"; systemctl status wpa_supplicant@wlan0 --no-pager -l; } >/boot/efi/sp12-logs/net.log 2>&1; sync'
RemainAfterExit=yes
EOF
# timer 90s (capture etat stable)
cat > "$ROOT/etc/systemd/system/sp12-log.timer" <<'EOF'
[Unit]
Description=Delayed SP12 diag capture
[Timer]
OnBootSec=90
AccuracySec=1s
[Install]
WantedBy=timers.target
EOF
# n'activer QUE le timer
rm -f "$ROOT/etc/systemd/system/multi-user.target.wants/sp12-log.service" "$ROOT/etc/systemd/system/network.target.wants/sp12-log.service"
mkdir -p "$ROOT/etc/systemd/system/timers.target.wants"
ln -sf /etc/systemd/system/sp12-log.timer "$ROOT/etc/systemd/system/timers.target.wants/sp12-log.timer"
# --- cmdline : -nomodeset +regdom=FR ---
sed -i 's/ nomodeset//; s/usbcore.autosuspend=-1/usbcore.autosuspend=-1 cfg80211.ieee80211_regdom=FR/' "$ROOT/boot/grub/grub.cfg"
echo "--- cmdline v8 ---"; grep -o 'linux /boot/Image.*' "$ROOT/boot/grub/grub.cfg"
# --- rebuild image ---
IMG=/root/sp12/sp12.img; export MTOOLS_SKIP_CHECK=1
for m in proc sys dev; do umount -R "$ROOT/$m" 2>/dev/null||true; done
umount -R /mnt/t 2>/dev/null||true; losetup -D 2>/dev/null||true
cat > /tmp/embed.cfg <<'EOF'
search --no-floppy --set=root --label SP12ROOT
configfile ($root)/boot/grub/grub.cfg
EOF
rm -f "$IMG"; truncate -s 12G "$IMG"; sgdisk -Z "$IMG" >/dev/null
sgdisk -n1:0:+512M -t1:ef00 -c1:SP12ESP "$IMG" >/dev/null
sgdisk -n2:0:0 -t2:8300 -c2:SP12ROOT "$IMG" >/dev/null
LOOP=$(losetup -fP --show "$IMG")
mkfs.fat -F32 -n SP12ESP "${LOOP}p1" >/dev/null; mkfs.ext4 -q -L SP12ROOT "${LOOP}p2"
mkdir -p /mnt/t; mount "${LOOP}p2" /mnt/t; cp -a "$ROOT"/. /mnt/t/; sync; umount /mnt/t
grub-mkstandalone -O arm64-efi -o /tmp/BOOTAA64.EFI --modules="part_gpt ext2 fat search search_label search_fs_uuid normal linux fdt configfile echo test all_video gfxterm gzio" "boot/grub/grub.cfg=/tmp/embed.cfg" 2>&1 | tail -1
mmd -i "${LOOP}p1" ::/EFI ::/EFI/BOOT 2>/dev/null||true
mcopy -o -i "${LOOP}p1" /tmp/BOOTAA64.EFI ::/EFI/BOOT/BOOTAA64.EFI
losetup -d "$LOOP"
cp "$IMG" /mnt/c/sp12-linux/sp12.img; sync
echo "image C: = $(stat -c%s /mnt/c/sp12-linux/sp12.img) octets"
echo "=== STAGE13 done $(date -u +%H:%M:%S) ==="
