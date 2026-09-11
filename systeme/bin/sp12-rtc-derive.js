#!/usr/bin/env node
//
// sp12-rtc-derive.js — reconstruit l'erreur du RTC démarrage par démarrage.
//
// Pourquoi : le décalage d'époque statique (qcom,rtc-offset, correctif 0008) se
// dégrade avec le temps, et deux relevés isolés ne disent pas COMMENT. Deux points
// reliés par une droite avaient produit un « ~250 s/jour » qui n'existe pas.
//
// Méthode : dans chaque démarrage, la ligne
//     rtc-pm8xxx …: setting system clock to <T> UTC
// donne la valeur du RTC, et son horodatage journal EST cette valeur. L'heure vraie
// au même instant se retrouve en remontant l'horloge monotone depuis une ligne
// tardive du même démarrage, quand le NTP a déjà corrigé. La différence est l'erreur.
//
//     erreur = T_rtc − ( T_fin − ( M_fin − M_rtc ) )
//
// Usage : sudo ./sp12-rtc-derive.js [nombre de démarrages, défaut 10]
//
const { execSync } = require('child_process');

const N = Math.max(2, parseInt(process.argv[2] || '10', 10));

const lignes = (args) =>
  execSync(`journalctl ${args} -o json --no-pager`, { maxBuffer: 1 << 28 })
    .toString().split('\n').filter(Boolean)
    .map((l) => { try { return JSON.parse(l); } catch { return null; } })
    .filter(Boolean);

const R = (e) => Number(e.__REALTIME_TIMESTAMP) / 1e6;
const M = (e) => Number(e.__MONOTONIC_TIMESTAMP) / 1e6;

const rows = [];
for (let b = -(N - 1); b <= 0; b++) {
  let all;
  try { all = lignes(`-b ${b}`); } catch { continue; }
  if (all.length < 2) continue;

  const fin = all[all.length - 1];
  const vrai = (m) => R(fin) - (M(fin) - m);   // heure vraie, ancrée sur la fin (NTP OK)
  const rtc = all.find((e) => (e.MESSAGE || '').includes('setting system clock to'));

  rows.push({
    b,
    debut: vrai(0),
    fin: R(fin),
    err: rtc ? R(rtc) - vrai(M(rtc)) : null,
  });
}

const f = (t) => new Date(t * 1000).toLocaleString('fr-CH', { timeZone: 'Europe/Zurich' });
const hms = (s) => {
  const a = Math.abs(s);
  return `${Math.floor(a / 3600)}h${String(Math.floor((a % 3600) / 60)).padStart(2, '0')}m` +
         `${String(Math.round(a % 60)).padStart(2, '0')}s`;
};

console.log('boot | démarrage réel      | arrêt réel          | erreur RTC   | éteint avant');
console.log('-----+---------------------+---------------------+--------------+-------------');
rows.forEach((r, i) => {
  const off = i > 0 ? r.debut - rows[i - 1].fin : null;
  console.log(
    String(r.b).padStart(4), '|',
    f(r.debut).padEnd(19), '|',
    f(r.fin).padEnd(19), '|',
    (r.err === null ? '—' : (r.err < 0 ? '-' : '+') + hms(r.err)).padStart(12), '|',
    off === null ? '—' : hms(off),
  );
});

// Ce qui compte : l'erreur bouge-t-elle pendant que la machine TOURNE, ou seulement
// en travers des arrêts ? Les deux colonnes ci-dessous répondent séparément.
const m = rows.filter((r) => r.err !== null);
if (m.length >= 2) {
  let marche = 0, arret = 0;
  for (let i = 1; i < m.length; i++) {
    const d = m[i].err - m[i - 1].err;
    const off = m[i].debut - m[i - 1].fin;
    if (off < 60) marche += d; else arret += d;   // arrêt court = rien perdu, on l'agrège
  }
  const jMarche = rows.reduce((s, r) => s + (r.fin - r.debut), 0) / 86400;
  console.log('');
  console.log(`allumé         : ${jMarche.toFixed(2)} j cumulés`);
  console.log(`erreur gagnée en travers des arrêts longs : ${arret.toFixed(1)} s`);
  console.log(`erreur gagnée hors de ces arrêts          : ${marche.toFixed(1)} s`);
}
