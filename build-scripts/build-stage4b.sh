#!/bin/bash
set -e
LOG=/mnt/c/sp12-linux/build.log
exec >> "$LOG" 2>&1
echo "=== STAGE4b rootfs extract start $(date -u +%H:%M:%S) ==="
cd /root/sp12
mkdir -p rootfs
if [ ! -e rootfs/etc/pacman.conf ]; then
  tar xpf ArchLinuxARM-aarch64-latest.tar.gz -C rootfs --numeric-owner 2>/dev/null || true
fi
if [ -e rootfs/etc/pacman.conf ]; then
  echo "rootfs OK: $(du -sh rootfs 2>/dev/null | cut -f1)"
  ls rootfs/ | tr '\n' ' '; echo
else
  echo "rootfs EXTRACT FAIL"
fi
echo "=== STAGE4b rootfs extract done $(date -u +%H:%M:%S) ==="
