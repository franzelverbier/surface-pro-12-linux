#!/bin/bash
R=/root/sp12/rootfs
echo "=== cles d'hote SSH presentes ? (la cause probable) ==="
ls -la "$R"/etc/ssh/ssh_host_* 2>/dev/null || echo "AUCUNE CLE D'HOTE -> sshd echoue au boot !"
echo
echo "=== services actives (multi-user.target.wants) ==="
ls "$R"/etc/systemd/system/multi-user.target.wants/ 2>/dev/null
echo
echo "=== sshd.service / sshd.socket enabled ? ==="
ls "$R"/etc/systemd/system/*/sshd* 2>/dev/null; ls "$R"/etc/systemd/system/sshd* 2>/dev/null
echo
echo "=== drop-in sshd ==="
cat "$R"/etc/ssh/sshd_config.d/10-sp12.conf 2>/dev/null
echo
echo "=== dhcpcd unit (risque de blocage boot ?) ==="
ls "$R"/etc/systemd/system/*/dhcpcd* 2>/dev/null
echo
echo "=== getty autologin (console) ==="
cat "$R"/etc/systemd/system/getty@tty1.service.d/autologin.conf 2>/dev/null
echo
echo "=== sshdgenkeys.service existe-t-il (genere les cles au boot) ? ==="
ls "$R"/usr/lib/systemd/system/sshdgenkeys.service 2>/dev/null || echo "pas de sshdgenkeys -> cles JAMAIS generees auto"
grep -i 'wants\|requires\|after' "$R"/usr/lib/systemd/system/sshd.service 2>/dev/null
