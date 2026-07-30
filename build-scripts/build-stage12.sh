#!/bin/bash
set -e
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE12 v7 nomodeset start $(date -u +%H:%M:%S) ==="
IMG=/root/sp12/sp12.img
ROOT=/root/sp12/rootfs
umount -R /mnt/t 2>/dev/null||true; losetup -D 2>/dev/null||true
LOOP=$(losetup -fP --show "$IMG")
mkdir -p /mnt/t; mount "${LOOP}p2" /mnt/t
# ajouter nomodeset (si pas deja la)
grep -q nomodeset /mnt/t/boot/grub/grub.cfg || sed -i 's/usbcore.autosuspend=-1/usbcore.autosuspend=-1 nomodeset/' /mnt/t/boot/grub/grub.cfg
echo "--- cmdline ---"; grep -o 'linux /boot/Image.*' /mnt/t/boot/grub/grub.cfg
# capture log plus tot : sp12-log aussi sur network.target (au cas ou multi-user n'est pas atteint)
sed -i 's/^After=multi-user.target/After=network.target/' /mnt/t/etc/systemd/system/sp12-log.service 2>/dev/null || true
mkdir -p /mnt/t/etc/systemd/system/network.target.wants
ln -sf /etc/systemd/system/sp12-log.service /mnt/t/etc/systemd/system/network.target.wants/sp12-log.service 2>/dev/null || true
sync; umount /mnt/t; losetup -d "$LOOP"
# repercuter sur le rootfs source aussi
grep -q nomodeset "$ROOT/boot/grub/grub.cfg" || sed -i 's/usbcore.autosuspend=-1/usbcore.autosuspend=-1 nomodeset/' "$ROOT/boot/grub/grub.cfg"
echo "copie -> C: ..."; cp "$IMG" /mnt/c/sp12-linux/sp12.img; sync
echo "image C: = $(stat -c%s /mnt/c/sp12-linux/sp12.img) octets"
echo "=== STAGE12 done $(date -u +%H:%M:%S) ==="
