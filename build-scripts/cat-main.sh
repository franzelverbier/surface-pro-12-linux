#!/bin/bash
set -u
ISO=/mnt/c/sp12-linux/archboot-aarch64-local.iso
mountpoint -q /mnt/iso 2>/dev/null || { mkdir -p /mnt/iso; mount -o loop,ro "$ISO" /mnt/iso; }
echo "===== archboot-main-grub.cfg (numerote) ====="
cat -n /mnt/iso/boot/grub/archboot-main-grub.cfg
