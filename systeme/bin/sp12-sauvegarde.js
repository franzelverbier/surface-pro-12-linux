#!/usr/bin/env node
// sp12-sauvegarde.js — instantané local du système, avant expérimentation.
//
// À exécuter en root. Écrit dans /data/sauvegardes/<horodatage>-<description>/.
// /data est une partition distincte de / : une racine cassée n'emporte pas l'instantané.
// ⚠️ Même disque physique. Protège d'une bêtise logicielle, PAS d'une panne de disque.
//
// Usage : sudo node sp12-sauvegarde.js "avant-rust"

const { execFileSync, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const DESC = (process.argv[2] || 'instantane').replace(/[^A-Za-z0-9._-]/g, '-');
const STAMP = new Date().toISOString().replace(/[-:]/g, '').replace(/\..+/, '').replace('T', '-');
const DEST = `/data/sauvegardes/${STAMP}-${DESC}`;

const EXCLURE = [
  '/proc', '/sys', '/dev', '/run', '/tmp', '/mnt', '/media',
  '/swapfile',                       // 4 Go, recréable par fallocate
  '/var/cache/pacman/pkg',           // 5,5 Go, retéléchargeable
  '/var/tmp', '/var/lib/systemd/coredump',
  '/lost+found',
];

fs.mkdirSync(DEST, { recursive: true });
const journal = (s) => { console.log(s); fs.appendFileSync(`${DEST}/journal.txt`, s + '\n'); };

journal(`>> instantané SP12 -> ${DEST}`);
journal(`>> démarré ${new Date().toISOString()}`);

// --- 1. manifeste : tout ce qu'il faut pour reconstruire sans l'archive
const cmd = (c) => { try { return execFileSync('/bin/bash', ['-c', c], { encoding: 'utf8', maxBuffer: 1 << 28 }); } catch (e) { return (e.stdout || '') + '\n[erreur] ' + e.message; } };

fs.writeFileSync(`${DEST}/manifest.txt`, [
  '=== uname ===',            cmd('uname -a'),
  '=== cmdline ===',          cmd('cat /proc/cmdline'),
  '=== systemd ===',          cmd('systemctl --version | head -1'),
  '=== services en echec ===', cmd('systemctl --failed --no-legend --no-pager'),
  '=== montages ===',         cmd('findmnt -no TARGET,SOURCE,FSTYPE,LABEL,OPTIONS'),
  '=== blocs ===',            cmd('lsblk -o NAME,LABEL,FSTYPE,SIZE,MOUNTPOINT,PARTUUID'),
  '=== espace ===',           cmd('df -h'),
  '=== modules charges ===',  cmd('lsmod'),
  '=== entrees GRUB ===',     cmd('grep -n "^menuentry\\|^set default" /boot/grub/grub.cfg'),
  '=== /boot ===',            cmd('ls -la --time-style=long-iso /boot'),
].join('\n') + '\n');

for (const [f, c] of [
  ['paquets-tous.txt', 'pacman -Q'],
  ['paquets-explicites.txt', 'pacman -Qqe'],
  ['paquets-aur.txt', 'pacman -Qm'],
  ['paquets-fichiers-modifies.txt', 'pacman -Qkk 2>&1 | grep -v ": 0 fichier" | head -200'],
]) fs.writeFileSync(`${DEST}/${f}`, cmd(c));
fs.copyFileSync('/etc/pacman.conf', `${DEST}/pacman.conf`);
journal('== 1. manifeste et listes de paquets : fait');

// --- 2. les archives
function archiver(nom, racine, args) {
  const sortie = `${DEST}/${nom}`;
  journal(`== archivage ${racine} -> ${nom}`);
  const t0 = Date.now();
  const r = spawnSync('tar', [
    '--numeric-owner', '--acls', '--xattrs', '--one-file-system',
    '-I', 'zstd -T0 -3',
    ...args, '-cpf', sortie, '-C', racine, '.',
  ], { stdio: ['ignore', 'ignore', 'pipe'], encoding: 'utf8' });

  // tar sort en 1 quand des fichiers ont change pendant la lecture : normal sur un
  // systeme vivant, ce n'est PAS un echec. Seul >1 est une vraie erreur.
  const err = (r.stderr || '').split('\n').filter(Boolean);
  const taille = fs.existsSync(sortie) ? fs.statSync(sortie).size : 0;
  journal(`   code=${r.status}  ${(taille / 2 ** 30).toFixed(2)} Gio  ${((Date.now() - t0) / 1000).toFixed(0)} s`);
  if (err.length) journal(`   avertissements tar : ${err.length} (voir tar-${nom}.log)`);
  if (err.length) fs.writeFileSync(`${DEST}/tar-${nom}.log`, err.join('\n'));
  if (r.status > 1) { journal(`   !! ECHEC sur ${nom}`); process.exitCode = 1; }
  return sortie;
}

const fichiers = [];
fichiers.push(archiver('esp.tar.zst', '/boot/efi', []));
fichiers.push(archiver('rootfs.tar.zst', '/', EXCLURE.map((e) => `--exclude=.${e}`)));

// --- 3. empreintes
journal('== 3. empreintes sha256');
const sommes = fichiers.map((f) => cmd(`sha256sum "${f}"`).trim()).join('\n');
fs.writeFileSync(`${DEST}/SHA256SUMS`, sommes + '\n');
journal(sommes);

// --- 4. mode d emploi
fs.writeFileSync(`${DEST}/LISEZ-MOI.md`, `# Instantané SP12 — ${STAMP} (${DESC})

⚠️ **Même disque physique que le système.** Protège d'une bêtise logicielle
(expérimentation, mise à jour ratée, /etc cassé), **pas** d'une panne de disque.
Pour ça, copier ce répertoire ailleurs — kDrive par rclone, ou un disque externe.

## Ce qu'il contient

| Fichier | |
|---|---|
| \`rootfs.tar.zst\` | la racine (sda6, LABEL=SP12ROOT-INT), \`/boot\` compris |
| \`esp.tar.zst\` | la partition EFI (sda1, LABEL=SYSTEM) |
| \`manifest.txt\` | noyau, cmdline, montages, partitions, modules, entrées GRUB |
| \`paquets-*.txt\` | l'état de pacman, dont les paquets AUR |
| \`SHA256SUMS\` | empreintes des archives |

Exclus volontairement : \`/swapfile\` (4 Go, recréable), le cache pacman (5,5 Go,
retéléchargeable), les pseudo-systèmes de fichiers, \`/home\` et \`/data\` (partitions
distinctes, \`--one-file-system\`).

## Restaurer

Depuis un système live aarch64, la racine cible montée sur \`/mnt\` :

\`\`\`bash
sha256sum -c SHA256SUMS                 # d'abord vérifier
mount /dev/disk/by-label/SP12ROOT-INT /mnt
rm -rf /mnt/*                            # ⚠️ irréversible
tar --numeric-owner --acls --xattrs -I 'zstd -d' -xpf rootfs.tar.zst -C /mnt
mkdir -p /mnt/{proc,sys,dev,run,tmp,mnt,media}
chmod 1777 /mnt/tmp
fallocate -l 4G /mnt/swapfile && chmod 600 /mnt/swapfile && mkswap /mnt/swapfile

mount /dev/disk/by-label/SYSTEM /mnt/boot/efi
tar -I 'zstd -d' -xpf esp.tar.zst -C /mnt/boot/efi
\`\`\`

Les entrées GRUB et le DTB vivent dans \`/boot\`, donc dans \`rootfs.tar.zst\`.
\`manifest.txt\` rappelle la ligne de commande noyau et l'entrée par défaut du moment.
`);

journal(`>> terminé ${new Date().toISOString()}`);
journal(`>> ${cmd(`du -sh "${DEST}"`).trim()}`);
