#!/bin/bash
set -e
ROOT=/root/sp12/rootfs
KREL=7.1.0-next-20260626
LOG=/mnt/c/sp12-linux/build.log
exec >> "$LOG" 2>&1
echo "=== STAGE4d chroot config start $(date -u +%H:%M:%S) ==="

# --- fichiers de config (hors chroot) ---
echo "sp12" > "$ROOT/etc/hostname"

# autologin root sur tty1 (console=tty0)
mkdir -p "$ROOT/etc/systemd/system/getty@tty1.service.d"
cat > "$ROOT/etc/systemd/system/getty@tty1.service.d/autologin.conf" <<'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
EOF

# fstab par label
cat > "$ROOT/etc/fstab" <<'EOF'
LABEL=SP12ROOT  /         ext4  rw,relatime  0 1
LABEL=SP12ESP   /boot/efi vfat  rw,noatime   0 2
EOF

# service: dump dmesg + journal sur l'ESP a chaque boot (ENREGISTREUR DE LOG)
cat > "$ROOT/etc/systemd/system/sp12-log.service" <<'EOF'
[Unit]
Description=SP12 boot log dumper to ESP
After=multi-user.target
[Service]
Type=oneshot
ExecStart=/bin/sh -c 'mkdir -p /boot/efi/sp12-logs; dmesg > /boot/efi/sp12-logs/dmesg.log 2>&1; journalctl -b --no-pager > /boot/efi/sp12-logs/journal.log 2>&1; sync'
[Install]
WantedBy=multi-user.target
EOF
ln -sf /etc/systemd/system/sp12-log.service "$ROOT/etc/systemd/system/multi-user.target.wants/sp12-log.service"

# --- chroot: mot de passe + initramfs portable ---
mount -t proc proc "$ROOT/proc"
mount --rbind /sys "$ROOT/sys"; mount --make-rslave "$ROOT/sys"
mount --rbind /dev "$ROOT/dev"; mount --make-rslave "$ROOT/dev"
cleanup(){ umount -R "$ROOT/proc" 2>/dev/null||true; umount -R "$ROOT/sys" 2>/dev/null||true; umount -R "$ROOT/dev" 2>/dev/null||true; }
trap cleanup EXIT

chroot "$ROOT" /bin/bash -ec "
echo 'root:sp12' | chpasswd
echo 'autologin root + mdp=sp12 OK'
# initramfs SANS autodetect -> portable (tous modules: USB/dwc3/phy/ext4/msm)
mkinitcpio -k $KREL -g /boot/initramfs-sp12.img -S autodetect 2>&1 | tail -15
"
echo '--- /boot du rootfs ---'
ls -la "$ROOT/boot/" | grep -E 'Image|initramfs-sp12|sp12.dtb'
echo "=== STAGE4d done $(date -u +%H:%M:%S) ==="
