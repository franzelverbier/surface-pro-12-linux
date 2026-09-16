#!/usr/bin/env node
// Archive ce qui n'est plus utile dans /boot et dans /lib/modules.
//
// Règle : on ne décide PAS au jugé. Un fichier n'est candidat que s'il est
//   1. absent de /boot/grub/grub.cfg, ET
//   2. absent de toute référence sous /etc (services, presets mkinitcpio, hooks),
//      de /etc/fstab et des unités systemd.
// Tout le reste est conservé. Rien n'est supprimé : on DÉPLACE, avec un
// manifeste qui dit d'où vient chaque fichier et comment le remettre.
//
// Usage : node archiver-boot.js [--executer]    (sans l'option : simulation)
'use strict';
const fs = require('fs');
const path = require('path');
const { execSync, execFileSync } = require('child_process');

const EXEC = process.argv.includes('--executer');
const DEST = '/data/sp12data/archives/boot-20260916';

const grub = fs.readFileSync('/boot/grub/grub.cfg', 'utf8');
const refsEtc = execSync(
  `grep -rhoE '(/boot/[A-Za-z0-9._-]+|/lib/modules/[A-Za-z0-9._-]+)' /etc 2>/dev/null | sort -u || true`,
  { encoding: 'utf8' });

const cite = nom => grub.includes(nom) || refsEtc.includes(nom);

// --- fichiers de /boot ------------------------------------------------------
const fichiers = fs.readdirSync('/boot', { withFileTypes: true })
  .filter(d => d.isFile()).map(d => d.name);

const motif = [
  [/\.(ecarte-\d+|bak)$/,           'sauvegarde datée, écartée à l\'époque'],
  [/\.avant-[a-z0-9-]+$/,           'sauvegarde d\'avant une modification'],
  [/\.ife1-bug$/,                   'DTB de la greffe caméra fautive du 16/09'],
  [/7\.3rc3/,                       'essai mainline 7.3-rc3, retiré du menu le 16/09'],
  [/^sp12-sans-geni\.dtb$/,         'DTB de diagnostic geni, hypothèse réfutée'],
  [/^sp12-amont-el2-nocs\.dtb$/,    'DTB sans CoreSight, hypothèse réfutée'],
  [/^Image-el2(gic|vsock|audio)$/,  'noyau d\'essai EL2, plus au menu'],
  [/^initramfs-(el2min|nft|sp12-audio)\.img$/, 'initramfs d\'un essai plus au menu'],
  [/^initramfs-linux\.img$/,        'initramfs du noyau ALARM, dont l\'Image a été écrasée'],
  [/^sp12(-el2-audio|-juin-pdcfix)?\.dtb$/,    'DTB d\'une entrée retirée du menu'],
];

const plan = [];
for (const f of fichiers) {
  if (cite(f)) continue;
  const m = motif.find(([re]) => re.test(f));
  if (!m) { plan.push({ chemin: '/boot/' + f, raison: null }); continue; }
  plan.push({ chemin: '/boot/' + f, raison: m[1] });
}

// --- arbres de modules ------------------------------------------------------
for (const d of fs.readdirSync('/lib/modules')) {
  if (cite(d)) continue;
  let paquet = null;
  try { paquet = execSync(`pacman -Qo /lib/modules/${d}/modules.dep 2>/dev/null`, { encoding: 'utf8' }).trim(); } catch {}
  if (paquet) continue;                       // appartient à un paquet : on n'y touche pas
  if (!/^7\.3\.0-rc3/.test(d)) continue;      // seuls les arbres 7.3-rc3 sont candidats
  plan.push({ chemin: '/lib/modules/' + d, raison: 'arbre de modules de l\'essai mainline 7.3-rc3' });
}

const taille = p => { try { return parseInt(execSync(`du -sb ${p} | cut -f1`, { encoding: 'utf8' })); } catch { return 0; } };
const mo = o => (o / 1048576).toFixed(1).padStart(7);

const connus = plan.filter(p => p.raison);
const inconnus = plan.filter(p => !p.raison);

console.log(`=== ${connus.length} éléments à archiver ===`);
let total = 0;
for (const p of connus.sort((a, b) => a.chemin.localeCompare(b.chemin))) {
  const t = taille(p.chemin); total += t;
  console.log(`  ${mo(t)} Mo  ${path.basename(p.chemin).padEnd(44)} ${p.raison}`);
}
console.log(`  ${mo(total)} Mo  TOTAL`);

if (inconnus.length) {
  console.log(`\n=== ${inconnus.length} NON référencés mais sans motif connu — CONSERVÉS ===`);
  for (const p of inconnus) console.log(`  ${mo(taille(p.chemin))} Mo  ${path.basename(p.chemin)}`);
}

if (!EXEC) { console.log('\n(simulation — relancer avec --executer)'); process.exit(0); }

fs.mkdirSync(DEST, { recursive: true });
const manifeste = [`# Archive /boot et /lib/modules du 2026-09-16`, '',
  `Rien n'a été supprimé : chaque élément a été DÉPLACÉ ici depuis son emplacement`,
  `d'origine. Pour en remettre un : sudo mv <ici>/<nom> <chemin d'origine>.`, '',
  '| Taille | Nom | Origine | Motif |', '|---|---|---|---|'];
for (const p of connus) {
  const nom = path.basename(p.chemin);
  const t = mo(taille(p.chemin)).trim();          // mesurer AVANT de déplacer
  execFileSync('sudo', ['mv', p.chemin, path.join(DEST, nom)]);
  manifeste.push(`| ${t} Mo | \`${nom}\` | \`${p.chemin}\` | ${p.raison} |`);
}
fs.writeFileSync('/tmp/manifeste.md', manifeste.join('\n') + '\n');
execFileSync('sudo', ['cp', '/tmp/manifeste.md', path.join(DEST, 'MANIFESTE.md')]);
console.log(`\n${connus.length} éléments déplacés vers ${DEST}`);
