#!/bin/bash
set -e
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE5c fix ESP start $(date -u +%H:%M:%S) ==="
IMG=/root/sp12/sp12.img
export MTOOLS_SKIP_CHECK=1
losetup -D 2>/dev/null || true
LOOP=$(losetup -fP --show "$IMG"); echo "loop=$LOOP"
cat > /tmp/embed.cfg <<'EOF'
search --no-floppy --set=root --label SP12ROOT
configfile ($root)/boot/grub/grub.cfg
EOF
grub-mkstandalone -O arm64-efi -o /tmp/BOOTAA64.EFI \
  --modules="part_gpt ext2 fat search search_label search_fs_uuid normal linux fdt configfile echo test all_video gfxterm gzio" \
  "boot/grub/grub.cfg=/tmp/embed.cfg" 2>&1 | tail -3
echo "taille EFI generee: $(stat -c%s /tmp/BOOTAA64.EFI 2>/dev/null) octets"
mcopy -o -i "${LOOP}p1" /tmp/BOOTAA64.EFI ::/EFI/BOOT/BOOTAA64.EFI
echo "--- ESP /EFI/BOOT ---"; mdir -i "${LOOP}p1" ::/EFI/BOOT
echo "--- verif grub.cfg sur ext4 ---"
mkdir -p /mnt/t; mount "${LOOP}p2" /mnt/t
ls -la /mnt/t/boot/ | grep -E 'Image|initramfs-sp12|sp12.dtb|grub'
echo "--- grub.cfg ---"; cat /mnt/t/boot/grub/grub.cfg
umount /mnt/t
losetup -d "$LOOP"
echo "IMAGE OK: $IMG ($(ls -la "$IMG" | awk '{print $5}') octets)"
echo "=== STAGE5c done $(date -u +%H:%M:%S) ==="
