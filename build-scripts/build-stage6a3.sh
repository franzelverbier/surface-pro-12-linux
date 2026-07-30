#!/bin/bash
set -e
ROOT=/root/sp12/rootfs
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE6a3 iwd (resolv fix) start $(date -u +%H:%M:%S) ==="
mount -t proc proc "$ROOT/proc"; mount --rbind /sys "$ROOT/sys"; mount --make-rslave "$ROOT/sys"; mount --rbind /dev "$ROOT/dev"; mount --make-rslave "$ROOT/dev"
cleanup(){ umount -R "$ROOT/proc" 2>/dev/null||true; umount -R "$ROOT/sys" 2>/dev/null||true; umount -R "$ROOT/dev" 2>/dev/null||true; }
trap cleanup EXIT
chroot "$ROOT" /bin/bash -ec '
rm -f /etc/resolv.conf
printf "nameserver 10.255.255.254\n" > /etc/resolv.conf
if getent hosts mirror.archlinuxarm.org >/dev/null; then echo "DNS OK"; else echo "DNS KO"; exit 1; fi
pacman -Sy --noconfirm iwd 2>&1 | tail -6
mkdir -p /etc/iwd
printf "[General]\nEnableNetworkConfiguration=true\n" > /etc/iwd/main.conf
systemctl enable iwd.service >/dev/null 2>&1 && echo "iwd.service active"
systemctl enable systemd-resolved.service >/dev/null 2>&1 || true
# remettre un resolv.conf systemd pour le runtime cible (iwd+resolved geront)
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
[ -e /usr/bin/iwctl ] && echo "IWCTL PRESENT" || echo "IWCTL ABSENT"
'
echo "=== STAGE6a3 done $(date -u +%H:%M:%S) ==="
