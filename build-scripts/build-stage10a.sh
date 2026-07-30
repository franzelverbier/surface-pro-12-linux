#!/bin/bash
set -e
ROOT=/root/sp12/rootfs
exec >> /mnt/c/sp12-linux/build.log 2>&1
echo "=== STAGE10a v5 stack start $(date -u +%H:%M:%S) ==="
mount -t proc proc "$ROOT/proc"; mount --rbind /sys "$ROOT/sys"; mount --make-rslave "$ROOT/sys"; mount --rbind /dev "$ROOT/dev"; mount --make-rslave "$ROOT/dev"
cleanup(){ umount -R "$ROOT/proc" 2>/dev/null||true; umount -R "$ROOT/sys" 2>/dev/null||true; umount -R "$ROOT/dev" 2>/dev/null||true; }
trap cleanup EXIT
chroot "$ROOT" /bin/bash -ec '
rm -f /etc/resolv.conf; printf "nameserver 10.255.255.254\n" > /etc/resolv.conf
sed -i "s/^SigLevel.*/SigLevel = Never/" /etc/pacman.conf
echo ">>> pacman openssh nodejs npm git"
pacman -Sy --noconfirm openssh nodejs npm git 2>&1 | tail -4
echo ">>> services auto (sshd + dhcpcd), iwd off (inutile sans crypto noyau)"
systemctl enable sshd.service >/dev/null 2>&1 && echo "sshd enabled"
systemctl enable dhcpcd.service >/dev/null 2>&1 && echo "dhcpcd enabled"
systemctl disable iwd.service >/dev/null 2>&1 || true
echo ">>> Claude Code (npm + postinstall)"
npm install -g @anthropic-ai/claude-code 2>&1 | tail -3
node "$(npm root -g)/@anthropic-ai/claude-code/install.cjs" 2>&1 | tail -5 || echo "postinstall: voir ci-dessus"
echo ">>> verifs"
command -v claude && echo "CLAUDE OK: $(claude --version 2>&1 | head -1)" || echo "claude binaire absent"
command -v sshd && echo "sshd OK"
# restaurer resolv.conf systemd + un resolveur de secours pour le runtime
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
'
echo "=== STAGE10a done $(date -u +%H:%M:%S) ==="
