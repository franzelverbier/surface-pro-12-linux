#!/bin/bash
set -e
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE9 v4 (no blacklist + quiet) start $(date -u +%H:%M:%S) ==="
IMG=/root/sp12/sp12.img
ROOT=/root/sp12/rootfs
umount -R /mnt/t 2>/dev/null||true; losetup -D 2>/dev/null||true
LOOP=$(losetup -fP --show "$IMG")
mkdir -p /mnt/t; mount "${LOOP}p2" /mnt/t
# 1) retirer le blacklist de la cmdline (garde loglevel=7)
sed -i 's/ modprobe.blacklist=[^ ]*//' /mnt/t/boot/grub/grub.cfg
echo "--- cmdline v4 ---"; grep -o 'linux /boot/Image.*' /mnt/t/boot/grub/grub.cfg
# 2) service qui calme la console apres le boot
cat > /mnt/t/etc/systemd/system/sp12-quiet.service <<'EOF'
[Unit]
Description=Quiet kernel console after boot (SP12)
After=multi-user.target
[Service]
Type=oneshot
ExecStart=/usr/bin/dmesg -n 1
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF
mkdir -p /mnt/t/etc/systemd/system/multi-user.target.wants
ln -sf /etc/systemd/system/sp12-quiet.service /mnt/t/etc/systemd/system/multi-user.target.wants/sp12-quiet.service
echo "quiet.service: $([ -L /mnt/t/etc/systemd/system/multi-user.target.wants/sp12-quiet.service ] && echo active)"
sed -i 's/ modprobe.blacklist=[^ ]*//' "$ROOT/boot/grub/grub.cfg" 2>/dev/null||true
sync; umount /mnt/t; losetup -d "$LOOP"
echo "copie -> C: ..."; cp "$IMG" /mnt/c/sp12-linux/sp12.img; sync
echo "image C: = $(stat -c%s /mnt/c/sp12-linux/sp12.img) octets"
echo "=== STAGE9 done $(date -u +%H:%M:%S) ==="
