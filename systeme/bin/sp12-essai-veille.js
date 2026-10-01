#!/usr/bin/env node
// SP12 — 01/10/2026 : essai de repos profond sans intervention à l'écran.
// À 90 s de fonctionnement : relève qcom_stats et l'état système, met en veille
// (echo mem), relève de nouveau au réveil, écrit le résultat puis redémarre sur
// l'entrée par défaut. Ne tourne que si la ligne de commande porte sp12.essai_veille.
'use strict';
const fs = require('fs');
const { execFileSync } = require('child_process');
const dir = '/data/sp12data/diag';
const boot = fs.readFileSync('/proc/sys/kernel/random/boot_id', 'utf8').trim().slice(0, 8);
const sortie = `${dir}/essai-veille-${boot}.txt`;
const uptime = () => parseFloat(fs.readFileSync('/proc/uptime', 'utf8'));
const lire = f => { try { return fs.readFileSync(f, 'utf8'); } catch (e) { return `illisible : ${e.message}\n`; } };
function releve(etiquette) {
  let t = `== ${etiquette} (uptime ${uptime().toFixed(1)} s, ${new Date().toISOString()})\n`;
  for (const s of ['apss', 'aosd', 'cxsd', 'ddr', 'adsp', 'cdsp']) {
    const x = lire(`/sys/kernel/debug/qcom_stats/${s}`);
    const c = (x.match(/Count:\s*(\d+)/) || [])[1], d = (x.match(/Accumulated Duration:\s*(\d+)/) || [])[1];
    t += `${s.padEnd(5)} Count=${c} Accumulated=${d}\n`;
  }
  t += 'power-domain-system :\n' + lire('/sys/kernel/debug/pm_genpd/power-domain-system/idle_states');
  fs.appendFileSync(sortie, t + '\n');
}
fs.mkdirSync(dir, { recursive: true });
fs.appendFileSync(sortie, `# ${fs.readFileSync('/proc/cmdline', 'utf8')}`);
setTimeout(() => {
  releve('avant veille');
  execFileSync('sync');
  const t0 = Date.now();
  try { fs.writeFileSync('/sys/power/state', 'mem'); } catch (e) { fs.appendFileSync(sortie, `échec veille : ${e.message}\n`); }
  fs.appendFileSync(sortie, `veille : ${((Date.now() - t0) / 1000).toFixed(1)} s\n`);
  releve('après réveil');
  execFileSync('sync');
  setTimeout(() => execFileSync('systemctl', ['reboot']), 5000);
}, Math.max(0, 90 - uptime()) * 1000);
