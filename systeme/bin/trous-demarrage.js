// Cherche les plus gros silences dans le journal d'un démarrage, bornés à la
// phase de démarrage proprement dite : on s'arrête à « Reached target Graphical
// Interface ». Sans cette borne on ramasse les blocages de l'EXTINCTION, qui
// portent des horodatages monotones plus grands mais n'ont rien à voir.
const { execFileSync } = require('child_process');
const boot = process.argv[2] || '-1';
const lignes = execFileSync('journalctl', ['-b', boot, '-o', 'short-monotonic', '--no-pager'],
  { encoding: 'utf8', maxBuffer: 256 * 1024 * 1024 }).split('\n');

let prev = null, trous = [], fin = null;
for (const l of lignes) {
  const m = l.match(/^\s*\[\s*([0-9.]+)\]\s+(.*)$/);
  if (!m) continue;
  const t = parseFloat(m[1]), txt = m[2];
  if (prev && t - prev.t > 0.5) trous.push({ d: t - prev.t, a: prev.t, apres: prev.txt, avant: txt });
  prev = { t, txt };
  if (/Reached target Graphical Interface|Atteint la cible.*Graphique/i.test(txt)) { fin = t; break; }
}
console.log(`  cible graphique atteinte à ${fin === null ? '(jamais vue)' : fin.toFixed(2) + ' s'}`);
trous.sort((x, y) => y.d - x.d);
for (const g of trous.slice(0, 5))
  console.log(`\n  ${g.d.toFixed(2)} s  (à t=${g.a.toFixed(1)} s)\n     après : ${g.apres.slice(0, 120)}\n     avant : ${g.avant.slice(0, 120)}`);
