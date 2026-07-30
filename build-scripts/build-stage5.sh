#!/bin/bash
set -e
LOG=/mnt/c/sp12-linux/build.log
exec >> "$LOG" 2>&1
echo "=== STAGE5 image build start $(date -u +%H:%M:%S) ==="
ROOT=/root/sp12/rootfs
IMG=/root/sp12/sp12.img
export DEBIAN_FRONTEND=noninteractive
apt-get install -y grub-efi-arm64-bin grub-common gdisk dosfstools e2fsprogs >/dev/null 2>&1
for m in proc sys dev; do umount -R "$ROOT/$m" 2>/dev/null || true; done
mkdir -p "$ROOT/boot/efi"
echo "rootfs taille: $(du -sh "$ROOT" 2>/dev/null | cut -f1)"
rm -f "$IMG"; truncate -s 12G "$IMG"
sgdisk -Z "$IMG" >/dev/null
sgdisk -n1:0:+512M -t1:ef00 -c1:SP12ESP "$IMG" >/dev/null
sgdisk -n2:0:0     -t2:8300 -c2:SP12ROOT "$IMG" >/dev/null
LOOP=$(losetup -fP --show "$IMG"); echo "loop=$LOOP"
mkfs.fat -F32 -n SP12ESP "${LOOP}p1" >/dev/null
mkfs.ext4 -q -L SP12ROOT "${LOOP}p2"
mkdir -p /mnt/t; mount "${LOOP}p2" /mnt/t
mkdir -p /mnt/t/boot/efi; mount "${LOOP}p1" /mnt/t/boot/efi
echo "copie rootfs -> image (peut prendre quelques min)..."
cp -a "$ROOT"/. /mnt/t/
echo "grub-install..."
grub-install --target=arm64-efi --efi-directory=/mnt/t/boot/efi --boot-directory=/mnt/t/boot --removable --no-nvram --recheck 2>&1 | tail -6
cat > /mnt/t/boot/grub/grub.cfg <<'EOF'
set timeout=5
set default=0
menuentry "Surface Pro 12 - linux-next (x1p42100)" {
    search --no-floppy --set=root --label SP12ROOT
    linux /boot/Image root=LABEL=SP12ROOT rw rootwait clk_ignore_unused pd_ignore_unused console=tty0 loglevel=7
    initrd /boot/initramfs-sp12.img
    devicetree /boot/sp12.dtb
}
EOF
sync
echo "--- ESP /EFI/BOOT ---"; ls -la /mnt/t/boot/efi/EFI/BOOT/ 2>&1
echo "--- grub.cfg ---"; cat /mnt/t/boot/grub/grub.cfg
umount -R /mnt/t; losetup -d "$LOOP"
echo "IMAGE PRETE: $IMG ($(ls -la "$IMG" | awk '{print $5}') octets)"
echo "=== STAGE5 done $(date -u +%H:%M:%S) ==="
