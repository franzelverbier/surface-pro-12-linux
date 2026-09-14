#!/usr/bin/env node
// sp12-wifi-chrono.js — decompose le delai de connexion WiFi au demarrage.
//
// Pourquoi : le pilote ath12k n'est PAS le coupable. Mesure du 2026-09-13 —
// il expose wlan0 en 1,1 s et l'association prend 32 ms ; entre les deux,
// NetworkManager attend 15,7 s avant d'ordonner la connexion. Cet outil rend
// cette decomposition reproductible, pour qu'on cesse d'accuser le pilote.
//
// Usage : node sp12-wifi-chrono.js [boot, defaut 0]

const { execSync } = require('child_process');
const B = process.argv[2] || '0';

const lignes = execSync(`journalctl -b ${B} -o json --no-pager -q`, { maxBuffer: 1 << 28 })
  .toString().split('\n').filter(Boolean)
  .map((l) => { try { return JSON.parse(l); } catch { return null; } })
  .filter((e) => e && e.__MONOTONIC_TIMESTAMP);

const m = (e) => Number(e.__MONOTONIC_TIMESTAMP) / 1e6;   // secondes depuis le demarrage
const premier = (re) => { const e = lignes.find((x) => re.test(x.MESSAGE || '')); return e ? m(e) : null; };

const jalons = [
  ['périphérique détecté',   /ath12k.*Hardware name/],
  ['firmware chargé',        /ath12k.*fw_version/],
  ['wlan0 exposé',           /new 802\.11 Wi-Fi device/],
  ['supplicant prêt',        /supplicant interface state: internal-starting -> disconnected/],
  ['domaine réglementaire',  /CTRL-EVENT-REGDOM-CHANGE .*type=COUNTRY/],
  ['NM ordonne la connexion',/policy: auto-activating connection/],
  ['authentification',       /wlan0: authenticate with/],
  ['associé',                /wlan0: associated/],
];

const t = {};
console.log(`démarrage ${B} — jalons (secondes depuis le démarrage)\n`);
for (const [nom, re] of jalons) {
  const v = premier(re);
  t[nom] = v;
  console.log(`  ${nom.padEnd(26)} ${v === null ? '—' : v.toFixed(3).padStart(8)}`);
}

const seg = (a, b) => (t[a] !== null && t[b] !== null) ? (t[b] - t[a]) : null;
const f = (v) => v === null ? '—' : `${v.toFixed(2)} s`;
console.log('\nsegments :');
console.log(`  pilote (détection -> wlan0 exposé)    ${f(seg('périphérique détecté', 'wlan0 exposé'))}`);
console.log(`  ATTENTE (supplicant -> NM ordonne)    ${f(seg('supplicant prêt', 'NM ordonne la connexion'))}`);
console.log(`  radio (authentification -> associé)   ${f(seg('authentification', 'associé'))}`);
console.log(`  total (détection -> associé)          ${f(seg('périphérique détecté', 'associé'))}`);

const rd = execSync('grep -o "cfg80211.ieee80211_regdom=[A-Z]*" /proc/cmdline || true', { encoding: 'utf8' }).trim();
console.log(`\nligne de commande : ${rd || 'pas de cfg80211.ieee80211_regdom'}`);
