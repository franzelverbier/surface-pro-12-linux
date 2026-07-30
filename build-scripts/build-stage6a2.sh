#!/bin/bash
set -e
ROOT=/root/sp12/rootfs
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE6a2 retry iwd start $(date -u +%H:%M:%S) ==="
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > "$ROOT/etc/resolv.conf"
mount -t proc proc "$ROOT/proc"; mount --rbind /sys "$ROOT/sys"; mount --make-rslave "$ROOT/sys"; mount --rbind /dev "$ROOT/dev"; mount --make-rslave "$ROOT/dev"
cleanup(){ umount -R "$ROOT/proc" 2>/dev/null||true; umount -R "$ROOT/sys" 2>/dev/null||true; umount -R "$ROOT/dev" 2>/dev/null||true; }
trap cleanup EXIT
chroot "$ROOT" /bin/bash -ec '
echo "test DNS:"; getent hosts mirror.archlinuxarm.org | head -1 || echo "DNS KO"
pacman -Sy --noconfirm iwd 2>&1 | tail -5
mkdir -p /etc/iwd
printf "[General]\nEnableNetworkConfiguration=true\n" > /etc/iwd/main.conf
systemctl enable iwd.service >/dev/null 2>&1 && echo "iwd.service active"
systemctl enable systemd-resolved.service >/dev/null 2>&1 || true
[ -e /usr/bin/iwctl ] && echo "IWCTL PRESENT ($(/usr/bin/iwctl --version 2>/dev/null))" || echo "IWCTL ABSENT"
'
echo "=== STAGE6a2 done $(date -u +%H:%M:%S) ==="
