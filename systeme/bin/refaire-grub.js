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

// L'essai s2idle doit tourner sur le noyau qui porte le correctif de reprise du
// SAM (patches/0016), c'est-à-dire -nft, et sur le device tree amont. Plutôt que
// de retaper une ligne de commande, on DÉRIVE celle de amont-el1-nft.
const versS2idle = corps => corps.map(l => l.startsWith('    linux ')
  ? l.replace('loglevel=4', 'loglevel=7') + ' mem_sleep_default=s2idle systemd.mask=hexagonrpc.service'
  : l);

// La greffe caméra ne change QUE le device tree : on dérive le corps de
// « courant » plutôt que de retaper une ligne de commande.
const versCameras = corps => corps.map(l => l.startsWith('    devicetree ')
  ? '    devicetree /boot/sp12-el2-cam.dtb' : l);

// Le test 7.3 avec le revert QoS ne change QUE le noyau : on dérive le corps de
// amont-el1, dont le device tree (sp12-amont.dtb, celui de l'arbre 7.3) démarre
// déjà sur d'autres noyaux. Garde : retour automatique au bout de dix minutes.
const versQos73 = corps => corps.map(l => {
  if (l.startsWith('    linux ')) return l.replace('/boot/Image ', '/boot/Image-7.3rc3-qos ') + ' sp12.autoreboot=600';
  if (l.startsWith('    initrd ')) return '    initrd /boot/initramfs-7.3rc3-qos.img';
  return l;
});

// --- ce qu'on garde, dans l'ordre d'affichage voulu -------------------------
// ['motif de titre' | null, id, titre, [commentaires], transform?]
// Un motif null introduit un séparateur de groupe.
const garder = [
  [null, null, '═══ AU QUOTIDIEN ═══'],

  ['courant', 'el2-cam',
   "SP12 — usage courant + caméras  (EL2 + KVM + son)  ← DÉFAUT",
   ["Tout à la fois. Le DTB de juin, celui qui",
    "démarre en EL2 depuis le 11/09, avec les caméras GREFFÉES par overlay :",
    "cci0, cci1, camss, csiphy0, csiphy4, les deux capteurs, leurs états",
    "pinctrl — et le banc de régulateurs 8 (PMIC pm8010), qui manquait et qui",
    "alimente 7 des 11 rails des capteurs.",
    "",
    "Fabriqué par systeme/bin/greffer-cameras.js ; source dans dts/cameras-greffe.dtso.",
    "Contrôlé : 0 ligne supprimée, 615 ajoutées, aucune référence pendante, et",
    "les phandles résolus pointent bien sur camcc, apps_smmu et tlmm de CE DTB.",
    "",
    "⚠️ Piège payé le 16/09 : camss avait d'abord été pris dans hamoa.dtsi, qui",
    "décrit le x1e80100 avec DEUX IFE. Le x1p42100 n'en a qu'un. camss reportait",
    "sa sonde puis plantait dans son nettoyage — dans le fil des sondes reportées,",
    "ce qui emportait aussi la carte son. purwa.dtsi redéfinit &camss : la chaîne",
    "est hamoa -> purwa -> carte, et s'arrêter en chemin donne une version périmée."],
   versCameras],
  ['courant', 'courant',
   "SP12 — usage courant, sans caméras  (EL2 + KVM, audio, réseau)",
   ["Le quotidien du 11/09 au 16/09. Même DTB de juin que le défaut, mais SANS la",
    "greffe caméra. Repli sûr : si quelque chose cloche avec les caméras, c'est ici",
    "qu'on revient, et cette entrée n'a pas bougé d'un octet depuis le 11/09."]],

  ['amont-el1-nft', 'amont-el1-nft',
   "SP12 — DTS amont : caméras + audio + RTC  (EL1, démarrage lent)",
   ["Le plus complet en EL1 : les deux caméras, la carte son x1e80100 et le RTC",
    "du SAM (rtc-surface n'existe QUE dans l'arbre -nft). Prix à payer : pas de",
    "KVM, et 18,9 s jusqu'au bureau — retard diffus, propre au noyau -nft."]],

  ['amont-el1', 'amont-el1',
   "SP12 — DTS amont : caméras, démarrage en 4,8 s  (EL1, sans son)",
   ["Même device tree, noyau de base. Bureau en 4,8 s au lieu de 18,9 s, et les",
    "caméras marchent (l'arrière sort en 4216x3136). En revanche le DSP est sur",
    "liste noire — aucune carte son — et /dev/rtc retombe sur le pm8xxx qui dérive."]],

  [null, null, '═══ LE DEVICE TREE AMONT : toujours refusé par la bascule EL2 ═══'],
  ['amont-el2-nocam', 'amont-el2-nocam',
   "SP12 — DTS amont + EL2, sans les caméras  (échoue aussi)",
   ["Acquis : DTB amont en EL1 démarre (entrée 2), DTB de juin en EL2 démarre",
    "(entrée 1), DTB amont en EL2 donne un écran noir. C'est donc la BASCULE EL2",
    "qui refuse quelque chose du device tree amont. CoreSight a déjà été écarté.",
    "Ici les six nœuds caméra sont désactivés — camss, les deux cci, les deux",
    "capteurs, le PHY MIPI CSI-2. camss consomme l'IOMMU apps_smmu, exactement le",
    "genre de bloc dont l'état change entre EL1 et EL2.",
    "",
    "Démarre  → ce sont les nœuds caméra, et on sait quoi corriger pour EL2.",
    "Replante → le coupable est ailleurs dans l'écart avec le DTB de juin.",
    "",
    "En cas d'écran noir : maintenir le bouton marche, puis reprendre l'entrée 1."]],

  ['amont-el2', 'amont-el2',
   "SP12 — DTS amont + caméras, EL2  (échoue aujourd'hui)",
   ["La cible : tout à la fois, caméras et KVM. Écran noir puis redémarrage au",
    "16/09. Gardée pour revérifier après chaque correctif."]],

  [null, null, '═══ ESSAIS EN ATTENTE ═══'],

  ['amont-el1', 'mainline-73-qos',
   "SP12 — essai : mainline 7.3-rc3 + revert QoS  (EL1, retour auto 10 min)",
   ["Le 7.3-rc3 se réinitialisait pendant les initcalls, même en defconfig. Le",
    "15/09, Marc Zyngier a annulé en amont (2cc67425a97e) l'activation de la QoS",
    "de l'interconnect x1e80100 (5a8b2cc36e79, 7.3-rc1) : les machines Purwa",
    "« take a hard reset at boot time ». Ce noyau = /data/linux-7.3 + ce revert.",
    "Même device tree et même ligne de commande que amont-el1 : seul le noyau change.",
    "",
    "Démarre  → c'était la QoS, et la voie vers un noyau amont est ouverte.",
    "Replante → il y a autre chose ; noter jusqu'où l'écran défile.",
    "sp12.autoreboot=600 : la machine revient seule au bout de dix minutes."],
   versQos73],

  ['amont-el1-nft', 's2idle',
   "SP12 — essai : veille s2idle  (jamais tentée)",
   ["Dérivée de l'entrée 2, plus mem_sleep_default=s2idle, hexagonrpc masqué et",
    "loglevel=7. Sur -nft, donc AVEC le correctif de reprise du SAM (patches/0016)",
    "— l'essayer sur le noyau de base testerait un noyau qui ne l'a pas."],
   versS2idle],

  ['cybermyth', 'cybermyth',
   "SP12 — essai : noyau CyberMyth 7.2.3  (référence qui marche ailleurs)",
   ["Noyau, device tree et modules de l'image officielle CyberMyth OS 1.0, bâtie",
    "pour CE modèle. Tranche la question « mes compilations ou cette machine ? ».",
    "sp12.autoreboot=600 : la machine revient seule au bout de dix minutes."]],

  ['rust', 'rust',
   "SP12 — essai : noyau Rust",
   ["7.1.0-next-20260626-rust, arbre de modules à lui. N'apporte rien au projet,",
    "gardé comme terrain d'essai. Ne compte pas dans l'expérience des coupures."]],

  [null, null, '═══ SECOURS ═══'],

  ['secours', 'secours',
   "SP12 — secours figé du 20 août  (verbeux)",
   ["Jeu figé et vérifié octet par octet, que rien ne réécrit. loglevel=7.",
    "⚠️ Partage l'arbre de modules -nft avec l'entrée courante."]],

  ['shell', 'shell',
   "SP12 — Shell UEFI  (diagnostic)", []],
];

const entete = `# Surface Pro 12 (x1p42100) — menu de démarrage
#
# Trié le 2026-09-16 : 16 entrées ramenées à 10. Retirées du MENU seulement —
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
