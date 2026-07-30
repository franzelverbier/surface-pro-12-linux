#!/usr/bin/env bash
# backup-sp12.sh — snapshot versionné du rootfs SP12 (via SSH/Tailscale), depuis CachyOS.
# Usage : bash backup-sp12.sh "description-courte-sans-espaces"
# Stocke dans ~/sp12-backups/<horodatage>-<description>/ (HORS OneDrive, pas de sync cloud).
set -euo pipefail

DESC="${1:-snapshot}"
DEST_ROOT="$HOME/sp12-backups"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST="$DEST_ROOT/${STAMP}-${DESC}"
HOST="root@sp12"   # via Tailscale (nom tailnet) ; fallback : root@sp12.local ou IP directe
SSH="sshpass -p sp12 ssh -o StrictHostKeyChecking=accept-new"

mkdir -p "$DEST"
echo ">> Backup SP12 -> $DEST"

echo "== 1. Manifeste (kernel, systemd, paquets, services, cmdline) =="
$SSH -o ConnectTimeout=10 "$HOST" '
  echo "--- uname ---"; uname -a
  echo "--- cmdline ---"; cat /proc/cmdline
  echo "--- systemd ---"; systemctl --version | head -1
  echo "--- services en echec ---"; systemctl --failed --no-legend --no-pager || true
  echo "--- disque root ---"; findmnt -n -o SOURCE,LABEL,FSTYPE /
  echo "--- paquets installes ---"; pacman -Q
' > "$DEST/manifest.txt" 2>&1

echo "== 2. dmesg complet (diagnostic driver) =="
$SSH "$HOST" 'dmesg' > "$DEST/dmesg.log" 2>&1 || true

echo "== 3. Snapshot rootfs (tar.zst ; exclut proc/sys/dev/tmp/run/mnt + cache) =="
# --one-file-system : ne franchit AUCUN point de montage (protège contre /mnt/winc NTFS,
# /mnt/wsl-build WSL, /boot/efi vfat, etc. laissés montés).
$SSH "$HOST" '
  tar --numeric-owner --acls --xattrs --one-file-system \
      --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/tmp --exclude=/run \
      --exclude=/mnt --exclude=/media \
      --exclude=/var/cache/pacman/pkg -cpf - / 2>/dev/null | zstd -T0 -3
' > "$DEST/rootfs.tar.zst"

SIZE=$(du -sh "$DEST/rootfs.tar.zst" | cut -f1)
echo ">> Backup termine : $DEST (rootfs: $SIZE)"
echo ">> Pour restaurer : voir scripts/restore-sp12.sh (a ecrire au besoin) ou extraire manuellement"
      # tar --numeric-owner --acls --xattrs -xpf rootfs.tar.zst -C /mnt/cible
