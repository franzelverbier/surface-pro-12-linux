#!/usr/bin/env node
// Mesure le NIVEAU DE NOIR d'un capteur, à partir d'une image brute prise
// objectif occulté. C'est la définition même de la grandeur : la valeur que
// rend un photosite qui ne reçoit aucune lumière.
//
// Le flux brut est du SGRBG10_CSI2P : 10 bits par photosite, empaquetés par
// groupes de quatre sur cinq octets (4 × 8 bits de poids fort, puis un octet
// portant les 4 paires de bits de poids faible).
//
// Usage : node mesure-niveau-noir.js <fichier.bin> <largeur> <hauteur> <stride>
'use strict';
const fs = require('fs');
const [fichier, L, H, STRIDE] = [process.argv[2], +process.argv[3], +process.argv[4], +process.argv[5]];
const buf = fs.readFileSync(fichier);

// SGRBG : ligne paire = G R G R…, ligne impaire = B G B G…
const canaux = { Gr: [], R: [], B: [], Gb: [] };
const pousse = (y, x, v) => {
  const pair = y % 2 === 0;
  if (pair) (x % 2 === 0 ? canaux.Gr : canaux.R).push(v);
  else (x % 2 === 0 ? canaux.B : canaux.Gb).push(v);
};

for (let y = 0; y < H; y++) {
  const base = y * STRIDE;
  for (let g = 0; g * 5 + 4 < STRIDE; g++) {
    const o = base + g * 5;
    if (o + 4 >= buf.length) break;
    const lsb = buf[o + 4];
    for (let k = 0; k < 4; k++) {
      const x = g * 4 + k;
      if (x >= L) break;
      pousse(y, x, (buf[o + k] << 2) | ((lsb >> (k * 2)) & 0x3));
    }
  }
}

const stat = a => {
  if (!a.length) return null;
  const t = a.slice().sort((p, q) => p - q);
  const moy = a.reduce((s, v) => s + v, 0) / a.length;
  const ec = Math.sqrt(a.reduce((s, v) => s + (v - moy) ** 2, 0) / a.length);
  return { n: a.length, moy, ec, med: t[t.length >> 1], min: t[0], max: t[t.length - 1], p99: t[Math.floor(t.length * 0.99)] };
};

console.log(`  fichier : ${fichier} (${buf.length} octets, attendu ${STRIDE * H})`);
let somme = 0, poids = 0;
for (const [nom, a] of Object.entries(canaux)) {
  const s = stat(a);
  if (!s) continue;
  somme += s.moy * s.n; poids += s.n;
  console.log(`  ${nom.padEnd(3)} n=${String(s.n).padStart(8)}  moyenne=${s.moy.toFixed(2).padStart(7)}  médiane=${String(s.med).padStart(4)}  écart-type=${s.ec.toFixed(2).padStart(6)}  min=${s.min}  max=${s.max}  p99=${s.p99}`);
}
const global = somme / poids;
console.log(`\n  niveau de noir global (10 bits) : ${global.toFixed(2)}`);
console.log(`  soit sur l'échelle 16 bits de libcamera : ${Math.round(global * 64)}`);
