#!/bin/bash
set -u
ISO=/mnt/c/sp12-linux/archboot-aarch64-local.iso
mountpoint -q /mnt/iso 2>/dev/null || { mkdir -p /mnt/iso; mount -o loop,ro "$ISO" /mnt/iso; }
echo "=== /boot dans l'ISO (iso9660) ==="
ls -la /mnt/iso/boot 2>&1
echo "=== extraction efi.img -> /tmp ==="
cp /mnt/iso/efi.img /tmp/efi.img
ls -la /tmp/efi.img
echo "=== montage efi.img ==="
mkdir -p /mnt/efi
mount -o loop,ro /tmp/efi.img /mnt/efi 2>&1 && echo EFI_OK
echo "=== /boot dans efi.img ==="
ls -la /mnt/efi/boot 2>&1
echo "=== /boot/grub dans efi.img ==="
ls -la /mnt/efi/boot/grub 2>&1
echo "=== EFI/ dans efi.img ==="
find /mnt/efi/EFI -maxdepth 2 2>/dev/null
