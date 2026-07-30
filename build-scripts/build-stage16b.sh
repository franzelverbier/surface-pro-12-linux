#!/bin/bash
set -e
ROOT=/root/sp12/rootfs
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE16b udev-init + ventoy start $(date -u +%H:%M:%S) ==="
mount -t proc proc "$ROOT/proc"; mount --rbind /sys "$ROOT/sys"; mount --make-rslave "$ROOT/sys"; mount --rbind /dev "$ROOT/dev"; mount --make-rslave "$ROOT/dev"
cleanup(){ umount -R "$ROOT/proc" 2>/dev/null||true; umount -R "$ROOT/sys" 2>/dev/null||true; umount -R "$ROOT/dev" 2>/dev/null||true; }
trap cleanup EXIT
chroot "$ROOT" /bin/bash -ec '
# init udev (busybox) au lieu de systemd, ventoy AVANT filesystems
sed -i "s/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block ventoy filesystems fsck)/" /etc/mkinitcpio.conf
grep -q "dm_mod" /etc/mkinitcpio.conf || sed -i "s/^MODULES=(\(.*\))/MODULES=(\1 dm_mod)/" /etc/mkinitcpio.conf
echo "HOOKS: $(grep ^HOOKS= /etc/mkinitcpio.conf)"
mkinitcpio -k 7.1.0-next-20260626 -g /boot/initramfs-sp12.img -S autodetect 2>&1 | tail -14
echo "taille initramfs: $(ls -la /boot/initramfs-sp12.img | awk "{print \$5}")"
'
echo "=== STAGE16b done $(date -u +%H:%M:%S) ==="
