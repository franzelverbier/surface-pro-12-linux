#!/usr/bin/env node
// Liste les pilotes qui, sur cette machine, sondent pendant les initcall du noyau
// 7.3 (donc INTÉGRÉS, pas modules) ET dont le code a changé depuis notre noyau de
// juin. C'est l'ensemble des suspects possibles pour un reset pendant l'init.
//
// Méthode :
//   1. compatibles présents dans le DTB réellement chargé ;
//   2. fichiers source de 7.3 qui contiennent l'un de ces compatibles ;
//   3. parmi eux, ceux qui ne produisent PAS de .ko dans l'arbre de modules 7.3
//      -> ils sont intégrés, donc ils s'exécutent pendant les initcall ;
//   4. parmi ceux-là, ceux dont le fichier diffère de notre arbre de juin.
'use strict';
const fs = require('fs');
const path = require('path');
const { execSync, execFileSync } = require('child_process');

const DTB = process.argv[2] || '/boot/sp12.dtb';
const T73 = '/data/linux-7.3';
const T71 = '/home/franz/sp12-kernel-rebuild/linux-next';
const MODS = '/lib/modules/7.3.0-rc3-mainline';

const sh = (c) => { try { return execSync(c, { encoding: 'utf8', maxBuffer: 1 << 28 }); } catch (e) { return e.stdout || ''; } };

// 1. compatibles du DTB
const dts = sh(`dtc -I dtb -O dts -q ${DTB} 2>/dev/null`);
const compat = [...new Set((dts.match(/"[a-z0-9]+,[a-z0-9._+-]+"/g) || []).map(s => s.slice(1, -1)))];
fs.writeFileSync('/tmp/compat-list.txt', compat.join('\n') + '\n');
console.log(`compatibles dans ${path.basename(DTB)} : ${compat.length}`);

// 2. fichiers source qui les mentionnent
const fichiers = [...new Set(sh(`grep -rlFf /tmp/compat-list.txt ${T73}/drivers ${T73}/sound 2>/dev/null`)
  .trim().split('\n').filter(f => f.endsWith('.c')))];
console.log(`fichiers source les mentionnant dans 7.3 : ${fichiers.length}`);

// 3. lesquels ne produisent pas de module ? (donc intégrés)
const kos = new Set(sh(`find ${MODS} -name '*.ko' -printf '%f\\n'`).trim().split('\n')
  .map(s => s.replace(/\.ko$/, '').replace(/_/g, '-')));

const integres = fichiers.filter(f => {
  const base = path.basename(f, '.c').replace(/_/g, '-');
  return !kos.has(base);
});
console.log(`parmi eux, INTÉGRÉS au noyau (aucun .ko correspondant) : ${integres.length}`);

// 4. lesquels ont changé depuis juin ?
const change = [];
for (const f of integres) {
  const rel = path.relative(T73, f);
  const vieux = path.join(T71, rel);
  if (!fs.existsSync(vieux)) { change.push([rel, 'NOUVEAU FICHIER']); continue; }
  const d = sh(`diff -q "${vieux}" "${f}" 2>/dev/null`);
  if (d.trim()) {
    const n = sh(`diff "${vieux}" "${f}" | grep -c '^[<>]'`).trim();
    change.push([rel, `${n} lignes changées`]);
  }
}

console.log(`\n=== SUSPECTS : intégrés, liés à notre matériel, et modifiés depuis juin ===`);
change.sort((a, b) => (parseInt(b[1]) || 1e9) - (parseInt(a[1]) || 1e9));
for (const [f, n] of change) console.log(`  ${n.padStart(20)}  ${f}`);
console.log(`\ntotal : ${change.length} fichiers`);
