#!/bin/bash
echo "=== HOST /etc/resolv.conf ==="
cat /etc/resolv.conf
echo "=== HOST getent (doit marcher) ==="
getent hosts mirror.archlinuxarm.org || echo "HOST DNS KO"
echo "=== /etc/wsl.conf ==="
cat /etc/wsl.conf 2>/dev/null || echo "(aucun)"
echo "=== systemd-resolved actif ? ==="
systemctl is-active systemd-resolved 2>/dev/null || echo "non"
echo "=== ip route default ==="
ip route 2>/dev/null | grep default
echo "=== test: chroot avec resolv.conf bind-monte ==="
ROOT=/root/sp12/rootfs
mount -t proc proc "$ROOT/proc" 2>/dev/null; mount --rbind /sys "$ROOT/sys" 2>/dev/null; mount --rbind /dev "$ROOT/dev" 2>/dev/null
mount --bind /etc/resolv.conf "$ROOT/etc/resolv.conf"
chroot "$ROOT" /bin/bash -ec 'echo "chroot resolv.conf:"; cat /etc/resolv.conf; echo "chroot getent:"; getent hosts mirror.archlinuxarm.org || echo "CHROOT DNS KO"'
umount "$ROOT/etc/resolv.conf" 2>/dev/null
umount -R "$ROOT/proc" 2>/dev/null; umount -R "$ROOT/sys" 2>/dev/null; umount -R "$ROOT/dev" 2>/dev/null
