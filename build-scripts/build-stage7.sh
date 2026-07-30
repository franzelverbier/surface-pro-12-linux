#!/bin/bash
set -e
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE7 rebuild start $(date -u +%H:%M:%S) ==="
ROOT=/root/sp12/rootfs
IMG=/root/sp12/sp12.img
export MTOOLS_SKIP_CHECK=1
for m in proc sys dev; do umount -R "$ROOT/$m" 2>/dev/null||true; done
umount -R /mnt/t 2>/dev/null||true; losetup -D 2>/dev/null||true
mkdir -p "$ROOT/boot/efi" "$ROOT/boot/grub"
echo "verif board.bin: $(ls -la "$ROOT/lib/firmware/ath12k/WCN7850/hw2.0/board.bin" 2>/dev/null | awk '{print $5}') octets"
echo "verif iwctl: $([ -e "$ROOT/usr/bin/iwctl" ] && echo OUI || echo NON)"
BL="snd_soc_x1e80100,q6apm_dai,snd_q6apm,q6apm_lpass_dais,q6prm,q6prm_clocks,q6afe,q6afe_dai,q6afe_clocks,q6routing,qcom_iris,venus_core,venus_dec,venus_enc"
cat > "$ROOT/boot/grub/grub.cfg" <<EOF
set timeout=5
set default=0
menuentry "Surface Pro 12 - linux-next (x1p42100)" {
    search --no-floppy --set=root --label SP12ROOT
    linux /boot/Image root=LABEL=SP12ROOT rw rootwait clk_ignore_unused pd_ignore_unused console=tty0 loglevel=4 modprobe.blacklist=$BL
    initrd /boot/initramfs-sp12.img
    devicetree /boot/sp12.dtb
}
EOF
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
grub-mkstandalone -O arm64-efi -o /tmp/BOOTAA64.EFI --modules="part_gpt ext2 fat search search_label search_fs_uuid normal linux fdt configfile echo test all_video gfxterm gzio" "boot/grub/grub.cfg=/tmp/embed.cfg" 2>&1 | tail -2
mmd -i "${LOOP}p1" ::/EFI ::/EFI/BOOT 2>/dev/null||true
mcopy -o -i "${LOOP}p1" /tmp/BOOTAA64.EFI ::/EFI/BOOT/BOOTAA64.EFI
echo "EFI genere: $(stat -c%s /tmp/BOOTAA64.EFI) octets"
losetup -d "$LOOP"
echo "--- cmdline finale ---"; grep -o 'modprobe.blacklist=[^ ]*' "$ROOT/boot/grub/grub.cfg"
echo "IMAGE OK ($(stat -c%s "$IMG") octets)"
echo "=== STAGE7 done $(date -u +%H:%M:%S) ==="
