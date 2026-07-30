#!/bin/bash
echo "=== espace disque WSL ==="
df -h / 2>/dev/null | tail -1
echo "=== rootfs de build present ? ==="
if [ -d /root/sp12/rootfs ]; then du -sh /root/sp12/rootfs 2>/dev/null; else echo "  ABSENT"; fi
echo "=== systemd installe dans le rootfs (version) ==="
ls -d /root/sp12/rootfs/var/lib/pacman/local/systemd-[0-9]* 2>/dev/null || echo "  (introuvable)"
echo "=== noyau dans rootfs/boot/Image ==="
strings /root/sp12/rootfs/boot/Image 2>/dev/null | grep -m1 'Linux version' || echo "  (pas d'Image / illisible)"
echo "=== paquets v5 (openssh/nodejs/npm/git) deja dans le rootfs ==="
for p in openssh nodejs npm git; do ls -d /root/sp12/rootfs/var/lib/pacman/local/$p-[0-9]* 2>/dev/null; done
echo "=== integrite (systemd dbus openssh) — si chroot possible ==="
ls /root/sp12/rootfs/usr/bin/sshd /root/sp12/rootfs/usr/bin/dbus-daemon 2>/dev/null || echo "  binaires manquants"
echo "=== DNS dans WSL ==="
getent hosts mirror.archlinuxarm.org 2>/dev/null | head -1 || echo "  DNS KO"
grep nameserver /etc/resolv.conf 2>/dev/null
echo "=== images .img dans WSL ==="
ls -la /root/sp12/*.img 2>/dev/null || echo "  (aucune)"
echo "=== artefacts noyau ==="
ls -la /root/linux-next/arch/arm64/boot/Image /root/linux-next/.config 2>/dev/null
ls -d /root/sp12/rootfs/usr/lib/modules/7.1.0-next-20260626 2>/dev/null
