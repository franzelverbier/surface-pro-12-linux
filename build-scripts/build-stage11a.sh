#!/bin/bash
set -e
ROOT=/root/sp12/rootfs
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE11a v6 wifi-auto start $(date -u +%H:%M:%S) ==="
mount -t proc proc "$ROOT/proc"; mount --rbind /sys "$ROOT/sys"; mount --make-rslave "$ROOT/sys"; mount --rbind /dev "$ROOT/dev"; mount --make-rslave "$ROOT/dev"
cleanup(){ umount -R "$ROOT/proc" 2>/dev/null||true; umount -R "$ROOT/sys" 2>/dev/null||true; umount -R "$ROOT/dev" 2>/dev/null||true; }
trap cleanup EXIT
# wpa_supplicant present ?
chroot "$ROOT" /bin/bash -ec '
command -v wpa_supplicant >/dev/null || pacman -Sy --noconfirm wpa_supplicant 2>&1 | tail -2
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
# services : wpa@wlan0 + dhcpcd ; virer le generique + networkd
systemctl disable wpa_supplicant.service 2>/dev/null || true
systemctl enable wpa_supplicant@wlan0.service
systemctl enable dhcpcd.service
systemctl disable systemd-networkd.service systemd-networkd-wait-online.service systemd-networkd.socket 2>/dev/null || true
# cles dhote SSH (robuste)
ssh-keygen -A >/dev/null 2>&1
echo "--- verifs ---"
ls /etc/ssh/ssh_host_*key 2>/dev/null | wc -l | xargs echo "cles ssh:"
ls -la /etc/systemd/system/multi-user.target.wants/ | grep -E "wpa_supplicant@wlan0|dhcpcd|sshd" || true
echo "wpa conf:"; grep ssid /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
echo "networkd actif ?"; systemctl is-enabled systemd-networkd 2>/dev/null || echo "disabled (ok)"
'
echo "=== STAGE11a done $(date -u +%H:%M:%S) ==="
