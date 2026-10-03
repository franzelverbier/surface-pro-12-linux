#!/usr/bin/env node
// Reconstruit /boot/grub/grub.cfg : moins d'entrées, titres courts, défaut
// désigné par identifiant, police agrandie. Les corps d'entrée (linux, initrd,
// devicetree) sont RECOPIÉS tels quels depuis le fichier existant — rien n'est
// retapé, donc rien ne peut être introduit par une faute de frappe.
//
// L'appariement se fait par IDENTIFIANT (--id), pas par titre : les titres
// changent à chaque passe, donc un appariement par titre rendait l'outil non
// idempotent — la deuxième exécution ne retrouvait plus ses entrées. Un
// identifiant introuvable, ou en double dans la source, arrête le programme.
//
// Usage : node refaire-grub.js <source.cfg> <sortie.cfg>
'use strict';
const fs = require('fs');
const [src, dst] = process.argv.slice(2);
if (!src || !dst) { console.error('usage : refaire-grub.js <source.cfg> <sortie.cfg>'); process.exit(2); }
const lignes = fs.readFileSync(src, 'utf8').split('\n');

// --- extraction des blocs menuentry existants -------------------------------
const blocs = [];
for (let i = 0; i < lignes.length; i++) {
  const m = lignes[i].match(/^menuentry\s+"([^"]*)"\s+--id\s+(\S+)/);
  if (!m) continue;
  let j = i + 1;
  while (j < lignes.length && !/^\}\s*$/.test(lignes[j])) j++;
  blocs.push({ titre: m[1], id: m[2], corps: lignes.slice(i + 1, j) });
  i = j;
}
console.log(`entrées trouvées dans la source : ${blocs.length}`);

// Ménage du 03/10/2026 : 15 entrées ramenées à 8. Retirées du MENU seulement
// (amont-el1, amont-el2-nocam, amont-el2, mainline-73-qos, s2idle, s2idle-cx,
// cybermyth, rust) : noyaux, DTB et initramfs restent dans /boot, et le menu
// d'avant est conservé en /boot/grub/grub.cfg.avant-menage-20261003.
// Les entrées gardées se recopient elles-mêmes (motif = leur propre id), sauf
// celles dérivées d'une autre par une transformation ci-dessous.

// La greffe caméra ne change QUE le device tree : on dérive le corps de
// « courant » plutôt que de retaper une ligne de commande.
const versCameras = corps => corps.map(l => l.startsWith('    devicetree ')
  ? '    devicetree /boot/sp12-el2-cam.dtb' : l);


// 7.3 en EL2 (03/10) : même noyau et même initramfs que mainline-73-dsp, mais le
// DTB EL2 de l'arbre 7.3 (overlay x1-el2 : zap-shader désactivé, ce qui déclenche
// la bascule de slbounce ; iris désactivé), plus id_aa64mmfr0.ecv=1, obligatoire en
// EL2 sur x1p42100. Avec le noyau -nft, ce DTB donnait un écran noir ; avec 7.3,
// jamais essayé (7.3 ne démarrait pas avant le revert QoS). pstore pour garder
// une trace en cas de plantage. Garde : dix minutes.
const vers73El2 = corps => corps.map(l => {
  if (l.startsWith('    devicetree ')) return '    devicetree /boot/sp12-amont-el2.dtb';
  if (l.startsWith('    linux ')) return l + ' id_aa64mmfr0.ecv=1 pstore.backend=pstore_blk sp12.autoreboot=600';
  return l;
});

// --- ce qu'on garde, dans l'ordre d'affichage voulu -------------------------
// ['motif de titre' | null, id, titre, [commentaires], transform?]
// Un motif null introduit un séparateur de groupe.
const garder = [
  [null, null, '═══ AU QUOTIDIEN ═══'],

  ['courant', 'el2-cam',
   "SP12 — usage courant + caméras  (EL2 + KVM + son)  ← DÉFAUT",
   ["Tout à la fois : le DTB de juin, qui démarre en EL2 depuis le 11/09, avec les",
    "caméras GREFFÉES par overlay (systeme/bin/greffer-cameras.js,",
    "dts/cameras-greffe.dtso). Veille s2idle active depuis le 30/09 (~1,3 W).",
    "⚠️ camss vient de purwa.dtsi (un seul IFE), pas de hamoa.dtsi (deux IFE)."],
   versCameras],
  ['courant', 'courant',
   "SP12 — usage courant, sans caméras  (EL2 + KVM, audio, réseau)",
   ["Même DTB de juin que le défaut, SANS la greffe caméra. Repli sûr si quelque",
    "chose cloche avec les caméras ; n'a pas bougé d'un octet depuis le 11/09."]],

  [null, null, '═══ ESSAIS ═══'],

  ['mainline-73-dsp', 'mainline-73-el2',
   "SP12 — essai : mainline 7.3 en EL2  (KVM ? son ? retour auto 10 min)",
   ["Le noyau 7.3-rc3 + revert QoS (démarre en EL1 depuis le 30/09) avec le DTB EL2",
    "de l'arbre 7.3 et id_aa64mmfr0.ecv=1. Bandeau de slbounce puis bureau = EL2",
    "atteint. À vérifier : /dev/kvm, écran, WiFi, DSP (le 7.3 sait-il s'y rattacher",
    "en EL2 ?). Écran noir : maintenir le bouton marche, l'entrée 1 démarre ensuite."],
   vers73El2],

  ['mainline-73-dsp', 'mainline-73-dsp',
   "SP12 — essai : mainline 7.3 en EL1  (son à finir, WiFi 2161 Mbit/s)",
   ["7.3-rc3 + revert QoS (2cc67425a97e), DTB amont, EL1. Démarre (30/09). L'ADSP",
    "redémarre au lieu de se rattacher et plante une fois (charger_process) ;",
    "ALSA joue, WirePlumber ne relie pas les flux. Pas de KVM."]],

  ['repos-profond', 'repos-profond',
   "SP12 — essai : el2-cam + état système SS3  (retour auto 10 min)",
   ["el2-cam avec l'état de repos « système » SS3 : l'APSS dort au repos ordinaire.",
    "En veille, le firmware rend la main aussitôt en EL2 ; le vrai repos profond",
    "demande un noyau ≥ 7.3 (série PDC, audit §48 ter)."]],

  [null, null, '═══ SECOURS ═══'],

  ['amont-el1-nft', 'amont-el1-nft',
   "SP12 — secours EL1 : DTS amont, caméras + audio + RTC  (démarrage lent)",
   ["Le plus complet en EL1, sur le noyau -nft. Pas de KVM ; 18,9 s jusqu'au bureau."]],

  ['secours', 'secours',
   "SP12 — secours figé du 20 août  (verbeux)",
   ["Jeu figé et vérifié octet par octet, que rien ne réécrit. loglevel=7.",
    "⚠️ Partage l'arbre de modules -nft avec l'entrée courante."]],

  ['shell', 'shell',
   "SP12 — Shell UEFI  (diagnostic)", []],
];

const entete = `# Surface Pro 12 (x1p42100) — menu de démarrage
#
# Trié le 2026-09-16 (16 → 10), puis le 2026-10-03 (15 → 8) ; voir le code. Trié le 2026-09-16 : 16 entrées ramenées à 10. Retirées du MENU seulement —
# dtb-origine, el1, amont-el2-nocs et les trois entrées mainline 7.3, dont les
# cinq hypothèses ont toutes été réfutées. Le fichier d'avant ce tri est conservé
# en entier dans le dépôt sous systeme/grub.cfg.avant-tri-20260916, et les
# noyaux, initramfs et DTB correspondants sont toujours dans /boot.
# RIEN N'A ÉTÉ SUPPRIMÉ DU DISQUE : remettre une entrée = recopier son bloc.
#
# DÉFAUT DEPUIS LE 16/09/2026 : el2-cam. Elle fait tout ce que faisait « courant »
# (EL2, KVM, audio, réseau) et y ajoute les deux caméras, greffées par overlay sur le
# même DTB de juin. Vérifié au démarrage de 17:49 : /dev/kvm, une carte son, 12 nœuds
# video, CMA 524288 kB, zéro oops, capture 4216x3136 à 30 img/s sans sudo.
# En cas de doute, « usage courant » reste intacte, juste en dessous.
#
# ⚠️ LE DÉFAUT EST DÉSIGNÉ PAR IDENTIFIANT, PAS PAR NUMÉRO. Ajouter ou retirer
# une entrée ne peut donc pas changer ce qui démarre. GRUB compte à partir de 0
# et le menu se lit à partir de 1 : le 15/09, cette ambiguïté a failli coûter
# une conclusion fausse sur un test.
#
# ⚠️ RUPTURE D'ABI DES MODULES — lire avant d'ajouter une entrée.
# La série remoteproc « attach » convertit auto_boot en enum : struct rproc
# grandit de 8 octets. CONFIG_REMOTEPROC est intégré et CONFIG_MODVERSIONS
# désactivé, donc charger un module bâti pour une AUTRE Image écrit au-delà de
# la structure allouée, sans le moindre message.
#
# Trois arbres de modules coexistent, un par chaîne de version :
#   /lib/modules/7.1.0-next-20260626       <- Image, Image-el2audio
#   /lib/modules/7.1.0-next-20260626-nft   <- Image-nft et sa copie figée
#   /lib/modules/7.1.0-next-20260626-rust  <- Image-rust
# Les modules du premier ont été bâtis pour Image-el2audio : toute autre entrée
# qui les utilise doit porter modprobe.blacklist=qcom_q6v5_pas.

set timeout=5
set default=el2-cam

# Police agrandie — l'écran fait 2196 px de large et la police par défaut de
# GRUB y est minuscule. TOUT EST CONDITIONNEL : si l'image GRUB n'a pas ces
# modules ou si le fichier manque, le menu s'affiche exactement comme avant.
# Et même si l'affichage échouait complètement, le délai de 5 s démarre de
# toute façon l'entrée « el2-cam » : cette machine ne peut pas rester bloquée
# sur un menu invisible.
if search --no-floppy --set=fontroot --label SP12ROOT-INT ; then
    if loadfont ($fontroot)/boot/grub/fonts/sp12-36.pf2 ; then
        set gfxmode=auto
        terminal_output gfxterm
    fi
fi

# Maintenir Échap ou une touche fléchée pendant le décompte pour rester au menu.
`;

const sortie = [entete];
let n = 0;
for (const [motif, id, titre, commentaires, transform] of garder) {
  if (motif === null) { sortie.push('', `## ${titre}`); continue; }
  const trouves = blocs.filter(x => x.id === motif);
  if (trouves.length === 0) { console.error(`ENTRÉE INTROUVABLE : identifiant « ${motif} » — abandon`); process.exit(1); }
  if (trouves.length > 1) {
    console.error(`IDENTIFIANT EN DOUBLE : « ${motif} » apparaît ${trouves.length} fois dans la source — abandon`);
    for (const t of trouves) console.error(`   - ${t.titre}`);
    process.exit(1);
  }
  n++;
  sortie.push('');
  sortie.push(`## ${n}. ${titre}`);
  for (const c of commentaires) sortie.push(c ? `##    ${c}` : '##');
  sortie.push(`menuentry "${titre}" --id ${id} {`);
  sortie.push(...(transform ? transform(trouves[0].corps) : trouves[0].corps));
  sortie.push('}');
}
fs.writeFileSync(dst, sortie.join('\n') + '\n');
console.log(`entrées conservées : ${n} — écrit dans ${dst}`);
