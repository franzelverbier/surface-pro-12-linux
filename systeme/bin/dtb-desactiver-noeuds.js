#!/usr/bin/env node
// Produit une copie d'un DTB où tout nœud dont le `compatible` correspond au motif
// donné est mis à status = "disabled". Sert à retirer un pilote du chemin de
// démarrage sans toucher au noyau : le périphérique n'existe plus, donc le pilote
// ne sonde jamais, et rien d'autre ne change.
//
// Usage : node dtb-desactiver-noeuds.js <entrée.dtb> <sortie.dtb> <motif-regex>
// Exemple : ... /boot/sp12.dtb /boot/sp12-sans-geni.dtb 'geni'
//
// ⚠️ Le `status` s'insère juste après l'accolade ouvrante : dtc exige que les
// propriétés précèdent les sous-nœuds.
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const [src, dst, motif] = process.argv.slice(2);
if (!src || !dst || !motif) {
  console.error("usage : dtb-desactiver-noeuds.js <entrée.dtb> <sortie.dtb> <motif>");
  process.exit(2);
}
const RE = new RegExp(`compatible\\s*=.*${motif}`);

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'dtbmod-'));
const dtsIn = path.join(tmp, 'in.dts');
const dtsOut = path.join(tmp, 'out.dts');
execFileSync('dtc', ['-I', 'dtb', '-O', 'dts', '-q', '-o', dtsIn, src]);
const lignes = fs.readFileSync(dtsIn, 'utf8').split('\n');

const pile = [];
const noeuds = [];
for (let i = 0; i < lignes.length; i++) {
  const l = lignes[i];
  if (/\{\s*$/.test(l) && !/^\s*\/\s*\{/.test(l)) {
    pile.push({ debut: i, cible: false, indent: (l.match(/^\s*/) || [''])[0], nom: l.trim() });
  } else if (/^\s*\};\s*$/.test(l)) {
    const n = pile.pop();
    if (n) { n.fin = i; noeuds.push(n); }
  } else if (RE.test(l) && pile.length) {
    pile[pile.length - 1].cible = true;
  }
}

const cibles = noeuds.filter(n => n.cible);
if (!cibles.length) { console.error(`aucun nœud ne correspond à « ${motif} »`); process.exit(1); }

const aInserer = new Map();
const aRemplacer = new Set();
for (const n of cibles) {
  let statusTrouve = -1, prof = 0;
  for (let i = n.debut + 1; i < n.fin; i++) {
    if (/\{\s*$/.test(lignes[i])) prof++;
    else if (/^\s*\};\s*$/.test(lignes[i])) prof--;
    else if (prof === 0 && /^\s*status\s*=/.test(lignes[i])) statusTrouve = i;
  }
  if (statusTrouve >= 0) aRemplacer.add(statusTrouve);
  else aInserer.set(n.debut, n.indent + '\t');
}

const sortie = [];
for (let i = 0; i < lignes.length; i++) {
  sortie.push(aRemplacer.has(i)
    ? lignes[i].replace(/status\s*=\s*"[^"]*"/, 'status = "disabled"')
    : lignes[i]);
  if (aInserer.has(i)) sortie.push(aInserer.get(i) + 'status = "disabled";');
}
fs.writeFileSync(dtsOut, sortie.join('\n'));
execFileSync('dtc', ['-I', 'dts', '-O', 'dtb', '-q', '-o', dst, dtsOut]);

// contrôle : le seul écart avec l'original doit porter sur des propriétés status
const a = execFileSync('dtc', ['-I', 'dtb', '-O', 'dts', '-q', src], { encoding: 'utf8' }).split('\n');
const b = execFileSync('dtc', ['-I', 'dtb', '-O', 'dts', '-q', dst], { encoding: 'utf8' }).split('\n');
let horsStatus = 0, statusChanges = 0;
const max = Math.max(a.length, b.length);
if (a.length !== b.length) {
  // longueurs différentes : on compte les lignes status ajoutées
  statusChanges = b.filter(l => /status\s*=\s*"disabled"/.test(l)).length
                - a.filter(l => /status\s*=\s*"disabled"/.test(l)).length;
} else {
  for (let i = 0; i < max; i++) {
    if (a[i] === b[i]) continue;
    if (/status\s*=/.test(a[i]) || /status\s*=/.test(b[i])) statusChanges++;
    else horsStatus++;
  }
}
fs.rmSync(tmp, { recursive: true, force: true });
console.log(`${cibles.length} nœuds « ${motif} » désactivés (${aRemplacer.size} status réécrits, ${aInserer.size} ajoutés)`);
console.log(`contrôle : ${statusChanges} propriétés status de différence, ${horsStatus} différence(s) hors status`);
if (horsStatus) { console.error('⚠️ des différences hors status : NE PAS UTILISER ce DTB'); process.exit(1); }
