#!/bin/bash
set -u
cd /mnt/c/sp12-linux || exit 1
[ -s Image.tmp ] || { mountpoint -q /mnt/iso 2>/dev/null || { mkdir -p /mnt/iso; mount -o loop,ro archboot-aarch64-local.iso /mnt/iso; }; zcat /mnt/iso/boot/Image-aarch64.gz > Image.tmp; }
echo "=== contexte exact des 'x1p42100' dans le noyau ==="
grep -aoE '[a-z0-9,_-]*x1p42100[a-z0-9,_-]*' Image.tmp | sort -u
echo
echo "=== compatibles critiques builtin dans le noyau ? (compte) ==="
for c in qcom,x1p42100-gcc qcom,x1e80100-gcc qcom,x1e80100-tlmm qcom,x1e80100-pinctrl qcom,x1e80100-dispcc qcom,x1e80100-rpmh-clk qcom,x1e80100-ufshc; do
  n=$(grep -ao "$c" Image.tmp | wc -l)
  printf '  %-28s : %s\n' "$c" "$n"
done
