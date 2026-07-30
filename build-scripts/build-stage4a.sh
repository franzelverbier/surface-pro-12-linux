#!/bin/bash
set -e
LOG=/mnt/c/sp12-linux/build.log
exec >> "$LOG" 2>&1
echo "=== STAGE4a rootfs download start $(date -u +%H:%M:%S) ==="
mkdir -p /root/sp12
cd /root/sp12
URL=http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
if [ ! -s ArchLinuxARM-aarch64-latest.tar.gz ]; then
  wget -q "$URL" -O ArchLinuxARM-aarch64-latest.tar.gz || echo "WGET_FAIL"
fi
if [ -s ArchLinuxARM-aarch64-latest.tar.gz ]; then
  echo "tarball OK: $(du -h ArchLinuxARM-aarch64-latest.tar.gz | cut -f1)"
else
  echo "tarball MANQUANT"
fi
echo "=== STAGE4a rootfs download done $(date -u +%H:%M:%S) ==="
