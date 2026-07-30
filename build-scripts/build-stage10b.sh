#!/bin/bash
set -e
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE10b v5 rebuild start $(date -u +%H:%M:%S) ==="
ROOT=/root/sp12/rootfs
IMG=/root/sp12/sp12.img
export MTOOLS_SKIP_CHECK=1
# sshd : login root par mot de passe (sp12)
mkdir -p "$ROOT/etc/ssh/sshd_config.d"
printf 'PermitRootLogin yes\nPasswordAuthentication yes\n' > "$ROOT/etc/ssh/sshd_config.d/10-sp12.conf"
# tweak USB anti-capricieux
sed -i 's/loglevel=7/loglevel=7 usbcore.autosuspend=-1/' "$ROOT/boot/grub/grub.cfg"
echo "--- cmdline ---"; grep -o 'linux /boot/Image.*' "$ROOT/boot/grub/grub.cfg"
# helper bureau (a lancer plus tard en SSH)
cat > "$ROOT/root/sp12-setup-gui.sh" <<'EOF'
#!/bin/bash
# Bureau minimal Wayland (sway) sur le SP12 - lancer en SSH puis: sway
set -e
sed -i 's/^SigLevel.*/SigLevel = Never/' /etc/pacman.conf
pacman -Sy --noconfirm mesa vulkan-freedreno sway foot wmenu xorg-xwayland seatd
systemctl enable seatd
echo "OK. Ajoute ton user a seat, ou en root: 'seatd-launch sway' depuis un tty."
EOF
chmod +x "$ROOT/root/sp12-setup-gui.sh"
# petit MOTD d'accueil
printf '\n=== Surface Pro 12 / linux-next ===\nclaude  -> Claude Code\nsp12-setup-gui.sh -> bureau\nscripts: /root/sp12-graft/\n\n' > "$ROOT/etc/motd"

# --- rebuild image ---
for m in proc sys dev; do umount -R "$ROOT/$m" 2>/dev/null||true; done
umount -R /mnt/t 2>/dev/null||true; losetup -D 2>/dev/null||true
cat > /tmp/embed.cfg <<'EOF'
search --no-floppy --set=root --label SP12ROOT
configfile ($root)/boot/grub/grub.cfg
EOF
rm -f "$IMG"; truncate -s 12G "$IMG"
sgdisk -Z "$IMG" >/dev/null
sgdisk -n1:0:+512M -t1:ef00 -c1:SP12ESP "$IMG" >/dev/null
sgdisk -n2:0:0 -t2:8300 -c2:SP12ROOT "$IMG" >/dev/null
LOOP=$(losetup -fP --show "$IMG")
mkfs.fat -F32 -n SP12ESP "${LOOP}p1" >/dev/null
mkfs.ext4 -q -L SP12ROOT "${LOOP}p2"
mkdir -p /mnt/t; mount "${LOOP}p2" /mnt/t
echo "copie rootfs..."; cp -a "$ROOT"/. /mnt/t/; sync; umount /mnt/t
grub-mkstandalone -O arm64-efi -o /tmp/BOOTAA64.EFI --modules="part_gpt ext2 fat search search_label search_fs_uuid normal linux fdt configfile echo test all_video gfxterm gzio" "boot/grub/grub.cfg=/tmp/embed.cfg" 2>&1 | tail -1
mmd -i "${LOOP}p1" ::/EFI ::/EFI/BOOT 2>/dev/null||true
mcopy -o -i "${LOOP}p1" /tmp/BOOTAA64.EFI ::/EFI/BOOT/BOOTAA64.EFI
echo "EFI: $(stat -c%s /tmp/BOOTAA64.EFI) octets"
losetup -d "$LOOP"
echo "copie -> C: ..."; cp "$IMG" /mnt/c/sp12-linux/sp12.img; sync
echo "image C: = $(stat -c%s /mnt/c/sp12-linux/sp12.img) octets"
echo "=== STAGE10b done $(date -u +%H:%M:%S) ==="
