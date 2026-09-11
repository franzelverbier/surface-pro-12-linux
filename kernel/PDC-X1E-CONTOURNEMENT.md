# Le contournement x1e du PDC s'applique à nous, et il ne devrait pas

> État au 2026-09-11 : **hypothèse en cours de test**, pas un correctif validé.
> Le DTB de test tourne depuis 10:57. Voir la fin du document pour ce qui est déjà réfuté.

## Ce que dit l'amont

Trois commits du 4 septembre 2026, signés Maulik Shah (Qualcomm), concernent notre SoC :

```
086eac130a94  irqchip/qcom-pdc: Add purwa compatible for PDC secondary mode
13ca1c0b7d8a  arm64: dts: qcom: purwa: Drop the Hamoa workaround for PDC
9d6498c113b7  dt-bindings: interrupt-controller: qcom,pdc: Document Purwa PDC
```

Le message est explicite : X1P42100 (Purwa) et X1E80100 (Hamoa) partagent le même PDC,
mais **le quirk x1e, qui contourne un bug matériel, ne doit être appliqué qu'au X1E80100 —
le X1P42100 l'a corrigé en silicium.** L'amont fait désormais déclarer
`compatible = "qcom,x1p42100-pdc", "qcom,pdc";` à `purwa.dtsi`.

## Ce que fait ce contournement chez nous

Notre DTB déclarait `qcom,x1e80100-pdc`, donc `qcom-pdc.c` posait `pdc_x1e_quirk = true`
et redirigeait les écritures d'activation d'interruption :

```c
static void pdc_x1e_irq_enable_write(u32 bank, u32 enable)
{
	switch (bank) {
	case 0 ... 1:
		/* Use previous DRV (client) region and shift to bank 3-4 */
		base = pdc_prev_base;   /* region d'un AUTRE client, absente du device tree */
		bank += 3;
		break;
	case 2 ... 4:
		/* Use our own region and shift to bank 0-2 */
		base = pdc_base;
		bank -= 2;
		break;
	case 5:
		base = pdc_base;        /* seul banc correct */
```

La **lecture** se fait au bon endroit (`pdc_reg_read(IRQ_ENABLE_BANK, index)` sur notre
propre base, au bon index) mais l'**écriture** part ailleurs. Le cycle
lecture–modification–écriture est donc rompu pour les bancs 0 à 4.

## La portée, mesurée et non supposée

Le banc vaut `hwirq >> 5`. Nos dix consommateurs PDC, relevés dans `/proc/interrupts` :

| broche | banc | consommateur |
|---|---|---|
| 6 | 0 | `q6v5 wdog` |
| 11, 15, 17 | 0 | `dm_hs_phy_irq`, `ss_phy_irq` |
| 26, 27, 28 | 0 | capteurs thermiques `c271000`–`c273000` |
| 47, 60, 61 | 1 | `ss_phy_irq`, `dp_hs_phy_irq` |

**Toutes en bancs 0 et 1** — exactement les deux que le contournement envoie dans la
région du client précédent. Soit **100 %** de nos interruptions de réveil.

## Le contrôle qui pouvait tout annuler

`qcom-pdc` n'emprunte le chemin `IRQ_ENABLE_BANK` que si `pdc_version < PDC_VERSION_3_2`.
Au-delà, il passe par `pdc_enable_intr_cfg()` et le contournement est du code mort.
Le pilote ne journalise pas cette version, et `CONFIG_STRICT_DEVMEM=y` interdit
`/dev/mem`. Lu par un module dédié (`tools/sp12-pdcver`) :

```
PDC_VERSION = 0x00030000 -> 3.0.0
```

**Sous le seuil.** Le contournement est bien actif. Sans cette lecture, tout ce qui
précède n'aurait été qu'une hypothèse sur du code non exécuté.

Vérifié aussi : `qcom,x1e80100-pdc` n'est testé **qu'à un seul endroit** dans tout l'arbre
noyau, `drivers/irqchip/qcom-pdc.c:394`. Le pilote se lie sur `IRQCHIP_MATCH("qcom,pdc")`,
donc retirer le compatible x1e ne débinde rien.

## Le DTB de test

Une seule propriété change, dans le nœud `interrupt-controller@b220000` :

```diff
-	compatible = "qcom,x1e80100-pdc", "qcom,pdc";
+	compatible = "qcom,x1p42100-pdc", "qcom,pdc";
```

`qcom,x1p42100-pdc` est **inerte** pour notre noyau, qui ne le connaît pas ; il est choisi
pour coller à `purwa.dtsi` amont si la série est reprise. Un `qcom,pdc` nu aurait le même
effet aujourd'hui.

Fabrication et contrôle :

```bash
cp sp12-el2.dts sp12-el2-pdc-test.dts
# éditer la seule ligne ci-dessus
dtc -I dts -O dtb -o sp12-el2-pdc-test.dtb sp12-el2-pdc-test.dts
# le DTB compilé ne doit différer que par cette propriété :
dtc -I dtb -O dts -o a.dts /boot/sp12-el2-audio.dtb
dtc -I dtb -O dts -o b.dts sp12-el2-pdc-test.dtb
diff a.dts b.dts          # -> 2 lignes
```

Contrôle préalable indispensable : `dtc` doit reproduire le DTB courant **à l'octet près**
depuis `sp12-el2.dts` (196 707 octets), sinon la comparaison ne vaut rien.

Installé en entrée GRUB 5, identique en tout point à l'entrée 0 sauf le DTB. L'entrée 0
reste intacte pour le retour arrière.

## Ce qu'on n'a pas, et qu'on ne perd pas

L'autre moitié du correctif amont est le reset du PDC du mode secondaire vers pass-through
par `qcom_scm_io_writel()`, que le firmware Windows rend nécessaire. Notre noyau n'en fait
**aucun** — 0 appel contre 2 en amont — ni avant ni après ce changement. Rien n'est donc
perdu.

⚠️ Si nous le rapatrions un jour, prévoir que TrustZone n'est que partiellement fonctionnel
en EL2 : `TZ_OWNER_SIP`/`INFO_VERSION` répond, `TZ_OWNER_QSEE_OS`/`APP_LOOKUP` échoue en
`-22`. L'écriture SCM pourrait ne pas passer. Et `qcom-pdc` est **intégré**, donc ce serait
une recompilation du noyau, pas un module de 12 secondes.

## Signal d'alarme

Réveils morts après une reprise — clavier, USB ou capteurs muets. Cela voudrait dire que
notre silicium a le bug malgré ce qu'en dit Qualcomm. Retour : entrée GRUB 0.

Point de comparaison pris avant le changement : les dix interruptions PDC étaient **toutes
à zéro déclenchement** après 1 h 40 de fonctionnement. Ce sont des sources rares par
nature, donc zéro n'est pas anormal — mais si elles se mettent à compter après le
changement, ce sera une preuve directe que les écritures arrivaient au mauvais endroit.

## Ce qui est déjà réfuté

**Le retrait du contournement n'empêche pas les coupures.** Coupure du 2026-09-11 à
15:18:32, 4 h 21 après le passage à l'entrée 5, signature firmware `Reset Type: Hard Reset`
+ `PON by CBLPWR`, donc bien une perte d'alimentation. Détail complet et relevé du témoin
dans `/data/sp12data/experience-coupures.md`.

Il reste possible que le changement **réduise** la fréquence. Quatre heures ne disent rien :
au taux de fond de 0,5/jour, une coupure dans ce délai a environ 9 % de chances de tomber.
Compter en semaines.
