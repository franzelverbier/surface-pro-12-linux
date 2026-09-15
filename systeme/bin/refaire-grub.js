#!/usr/bin/env node
// Reconstruit /boot/grub/grub.cfg : moins d'entrées, titres courts, défaut
// désigné par identifiant, police agrandie. Les corps d'entrée (linux, initrd,
// devicetree) sont RECOPIÉS tels quels depuis le fichier existant — rien n'est
// retapé, donc rien ne peut être introduit par une faute de frappe.
// Usage : node refaire-grub.js <source.cfg> <sortie.cfg>
'use strict';
const fs = require('fs');
const [src, dst] = process.argv.slice(2);
const lignes = fs.readFileSync(src, 'utf8').split('\n');

// --- extraction des blocs menuentry existants -------------------------------
const blocs = [];
for (let i = 0; i < lignes.length; i++) {
  const m = lignes[i].match(/^menuentry\s+"([^"]*)"/);
  if (!m) continue;
  let j = i + 1;
  while (j < lignes.length && !/^\}\s*$/.test(lignes[j])) j++;
  blocs.push({ titre: m[1], corps: lignes.slice(i + 1, j) });
  i = j;
}
console.log(`entrées trouvées dans la source : ${blocs.length}`);

// --- ce qu'on garde, dans l'ordre d'affichage voulu -------------------------
const garder = [
  ['TEST PDC sans contournement x1e', 'courant',
   "SP12 — usage courant  (EL2 + KVM, audio, réseau)",
   ["Le quotidien depuis le 11/09. DTB déclarant qcom,x1p42100-pdc, donc sans le",
    "contournement matériel x1e que notre silicium n'a pas. Modules : -nft."]],
  ['secours figé 2026-08-20', 'secours',
   "SP12 — secours figé du 20 août  (verbeux)",
   ["Jeu figé et vérifié octet par octet, que rien ne réécrit. loglevel=7.",
    "⚠️ Partage l'arbre de modules -nft avec l'entrée courante."]],
  ['EL2 / KVM + audio + nftables', 'dtb-origine',
   "SP12 — repli : DTB d'origine (PDC x1e80100)",
   ["Identique au quotidien mais avec le DTB d'avant le 11/09. À prendre si les",
    "réveils cessent de fonctionner (clavier, USB ou capteurs muets)."]],
  ['EL1  (sans KVM', 'el1',
   "SP12 — EL1 : décodage vidéo, variables EFI",
   ["Noyau du 26 juin, pas de KVM. C'est ici qu'on relit le décalage RTC et qu'on",
    "retrouve /dev/video*. Modules : 7.1.0-next-20260626, d'où la liste noire."]],
  ['TEST veille s2idle', 's2idle',
   "SP12 — essai : veille s2idle",
   ["EL1 avec mem_sleep_default=s2idle et hexagonrpc masqué. Jamais essayée.",
    "Voir docs/AUDIT-2026-09-14.md."]],
  ['noyau Rust', 'rust',
   "SP12 — essai : noyau Rust",
   ["7.1.0-next-20260626-rust, arbre de modules à lui. N'apporte rien au projet,",
    "gardé comme terrain d'essai. Ne compte pas dans l'expérience des coupures."]],
  ['initcall_debug AU RALENTI', 'mainline-diag',
   "SP12 — essai : mainline 7.3 au ralenti  (diagnostic)",
   ["Mainline 7.3-rc3, qui ne démarre PAS : la machine se réinitialise pendant",
    "les initcall. initcall_debug + boot_delay=15 rendent le défilement filmable.",
    "Chercher la dernière ligne « calling » sans son « returned »."]],
  ['Shell UEFI', 'shell',
   "SP12 — Shell UEFI  (diagnostic)", []],
];

const entete = `# Surface Pro 12 (x1p42100) — menu de démarrage
#
# Trié le 2026-09-15. Les neuf entrées d'essai de mainline 7.3 ont été retirées
# du menu ; le fichier d'avant le tri est conservé en entier dans le dépôt sous
# systeme/grub.cfg.avant-tri-20260915, et les noyaux, initramfs et DTB
# correspondants sont toujours dans /boot. Rien n'a été supprimé du disque.
#
# ⚠️ LE DÉFAUT EST DÉSIGNÉ PAR IDENTIFIANT, PAS PAR NUMÉRO. Ajouter ou retirer
# une entrée ne peut donc plus changer ce qui démarre. GRUB compte à partir de 0
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
set default=courant

# Police agrandie — l'écran fait 2196 px de large et la police par défaut de
# GRUB y est minuscule. TOUT EST CONDITIONNEL : si l'image GRUB n'a pas ces
# modules ou si le fichier manque, le menu s'affiche exactement comme avant.
# Et même si l'affichage échouait complètement, le délai de 5 s démarre de
# toute façon l'entrée « courant » : cette machine ne peut pas rester bloquée
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
for (const [motif, id, titre, commentaires] of garder) {
  const b = blocs.find(x => x.titre.includes(motif));
  if (!b) { console.error(`ENTRÉE INTROUVABLE : « ${motif} » — abandon`); process.exit(1); }
  n++;
  sortie.push('');
  sortie.push(`## ${n}. ${titre}`);
  for (const c of commentaires) sortie.push(`##    ${c}`);
  sortie.push(`menuentry "${titre}" --id ${id} {`);
  sortie.push(...b.corps);
  sortie.push('}');
}
fs.writeFileSync(dst, sortie.join('\n') + '\n');
console.log(`entrées conservées : ${n} — écrit dans ${dst}`);
