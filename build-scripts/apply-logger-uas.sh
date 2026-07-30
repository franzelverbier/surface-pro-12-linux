#!/bin/bash
set -e
ROOT=/root/sp12/rootfs

echo "=== 1) Logger de boot vers l'ESP ==="
cat > "$ROOT/usr/local/bin/sp12-boot-log.sh" <<'EOS'
#!/bin/bash
ESP=/run/sp12esp
mkdir -p "$ESP"
mount -L SP12ESP "$ESP" 2>/dev/null || mount /dev/disk/by-label/SP12ESP "$ESP" 2>/dev/null || exit 0
D="$ESP/sp12-boot"; mkdir -p "$D"
n=0
while [ $n -lt 12 ]; do
  dmesg > "$D/dmesg.log" 2>&1
  journalctl -b --no-pager > "$D/journal.log" 2>&1
  { date; echo "--- ip -br addr ---"; ip -br addr 2>&1; echo "--- iw wlan0 link ---"; iw dev wlan0 link 2>&1; echo "--- wpa status ---"; wpa_cli -i wlan0 status 2>&1; echo "--- iw reg ---"; iw reg get 2>&1; echo "--- units en echec ---"; systemctl --failed --no-pager 2>&1; } > "$D/status.log" 2>&1
  sync
  n=$((n+1)); sleep 15
done
umount "$ESP" 2>/dev/null || true
EOS
chmod +x "$ROOT/usr/local/bin/sp12-boot-log.sh"

cat > "$ROOT/etc/systemd/system/sp12-boot-log.service" <<'EOS'
[Unit]
Description=SP12 boot log to ESP
DefaultDependencies=no
After=systemd-journald.service local-fs.target
[Service]
Type=simple
ExecStart=/usr/local/bin/sp12-boot-log.sh
[Install]
WantedBy=sysinit.target
EOS
mkdir -p "$ROOT/etc/systemd/system/sysinit.target.wants"
ln -sf ../sp12-boot-log.service "$ROOT/etc/systemd/system/sysinit.target.wants/sp12-boot-log.service"
echo "  service active (sysinit.target)"

echo "=== 2) Blacklist uas (force BOT, complementaire du quirk) ==="
echo 'blacklist uas' > "$ROOT/etc/modprobe.d/blacklist-uas.conf"
cat "$ROOT/etc/modprobe.d/blacklist-uas.conf"

echo "=== 3) Regeneration initramfs (embarque le blacklist via modconf) ==="
mount -t proc proc "$ROOT/proc"; mount --rbind /sys "$ROOT/sys"; mount --make-rslave "$ROOT/sys"; mount --rbind /dev "$ROOT/dev"; mount --make-rslave "$ROOT/dev"
cleanup(){ umount -R "$ROOT/proc" 2>/dev/null||true; umount -R "$ROOT/sys" 2>/dev/null||true; umount -R "$ROOT/dev" 2>/dev/null||true; }
trap cleanup EXIT
chroot "$ROOT" /bin/bash -ec 'mkinitcpio -k 7.1.0-next-20260626 -g /boot/initramfs-sp12.img -S autodetect 2>&1 | tail -8'
echo "=== initramfs regenere ==="
ls -la "$ROOT/boot/initramfs-sp12.img"
echo "=== PREP OK ==="
