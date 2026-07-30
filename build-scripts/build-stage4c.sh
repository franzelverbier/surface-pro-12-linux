#!/bin/bash
set -e
cd /root/linux-next
LOG=/mnt/c/sp12-linux/build.log
exec >> "$LOG" 2>&1
echo "=== STAGE4c modules+firmware start $(date -u +%H:%M:%S) ==="
KREL=$(make -s kernelrelease)
echo "kernelrelease: $KREL"
ROOT=/root/sp12/rootfs
make -s modules_install INSTALL_MOD_PATH="$ROOT" 2>/dev/null
echo "modules dir: $(ls "$ROOT/lib/modules/")"
echo "nb .ko: $(find "$ROOT/lib/modules/$KREL" -name '*.ko*' 2>/dev/null | wc -l)"
cp arch/arm64/boot/Image "$ROOT/boot/Image"
echo "Image copie: $(ls -la "$ROOT/boot/Image" | awk '{print $5}') octets"
mkdir -p "$ROOT/lib/firmware"
cp -a /mnt/c/sp12-linux/graft/lib/firmware/. "$ROOT/lib/firmware/"
echo "firmware top: $(ls "$ROOT/lib/firmware/" | tr '\n' ' ')"
echo "ath12k: $(ls "$ROOT/lib/firmware/ath12k/WCN7850/hw2.0/" 2>/dev/null | tr '\n' ' ')"
cp /mnt/c/sp12-linux/graft/boot/dtb "$ROOT/boot/sp12.dtb"
echo "DTB: $(ls -la "$ROOT/boot/sp12.dtb" | awk '{print $5}') octets"
echo "espace WSL libre: $(df -h /root | tail -1 | awk '{print $4}')"
echo "=== STAGE4c done $(date -u +%H:%M:%S) ==="
