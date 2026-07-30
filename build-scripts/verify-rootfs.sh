#!/bin/bash
ROOT=/root/sp12/rootfs
mount -t proc proc "$ROOT/proc" 2>/dev/null
mount --rbind /sys "$ROOT/sys" 2>/dev/null; mount --make-rslave "$ROOT/sys" 2>/dev/null
mount --rbind /dev "$ROOT/dev" 2>/dev/null; mount --make-rslave "$ROOT/dev" 2>/dev/null
cleanup(){ umount -R "$ROOT/proc" 2>/dev/null; umount -R "$ROOT/sys" 2>/dev/null; umount -R "$ROOT/dev" 2>/dev/null; }
trap cleanup EXIT

echo "=== versions ==="
chroot "$ROOT" /bin/bash -c 'pacman -Q systemd dbus openssh nodejs git 2>/dev/null'
echo "=== INTEGRITE pacman -Qkk (le test cle du 'v5 bacle') ==="
chroot "$ROOT" /bin/bash -c 'pacman -Qkk systemd systemd-libs dbus openssh pam pambase util-linux glibc 2>&1 | grep -viE "총|total|: 0 altered| 0 missing" ; echo "--- lignes de synthese ---"; pacman -Qkk systemd dbus openssh 2>&1 | tail -6'
echo "=== ldd sshd (libs manquantes ?) ==="
chroot "$ROOT" /bin/bash -c 'ldd /usr/bin/sshd 2>&1 | grep -i "not found" || echo "  OK aucune lib manquante pour sshd"'
echo "=== ldd systemd + dbus-daemon ==="
chroot "$ROOT" /bin/bash -c 'for b in /usr/lib/systemd/systemd /usr/bin/dbus-daemon /usr/lib/systemd/systemd-logind; do echo -n "$b: "; ldd "$b" 2>&1 | grep -ci "not found"; done'
echo "=== units critiques presents ==="
ls "$ROOT"/usr/lib/systemd/system/dbus.service "$ROOT"/usr/lib/systemd/system/systemd-logind.service "$ROOT"/usr/lib/systemd/system/sshd.service "$ROOT"/usr/lib/systemd/system/dhcpcd.service 2>/dev/null
echo "=== services actives (multi-user.target.wants) ==="
ls "$ROOT"/etc/systemd/system/multi-user.target.wants/ 2>/dev/null | grep -iE 'sshd|dhcpcd|wpa|dbus'
echo "=== wpa config ==="
cat "$ROOT"/etc/wpa_supplicant/wpa_supplicant-wlan0.conf 2>/dev/null
echo "=== ath12k firmware ==="
ls "$ROOT"/usr/lib/firmware/ath12k/WCN7850/hw2.0/ 2>/dev/null
echo "=== cmdline dans grub.cfg du rootfs ==="
grep -o 'linux /boot/Image.*' "$ROOT"/boot/grub/grub.cfg 2>/dev/null
echo "=== fin verif ==="
