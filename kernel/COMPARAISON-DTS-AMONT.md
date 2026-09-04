# Comparaison DTS : le nôtre contre l'amont

Établi le 2026-09-04 contre `next-20260903`.

**Conclusion : il n'y a rien à gagner à basculer sur le DTS amont.** Le détail ci-dessous,
puis la méthode qui m'a d'abord fait conclure l'inverse.

## Le résultat

DTB contre DTB — le nôtre en service, celui d'amont construit depuis `next-20260903` :

| | nœuds | taille |
|---|---|---|
| nous (`sp12-el2-audio.dtb`) | 494 | 196 707 o |
| amont (`x1p42100-microsoft-sp12in.dtb`) | 520 | 202 607 o |

**Un seul nœud nous est propre** : `/reserved-memory/ramoops@a0000000` — notre ajout EL2,
devenu redondant depuis que `pstore-blk` a pris le relais.

**Les 26 nœuds supplémentaires de l'amont sont tous le sous-système CoreSight** :
`ctcu@10001000` (`qcom,x1e80100-ctcu`), deux `replicator@`, 18 `channel@`, et les ports
associés — ce qui explique aussi les écarts `in-ports` 24→29, `out-ports` 53→57,
`port` 67→75.

Ils ne viennent **pas** du fichier de carte mais de `hamoa.dtsi`, l'include du SoC, qui a
gagné le traçage matériel depuis notre base de juin. Rien de spécifique à la Surface Pro 12,
rien de fonctionnel pour l'usage quotidien.

Autrement dit : sur tout ce qui concerne la carte, **notre DTB et celui d'amont disent déjà
la même chose**.

## Ce qui reste vrai et utile

**Notre patch panneau est en amont** — `6ed8d820cea9`, 2026-08-03,
`drm/panel-edp: Add Sharp LQ120P1JX51`, signé François Roux. À retirer de nos patches
hors-arbre au prochain rebase : 19 deviennent 18.

**L'écran tactile a convergé.** L'amont déclare `interrupts-extended = <&tlmm 38>` plus
`wakeup-source` ; notre DTB compilé porte `<0x57 0x26 0x08>`, soit GPIO 38 — identique.
Le tactile fonctionne (`hid-over-i2c 04F3:4377`, stylet inclus). La divergence 51/38 qui
avait motivé l'échange d'août avec Harrison Vanderbyl est résolue des deux côtés.

**Aucun de nos 18 autres patches n'est fusionné** : la série remoteproc « attach » de
Stephan Gerhold (6, dont celui qui porte l'oops du CDSP), les 6 `smp2p`, les 2
`irqchip nov4` de TravMurav, nos 2 DTS EL2. Nos 0008 (RTC) et 0009 (audio) n'ont jamais été
soumis, décision documentée dans leurs messages de commit.

## Une piste ouverte : CoreSight

Le seul apport amont est du **traçage matériel**. Cela pourrait intéresser l'enquête sur les
coupures inexpliquées — mais avec une réserve de taille : CoreSight écrit dans des tampons
qui ne survivent pas plus à une coupure d'alimentation que ne le faisait ramoops. À creuser
seulement si une piste précise le justifie.

## La méthode, et l'erreur qu'elle a d'abord produite

La première version de ce document annonçait que l'amont apportait les endpoints SBU, le
pinctrl `pcie4_default`, les boutons de volume et le nœud panneau — et que basculer
corrigerait deux erreurs de démarrage. **Tout cela était faux.**

Cause : j'ai comparé l'amont à `x1p42100-microsoft-sp12.dts`, la base figée dans l'arbre
noyau au 26 juin. Ce n'est pas ce que la machine exécute. Notre DTB est bâti depuis
`sp12-el2.dts`, source bien plus récente qui contenait déjà tout cela — vérifié après coup :
`pcie4_default`, `vol_up_n_default`, `vreg_panel_en`, `usb_1_ss1_sbu_mux`, tous présents.

Circonstance aggravante : j'avais écrit ce piège **en tête du document**, après l'avoir
identifié sur l'écran tactile — « comparer à `sp12.dts` induit en erreur » — et j'ai bâti
l'analyse sur ce même fichier deux paragraphes plus bas.

⚠️ **La règle, pour la prochaine fois.** Il existe trois DTS et un seul fait autorité :

| fichier | ce que c'est | comparer ? |
|---|---|---|
| `linux-next/.../x1p42100-microsoft-sp12.dts` | base figée en juin | **jamais** |
| `sp12-el2.dts` | source réelle de notre DTB | oui |
| `/boot/sp12-el2-audio.dtb` | ce qui tourne | **la référence** |

Et comparer des **DTB décompilés**, pas des sources : un DTB décompilé renumérote les
phandles, donc un `diff` textuel produit ici 499 hunks dont la quasi-totalité est du bruit.
Il faut comparer les **chemins de nœuds**. C'est ce qui a fait tomber 499 hunks à
1 nœud contre 26.

Contrôle préalable indispensable, fait ici : `dtc -I dts -O dtb sp12-el2.dts` reproduit
`/boot/sp12-el2-audio.dtb` **octet pour octet** (196 707 des deux côtés). Sans cette
vérification, rien de ce qui suit ne tient.

## Erreur également corrigée

Les deux messages vus à chaque démarrage —

```
qcom_pmic_glink pmic-glink: Failed to create device link (0x180)
  with supplier usb-1-ss0-sbu-mux for /pmic-glink/connector@0
```

— ne viennent **pas** d'un nœud manquant. Nos deux mux SBU existent, avec des références
croisées parfaitement mutuelles (le mux, phandle `0x19a`, pointe vers `0x1ac` ; le
connecteur, `0x1ac`, pointe vers `0x19a`). Le journal donne la vraie cause :

```
/pmic-glink/connector@0: Fixed dependency cycle(s) with /usb-1-ss0-sbu-mux
```

`fw_devlink` détecte un cycle entre deux nœuds qui se référencent mutuellement, le casse,
et la création ultérieure du lien par le pilote échoue. **L'amont produirait exactement les
mêmes messages** : sa structure est identique.
