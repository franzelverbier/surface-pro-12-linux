#!/usr/bin/env node
// SP12 — 18/10/2026 : consommation au repos, machine ALLUMÉE, écran allumé à luminosité fixe.
//
// Sert à comparer deux configurations (ex. DTB du défaut contre DTB + état système SS3) :
// même luminosité, même durée, sur batterie, sans toucher la machine. Relève la puissance
// instantanée de la jauge toutes les 10 s, l'énergie perdue sur la période, et les compteurs
// qcom_stats (apss = l'APSS s'est-il endormi ?) et du domaine système.
//
//   sudo systemd-inhibit --what=idle:sleep node sp12-mesure-repos.js <étiquette> [minutes=10]
//
// Les 2 premières minutes ne comptent pas (stabilisation). Résultat ajouté à JOURNAL.
'use strict';
const fs = require('fs');

const JOURNAL = '/data/sp12data/diag/repos-mesures.jsonl';
const BAT = '/sys/class/power_supply/qcom-battmgr-bat/uevent';
const ECRAN = '/sys/class/backlight/backlight';
const LUMINOSITE = 2048;                 // sur 4095 : environ 50 %
const STABILISATION_S = 120, PAS_S = 10;

const [etiquette, minutes = '10'] = process.argv.slice(2);
if (!etiquette) { console.error('usage : sp12-mesure-repos.js <étiquette> [minutes]'); process.exit(2); }
const lire = f => { try { return fs.readFileSync(f, 'utf8'); } catch { return ''; } };
const bat = () => Object.fromEntries(lire(BAT).split('\n').filter(Boolean).map(l => l.replace('POWER_SUPPLY_', '').split('=')));
const compteur = s => Number((lire(`/sys/kernel/debug/qcom_stats/${s}`).match(/Count:\s*(\d+)/) || [])[1] ?? NaN);
const systeme = () => {
  const l = lire('/sys/kernel/debug/pm_genpd/power-domain-system/idle_states').split('\n').slice(1).map(x => x.trim().split(/\s+/));
  return l.filter(c => c.length >= 7).map(c => ({ etat: c[0], temps_ms: +c[1], usage: +c[2] }));
};
const dormir = s => new Promise(r => setTimeout(r, s * 1000));

(async () => {
  if (bat().STATUS !== 'Discharging') { console.error(`sur secteur (${bat().STATUS}) : débrancher le chargeur`); process.exit(1); }
  fs.writeFileSync(`${ECRAN}/brightness`, String(LUMINOSITE));
  console.log(`${etiquette} : stabilisation ${STABILISATION_S} s, puis ${minutes} min de mesure. Ne pas toucher la machine.`);
  await dormir(STABILISATION_S);

  const a = { t: Date.now(), bat: bat(), apss: compteur('apss'), cxsd: compteur('cxsd'), sys: systeme() };
  const puissances = [];
  const fin = a.t + Number(minutes) * 60e3;
  while (Date.now() < fin) {
    const p = Number(bat().POWER_NOW);
    if (Number.isFinite(p)) puissances.push(p / 1e6);
    await dormir(PAS_S);
  }
  const b = { t: Date.now(), bat: bat(), apss: compteur('apss'), cxsd: compteur('cxsd'), sys: systeme() };

  const h = (b.t - a.t) / 3.6e6;
  const wh = (Number(a.bat.ENERGY_NOW) - Number(b.bat.ENERGY_NOW)) / 1e6;
  const moy = puissances.reduce((x, y) => x + y, 0) / puissances.length;
  const lum = Number(lire(`${ECRAN}/brightness`));
  const r = {
    etiquette, debut: new Date(a.t).toISOString(), minutes: +(h * 60).toFixed(1),
    noyau: lire('/proc/sys/kernel/osrelease').trim(),
    // GRUB ne met pas le DTB dans la ligne de commande : on regarde si l'état système est déclaré.
    ss3: fs.existsSync('/proc/device-tree/cpus/domain-idle-states/domain-sleep-0'),
    puissance_moyenne_W: +moy.toFixed(3), mesures: puissances.length,
    energie_W: h > 0 ? +(wh / h).toFixed(3) : null,
    apss_plus: b.apss - a.apss, cxsd_plus: b.cxsd - a.cxsd,
    systeme: b.sys.map((s, i) => ({ etat: s.etat, temps_ms_plus: s.temps_ms - (a.sys[i]?.temps_ms || 0), usage_plus: s.usage - (a.sys[i]?.usage || 0) })),
    luminosite_fin: lum, statut_fin: b.bat.STATUS,
    alerte: [lum !== LUMINOSITE && 'luminosité changée (écran assombri ?)', b.bat.STATUS !== 'Discharging' && 'secteur branché pendant la mesure'].filter(Boolean),
  };
  fs.mkdirSync('/data/sp12data/diag', { recursive: true });
  fs.appendFileSync(JOURNAL, JSON.stringify(r) + '\n');
  console.log(JSON.stringify(r, null, 1));
})();
