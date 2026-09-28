#!/usr/bin/env node
// Relève l'état de la machine PENDANT un ralentissement vidéo, pour remplacer
// les hypothèses par des mesures. À lancer avant de partager l'écran, puis à
// laisser tourner : il échantillonne toutes les 2 s et écrit un JSONL.
//
// Usage : node mesure-visio.js [secondes]        (défaut : 300)
'use strict';
const fs = require('fs');
const { execSync } = require('child_process');
// --- mode analyse ------------------------------------------------------------
if (process.argv[2] === '--resume') {
  const f = process.argv[3];
  const l = fs.readFileSync(f, 'utf8').trim().split('\n').map(x => JSON.parse(x));
  const med = a => { const s = a.slice().sort((x,y)=>x-y); return s[s.length>>1]; };
  const moy = a => a.reduce((s,v)=>s+v,0)/a.length;
  const cpuMoy = l.map(e => moy(e.cpu_kHz)/1000);
  const plafond = (l[0].cpu_hw_kHz || l[0].cpu_max_kHz)/1000;   // matériel, pas l'appliqué
  console.log(`  ${l.length} relevés sur ${l[l.length-1].up} s`);
  console.log(`  fréquence CPU moyenne : médiane ${med(cpuMoy).toFixed(0)} MHz, min ${Math.min(...cpuMoy).toFixed(0)}, max ${Math.max(...cpuMoy).toFixed(0)}  (plafond ${plafond} MHz)`);
  const brides = l.filter(e => e.cpu_max_kHz < plafond*1000).length;
  const surBat = l.filter(e => e.secteur === false).length;
  console.log(`  relevés avec plafond RÉDUIT : ${brides}/${l.length}${brides ? ` (à ${(med(l.filter(e=>e.cpu_max_kHz<plafond*1000).map(e=>e.cpu_max_kHz))/1000).toFixed(0)} MHz)` : ''}`);
  console.log(`  relevés sur batterie : ${surBat}/${l.length}${surBat && brides ? '  ⚠️ TLP bride sur batterie' : ''}`);
  console.log(`  température : médiane ${(med(l.map(e=>e.tmax_mC))/1000).toFixed(1)} °C, pic ${(Math.max(...l.map(e=>e.tmax_mC))/1000).toFixed(1)} °C`);
  console.log(`  charge : médiane ${med(l.map(e=>e.charge[0])).toFixed(2)}, pic ${Math.max(...l.map(e=>e.charge[0])).toFixed(2)}`);
  console.log(`  GPU : médiane ${(med(l.map(e=>e.gpu_Hz))/1e6).toFixed(0)} MHz, pic ${(Math.max(...l.map(e=>e.gpu_Hz))/1e6).toFixed(0)} MHz`);
  console.log(`  CMA libre : min ${Math.min(...l.map(e=>e.cma_libre_kB))} kB`);
  const tx = l.map(e=>e.tx_o||0), rx = l.map(e=>e.rx_o||0);
  const ko = v => (v/1024).toFixed(0);
  console.log(`  réseau montée  : médiane ${ko(med(tx))} Ko/s, pic ${ko(Math.max(...tx))} Ko/s`);
  console.log(`  réseau descente: médiane ${ko(med(rx))} Ko/s, pic ${ko(Math.max(...rx))} Ko/s`);
  const sigs = l.map(e=>e.wifi&&e.wifi.sig).filter(Boolean);
  if (sigs.length) console.log(`  WiFi : signal médian ${med(sigs)} dBm, pire ${Math.min(...sigs)} dBm`);
  const tops = {};
  for (const e of l) for (const s of (e.top||[])) { const [pc,nom]=s.split(':'); tops[nom]=(tops[nom]||0)+ +pc; }
  const cls = Object.entries(tops).sort((a,b)=>b[1]-a[1]).slice(0,5);
  console.log('  processus les plus gourmands (somme des %CPU relevés) :');
  for (const [nom,v] of cls) console.log(`    ${nom.padEnd(20)} ${v.toFixed(0)}`);
  process.exit(0);
}

const DUREE = (+process.argv[2] || 300) * 1000;
const SORTIE = `/tmp/mesure-visio-${new Date().toISOString().slice(0,19).replace(/[:T]/g,'')}.jsonl`;
const dodo = ms => Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
const lire = p => { try { return fs.readFileSync(p,'utf8').trim(); } catch { return null; } };

const zones = fs.readdirSync('/sys/class/thermal').filter(z => /^thermal_zone/.test(z));
const cpus  = fs.readdirSync('/sys/devices/system/cpu').filter(c => /^cpu[0-9]+$/.test(c)).sort();

const IFACE = fs.readdirSync('/sys/class/net').find(i => /^wl/.test(i)) || 'wlan0';
const octets = () => ({
  rx: +lire(`/sys/class/net/${IFACE}/statistics/rx_bytes`) || 0,
  tx: +lire(`/sys/class/net/${IFACE}/statistics/tx_bytes`) || 0,
});
let prec = octets(), precT = Date.now();

const t0 = Date.now();
let n = 0;
while (Date.now() - t0 < DUREE) {
  const e = { t: new Date().toISOString(), up: +(( Date.now()-t0)/1000).toFixed(1) };
  e.cpu_kHz = cpus.map(c => +lire(`/sys/devices/system/cpu/${c}/cpufreq/scaling_cur_freq`) || 0);
  e.cpu_max_kHz = +lire(`/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq`) || 0;
  e.cpu_hw_kHz  = +lire(`/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq`) || 0;
  e.secteur = fs.readdirSync('/sys/class/power_supply')
    .some(s => (lire(`/sys/class/power_supply/${s}/online`) === '1'));
  e.charge = lire('/proc/loadavg').split(' ').slice(0,3).map(Number);
  e.tmax_mC = Math.max(...zones.map(z => +lire(`/sys/class/thermal/${z}/temp`) || 0));
  e.gpu_Hz = +lire('/sys/class/devfreq/3d00000.gpu/cur_freq') || 0;
  e.cma_libre_kB = +(lire('/proc/meminfo').match(/CmaFree:\s+(\d+)/)||[])[1] || 0;
  e.mem_dispo_kB = +(lire('/proc/meminfo').match(/MemAvailable:\s+(\d+)/)||[])[1] || 0;
  // débit réseau : c'est le tuyau montant qui limite un partage d'écran
  const o = octets(), dt = (Date.now() - precT) / 1000;
  e.rx_o = dt > 0 ? Math.round((o.rx - prec.rx) / dt) : 0;
  e.tx_o = dt > 0 ? Math.round((o.tx - prec.tx) / dt) : 0;
  prec = o; precT = Date.now();
  e.wifi = (() => {
    try {
      const l = execSync(`iw dev ${IFACE} link 2>/dev/null`, {encoding:'utf8'});
      return { sig: +(l.match(/signal:\s*(-?\d+)/)||[])[1] || 0,
               tx_Mbps: parseFloat((l.match(/tx bitrate:\s*([\d.]+)/)||[])[1]) || 0 };
    } catch { return null; }
  })();
  // les trois processus les plus gourmands, pour voir QUI consomme
  try {
    e.top = execSync("ps -eo pcpu,comm --sort=-pcpu --no-headers | head -3", {encoding:'utf8'})
      .trim().split('\n').map(l => l.trim().replace(/\s+/g,':'));
  } catch {}
  fs.appendFileSync(SORTIE, JSON.stringify(e) + '\n');
  n++;
  dodo(2000);
}
console.log(`${n} relevés écrits dans ${SORTIE}`);
console.log(`Analyse : node ${__filename} --resume ${SORTIE}`);
