#!/bin/bash
set -e
ROOT=/root/sp12/rootfs
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE6a wifi-tools+scripts start $(date -u +%H:%M:%S) ==="
# scripts de greffe sur le rootfs (pour fixwifi/audio/sensors plus tard)
mkdir -p "$ROOT/root/sp12-graft"
cp -a /mnt/c/sp12-linux/graft/. "$ROOT/root/sp12-graft/" 2>/dev/null || true
echo "scripts stages: $(ls "$ROOT/root/sp12-graft"/*.sh 2>/dev/null | wc -l)"
# DNS pour le chroot
cp /etc/resolv.conf "$ROOT/etc/resolv.conf" 2>/dev/null || printf 'nameserver 1.1.1.1\n' > "$ROOT/etc/resolv.conf"
# binds
mount -t proc proc "$ROOT/proc"; mount --rbind /sys "$ROOT/sys"; mount --make-rslave "$ROOT/sys"; mount --rbind /dev "$ROOT/dev"; mount --make-rslave "$ROOT/dev"
cleanup(){ umount -R "$ROOT/proc" 2>/dev/null||true; umount -R "$ROOT/sys" 2>/dev/null||true; umount -R "$ROOT/dev" 2>/dev/null||true; }
trap cleanup EXIT
chroot "$ROOT" /bin/bash -ec '
if ! pacman -Sy --noconfirm iwd 2>&1 | tail -4; then
  echo "retry avec keyring..."; pacman-key --init >/dev/null 2>&1; pacman-key --populate archlinuxarm >/dev/null 2>&1
  pacman -Sy --noconfirm iwd 2>&1 | tail -4
fi
mkdir -p /etc/iwd
printf "[General]\nEnableNetworkConfiguration=true\n" > /etc/iwd/main.conf
systemctl enable iwd.service >/dev/null 2>&1 && echo "iwd.service active"
systemctl enable systemd-resolved.service >/dev/null 2>&1 || true
if [ -e /usr/bin/iwctl ]; then echo "IWCTL PRESENT"; else echo "IWCTL ABSENT"; fi
'
echo "=== STAGE6a done $(date -u +%H:%M:%S) ==="
