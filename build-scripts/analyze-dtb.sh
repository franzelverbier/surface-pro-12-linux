#!/bin/bash
set -u
DTB=/mnt/c/sp12-linux/graft/boot/dtb
ISO=/mnt/c/sp12-linux/archboot-aarch64-local.iso

# outils
if ! command -v dtc >/dev/null 2>&1; then
  echo "[*] installation de dtc..."; apt-get update -y >/dev/null 2>&1; apt-get install -y device-tree-compiler >/dev/null 2>&1
fi
# noyau decompresse (si pas deja la)
if [ ! -s /tmp/Image ]; then
  mountpoint -q /mnt/iso 2>/dev/null || { mkdir -p /mnt/iso; mount -o loop,ro "$ISO" /mnt/iso; }
  zcat /mnt/iso/boot/Image-aarch64.gz > /tmp/Image
fi

dtc -I dtb -O dts -o /tmp/sp12.dts "$DTB" 2>/dev/null
echo "DTS: $(wc -l < /tmp/sp12.dts) lignes ; model: $(grep -m1 'model =' /tmp/sp12.dts | tr -s ' ')"
echo

# Tous les compatibles x1p42100 du DTB, et pour chacun : repli x1e80100 dans le meme noeud ? present dans le noyau ?
echo "=== Compatibles x1p42100 du DTB : repli x1e ? / connu du noyau ? ==="
grep -oE '"qcom,x1p42100-[a-z0-9-]+"' /tmp/sp12.dts | tr -d '"' | sort -u | while read -r c; do
  base=${c#qcom,x1p42100-}
  fallback="qcom,x1e80100-$base"
  has_fb=$(grep -q "\"$fallback\"" /tmp/sp12.dts && echo "repli-x1e:OUI" || echo "repli-x1e:non")
  in_krnl=$(grep -aq "$c" /tmp/Image && echo "noyau:OUI" || echo "noyau:NON")
  printf '  %-34s %-14s %s\n' "$base" "$has_fb" "$in_krnl"
done

echo
echo "=== Bilan repli : noeuds x1p42100 SANS repli x1e ET absents du noyau (= risque) ==="
grep -oE '"qcom,x1p42100-[a-z0-9-]+"' /tmp/sp12.dts | tr -d '"' | sort -u | while read -r c; do
  base=${c#qcom,x1p42100-}
  fallback="qcom,x1e80100-$base"
  if ! grep -q "\"$fallback\"" /tmp/sp12.dts && ! grep -aq "$c" /tmp/Image; then
    echo "  !! $c"
  fi
done
echo "(rien ci-dessus = tout est couvert soit par repli x1e, soit par le noyau)"
