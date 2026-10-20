#!/usr/bin/env node
// SP12 — 18/10/2026 : lit le journal d'allumage/extinction du PMIC PMK8550.
//
// Le PMIC enregistre, dans un FIFO en mémoire SDAM, les événements de chaque mise sous
// tension, réinitialisation et défaut : qui a déclenché le redémarrage (PS_HOLD tombé =
// le SoC l'a demandé, chien de garde du PMIC, bouton, sous-tension…). C'est le seul
// témoin d'un redémarrage que le noyau n'a pas vu venir (pstore est inutilisable ici :
// la RAM ne survit pas et les variables EFI passent par qseecom, refusé en EL2).
//
// Format et libellés repris du pilote Qualcomm « pmic-pon-log »
// (drivers/soc/qcom/pmic-pon-log.c des noyaux Android SM8550), qui lit SDAM 5 et 6 du
// PMK8550 (0x7400, 0x7500) ; les deux sont utilisés (REG_SDAM_COUNT = 1, soit 2 SDAM).
// Lecture seule, par le debugfs regmap de l'esclave SPMI 0-00 : il faut root.
//
//   sudo node sp12-pmic-journal.js           → le journal décodé, du plus ancien au plus récent
//   sudo node sp12-pmic-journal.js --brut    → avec les octets de chaque entrée
'use strict';
const fs = require('fs');

const REGMAP = '/sys/kernel/debug/regmap/0-00/registers';
const SDAM = [0x7400, 0x7500];
const REG_SDAM_COUNT = 0x45, REG_PUSH_PTR = 0x46, REG_PUSH_SDAM_NUM = 0x47;
const DEBUT = 0x4B, FIN = 0xBF, TAILLE = FIN - DEBUT + 1, ENTREE = 4;

const ETATS = ['FAULT', 'PON', 'POFF', 'ON', 'RESET', 'OFF', 'FAULT', 'WARM_RESET'];
const TYPES_RESET = { 1: 'WARM_RESET', 4: 'SHUTDOWN', 7: 'HARD_RESET' };
const FAUTE1 = ['GP_FAULT0', 'GP_FAULT1', 'GP_FAULT2', 'GP_FAULT3', 'MBG_FAULT', 'OVLO', 'UVLO', 'AVDD_RB'];
const FAUTE2 = ['?0', '?1', 'PMIC_RB', 'FAULT_N', 'FAULT_WATCHDOG', 'PBS_NACK', 'RESTART_PON', 'OVERTEMP_STAGE3'];
const FAUTE3 = ['GP_FAULT4', 'GP_FAULT5', 'GP_FAULT6', 'GP_FAULT7', 'GP_FAULT8', 'GP_FAULT9', 'GP_FAULT10', 'GP_FAULT11'];
const S3 = ['?0', '?1', '?2', '?3', 'FAULT_N', 'FAULT_WATCHDOG', 'PBS_NACK', 'KPDPWR_ET/OU_RESIN'];
const PBL = ['?0', '?1', '?2', '?3', '?4', '?5', 'XVDD', 'DVDD'];
const DECL_PON = { 0x0084: 'PS_HOLD', 0x0085: 'HARD_RESET', 0x0086: 'RESIN_N', 0x0087: 'KPDPWR_N (bouton)',
  0x0621: 'RTC_ALARM', 0x0640: 'SMPL (coupure brève)', 0x71C2: 'USB_CHARGER', 0x31C2: 'USB_CHARGER' };
const DECL_RESET = { 0x0080: 'KPDPWR_N_S2 (bouton long)', 0x0081: 'RESIN_N_S2', 0x0082: 'KPDPWR_N+RESIN_N_S2',
  0x0083: 'PMIC_WATCHDOG_S2 (chien de garde du PMIC)', 0x0084: 'PS_HOLD (demandé par le SoC)',
  0x0085: 'SW_RESET', 0x0086: 'RESIN_N_DEBOUNCE', 0x0087: 'KPDPWR_N_DEBOUNCE',
  0x21E3: 'SID2 BCL_ALARM (batterie)', 0x31F5: 'SID3 BCL_ALARM (batterie)',
  0x11D0: 'SID1 OCP (surintensité)', 0x21D0: 'SID2 OCP', 0x41D0: 'SID4 OCP', 0x51D0: 'SID5 OCP' };

const bits = (v, noms) => v ? noms.filter((_, i) => v & (1 << i)).join(', ') : 'aucun';
const hex = (v, n = 2) => '0x' + v.toString(16).toUpperCase().padStart(n, '0');
const sid = (d1, d0) => `SID=${d1 >> 4}, PID=${hex((((d1 << 8) | d0) >> 4) & 0xFF)}, IRQ=${d0 & 7}`;

function decoder([etat, ev, d1, d0]) {
  const d = (d1 << 8) | d0;
  switch (ev) {
    case 0x01: return `Déclencheur d'allumage : ${DECL_PON[d] || sid(d1, d0)}`;
    case 0x02: return `Copie OTP terminée (${hex(d, 4)})`;
    case 0x03: return `Réglages chargés (${d} octets)`;
    case 0x04: return 'Contrôle XVLO terminé';
    case 0x05: return `PMIC détectés : masque SID ${hex(d, 4)}`;
    case 0x06: return `DÉCLENCHEUR DE RÉINITIALISATION : ${DECL_RESET[d] || sid(d1, d0)}`;
    case 0x07: return `Type de réinitialisation : ${TYPES_RESET[d0] || `inconnu (${d0})`}`;
    case 0x08: return `Réinitialisations à chaud : ${d0}`;
    case 0x09: return `FAULT_REASON1=${bits(d0, FAUTE1)} ; FAULT_REASON2=${bits(d1, FAUTE2)}`;
    case 0x0A: return `FAULT_REASON3=${bits(d0, FAUTE3)}`;
    case 0x0B: return `PC du PBS au moment du défaut : ${hex(d, 4)}`;
    case 0x0C: return `Réinitialisation fondamentale : PON_PBL_STATUS=${bits(d1, PBL)} ; S3_RESET_REASON=${bits(d0, S3)}`;
    case 0x0D: return 'Début de la séquence d\'allumage';
    case 0x0E: return 'Allumage réussi';
    case 0x0F: return 'Attente de PS_HOLD';
    case 0x20: return `Contrôle VREG : ${d ? 'DÉFAUT VREG' : 'pas de défaut'}`;
    default:
      if (ev >= 0x10 && ev <= 0x1C) return `PMIC SID${ev - 0x0F} : FAULT_REASON1=${bits(d0, FAUTE1)} ; FAULT_REASON2=${bits(d1, FAUTE2)}`;
      return `événement inconnu ${hex(ev)} (données ${hex(d, 4)})`;
  }
}

const regs = new Map();
for (const l of fs.readFileSync(REGMAP, 'utf8').split('\n')) {
  const m = /^([0-9a-f]+):\s+([0-9a-f]{2})/.exec(l);
  if (m) { const a = parseInt(m[1], 16); if (a >= SDAM[0] && a < SDAM[1] + 0x100) regs.set(a, parseInt(m[2], 16)); }
}
const lire = (n, off) => { const v = regs.get(SDAM[n] + off); if (v === undefined) throw new Error(`registre ${hex(SDAM[n] + off, 4)} illisible`); return v; };

// REG_SDAM_COUNT vaut le nombre de SDAM MOINS UN (pmic-pon-log.c : sdam_fifo_count = reg + 1).
// 20/10 : lu comme un compte, il rejetait tout journal dont l'écriture était passée dans SDAM 6.
const nbSdam = Math.min(lire(0, REG_SDAM_COUNT) + 1, SDAM.length);
const ptr = lire(0, REG_PUSH_PTR), sdamFin = lire(0, REG_PUSH_SDAM_NUM);
if (nbSdam < 1 || ptr < DEBUT || ptr > FIN || sdamFin >= nbSdam) {
  console.error(`journal incohérent : SDAM_COUNT=${nbSdam}, PUSH_PTR=${hex(ptr)}, PUSH_SDAM=${sdamFin}`);
  process.exit(1);
}
const total = TAILLE * nbSdam, max = Math.floor(total / ENTREE);
const fin = sdamFin * TAILLE + ptr - DEBUT;
let debut = fin - max * ENTREE; if (debut < 0) debut += total;
const octet = i => { i %= total; return lire(Math.floor(i / TAILLE), DEBUT + (i % TAILLE)); };

const brut = process.argv.includes('--brut');
let n = 0;
for (let k = 0; k < max; k++) {
  const e = [0, 1, 2, 3].map(j => octet(debut + k * ENTREE + j));
  if (e.every(x => x === 0)) continue;        // emplacement jamais écrit
  if (e[1] === 0x0D) console.log('──────');  // chaque séquence d'allumage commence ici
  console.log(`${String(++n).padStart(2)}. [${(ETATS[e[0] & 7] || '?').padEnd(10)}] ${decoder(e)}${brut ? `   (${e.map(x => hex(x)).join(' ')})` : ''}`);
}
