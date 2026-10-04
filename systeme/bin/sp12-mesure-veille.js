#!/usr/bin/env node
// SP12 — 04/10/2026 : mesure de la consommation en veille.
//
// Appelé par systemd à chaque veille et réveil (crochet system-sleep, voir
// systeme/system-sleep/sp12-mesure-veille) avec « pre suspend » puis
// « post suspend ». Chaque appel ajoute une ligne JSON à JOURNAL : heure,
// énergie de la batterie, état de charge, compteurs qcom_stats.
//
//   node sp12-mesure-veille.js bilan     → tableau des veilles mesurées
//
// La puissance moyenne d'une veille = énergie perdue / durée. Elle n'a de sens
// que sur batterie : une veille commencée ou finie sur secteur est signalée.
// La jauge ne se rafraîchit pas en continu : sous une demi-heure, l'erreur de
// lecture pèse lourd. Viser au moins 30 min.
'use strict';
const fs = require('fs');

const JOURNAL = '/data/sp12data/diag/veille-mesures.jsonl';
const BAT = '/sys/class/power_supply/qcom-battmgr-bat/uevent';
const STATS = '/sys/kernel/debug/qcom_stats';
// apss = cœurs ; cxsd = rail CX coupé (CXPC) ; aosd = sous-système toujours actif ;
// ddr = mémoire en autorafraîchissement profond. Le vrai repos profond fait monter
// cxsd et aosd ; en s2idle EL2 aujourd'hui, seul apss bouge.
const SOUS_SYSTEMES = ['apss', 'cxsd', 'aosd', 'ddr', 'adsp', 'cdsp'];

const lire = f => { try { return fs.readFileSync(f, 'utf8'); } catch { return ''; } };

function releve(phase) {
  const bat = Object.fromEntries(lire(BAT).split('\n').filter(Boolean)
    .map(l => l.replace('POWER_SUPPLY_', '').split('=')));
  const stats = {};
  for (const s of SOUS_SYSTEMES) {
    const x = lire(`${STATS}/${s}`);
    stats[s] = {
      n: Number((x.match(/Count:\s*(\d+)/) || [])[1] ?? NaN),
      duree: Number((x.match(/Accumulated Duration:\s*(\d+)/) || [])[1] ?? NaN),
    };
  }
  return {
    phase, t: Date.now(),
    energie_uWh: Number(bat.ENERGY_NOW), energie_pleine_uWh: Number(bat.ENERGY_FULL),
    statut: bat.STATUS, puissance_uW: Number(bat.POWER_NOW),
    noyau: lire('/proc/sys/kernel/osrelease').trim(),
    stats,
  };
}

function bilan() {
  const l = lire(JOURNAL).split('\n').filter(Boolean).map(x => JSON.parse(x));
  const lignes = [];
  for (let i = 0; i + 1 < l.length; i++) {
    const a = l[i], b = l[i + 1];
    if (a.phase !== 'pre' || b.phase !== 'post') continue;
    const h = (b.t - a.t) / 3.6e6;
    const wh = (a.energie_uWh - b.energie_uWh) / 1e6;
    const secteur = [a.statut, b.statut].some(s => s !== 'Discharging');
    const delta = s => b.stats[s].n - a.stats[s].n;
    lignes.push([
      new Date(a.t).toLocaleString('fr-CH').slice(0, 17),
      `${(h * 60).toFixed(0)} min`,
      `${wh.toFixed(2)} Wh`,
      h > 0 ? `${(wh / h).toFixed(2)} W` : '—',
      `${(100 * (a.energie_uWh - b.energie_uWh) / a.energie_pleine_uWh / h).toFixed(1)} %/h`,
      `cxsd+${delta('cxsd')} aosd+${delta('aosd')} ddr+${delta('ddr')}`,
      (secteur ? 'SECTEUR, à écarter ' : '') + (h < 0.5 ? 'courte, peu fiable' : ''),
      a.noyau,
    ].join(' | '));
  }
  console.log(lignes.length ? lignes.join('\n') : 'aucune veille mesurée');
}

const [phase] = process.argv.slice(2);
if (phase === 'bilan') bilan();
else if (phase === 'pre' || phase === 'post') {
  fs.mkdirSync('/data/sp12data/diag', { recursive: true });
  fs.appendFileSync(JOURNAL, JSON.stringify(releve(phase)) + '\n');
} else {
  console.error('usage : sp12-mesure-veille.js pre|post|bilan');
  process.exit(2);
}
