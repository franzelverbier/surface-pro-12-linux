#!/bin/bash
set -e
ROOT=/root/sp12/rootfs
G="$ROOT/boot/grub/grub.cfg"
echo "=== a) cmdline : usbcore.autosuspend=-1 + quirk anti-UAS (0781:55bb:u) ==="
grep -q 'usbcore.autosuspend' "$G" || sed -i 's/loglevel=7/loglevel=7 usbcore.autosuspend=-1/' "$G"
grep -q 'usb-storage.quirks' "$G" || sed -i 's/usbcore.autosuspend=-1/usbcore.autosuspend=-1 usb-storage.quirks=0781:55bb:u/' "$G"
grep -o 'linux /boot/Image.*' "$G"

echo "=== b) modprobe.d/uas-quirk.conf ==="
mkdir -p "$ROOT/etc/modprobe.d"
echo 'options usb-storage quirks=0781:55bb:u' > "$ROOT/etc/modprobe.d/uas-quirk.conf"
cat "$ROOT/etc/modprobe.d/uas-quirk.conf"

echo "=== c) anti-veille (cibles masquees + logind) ==="
for t in sleep suspend hibernate hybrid-sleep; do ln -sf /dev/null "$ROOT/etc/systemd/system/$t.target"; done
mkdir -p "$ROOT/etc/systemd/logind.conf.d"
printf '[Login]\nIdleAction=ignore\nHandleLidSwitch=ignore\nHandleLidSwitchExternalPower=ignore\nHandleSuspendKey=ignore\nHandleHibernateKey=ignore\n' > "$ROOT/etc/systemd/logind.conf.d/10-nosleep.conf"
ls -l "$ROOT/etc/systemd/system/sleep.target"

echo "=== d) IgnorePkg (anti-regression update) ==="
if ! grep -q '^IgnorePkg' "$ROOT/etc/pacman.conf"; then
  sed -i '/^\[options\]/a IgnorePkg = linux-aarch64 linux-aarch64-headers systemd systemd-libs systemd-resolvconf systemd-sysvcompat' "$ROOT/etc/pacman.conf"
fi
grep '^IgnorePkg' "$ROOT/etc/pacman.conf"

echo "=== e) wpa : un seul SSID <REDACTED> (retire le second bloc, obsolete) ==="
cat > "$ROOT/etc/wpa_supplicant/wpa_supplicant-wlan0.conf" <<'EOF'
ctrl_interface=/run/wpa_supplicant
update_config=1
country=FR

network={
    ssid="<REDACTED>"
    key_mgmt=SAE WPA-PSK
    psk="<REDACTED>"
    ieee80211w=1
}
EOF
chmod 600 "$ROOT/etc/wpa_supplicant/wpa_supplicant-wlan0.conf"
grep -E 'ssid|key_mgmt' "$ROOT/etc/wpa_supplicant/wpa_supplicant-wlan0.conf"

echo "=== f) SSH : config + cles d'hote ==="
mkdir -p "$ROOT/etc/ssh/sshd_config.d"
printf 'PermitRootLogin yes\nPasswordAuthentication yes\n' > "$ROOT/etc/ssh/sshd_config.d/10-sp12.conf"
if ! ls "$ROOT"/etc/ssh/ssh_host_*_key >/dev/null 2>&1; then
  mount -t proc proc "$ROOT/proc"; mount --rbind /dev "$ROOT/dev"; mount --make-rslave "$ROOT/dev"
  chroot "$ROOT" ssh-keygen -A
  umount -R "$ROOT/proc" 2>/dev/null; umount -R "$ROOT/dev" 2>/dev/null
fi
ls "$ROOT"/etc/ssh/ssh_host_*_key 2>/dev/null | wc -l | xargs echo "cles d'hote:"

echo "=== claude-code present ? ==="
if ls "$ROOT"/usr/lib/node_modules/@anthropic-ai/claude-code >/dev/null 2>&1; then
  echo "  OUI (module present)"; ls "$ROOT"/usr/bin/claude "$ROOT"/usr/local/bin/claude 2>/dev/null
else
  echo "  NON (a installer via npm -g)"
fi

echo "=== TOUS LES CORRECTIFS APPLIQUES ==="
