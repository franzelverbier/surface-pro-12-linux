#!/bin/bash
set -u
cd /mnt/d/ventoy || exit 1
sed -i 's/\r$//' ventoy.json archboot-main-grub.cfg
echo "=== JSON valide ? ==="
python3 -c 'import json;json.load(open("ventoy.json"));print("JSON OK")' 2>&1
echo "=== patch DTB present dans le cfg ? ==="
grep -n 'sp12.dtb\|devicetree\|_sp12dtb' archboot-main-grub.cfg
echo "=== CR restants (doit etre 0/0) ==="
printf 'json:%s cfg:%s\n' "$(tr -cd '\r' < ventoy.json | wc -c)" "$(tr -cd '\r' < archboot-main-grub.cfg | wc -c)"
echo "=== contenu ventoy.json ==="
cat ventoy.json
