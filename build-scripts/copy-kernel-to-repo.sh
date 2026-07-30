#!/bin/bash
set -e
D="/mnt/c/Users/Franz/OneDrive/Franzel/Dossiers/HumanLearning/Github/sp12-linux/kernel"
mkdir -p "$D"
cp /root/linux-next/.config "$D/config-7.1.0-next-20260626"
cp /root/sp12/rootfs/boot/sp12.dtb "$D/sp12.dtb"
echo "=== kernel/ ==="
ls -la "$D"
