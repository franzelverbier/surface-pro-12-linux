#!/bin/bash
set -e
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE14 v9 (nomodeset + 2 SSID) start $(date -u +%H:%M:%S) ==="
ROOT=/root/sp12/rootfs
IMG=/root/sp12/sp12.img
export MTOOLS_SKIP_CHECK=1
# wpa : les deux noms (avec et sans 's'), 2.4 et 5GHz
cat > "$ROOT/etc/wpa_supplicant/wpa_supplicant-wlan0.conf" <<'EOF'
ctrl_interface=/run/wpa_supplicant
update_config=1
country=FR

network={
    ssid="<REDACTED>"
    psk="<REDACTED>"
}
network={
    ssid="<REDACTED>"
    psk="<REDACTED>"
}
EOF
chmod 600 "$ROOT/etc/wpa_supplicant/wpa_supplicant-wlan0.conf"
echo "--- wpa SSIDs ---"; grep ssid "$ROOT/etc/wpa_supplicant/wpa_supplicant-wlan0.conf"
# cmdline : remettre nomodeset (garder regdom FR)
grep -q nomodeset "$ROOT/boot/grub/grub.cfg" || sed -i 's/cfg80211.ieee80211_regdom=FR/cfg80211.ieee80211_regdom=FR nomodeset/' "$ROOT/boot/grub/grub.cfg"
echo "--- cmdline v9 ---"; grep -o 'linux /boot/Image.*' "$ROOT/boot/grub/grub.cfg"
# rebuild
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
echo "=== STAGE14 done $(date -u +%H:%M:%S) ==="
