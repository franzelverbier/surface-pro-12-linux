#!/bin/bash
set -e
ROOT=/root/sp12/rootfs
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE11a2 v6 wifi-auto (DNS fix) start $(date -u +%H:%M:%S) ==="
mount -t proc proc "$ROOT/proc"; mount --rbind /sys "$ROOT/sys"; mount --make-rslave "$ROOT/sys"; mount --rbind /dev "$ROOT/dev"; mount --make-rslave "$ROOT/dev"
cleanup(){ umount -R "$ROOT/proc" 2>/dev/null||true; umount -R "$ROOT/sys" 2>/dev/null||true; umount -R "$ROOT/dev" 2>/dev/null||true; }
trap cleanup EXIT
chroot "$ROOT" /bin/bash -ec '
rm -f /etc/resolv.conf; printf "nameserver 10.255.255.254\n" > /etc/resolv.conf
sed -i "s/^SigLevel.*/SigLevel = Never/" /etc/pacman.conf
pacman -Sy --noconfirm wpa_supplicant 2>&1 | tail -3
mkdir -p /etc/wpa_supplicant
cat > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf <<EOF
ctrl_interface=/run/wpa_supplicant
update_config=1
country=FR
network={
    ssid="<REDACTED>"
    psk="<REDACTED>"
}
EOF
chmod 600 /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
systemctl disable wpa_supplicant.service 2>/dev/null || true
systemctl enable wpa_supplicant@wlan0.service
systemctl enable dhcpcd.service
systemctl disable systemd-networkd.service systemd-networkd-wait-online.service systemd-networkd.socket 2>/dev/null || true
ssh-keygen -A >/dev/null 2>&1
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
echo "--- verifs ---"
echo "cles ssh: $(ls /etc/ssh/ssh_host_*key 2>/dev/null | wc -l)"
echo "wpa_supplicant: $(command -v wpa_supplicant || echo ABSENT)"
echo "wpa@wlan0 enabled: $(systemctl is-enabled wpa_supplicant@wlan0.service 2>/dev/null)"
echo "dhcpcd enabled: $(systemctl is-enabled dhcpcd.service 2>/dev/null)"
echo "networkd: $(systemctl is-enabled systemd-networkd.service 2>/dev/null || echo disabled)"
echo "ssid configure: $(grep -o "ssid=\"[^\"]*\"" /etc/wpa_supplicant/wpa_supplicant-wlan0.conf)"
'
echo "=== STAGE11a2 done $(date -u +%H:%M:%S) ==="
