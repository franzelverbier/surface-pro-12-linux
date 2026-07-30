#!/usr/bin/env bash
set -euo pipefail
WORK=/mnt/sp12data/instiso; ISOROOT="$WORK/isoroot"; OUT=/mnt/sp12data/sp12-INSTALLER.iso
PAYLOAD=/mnt/sharge/sp12-base-20260714.tar.zst
rm -rf "$WORK"; mkdir -p "$ISOROOT/EFI/BOOT"
cp /boot/Image "$ISOROOT/Image"
cp /mnt/sp12data/initramfs-sp12-installer.img "$ISOROOT/initramfs-installer.img"
cp /boot/sp12.dtb "$ISOROOT/sp12.dtb"
echo "copie payload dans l'ISO ($(du -h "$PAYLOAD"|cut -f1))..."
cp "$PAYLOAD" "$ISOROOT/$(basename "$PAYLOAD")"

cat > "$WORK/grub.cfg" <<'EOF'
set timeout=8
set default=0
insmod all_video
menuentry "SP12 INSTALLEUR - installe Arch sur un disque (EFFACE la cible)" {
    search --no-floppy --set=root --label SP12INST
    linux /Image modprobe.blacklist=msm,panel_edp,phy_qcom_edp,aux_bridge,drm_kms_helper console=tty0 consoleblank=0 loglevel=3 clk_ignore_unused pd_ignore_unused usbcore.autosuspend=-1
    initrd /initramfs-installer.img
    devicetree /sp12.dtb
}
EOF
grub-mkstandalone -O arm64-efi \
  --modules="iso9660 part_gpt part_msdos fat exfat ntfs search search_label search_fs_uuid normal linux echo test configfile all_video efi_gop" \
  -o "$WORK/BOOTAA64.EFI" "boot/grub/grub.cfg=$WORK/grub.cfg"
EFIIMG="$ISOROOT/EFI/BOOT/efiboot.img"
sz=$(( $(stat -c%s "$WORK/BOOTAA64.EFI")/1048576 + 6 ))
dd if=/dev/zero of="$EFIIMG" bs=1M count=$sz status=none
mkfs.fat -n SP12EFI "$EFIIMG" >/dev/null
mmd -i "$EFIIMG" ::/EFI ::/EFI/BOOT
mcopy -i "$EFIIMG" "$WORK/BOOTAA64.EFI" ::/EFI/BOOT/BOOTAA64.EFI
cp "$WORK/BOOTAA64.EFI" "$ISOROOT/EFI/BOOT/BOOTAA64.EFI"

xorriso -as mkisofs -iso-level 3 -rock -joliet -volid SP12INST \
  -e EFI/BOOT/efiboot.img -no-emul-boot -o "$OUT" "$ISOROOT" 2>&1 | tail -2
ls -lh "$OUT"
