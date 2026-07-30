#!/usr/bin/env bash
# Assainit l'arbre rootfs extrait de la golden -> base distribuable générique.
# Usage: sudo bash sanitize-rootfs.sh /mnt/sp12data/sanitize-work
set -euo pipefail
W="${1:?arbre rootfs à assainir}"
[ -d "$W/etc" ] || { echo "!! $W ne ressemble pas à un rootfs"; exit 1; }
echo "== Assainissement de $W =="

# 1) Préserver les configs KDE de stabilité (anti-veille) -> /etc/skel
mkdir -p "$W/etc/skel/.config"
for f in powerdevilrc kscreenlockerrc kwinrc plasma-localerc; do
  [ -e "$W/home/franz/.config/$f" ] && cp -a "$W/home/franz/.config/$f" "$W/etc/skel/.config/$f" && echo "  skel <- $f"
done

# 2) SECRETS / DONNÉES PERSO
rm -rf "$W"/home/* "$W"/home/.[!.]* 2>/dev/null || true         # tout /home (perso, tokens, ssh, ollama, navigateur)
rm -f  "$W"/etc/ssh/ssh_host_*                                   # clés d'hôte SSH (régénérées à l'install)
rm -f  "$W"/etc/wpa_supplicant/wpa_supplicant-*.conf            # WiFi PSK
rm -rf "$W"/etc/NetworkManager/system-connections/* 2>/dev/null || true
rm -f  "$W"/etc/sudoers.d/99-franz-claude                        # NOPASSWD ajouté
rm -rf "$W"/var/lib/tailscale/* 2>/dev/null || true
rm -rf "$W"/root/.ssh "$W"/root/.git-credentials "$W"/root/.bash_history "$W"/root/.config "$W"/root/.cache "$W"/root/.local 2>/dev/null || true

# 3) ARTEFACTS DE BUILD (volumineux, perso)
rm -rf "$W"/root/sp12-graft "$W"/root/linux-next "$W"/root/sp12* "$W"/root/build "$W"/root/*.tar* 2>/dev/null || true

# 4) LOGS / CACHES / ÉTAT VOLATILE
rm -rf "$W"/var/log/* "$W"/var/cache/* "$W"/var/tmp/* "$W"/tmp/* 2>/dev/null || true
rm -f  "$W"/var/lib/systemd/random-seed 2>/dev/null || true
: > "$W"/etc/machine-id 2>/dev/null || true                     # regénéré au 1er boot
rm -f  "$W"/var/lib/dbus/machine-id 2>/dev/null || true

# 5) AUTOLOGIN + IDENTITÉ perso
rm -f  "$W"/etc/sddm.conf.d/autologin.conf                      # l'installeur (re)configurera si voulu
echo "sp12" > "$W"/etc/hostname                                 # défaut, écrasé par l'installeur

# 6) COMPTE franz -> retiré (l'installeur crée l'utilisateur)
for db in passwd shadow group gshadow; do
  [ -e "$W/etc/$db" ] && sed -i '/^franz:/d' "$W/etc/$db"
done
# root : mot de passe verrouillé (l'installeur le (re)définit)
sed -i 's#^root:[^:]*:#root:!:#' "$W/etc/shadow" 2>/dev/null || true

# 7) fstab -> template (l'installeur écrit les vraies entrées de la cible)
cat > "$W/etc/fstab" <<'FSTAB'
# Généré par l'installeur SP12. Root + ESP renseignés à l'installation.
FSTAB

# 8) marqueur first-boot pour régénérer les clés SSH si l'installeur ne l'a pas fait
mkdir -p "$W/etc/systemd/system/multi-user.target.wants"

echo "== Assainissement terminé =="
echo "-- reste de /home (doit être vide) --"; ls -la "$W/home" 2>/dev/null
echo "-- secrets restants ? --"
find "$W/etc/ssh" -name 'ssh_host_*' 2>/dev/null
ls "$W"/etc/wpa_supplicant/*.conf 2>/dev/null || echo "  (pas de wpa conf) OK"
du -sh "$W" 2>/dev/null
