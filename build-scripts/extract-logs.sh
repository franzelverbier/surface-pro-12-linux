#!/bin/bash
export MTOOLS_SKIP_CHECK=1
IMG=/mnt/c/sp12-linux/esp.img
echo "=== racine ESP ==="
mdir -i "$IMG" ::/ 2>&1 | head
echo "=== ::/sp12-logs ==="
mdir -i "$IMG" ::/sp12-logs 2>&1 | head
mkdir -p /mnt/c/sp12-linux/esp-logs
mcopy -o -i "$IMG" ::/sp12-logs/dmesg.log /mnt/c/sp12-linux/esp-logs/dmesg.log 2>&1 || echo "pas de dmesg.log"
mcopy -o -i "$IMG" ::/sp12-logs/journal.log /mnt/c/sp12-linux/esp-logs/journal.log 2>&1 || echo "pas de journal.log"
echo "=== recuperes ==="
ls -la /mnt/c/sp12-linux/esp-logs/ 2>/dev/null
