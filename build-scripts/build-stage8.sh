#!/bin/bash
set -e
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE8 loglevel=7 start $(date -u +%H:%M:%S) ==="
IMG=/root/sp12/sp12.img
ROOT=/root/sp12/rootfs
umount -R /mnt/t 2>/dev/null||true; losetup -D 2>/dev/null||true
# editer grub.cfg DANS l'image (ext4 montable par WSL)
LOOP=$(losetup -fP --show "$IMG")
mkdir -p /mnt/t; mount "${LOOP}p2" /mnt/t
sed -i 's/loglevel=4/loglevel=7/' /mnt/t/boot/grub/grub.cfg
echo "--- cmdline dans l'image ---"; grep -o 'loglevel=[0-9]*' /mnt/t/boot/grub/grub.cfg
sync; umount /mnt/t; losetup -d "$LOOP"
# idem dans le rootfs source (coherence futurs builds)
sed -i 's/loglevel=4/loglevel=7/' "$ROOT/boot/grub/grub.cfg" 2>/dev/null || true
# recopier sur C:
echo "copie image -> C: ..."
cp "$IMG" /mnt/c/sp12-linux/sp12.img
sync
echo "image C: = $(stat -c%s /mnt/c/sp12-linux/sp12.img) octets"
echo "=== STAGE8 done $(date -u +%H:%M:%S) ==="
