#!/usr/bin/env node
// Contrôle d'après-redémarrage du test PDC (voir /data/sp12data/experience-coupures.md).
const fs = require('fs');
const { execSync } = require('child_process');

const ok = (b) => (b ? '\x1b[32mOK\x1b[0m' : '\x1b[31mNON\x1b[0m');
const lire = (p) => { try { return fs.readFileSync(p, 'utf8'); } catch { return ''; } };

// 1. le DTB de test est-il bien celui qui a été chargé ?
const comp = lire('/proc/device-tree/soc@0/interrupt-controller@b220000/compatible')
  .replace(/\0/g, ' ').trim();
const testActif = comp.includes('x1p42100-pdc');
console.log(`compatible du PDC   : ${comp}`);
console.log(`  -> DTB de test    : ${ok(testActif)}${testActif ? '' : '  (on tourne sur l ancien DTB, entree 0)'}`);

// 2. le contournement est-il bien desactive ? il n a pas de trace ; on verifie
//    que le pilote s est lie et que les interruptions PDC existent toujours.
const irqs = lire('/proc/interrupts').split('\n').filter((l) => / PDC /.test(l));
console.log(`\ninterruptions PDC   : ${irqs.length} (attendu 10)   ${ok(irqs.length === 10)}`);
for (const l of irqs) {
  const m = l.match(/^\s*(\d+):\s+((?:\d+\s+){1,16})PDC\s+(\d+)\s+(\w+)\s+(.*)$/);
  if (!m) continue;
  const total = m[2].trim().split(/\s+/).reduce((s, n) => s + +n, 0);
  console.log(`  irq ${m[1].padStart(3)}  broche ${m[3].padStart(2)}  ${total.toString().padStart(6)} decl.  ${m[5]}`);
}
console.log('\n  (des compteurs qui bougent = le chemin fonctionne ; tous a zero apres');
console.log('   plusieurs heures d usage serait le signal d alarme)');

// 3. rien de casse au demarrage ?
let err = '';
try { err = execSync('journalctl -b 0 -p err --no-pager -q', { encoding: 'utf8' }); } catch {}
const lignes = err.split('\n').filter(Boolean);
console.log(`\nerreurs du demarrage : ${lignes.length}`);
lignes.slice(0, 8).forEach((l) => console.log('  ' + l.slice(0, 150)));

// 4. ou en est l experience ?
console.log('');
try { console.log(execSync('/home/franz/bilan-coupures.sh', { encoding: 'utf8' })); } catch {}
