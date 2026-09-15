#!/usr/bin/env node
// Produit une copie d'un DTS décompilé où tout nœud CoreSight (compatible
// contenant "coresight" ou le CTCU) est mis à status = "disabled".
// Usage : node dtb-sans-coresight.js <entrée.dts> <sortie.dts>
'use strict';
const fs = require('fs');
const [src, dst] = process.argv.slice(2);
const lines = fs.readFileSync(src, 'utf8').split('\n');

const RE_CIBLE = /compatible\s*=\s*"[^"]*(coresight|ctcu)[^"]*"/;

// Première passe : repérer, pour chaque nœud, sa ligne d'ouverture et de fermeture,
// et s'il porte un compatible CoreSight (directement, pas via un descendant).
const pile = [];            // { debut, fin, cible, indent }
const noeuds = [];
for (let i = 0; i < lines.length; i++) {
  const l = lines[i];
  if (/\{\s*$/.test(l) && !/^\s*\/\s*\{/.test(l)) {
    pile.push({ debut: i, cible: false, indent: (l.match(/^\s*/) || [''])[0] });
  } else if (/^\s*\};\s*$/.test(l)) {
    const n = pile.pop();
    if (n) { n.fin = i; noeuds.push(n); }
  } else if (RE_CIBLE.test(l) && pile.length) {
    pile[pile.length - 1].cible = true;
  }
}

const cibles = noeuds.filter(n => n.cible);
if (!cibles.length) { console.error('aucun nœud CoreSight trouvé'); process.exit(1); }

// Deuxième passe : dans chaque nœud cible, remplacer le status existant ou en insérer un.
const aInserer = new Map();   // ligne d'OUVERTURE -> indentation (les propriétés doivent précéder les sous-nœuds)
const aRemplacer = new Set(); // index de ligne status à réécrire
for (const n of cibles) {
  let statusTrouve = -1;
  let profondeur = 0;
  for (let i = n.debut + 1; i < n.fin; i++) {
    if (/\{\s*$/.test(lines[i])) profondeur++;
    else if (/^\s*\};\s*$/.test(lines[i])) profondeur--;
    else if (profondeur === 0 && /^\s*status\s*=/.test(lines[i])) statusTrouve = i;
  }
  if (statusTrouve >= 0) aRemplacer.add(statusTrouve);
  else aInserer.set(n.debut, n.indent + '\t');
}

const sortie = [];
for (let i = 0; i < lines.length; i++) {
  if (aRemplacer.has(i)) {
    sortie.push(lines[i].replace(/status\s*=\s*"[^"]*"/, 'status = "disabled"'));
  } else {
    sortie.push(lines[i]);
  }
  if (aInserer.has(i)) sortie.push(aInserer.get(i) + 'status = "disabled";');
}
fs.writeFileSync(dst, sortie.join('\n'));
console.log(`${cibles.length} nœuds CoreSight désactivés (${aRemplacer.size} status réécrits, ${aInserer.size} ajoutés)`);
