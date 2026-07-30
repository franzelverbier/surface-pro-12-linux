#!/bin/bash
set -u
G=/mnt/c/sp12-linux/graft
KREL=7.1.0-next-20260626
MODS=/root/sp12/rootfs/lib/modules/$KREL
echo "=== modules audio / iris / gpr presents ==="
find "$MODS" -type f \( -name '*x1e80100*' -o -name '*q6apm*' -o -name '*q6prm*' -o -name '*gpr*' -o -name '*iris*' -o -name '*venus*' -o -name '*q6dsp*' -o -name '*q6routing*' -o -name '*q6afe*' \) -printf '%f\n' 2>/dev/null | sort -u
echo "=== outils reseau deja dans le rootfs ==="
for t in iwd iwctl wpa_supplicant wpa_cli nmcli dhcpcd dhclient; do
  if [ -e "/root/sp12/rootfs/usr/bin/$t" ]; then echo "  PRESENT: $t"; fi
done
echo "=== generation board.bin WiFi ==="
command -v python3 >/dev/null 2>&1 || { apt-get install -y python3 >/dev/null 2>&1; }
tmp=$(mktemp -d); cd "$tmp"
cp "$G/lib/firmware/ath12k/WCN7850/hw2.0/board-2.bin" .
python3 "$G/ath12k-bdencoder" --extract board-2.bin >/dev/null 2>&1
fb='bus=pci,vendor=17cb,device=1107,subsystem-vendor=17cb,subsystem-device=3378,qmi-chip-id=2,qmi-board-id=255.bin'
dst="/root/sp12/rootfs/lib/firmware/ath12k/WCN7850/hw2.0/board.bin"
if [ -e "$fb" ]; then
  cp "$fb" "$dst"; echo "board.bin OK depuis 3378/255 ($(stat -c%s "$dst") octets) -> $dst"
else
  echo "fallback 3378/255 absent; candidats board-id=255:"; ls bus=*board-id=255*.bin 2>/dev/null | head
fi
cd /; rm -rf "$tmp"
