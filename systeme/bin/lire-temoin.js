#!/usr/bin/env node
// Combien de temps chaque démarrage récent a-t-il tourné, d'après le témoin ?
// Le témoin écrit un tick fsync'é toutes les 30 s : le dernier tick d'un boot
// donne la durée MINIMALE de vie de ce démarrage — donc il distingue un figeage
// précoce (aucun tick) d'une coupure après plusieurs minutes.
'use strict';
const fs = require('fs');
const L = fs.readFileSync('/data/sp12data/temoin/temoin.jsonl', 'utf8').trim().split('\n');
const parBoot = new Map();
for (const l of L) {
  let o; try { o = JSON.parse(l); } catch { continue; }
  if (!o.boot) continue;
  const e = parBoot.get(o.boot) || { n: 0, up: 0, premier: o.t, dernier: o.t, types: new Set() };
  e.n++; e.types.add(o.type);
  if (typeof o.up === 'number' && o.up > e.up) { e.up = o.up; e.dernier = o.t; }
  parBoot.set(o.boot, e);
}
const boots = [...parBoot.entries()].slice(-5);
for (const [id, e] of boots) {
  const m = Math.floor(e.up / 60), s = Math.round(e.up % 60);
  console.log(`  ${id.slice(0, 8)}  ${String(e.n).padStart(3)} ticks, a tourné au moins ${m} min ${s} s   [${[...e.types].join(',')}]`);
  console.log(`            du ${e.premier} au ${e.dernier}`);
}
