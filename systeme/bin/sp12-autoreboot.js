#!/usr/bin/env node
// SP12 — redémarrage automatique des entrées GRUB de test.
//
// Certaines entrées d'essai démarrent un noyau sans le pilote Surface Aggregator :
// le Type Cover ne fonctionne alors pas sous Linux (il fonctionne dans GRUB, qui
// passe par le firmware UEFI), et la machine devient intouchable une fois le
// bureau atteint. Ce service la ramène tout seul à l'entrée par défaut.
//
// Ne s'exécute QUE si /proc/cmdline contient `sp12.autoreboot` : le service porte
// la même condition, et l'entrée d'usage courant ne la porte pas. Délai par défaut
// 300 s, réglable par entrée avec `sp12.autoreboot=<secondes>`.
//
// Le redémarrage est PROPRE (`systemctl reboot`), donc il laisse une séquence
// d'arrêt dans le journal : il ne sera pas compté comme une coupure par
// ~/bilan-coupures.sh, contrairement à un bouton d'alimentation maintenu.
'use strict';
const fs = require('fs');
const { execFileSync } = require('child_process');

const DEFAUT_S = 300;
const MIN_S = 30;
const MAX_S = 3600;

const cmdline = fs.readFileSync('/proc/cmdline', 'utf8').trim().split(/\s+/);
const arg = cmdline.find(a => a === 'sp12.autoreboot' || a.startsWith('sp12.autoreboot='));
if (!arg) {
  console.log('sp12-autoreboot : sp12.autoreboot absent de la ligne de commande, rien à faire');
  process.exit(0);
}

let delai = DEFAUT_S;
const valeur = arg.includes('=') ? Number(arg.split('=')[1]) : NaN;
if (Number.isFinite(valeur) && valeur >= MIN_S && valeur <= MAX_S) {
  delai = Math.floor(valeur);
} else if (arg.includes('=')) {
  console.log(`sp12-autoreboot : valeur « ${arg.split('=')[1]} » hors bornes (${MIN_S}-${MAX_S} s), on garde ${DEFAUT_S} s`);
}

const noyau = execFileSync('uname', ['-r'], { encoding: 'utf8' }).trim();
console.log(`sp12-autoreboot : noyau ${noyau}, redémarrage propre dans ${delai} s`);

// Compte à rebours tracé dans le journal : si la machine tombe avant la fin, la
// dernière ligne dit jusqu'où elle est allée.
let restant = delai;
const pas = Math.max(30, Math.floor(delai / 5));
const tic = setInterval(() => {
  restant -= pas;
  if (restant > 0) console.log(`sp12-autoreboot : ${restant} s avant redémarrage`);
}, pas * 1000);
tic.unref?.();

setTimeout(() => {
  clearInterval(tic);
  console.log('sp12-autoreboot : redémarrage maintenant');
  try {
    execFileSync('systemctl', ['reboot'], { stdio: 'inherit' });
  } catch (e) {
    console.error('sp12-autoreboot : systemctl reboot a échoué, on force');
    try { execFileSync('systemctl', ['reboot', '--force'], { stdio: 'inherit' }); } catch (e2) {}
  }
}, delai * 1000);
