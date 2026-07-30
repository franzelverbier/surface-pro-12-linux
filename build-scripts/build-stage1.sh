#!/bin/bash
set -e
LOG=/mnt/c/sp12-linux/build.log
exec > >(tee -a "$LOG") 2>&1
echo "=== STAGE1 deps+clone start $(date -u +%H:%M:%S) ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null 2>&1
apt-get install -y build-essential flex bison libssl-dev libelf-dev bc kmod cpio rsync git wget xz-utils device-tree-compiler zstd >/dev/null 2>&1
echo "deps OK $(date -u +%H:%M:%S)"
cd /root
if [ ! -d linux-next/.git ]; then
  echo "clone linux-next (shallow)..."
  git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git linux-next 2>&1 | tail -3
else
  echo "linux-next deja present"
fi
cd /root/linux-next
echo "=== version: $(make kernelversion 2>/dev/null) ==="
echo "=== symboles x1p42100 dispo dans linux-next ==="
grep -rhoE 'config [A-Z0-9_]*X1P42100[A-Z0-9_]*' drivers/ 2>/dev/null | sort -u | head -40
echo "=== dts SP12 in-tree ? ==="
ls arch/arm64/boot/dts/qcom/ | grep -iE 'x1p42100|sp12|surface' || echo "(pas de board SP12 in-tree -> on utilisera le DTB harrison)"
echo "=== STAGE1 done $(date -u +%H:%M:%S) ==="
du -sh /root/linux-next 2>/dev/null
