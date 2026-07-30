#!/bin/bash
export MTOOLS_SKIP_CHECK=1
IMG=/root/sp12/sp12.img
losetup -D 2>/dev/null||true
LOOP=$(losetup -fP --show "$IMG")
echo "=== ESP ::/EFI/BOOT/ ==="
mdir -i "${LOOP}p1" ::/EFI/BOOT/ 2>&1 || echo "  (mdir a echoue)"
losetup -d "$LOOP"
