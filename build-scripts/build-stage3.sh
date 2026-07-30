#!/bin/bash
set -e
cd /root/linux-next
LOG=/mnt/c/sp12-linux/build.log
exec >> "$LOG" 2>&1
echo "=== STAGE3 build start $(date -u +%H:%M:%S) ==="
# pinctrl TLMM x1e80100 (le DTB SP12 utilise qcom,x1e80100-tlmm) -> integre
./scripts/config --enable PINCTRL_X1E80100 2>/dev/null || true
make olddefconfig >/dev/null
echo "PINCTRL_X1E80100=$(./scripts/config --state PINCTRL_X1E80100 2>/dev/null)"
echo "coeurs: $(nproc)"
echo "--- make Image modules (ceci prend du temps) ---"
/usr/bin/time -v make -j"$(nproc)" Image modules 2>&1 | tail -25
RC=${PIPESTATUS[0]}
echo "make RC=$RC $(date -u +%H:%M:%S)"
if [ "$RC" = 0 ]; then
  ls -la arch/arm64/boot/Image
  # construire aussi quelques dtbs x1p42100 in-tree (reference)
  make -j"$(nproc)" qcom/x1p42100-crd.dtb 2>/dev/null || true
fi
echo "=== STAGE3 done RC=$RC $(date -u +%H:%M:%S) ==="
