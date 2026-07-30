#!/bin/bash
set -u
ISO=/mnt/c/sp12-linux/archboot-aarch64-local.iso
mountpoint -q /mnt/iso 2>/dev/null || { mkdir -p /mnt/iso; mount -o loop,ro "$ISO" /mnt/iso; }
echo "ISO monte ? $(mountpoint -q /mnt/iso && echo oui || echo NON)"
ls -la /mnt/iso/boot/Image-aarch64.gz
cd /tmp || exit 1
zcat /mnt/iso/boot/Image-aarch64.gz > Image
echo "Image size: $(stat -c%s Image) bytes"
echo "=== version ==="
grep -aoE 'Linux version [0-9][^ ]*' Image | head -1
echo "=== occurrences (grep -ao | wc -l) ==="
for s in x1p42100 x1e80100 sc8280xp; do
  n=$(grep -ao "$s" Image | wc -l)
  printf '%-12s : %s\n' "$s" "$n"
done
echo "=== echantillons x1p* / x1e* ==="
grep -aoE 'x1[a-z][a-z0-9]+' Image | sort | uniq -c | sort -rn | head
