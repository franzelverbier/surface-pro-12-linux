#!/bin/bash
D=/usr/lib/grub/arm64-efi
echo "=== modules device/fdt presents ? ==="
ls "$D"/ | grep -iE 'devicetree|fdt' || echo "aucun fichier devicetree/fdt"
echo "=== command.lst: qui fournit devicetree/fdt ==="
grep -iE 'devicetree|fdt' "$D"/command.lst 2>/dev/null || echo "(rien dans command.lst)"
echo "=== nb modules .mod ==="
ls "$D"/*.mod 2>/dev/null | wc -l
echo "=== paquets grub installes ==="
dpkg -l | grep -i grub | awk '{print $2, $3}'
echo "=== Arch ARM rootfs a-t-il grub + devicetree.mod ? ==="
ls /root/sp12/rootfs/usr/lib/grub/arm64-efi/devicetree.mod 2>/dev/null && echo "OUI dans rootfs" || echo "non (grub pas installe dans le rootfs)"
