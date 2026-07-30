#!/bin/bash
set -u
ISO=/mnt/c/sp12-linux/archboot-aarch64-local.iso
command -v mdir >/dev/null 2>&1 || { apt-get update -y >/dev/null 2>&1; apt-get install -y mtools >/dev/null 2>&1; }
mountpoint -q /mnt/iso 2>/dev/null || { mkdir -p /mnt/iso; mount -o loop,ro "$ISO" /mnt/iso; }
[ -s /tmp/efi.img ] || cp /mnt/iso/efi.img /tmp/efi.img
echo "=== type efi.img ==="; file /tmp/efi.img
export MTOOLS_SKIP_CHECK=1
echo "=== racine de efi.img ==="
mdir -i /tmp/efi.img ::/ 2>&1 | head -40
echo "=== ::/boot ==="
mdir -i /tmp/efi.img ::/boot 2>&1 | head -40
echo "=== ::/boot/grub ==="
mdir -i /tmp/efi.img ::/boot/grub 2>&1 | head -40
echo "=== ::/EFI/BOOT ==="
mdir -i /tmp/efi.img ::/EFI/BOOT 2>&1 | head -40
