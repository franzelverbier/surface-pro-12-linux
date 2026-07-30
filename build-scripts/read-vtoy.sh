#!/bin/bash
cd /root || exit 1
rm -rf vtoy; mkdir -p vtoy
tar xzf /root/sp12/vtoyboot.tar.gz -C vtoy
cd vtoy/vtoyboot-1.0.6 || exit 1
echo "===== vtoyboot.sh ====="
cat vtoyboot.sh
echo
echo "===== mkinitcpio/ventoy-install.sh ====="
cat distros/mkinitcpio/ventoy-install.sh
echo
echo "===== mkinitcpio/ventoy-hook.sh ====="
cat distros/mkinitcpio/ventoy-hook.sh
echo
echo "===== mkinitcpio/vtoy.sh (runtime hook) ====="
cat distros/mkinitcpio/vtoy.sh
