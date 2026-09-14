#!/usr/bin/env node
// SP12 — régler l'horloge système depuis le RTC du Surface Aggregator (SAM).
//
// En EL2 le RTC du PMIC (rtc0, rtc-pm8xxx) ne connaît pas son décalage d'époque
// et pose une heure fausse au démarrage. Le SAM tient sa propre horloge, lue par
// rtc-surface (patches/0013). Ce script tourne quand ce RTC apparaît (udev ->
// sp12-rtc-sam.service) et :
//   - ne fait rien si NTP a déjà synchronisé ;
//   - refuse de reculer l'horloge en deçà du dernier arrêt connu (mtime de
//     /var/lib/systemd/timesync/clock), garde-fou si le SAM avait perdu l'heure ;
//   - sinon pose l'heure du SAM comme heure système (settimeofday via `date -s`).
// Le lien /dev/rtc pointe sur ce RTC (règle udev), donc systemd-timesyncd y
// réécrit l'heure NTP une fois synchronisé : le SAM reste juste d'un boot à l'autre.
//
// Options : --dry-run (n'applique rien), --status (affiche et sort).
'use strict';
const fs = require('fs');
const { execFileSync } = require('child_process');

const dry = process.argv.includes('--dry-run');
const statusOnly = process.argv.includes('--status');
const CLOCK_FILE = '/var/lib/systemd/timesync/clock';
const TOLERANCE_S = 60;

function findSamRtc() {
  for (const d of fs.readdirSync('/sys/class/rtc')) {
    const name = fs.readFileSync(`/sys/class/rtc/${d}/name`, 'utf8').trim();
    if (name.startsWith('surface_rtc')) return d;
  }
  return null;
}

function ntpSynchronized() {
  try {
    return execFileSync('timedatectl', ['show', '-p', 'NTPSynchronized', '--value'],
      { encoding: 'utf8' }).trim() === 'yes';
  } catch (e) { return false; }
}

const rtc = findSamRtc();
if (!rtc) { console.log('sp12-rtc-sam: aucun RTC surface_rtc, rien à faire'); process.exit(0); }

const samEpoch = Number(fs.readFileSync(`/sys/class/rtc/${rtc}/since_epoch`, 'utf8').trim());
const sysEpoch = Math.floor(Date.now() / 1000);
let lastKnown = 0;
try { lastKnown = Math.floor(fs.statSync(CLOCK_FILE).mtimeMs / 1000); } catch (e) { /* absent */ }
const iso = s => new Date(s * 1000).toISOString();
const synced = ntpSynchronized();

console.log(`sp12-rtc-sam: ${rtc} (SAM) = ${iso(samEpoch)} ; système = ${iso(sysEpoch)} ; ` +
  `écart SAM-système = ${samEpoch - sysEpoch} s ; dernier arrêt connu = ${lastKnown ? iso(lastKnown) : 'inconnu'} ; NTP = ${synced ? 'oui' : 'non'}`);

if (statusOnly) process.exit(0);
if (synced) { console.log('sp12-rtc-sam: NTP déjà synchronisé, horloge système laissée telle quelle'); process.exit(0); }
if (lastKnown && samEpoch < lastKnown - TOLERANCE_S) {
  console.log(`sp12-rtc-sam: REFUS — le SAM (${iso(samEpoch)}) est antérieur au dernier arrêt connu ` +
    `(${iso(lastKnown)}) : il a perdu l'heure, on ne recule pas l'horloge`);
  process.exit(0);
}
if (Math.abs(samEpoch - sysEpoch) < 2) { console.log('sp12-rtc-sam: déjà à l\'heure du SAM'); process.exit(0); }
if (dry) { console.log(`sp12-rtc-sam: (dry-run) poserait ${iso(samEpoch)}`); process.exit(0); }
execFileSync('date', ['-u', '-s', `@${samEpoch}`], { stdio: 'ignore' });
console.log(`sp12-rtc-sam: horloge système posée à ${iso(samEpoch)} depuis le SAM (était ${iso(sysEpoch)})`);
