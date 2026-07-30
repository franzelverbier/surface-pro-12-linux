#!/bin/bash
set -u
C=/root/linux-next/.config
echo "=== noyau : device-mapper / loop (requis par vtoyboot) ==="
for s in CONFIG_BLK_DEV_LOOP CONFIG_BLK_DEV_DM CONFIG_DM_SNAPSHOT CONFIG_DM_THIN_PROVISIONING CONFIG_BLK_DEV_DM_BUILTIN; do
  grep -E "^$s=" "$C" 2>/dev/null || echo "$s=NON"
done
echo
echo "=== telechargement vtoyboot ==="
cd /root/sp12 2>/dev/null || cd /root
if [ ! -s vtoyboot.tar.gz ]; then
  wget -q "https://github.com/ventoy/vtoyboot/releases/download/v1.0.6/vtoyboot-1.0.6.tar.gz" -O vtoyboot.tar.gz 2>&1 | tail -2 || echo WGET_FAIL
fi
ls -la vtoyboot.tar.gz 2>/dev/null
echo "=== contenu (recherche aarch64 + hook mkinitcpio) ==="
tar tzf vtoyboot.tar.gz 2>/dev/null | grep -iE 'aarch64|arm64|mkinitcpio|vtoyboot.sh|vtoy_' | head -30
