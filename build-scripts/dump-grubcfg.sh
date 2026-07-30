#!/bin/bash
set -u
ISO=/mnt/c/sp12-linux/archboot-aarch64-local.iso
mountpoint -q /mnt/iso 2>/dev/null || { mkdir -p /mnt/iso; mount -o loop,ro "$ISO" /mnt/iso; }
echo "===== arbo /boot/grub ====="
ls -la /mnt/iso/boot/grub 2>&1
echo; echo "===== EFI/ ====="
find /mnt/iso/EFI -maxdepth 3 2>/dev/null
echo; echo "===== *.cfg trouves dans l'ISO ====="
find /mnt/iso -name '*.cfg' 2>/dev/null
echo; echo "===== contenu grub.cfg principal ====="
for f in /mnt/iso/boot/grub/grub.cfg /mnt/iso/EFI/BOOT/grub.cfg; do
  if [ -f "$f" ]; then echo "----- $f -----"; cat "$f"; fi
done
echo; echo "===== recherche getparams / Image-aarch64 dans tous les cfg ====="
grep -rn -E 'getparams|Image-aarch64|menuentry|devicetree|configfile|search' /mnt/iso --include='*.cfg' 2>/dev/null | head -60
