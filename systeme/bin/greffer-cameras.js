#!/usr/bin/env node
// Fabrique un OVERLAY de device tree qui ajoute les caméras au DTB de juin —
// celui qui démarre en EL2 — au lieu de basculer sur le device tree amont, que
// la bascule EL2 refuse.
//
// POURQUOI UN OVERLAY ET NON UN RECOLLAGE DE TEXTE. Un DTB décompilé n'a plus
// de labels sur les références : tout est numérique, et les numéros de phandle
// diffèrent d'un fichier à l'autre. Recoller des nœuds ferait pointer les
// horloges et les IOMMU n'importe où. Le DTB de juin porte un nœud __symbols__
// (646 labels), donc fdtoverlay sait résoudre &camcc, &tlmm, &apps_smmu… vers
// les bons phandles de la CIBLE. C'est le mécanisme prévu pour ça.
//
// CE QUI MANQUE VRAIMENT DANS LE DTB DE JUIN, et qui n'a rien à voir avec EL2 :
// le banc de régulateurs 8 (PMIC pm8010), qui alimente 7 des 11 rails des
// capteurs. Les bancs 0,1,2,3,6,7 y sont, le 8 non. L'overlay l'ajoute.
//
// Aucun bloc n'est retapé : tout est DÉCOUPÉ dans les sources du noyau par
// appariement d'accolades, comme refaire-grub.js recopie les corps d'entrée.
'use strict';
const fs = require('fs');
const path = require('path');

const SRC = process.argv[2] || '/data/linux-7.3/arch/arm64/boot/dts/qcom';
const SORTIE = process.argv[3] || 'cameras.dtso';
const HAMOA = path.join(SRC, 'hamoa.dtsi');
const CARTE = path.join(SRC, 'x1p42100-microsoft-sp12in.dts');

const cache = new Map();
const lire = f => { if (!cache.has(f)) cache.set(f, fs.readFileSync(f, 'utf8').split('\n')); return cache.get(f); };

// Découpe le bloc dont la première ligne correspond au motif, en appariant les
// accolades. Renvoie les lignes telles quelles, indentation comprise.
function bloc(fichier, motif, nom) {
  const L = lire(fichier);
  const re = new RegExp(motif);
  const i = L.findIndex(l => re.test(l));
  if (i < 0) { console.error(`❌ INTROUVABLE : ${nom} (${motif}) dans ${path.basename(fichier)}`); process.exit(1); }
  let p = 0, j = i;
  do { p += (L[j].match(/\{/g) || []).length - (L[j].match(/\}/g) || []).length; j++; } while (p > 0 && j < L.length);
  if (p !== 0) { console.error(`❌ accolades non appariées pour ${nom}`); process.exit(1); }
  console.error(`   ${nom.padEnd(22)} ${path.basename(fichier)} ${i + 1}-${j}  (${j - i} lignes)`);
  return L.slice(i, j);
}

// Les #include de macros des deux sources (on écarte les inclusions de .dtsi,
// qui tireraient tout le SoC dans l'overlay).
function includes() {
  const vus = new Set();
  for (const f of [HAMOA, CARTE])
    for (const l of lire(f))
      if (/^#include\s+</.test(l)) vus.add(l.trim());
  return [...vus].sort();
}

const out = [];
console.error('=== blocs prélevés ===');
const ajouter = (titre, lignes) => out.push('', `\t/* ${titre} */`, ...lignes);

// 1. Le banc de régulateurs manquant, ancré par CHEMIN : le label rpmh_rsc
//    n'est pas exposé dans __symbols__, contrairement au nœud lui-même.
const reg8 = bloc(CARTE, '^\\tregulators-8 \\{', 'banc pm8010 (reg. 8)');

// 2. Les blocs de niveau SoC.
const socBlocs = [
  ['cci0', bloc(HAMOA, '^\\t\\tcci0: cci@ac15000 \\{', 'cci0')],
  ['cci1', bloc(HAMOA, '^\\t\\tcci1: cci@ac16000 \\{', 'cci1')],
  ['camss + csiphy0 + csiphy4', bloc(HAMOA, '^\\t\\tcamss: isp@acb7000 \\{', 'camss (+csiphy)')],
];

// 3. Les états pinctrl : ceux du SoC et ceux de la carte.
const pinBlocs = [
  ...['cci0_default', 'cci0_sleep', 'cci1_default', 'cci1_sleep']
    .map(n => [n, bloc(HAMOA, `^\\s*${n}: `, n)]),
  ...['cam_indicator_en', 'cam_front_default', 'cam_rear_default', 'cam_ir_default']
    .map(n => [n, bloc(CARTE, `^\\s*${n}: `, n)]),
];

// 4. Les fragments de carte, qui référencent les labels posés plus haut.
const carteBlocs = [
  ['leds (témoin de confidentialité)', bloc(CARTE, '^\\tleds \\{', 'leds')],
  ['&camss', bloc(CARTE, '^&camss \\{', '&camss')],
  ['&cci0', bloc(CARTE, '^&cci0 \\{', '&cci0')],
  ['&cci1', bloc(CARTE, '^&cci1 \\{', '&cci1')],
  ['&cci0_i2c1 — capteur arrière ov13858', bloc(CARTE, '^&cci0_i2c1 \\{', '&cci0_i2c1')],
  ['&cci1_i2c1 — capteur avant ov02c10', bloc(CARTE, '^&cci1_i2c1 \\{', '&cci1_i2c1')],
  ['&csiphy0', bloc(CARTE, '^&csiphy0 \\{', '&csiphy0')],
  ['&csiphy4', bloc(CARTE, '^&csiphy4 \\{', '&csiphy4')],
];

out.push('/dts-v1/;');
out.push('/plugin/;');
out.push('');
out.push('/* Greffe caméra pour le DTB de juin (sp12-el2-pdc-test.dtb).');
out.push(' * Fabriqué par systeme/bin/greffer-cameras.js — ne pas éditer à la main.');
out.push(' * Les blocs sont découpés dans hamoa.dtsi et x1p42100-microsoft-sp12in.dts.');
out.push(' */');
out.push('');
out.push(...includes());
out.push('');
out.push('/* Le banc pm8010 : absent du DTB de juin, il alimente 7 des 11 rails des');
out.push(' * capteurs. Ancré par chemin, faute de label rpmh_rsc dans __symbols__. */');
out.push('&{/soc@0/rsc@17500000} {');
out.push(...reg8);
out.push('};');
out.push('');
out.push('&soc {');
for (const [titre, b] of socBlocs) ajouter(titre, b);
out.push('};');
out.push('');
out.push('&tlmm {');
for (const [titre, b] of pinBlocs) ajouter(titre, b);
out.push('};');
for (const [titre, b] of carteBlocs) {
  out.push('', `/* ${titre} */`);
  if (/^\t*leds \{/.test(b[0])) { out.push('&{/} {', ...b, '};'); }   // nœud de racine
  else out.push(...b);
}
out.push('');

fs.writeFileSync(SORTIE, out.join('\n'));
console.error(`\n=== overlay écrit : ${SORTIE} (${out.length} lignes) ===`);
