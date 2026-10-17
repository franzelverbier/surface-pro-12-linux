#!/usr/bin/env node
// SP12 — 17/10/2026 : rattrapage du port PCIe du Wi-Fi quand son PHY ne démarre pas.
//
// Deux démarrages sur 33 (04/10 sous rc3, 17/10 sous rc7) : au deuxième essai
// d'initialisation du port 1c08000 (PCIe4, la WCN7850), le PHY 1c0e000 ne verrouille
// pas (« phy initialization timed-out »), qcom-pcie échoue en -110, et comme ce n'est
// pas un report (-EPROBE_DEFER), le noyau ne réessaie jamais : pas de Wi-Fi de tout le
// démarrage. Aucun commit rc3→rc7 ne touche PCIe/PHY/horloges ; pwrseq (2,96 s) passe
// après la panne (2,25 s) et n'y est pour rien.
//
// qcom-pcie a suppress_bind_attrs (pas de bind/unbind), mais un appareil resté sans
// pilote peut être resondé par /sys/bus/platform/drivers_probe. À ce stade pwrseq et
// pci-pwrctrl-pwrseq sont chargés : la sonde passe par le chemin normal.
//
// Chaque passage ajoute une ligne à JOURNAL, pour mesurer la fréquence de la panne.
'use strict';
const fs = require('fs');

const PORT = '1c08000.pci';
const CARTE = '/sys/bus/pci/devices/0004:01:00.0';
const LIE = `/sys/bus/platform/drivers/qcom-pcie/${PORT}`;
const JOURNAL = '/data/sp12data/diag/pcie-wifi.jsonl';
const ATTENTE_S = 30;   // la carte apparaît d'ordinaire vers 2,8 s
const ESSAIS = 3;

const existe = p => fs.existsSync(p);
const dormir = s => new Promise(r => setTimeout(r, s * 1000));
const noyau = fs.readFileSync('/proc/sys/kernel/osrelease', 'utf8').trim();
const noter = o => {
  try {
    fs.mkdirSync('/data/sp12data/diag', { recursive: true });
    fs.appendFileSync(JOURNAL, JSON.stringify({ t: new Date().toISOString(), noyau, ...o }) + '\n');
  } catch (e) { console.log(`journal impossible : ${e.message}`); }
};

(async () => {
  for (let s = 0; s < ATTENTE_S && !existe(CARTE); s++) await dormir(1);
  if (existe(CARTE)) {
    console.log('carte Wi-Fi présente, rien à faire');
    noter({ etat: 'ok' });
    return;
  }
  if (existe(LIE)) {
    // Le port a un pilote mais la carte n'est pas énumérée : autre panne, pas celle-ci.
    console.log(`carte Wi-Fi absente alors que ${PORT} a son pilote : cas non traité`);
    noter({ etat: 'absente-port-lie' });
    process.exit(1);
  }
  console.log(`carte Wi-Fi absente, ${PORT} sans pilote (sonde PCIe échouée) : nouvelle sonde`);
  for (let i = 1; i <= ESSAIS; i++) {
    try { fs.writeFileSync('/sys/bus/platform/drivers_probe', PORT); }
    catch (e) { console.log(`essai ${i} : écriture refusée (${e.message})`); }
    for (let s = 0; s < 10 && !existe(CARTE); s++) await dormir(1);
    if (existe(CARTE)) {
      console.log(`carte Wi-Fi revenue à l'essai ${i}`);
      noter({ etat: 'rattrapee', essai: i });
      return;
    }
    console.log(`essai ${i} : toujours absente`);
  }
  noter({ etat: 'echec', essais: ESSAIS });
  process.exit(1);
})();
