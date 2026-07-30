#!/bin/bash
set -e
ROOT=/root/sp12/rootfs
IMG=/root/sp12/sp12.img
export MTOOLS_SKIP_CHECK=1
for m in proc sys dev; do umount -R "$ROOT/$m" 2>/dev/null||true; done
umount -R /mnt/t 2>/dev/null||true; losetup -D 2>/dev/null||true
cat > /tmp/embed.cfg <<'EOF'
search --no-floppy --set=root --label SP12ROOT
configfile ($root)/boot/grub/grub.cfg
EOF
echo "=== creation image 12G (GPT: ESP + ext4) ==="
rm -f "$IMG"; truncate -s 12G "$IMG"; sgdisk -Z "$IMG" >/dev/null
sgdisk -n1:0:+512M -t1:ef00 -c1:SP12ESP "$IMG" >/dev/null
sgdisk -n2:0:0 -t2:8300 -c2:SP12ROOT "$IMG" >/dev/null
LOOP=$(losetup -fP --show "$IMG")
mkfs.fat -F32 -n SP12ESP "${LOOP}p1" >/dev/null
mkfs.ext4 -q -L SP12ROOT "${LOOP}p2"
echo "=== copie rootfs -> ext4 ==="
mkdir -p /mnt/t; mount "${LOOP}p2" /mnt/t; cp -a "$ROOT"/. /mnt/t/; sync
echo "=== VERIF dans l'image ==="
echo -n "noyau: "; strings /mnt/t/boot/Image 2>/dev/null | grep -m1 'Linux version'
echo -n "cmdline: "; grep -o 'linux /boot/Image.*' /mnt/t/boot/grub/grub.cfg
echo -n "systemd: "; ls -d /mnt/t/var/lib/pacman/local/systemd-[0-9]* | xargs -n1 basename
echo -n "quirk modprobe: "; cat /mnt/t/etc/modprobe.d/uas-quirk.conf 2>/dev/null
echo -n "services: "; ls /mnt/t/etc/systemd/system/multi-user.target.wants/ | grep -iE 'sshd|dhcpcd|wpa' | tr '\n' ' '; echo
umount /mnt/t
echo "=== GRUB autonome (BOOTAA64.EFI) ==="
grub-mkstandalone -O arm64-efi -o /tmp/BOOTAA64.EFI --modules="part_gpt ext2 fat search search_label search_fs_uuid normal linux fdt configfile echo test all_video gfxterm gzio" "boot/grub/grub.cfg=/tmp/embed.cfg" 2>&1 | tail -1
mmd -i "${LOOP}p1" ::/EFI ::/EFI/BOOT 2>/dev/null||true
mcopy -o -i "${LOOP}p1" /tmp/BOOTAA64.EFI ::/EFI/BOOT/BOOTAA64.EFI
losetup -d "$LOOP"
echo "=== IMAGE PRETE: $IMG ($(stat -c%s "$IMG") octets) ==="
