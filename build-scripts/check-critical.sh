#!/bin/bash
set -u
D=/tmp/sp12.dts
echo "=== Compatibles des blocs BOOT-CRITIQUES + affichage ==="
for node in gcc dispcc tlmm rpmh apps_rsc cpufreq ufshc pmic gpi-dma mdss; do
  line=$(grep -iE "compatible = \"qcom,x1[pe][0-9]+-$node" "$D" | head -1 | tr -s ' ')
  [ -z "$line" ] && line=$(grep -iE "compatible = .*$node" "$D" | head -1 | tr -s ' ')
  printf '  %-10s : %s\n' "$node" "${line:-(absent)}"
done
echo
echo "=== Ces blocs critiques sont-ils couverts (x1e80100 dans le noyau) ? ==="
for c in qcom,x1e80100-gcc qcom,x1e80100-dispcc qcom,x1e80100-tlmm qcom,x1e80100-rpmh-clk; do
  grep -aq "$c" /tmp/Image && echo "  OUI  $c" || echo "  NON  $c"
done
echo
echo "=== Le DTB utilise-t-il bien ces replis x1e ? ==="
for c in x1e80100-gcc x1e80100-dispcc x1e80100-tlmm; do
  grep -q "\"qcom,$c\"" "$D" && echo "  repli present dans DTB : qcom,$c" || echo "  PAS de repli : qcom,$c"
done
