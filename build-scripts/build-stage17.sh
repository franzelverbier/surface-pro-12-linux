#!/bin/bash
set -e
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE17 rebuild + copie SHARGE start $(date -u +%H:%M:%S) ==="
ROOT=/root/sp12/rootfs
IMG=/root/sp12/sp12.img
export MTOOLS_SKIP_CHECK=1
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
echo "image OK ($(stat -c%s "$IMG") octets)"
echo "=== copie vers SHARGE ==="
if [ -d /mnt/d ] && ls /mnt/d >/dev/null 2>&1; then
  echo "SHARGE = /mnt/d ; copie en cours..."
  cp "$IMG" /mnt/d/sp12-linux.img && sync && echo "COPIE SHARGE OK: /mnt/d/sp12-linux.img ($(stat -c%s /mnt/d/sp12-linux.img) octets)"
else
  echo "/mnt/d non monte -> copie sur C: (Windows copiera ensuite)"
  cp "$IMG" /mnt/c/sp12-linux/sp12.img && sync && echo "image sur C: prete"
fi
echo "=== STAGE17 done $(date -u +%H:%M:%S) ==="
