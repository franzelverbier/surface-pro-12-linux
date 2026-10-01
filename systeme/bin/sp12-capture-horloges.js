#!/usr/bin/env node
// SP12 — 01/10/2026 : photographie horloges, domaines et interconnexions pendant
// l'essai « repos profond », une fois AVANT le sync_state forcé de GCC (~15,8 s)
// et une fois APRÈS (60 s). Comparaison avec /data/sp12data/diag/*-reference-el2cam.txt.
'use strict';
const fs = require('fs');
const dir = '/data/sp12data/diag';
const boot = fs.readFileSync('/proc/sys/kernel/random/boot_id', 'utf8').trim().slice(0, 8);
const uptime = () => parseFloat(fs.readFileSync('/proc/uptime', 'utf8'));
const sources = {
  clk: '/sys/kernel/debug/clk/clk_summary',
  genpd: '/sys/kernel/debug/pm_genpd/pm_genpd_summary',
  icc: '/sys/kernel/debug/interconnect/interconnect_summary',
};
function capture(etiquette) {
  const t = uptime().toFixed(1);
  for (const [nom, src] of Object.entries(sources)) {
    let txt;
    try { txt = fs.readFileSync(src, 'utf8'); } catch (e) { txt = `illisible : ${e.message}\n`; }
    fs.writeFileSync(`${dir}/${nom}-repos-profond-${boot}-${etiquette}.txt`, `# uptime ${t} s\n${txt}`);
  }
  console.log(`capture ${etiquette} à ${t} s`);
}
fs.mkdirSync(dir, { recursive: true });
capture('avant');
const attente = Math.max(0, 60 - uptime());
setTimeout(() => capture('apres'), attente * 1000);
