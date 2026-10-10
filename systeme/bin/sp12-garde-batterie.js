#!/usr/bin/env node
// SP12 — 06/10/2026 : garde de batterie avant la veille.
//
// La nuit du 05 au 06/10, la machine s'est endormie à 5 % (1,64 Wh) et la veille
// (~1,4 W) a vidé la batterie jusqu'à la coupure matérielle. Pendant la veille,
// rien ne veille sur la batterie : UPower (extinction à 2 %) ne tourne qu'éveillé,
// et le SP12 n'a pas d'alarme RTC utilisable (surface_rtc sans alarme, RTC du PMIC
// en « qcom,no-alarm »). On décide donc à l'endormissement.
//
// Lancé par sp12-garde-batterie.service, que systemd-suspend.service exige
// (Requires=). Sur batterie et sous SEUIL % : demande l'extinction et sort en
// échec, ce qui annule la veille. Sur secteur, ou état inconnu : laisse dormir.
//
// 10/10/2026 : « systemctl poweroff » passait par logind, qui refuse toute extinction
// tant que l'opération « suspend » qu'il mène est en cours (« Action suspend already in
// progress ») : la garde n'a jamais éteint. La veille annulée, PowerDevil la redemandait
// toutes les 10 s (cache fermé) ; le soir du 09/10, 676 tours en 2 h ont mené de 27 % à 2 %.
// On demande donc l'extinction directement à systemd : poweroff.target en
// replace-irreversibly annule les jobs de veille en attente, sans passer par logind.
// Si l'extinction ne peut pas être demandée, on laisse dormir : une veille coûte ~3 %/h,
// une boucle de veilles avortées quatre fois plus.
//
// SP12_GARDE_ESSAI=1 : annule la veille sans éteindre (pour vérifier le mécanisme).
'use strict';
const fs = require('fs');
const { execFileSync } = require('child_process');

const SEUIL = 40;   // % : choix de FR le 06/10 — une nuit de 10 h à ~4 %/h doit tenir
const bat = Object.fromEntries(
  (() => { try { return fs.readFileSync('/sys/class/power_supply/qcom-battmgr-bat/uevent', 'utf8'); } catch { return ''; } })()
    .split('\n').filter(Boolean).map(l => l.replace('POWER_SUPPLY_', '').split('=')));
const pct = 100 * Number(bat.ENERGY_NOW) / Number(bat.ENERGY_FULL);
const essai = process.env.SP12_GARDE_ESSAI === '1';

if (essai) {
  console.log(`garde batterie : ESSAI — veille annulée (${bat.STATUS}, ${pct.toFixed(0)} %), pas d'extinction`);
  process.exit(1);
}
if (bat.STATUS !== 'Discharging' || !Number.isFinite(pct)) {
  console.log(`garde batterie : ${bat.STATUS || 'état inconnu'}, ${Number.isFinite(pct) ? pct.toFixed(0) + ' %' : '? %'} — veille autorisée`);
  process.exit(0);
}
if (pct >= SEUIL) {
  console.log(`garde batterie : ${pct.toFixed(0)} % sur batterie (seuil ${SEUIL} %) — veille autorisée`);
  process.exit(0);
}
console.log(`garde batterie : ${pct.toFixed(0)} % sur batterie, sous le seuil de ${SEUIL} % — extinction au lieu de la veille`);
try {
  execFileSync('/usr/bin/systemctl', ['start', 'poweroff.target', '--job-mode=replace-irreversibly', '--no-block']);
} catch (e) {
  console.log(`échec de l'extinction (${e.message.split('\n')[0]}) — veille autorisée plutôt qu'une boucle de veilles avortées`);
  process.exit(0);
}
process.exit(1);
