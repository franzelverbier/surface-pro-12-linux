#!/usr/bin/env node
// Témoin SP12 — relevé périodique fsync'é, destiné aux coupures sans trace.
//
// Raison d'être : ramoops ne survit pas à la chaîne UEFI/slbounce sur cette
// machine (« uncorrectable error in header » à CHAQUE démarrage, y compris
// après un redémarrage propre). Aucun vidage noyau n'est donc jamais capturé.
// Ce témoin ne remplace pas un pstore : il ne dira pas POURQUOI la machine est
// tombée. Il dit dans quel état elle était juste avant, et — par la présence ou
// l'absence du marqueur « stop » — si l'arrêt était volontaire.
//
// Chaque ligne est écrite puis fsync'ée : la dernière ligne avant une coupure
// brutale est garantie sur le disque.

const fs = require('fs');
const path = require('path');

const LOG = '/data/sp12data/temoin/temoin.jsonl';
const INTERVAL_MS = 30_000;
const MAX_BYTES = 32 * 1024 * 1024;   // rotation simple au-delà

const lire = (p, def = null) => {
  try { return fs.readFileSync(p, 'utf8').trim(); } catch { return def; }
};
const nombre = (p) => {
  const v = lire(p);
  return v === null || v === '' ? null : Number(v);
};

// Zones thermiques : découvertes une fois, relues à chaque tour.
const zones = fs.readdirSync('/sys/class/thermal')
  .filter((d) => d.startsWith('thermal_zone'))
  .map((d) => ({
    nom: lire(`/sys/class/thermal/${d}/type`, d),
    temp: `/sys/class/thermal/${d}/temp`,
  }));

const bootId = lire('/proc/sys/kernel/random/boot_id', 'inconnu');

function echantillon(type) {
  let tmax = -Infinity, tnom = null;
  for (const z of zones) {
    const t = nombre(z.temp);
    if (t !== null && t > tmax) { tmax = t; tnom = z.nom; }
  }
  const meminfo = lire('/proc/meminfo', '');
  const dispo = /MemAvailable:\s+(\d+)/.exec(meminfo);
  const uptime = lire('/proc/uptime', '0').split(' ')[0];

  return {
    t: new Date().toISOString(),
    type,                                   // 'tick' | 'start' | 'stop'
    boot: bootId,
    up: Number(uptime),
    tmax_mC: Number.isFinite(tmax) ? tmax : null,
    tzone: tnom,
    bat_uWh: nombre('/sys/class/power_supply/qcom-battmgr-bat/energy_now'),
    bat_uV: nombre('/sys/class/power_supply/qcom-battmgr-bat/voltage_now'),
    bat_st: lire('/sys/class/power_supply/qcom-battmgr-bat/status'),
    ac: nombre('/sys/class/power_supply/qcom-battmgr-ac/online'),
    usb: nombre('/sys/class/power_supply/qcom-battmgr-usb/online'),
    cpu0_kHz: nombre('/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq'),
    cpu4_kHz: nombre('/sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq'),
    load: Number(lire('/proc/loadavg', '0').split(' ')[0]),
    mem_dispo_kB: dispo ? Number(dispo[1]) : null,
  };
}

// Rotation avant ouverture, pour ne pas croître sans fin.
try {
  if (fs.statSync(LOG).size > MAX_BYTES) fs.renameSync(LOG, LOG + '.1');
} catch { /* fichier absent : normal au premier lancement */ }

const fd = fs.openSync(LOG, 'a');

function ecrire(ech) {
  fs.writeSync(fd, JSON.stringify(ech) + '\n');
  fs.fsyncSync(fd);           // le point entier de ce script
}

ecrire(echantillon('start'));
const timer = setInterval(() => ecrire(echantillon('tick')), INTERVAL_MS);

// Marqueur d'arrêt : sa PRÉSENCE signe un arrêt volontaire, son ABSENCE une
// coupure. C'est la seule chose que ce témoin établit avec certitude.
for (const sig of ['SIGTERM', 'SIGINT']) {
  process.on(sig, () => {
    clearInterval(timer);
    try { ecrire({ ...echantillon('stop'), signal: sig }); } catch {}
    process.exit(0);
  });
}
