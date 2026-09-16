#!/usr/bin/env node
// Taux de coupures sans trace, d'après le témoin — la seule source qui ne dépend
// pas du journal (lequel perd sa fin quand la machine est coupée).
//
// Un démarrage est « coupé » s'il n'a PAS d'enregistrement 'stop'. Le démarrage
// EN COURS est exclu : il n'a pas encore eu l'occasion d'en écrire un.
'use strict';
const fs = require('fs');
const { execSync } = require('child_process');
const bootCourant = fs.readFileSync('/proc/sys/kernel/random/boot_id', 'utf8').trim();

const parBoot = new Map();
for (const l of fs.readFileSync('/data/sp12data/temoin/temoin.jsonl', 'utf8').trim().split('\n')) {
  let o; try { o = JSON.parse(l); } catch { continue; }
  if (!o.boot) continue;
  const e = parBoot.get(o.boot) || { up: 0, stop: false, t: o.t };
  if (o.type === 'stop') e.stop = true;
  if (typeof o.up === 'number' && o.up > e.up) e.up = o.up;
  parBoot.set(o.boot, e);
}
parBoot.delete(bootCourant);

const tous = [...parBoot.entries()];
const coupes = tous.filter(([, e]) => !e.stop);
const brefs = coupes.filter(([, e]) => e.up < 120);

console.log(`  démarrages observés (hors celui en cours) : ${tous.length}`);
console.log(`  sans enregistrement « stop » (coupés)      : ${coupes.length}`);
console.log(`  dont coupés en MOINS DE 2 MINUTES          : ${brefs.length}`);
console.log('');
console.log('  les coupures brèves, du plus récent au plus ancien :');
for (const [id, e] of brefs.slice(-8).reverse())
  console.log(`    ${id.slice(0, 8)}  a tenu ${e.up.toFixed(0)} s   (${e.t})`);
