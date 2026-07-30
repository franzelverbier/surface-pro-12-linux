#!/bin/bash
set -e
ROOT=/root/sp12/rootfs
V=/root/vtoy/vtoyboot-1.0.6
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE16 vtoyboot hook start $(date -u +%H:%M:%S) ==="
[ -d "$V" ] || { rm -rf /root/vtoy; mkdir -p /root/vtoy; tar xzf /root/sp12/vtoyboot.tar.gz -C /root/vtoy; }
echo "vtoydrivers: $(tr '\n' ' ' < "$V/tools/vtoydrivers")"
# binaires aarch64
cp -a "$V/tools/vtoydumpaa64"  "$ROOT/usr/bin/vtoydump"
cp -a "$V/tools/vtoypartxaa64" "$ROOT/usr/bin/vtoypartx"
cp -a "$V/tools/vtoydrivers"   "$ROOT/usr/bin/vtoydrivers"
chmod +x "$ROOT/usr/bin/vtoydump" "$ROOT/usr/bin/vtoypartx"
# hooks mkinitcpio
mkdir -p "$ROOT/usr/lib/initcpio/install" "$ROOT/usr/lib/initcpio/hooks"
cp -a "$V/distros/mkinitcpio/ventoy-install.sh" "$ROOT/usr/lib/initcpio/install/ventoy"
cp -a "$V/distros/mkinitcpio/ventoy-hook.sh"    "$ROOT/usr/lib/initcpio/hooks/ventoy"
# chroot : HOOKS + dm_mod + regen NOTRE initramfs
mount -t proc proc "$ROOT/proc"; mount --rbind /sys "$ROOT/sys"; mount --make-rslave "$ROOT/sys"; mount --rbind /dev "$ROOT/dev"; mount --make-rslave "$ROOT/dev"
cleanup(){ umount -R "$ROOT/proc" 2>/dev/null||true; umount -R "$ROOT/sys" 2>/dev/null||true; umount -R "$ROOT/dev" 2>/dev/null||true; }
trap cleanup EXIT
chroot "$ROOT" /bin/bash -ec '
grep -q "ventoy" /etc/mkinitcpio.conf || sed -i "s/^HOOKS=(\(.*\))/HOOKS=(\1 ventoy)/" /etc/mkinitcpio.conf
grep -q "dm_mod" /etc/mkinitcpio.conf || sed -i "s/^MODULES=(\(.*\))/MODULES=(\1 dm_mod)/" /etc/mkinitcpio.conf
echo "HOOKS: $(grep ^HOOKS= /etc/mkinitcpio.conf)"
echo "MODULES: $(grep ^MODULES= /etc/mkinitcpio.conf)"
echo "vtoydump arch: $(file -b /usr/bin/vtoydump | cut -c1-40)"
mkinitcpio -k 7.1.0-next-20260626 -g /boot/initramfs-sp12.img -S autodetect 2>&1 | tail -12
'
echo "=== STAGE16 done $(date -u +%H:%M:%S) ==="
