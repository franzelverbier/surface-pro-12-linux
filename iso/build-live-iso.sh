#!/usr/bin/env bash
set -euo pipefail
WORK=/mnt/sp12data/isobuild; ISOROOT="$WORK/isoroot"; OUT=/mnt/sp12data/sp12-live-v4.iso
rm -rf "$WORK"; mkdir -p "$ISOROOT/EFI/BOOT"
cp /boot/Image "$ISOROOT/Image"
cp /mnt/sp12data/initramfs-sp12-live.img  "$ISOROOT/initramfs-live.img"
cp /mnt/sp12data/initramfs-sp12-debug.img "$ISOROOT/initramfs-debug.img"
cp /boot/sp12.dtb "$ISOROOT/sp12.dtb"

cat > "$WORK/grub.cfg" <<'EOF'
set timeout=10
set default=0
insmod all_video
menuentry "1. LIVE - Type Cover + shell VISIBLE (msm off) [defaut]" {
    search --no-floppy --set=root --label SP12LIVE
    linux /Image modprobe.blacklist=msm console=tty0 consoleblank=0 loglevel=3 clk_ignore_unused pd_ignore_unused usbcore.autosuspend=-1
    initrd /initramfs-live.img
    devicetree /sp12.dtb
}
menuentry "2. LOGGER - diag SP12DATA puis extinction (msm off)" {
    search --no-floppy --set=root --label SP12LIVE
    linux /Image modprobe.blacklist=msm console=tty0 consoleblank=0 loglevel=3 clk_ignore_unused pd_ignore_unused usbcore.autosuspend=-1
    initrd /initramfs-debug.img
    devicetree /sp12.dtb
}
menuentry "3. Boot systeme interne" {
    search --no-floppy --set=root --label SP12LIVE
    linux /Image root=LABEL=SP12ROOT-INT rw rootwait console=tty0 consoleblank=0 loglevel=3 clk_ignore_unused pd_ignore_unused usbcore.autosuspend=-1
    initrd /initramfs-debug.img
    devicetree /sp12.dtb
}
EOF

grub-mkstandalone -O arm64-efi \
  --modules="iso9660 part_gpt part_msdos fat exfat ntfs search search_label search_fs_uuid normal linux echo test configfile all_video efi_gop efinet loadenv" \
  -o "$WORK/BOOTAA64.EFI" "boot/grub/grub.cfg=$WORK/grub.cfg"

EFIIMG="$ISOROOT/EFI/BOOT/efiboot.img"
sz=$(( $(stat -c%s "$WORK/BOOTAA64.EFI") / 1048576 + 6 ))
dd if=/dev/zero of="$EFIIMG" bs=1M count=$sz status=none
mkfs.fat -n SP12EFI "$EFIIMG" >/dev/null
mmd -i "$EFIIMG" ::/EFI ::/EFI/BOOT
mcopy -i "$EFIIMG" "$WORK/BOOTAA64.EFI" ::/EFI/BOOT/BOOTAA64.EFI
cp "$WORK/BOOTAA64.EFI" "$ISOROOT/EFI/BOOT/BOOTAA64.EFI"

xorriso -as mkisofs -iso-level 3 -rock -joliet -volid SP12LIVE \
  -e EFI/BOOT/efiboot.img -no-emul-boot -o "$OUT" "$ISOROOT" 2>&1 | tail -1
ls -lh "$OUT"

echo "== copie Ventoy =="
mkdir -p /mnt/ventoy
mount.exfat-fuse /dev/sdb1 /mnt/ventoy
rm -f /mnt/ventoy/sp12-live-debug.iso /mnt/ventoy/sp12-live-bootproof.iso
cp "$OUT" /mnt/ventoy/sp12-live-v4.iso
sync; umount /mnt/ventoy
echo "  OK sur Ventoy : sp12-live-v4.iso"
