#!/bin/bash
set -u
cd /mnt/c/sp12-linux || exit 1
command -v dtc >/dev/null 2>&1 || { apt-get update -y >/dev/null 2>&1; apt-get install -y device-tree-compiler >/dev/null 2>&1; }
mountpoint -q /mnt/iso 2>/dev/null || { mkdir -p /mnt/iso; mount -o loop,ro archboot-aarch64-local.iso /mnt/iso; }
[ -s Image.tmp ] || zcat /mnt/iso/boot/Image-aarch64.gz > Image.tmp
dtc -I dtb -O dts -o sp12.dts.tmp graft/boot/dtb 2>/dev/null
echo "model : $(grep -m1 'model =' sp12.dts.tmp | tr -s ' ')"
echo "Image : $(stat -c%s Image.tmp) o ; DTS : $(wc -l < sp12.dts.tmp) lignes"
echo
echo "=== Compatibles qcom du DTB ABSENTS du noyau 7.1.1 (ne bindent pas) ==="
grep -oE '"qcom,[^"]+"' sp12.dts.tmp | tr -d '"' | sort -u > /tmp/all.tmp 2>/dev/null || grep -oE '"qcom,[^"]+"' sp12.dts.tmp | tr -d '"' | sort -u > all.tmp
ALL=$( [ -s /tmp/all.tmp ] && echo /tmp/all.tmp || echo all.tmp )
while read -r c; do grep -aq "$c" Image.tmp || echo "  ABSENT: $c"; done < "$ALL"
echo
echo "=== Compatibles BOOT-CRITIQUES utilises par le DTB (et statut noyau) ==="
for key in -gcc '"qcom,[^"]*-tlmm' -rpmh -dispcc -cpufreq -ufshc -smmu -pdc -apps-rsc; do
  for c in $(grep -oE "\"qcom,[^\"]*${key#\"}[^\"]*\"" sp12.dts.tmp 2>/dev/null | tr -d '"' | sort -u); do
    grep -aq "$c" Image.tmp && echo "  OK   $c" || echo "  MANQ $c"
  done
done | sort -u
