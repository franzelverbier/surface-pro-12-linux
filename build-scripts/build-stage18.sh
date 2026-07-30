#!/bin/bash
set -e
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE18 WPA3-SAE + rebuild + SHARGE start $(date -u +%H:%M:%S) ==="
ROOT=/root/sp12/rootfs
IMG=/root/sp12/sp12.img
export MTOOLS_SKIP_CHECK=1
# config wpa avec WPA3-SAE (+ repli WPA2)
cat > "$ROOT/etc/wpa_supplicant/wpa_supplicant-wlan0.conf" <<'EOF'
ctrl_interface=/run/wpa_supplicant
update_config=1
country=FR

network={
    ssid="<REDACTED>"
    key_mgmt=SAE WPA-PSK
    psk="<REDACTED>"
    ieee80211w=1
}
network={
    ssid="<REDACTED>"
    key_mgmt=SAE WPA-PSK
    psk="<REDACTED>"
    ieee80211w=1
}
EOF
chmod 600 "$ROOT/etc/wpa_supplicant/wpa_supplicant-wlan0.conf"
echo "--- wpa config ---"; grep -E 'ssid|key_mgmt' "$ROOT/etc/wpa_supplicant/wpa_supplicant-wlan0.conf"
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
echo "=== recopie sur SHARGE (ecrase l'ancienne) ==="
rm -f /mnt/d/sp12-linux.img
cp "$IMG" /mnt/d/sp12-linux.img && sync && echo "SHARGE OK: $(stat -c%s /mnt/d/sp12-linux.img) octets"
echo "=== STAGE18 done $(date -u +%H:%M:%S) ==="
