#!/bin/bash
set -e
LOG=/mnt/c/sp12-linux/build.log
exec >> "$LOG" 2>&1
echo "=== STAGE5b image build start $(date -u +%H:%M:%S) ==="
ROOT=/root/sp12/rootfs
IMG=/root/sp12/sp12.img
export MTOOLS_SKIP_CHECK=1
for m in proc sys dev; do umount -R "$ROOT/$m" 2>/dev/null || true; done
umount -R /mnt/t 2>/dev/null || true
losetup -D 2>/dev/null || true
mkdir -p "$ROOT/boot/efi" "$ROOT/boot/grub"

# grub.cfg reel (sur ext4)
cat > "$ROOT/boot/grub/grub.cfg" <<'EOF'
set timeout=5
set default=0
menuentry "Surface Pro 12 - linux-next (x1p42100)" {
    search --no-floppy --set=root --label SP12ROOT
    linux /boot/Image root=LABEL=SP12ROOT rw rootwait clk_ignore_unused pd_ignore_unused console=tty0 loglevel=7
    initrd /boot/initramfs-sp12.img
    devicetree /boot/sp12.dtb
}
EOF
# config embarquee dans le GRUB autonome
cat > /tmp/embed.cfg <<'EOF'
search --no-floppy --set=root --label SP12ROOT
configfile ($root)/boot/grub/grub.cfg
EOF

rm -f "$IMG"; truncate -s 12G "$IMG"
sgdisk -Z "$IMG" >/dev/null
sgdisk -n1:0:+512M -t1:ef00 -c1:SP12ESP "$IMG" >/dev/null
sgdisk -n2:0:0     -t2:8300 -c2:SP12ROOT "$IMG" >/dev/null
LOOP=$(losetup -fP --show "$IMG"); echo "loop=$LOOP"
mkfs.fat -F32 -n SP12ESP "${LOOP}p1" >/dev/null
mkfs.ext4 -q -L SP12ROOT "${LOOP}p2"

# ext4 : rootfs
mkdir -p /mnt/t; mount "${LOOP}p2" /mnt/t
echo "copie rootfs..."
cp -a "$ROOT"/. /mnt/t/
sync; umount /mnt/t

# ESP : GRUB autonome via mtools (sans monter la FAT)
grub-mkstandalone -O arm64-efi -o /tmp/BOOTAA64.EFI \
  --modules="part_gpt ext2 fat search search_label search_fs_uuid normal linux devicetree configfile echo test all_video gfxterm" \
  "boot/grub/grub.cfg=/tmp/embed.cfg" 2>&1 | tail -3
mmd -i "${LOOP}p1" ::/EFI ::/EFI/BOOT 2>/dev/null || true
mcopy -i "${LOOP}p1" /tmp/BOOTAA64.EFI ::/EFI/BOOT/BOOTAA64.EFI
echo "--- ESP /EFI/BOOT ---"; mdir -i "${LOOP}p1" ::/EFI/BOOT
losetup -d "$LOOP"
echo "IMAGE PRETE: $IMG ($(ls -la "$IMG" | awk '{print $5}') octets)"
echo "=== STAGE5b done $(date -u +%H:%M:%S) ==="
