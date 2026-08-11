# Patchs noyau

Appliqués sur `linux-next` 7.1.0-next-20260626. Les fichiers conservent leur paternité
d'origine ; voir le README racine pour la licence.

| Patch | Objet | Origine |
|---|---|---|
| `0001` … `0006` | SAM, panneau eDP BOE, ASoC, qcom-scm, DTS SP12 | Harrison van der Byl |
| ⚠️ `0005` | **contient un GPIO tactile erroné** — voir la section dédiée en fin de document | Harrison van der Byl (v1) |
| `0007` | panneau eDP Sharp LQ120P1JX51 — ✅ **accepté en amont**, `drm-misc-next` | ce dépôt |
| `0008` | RTC : décalage d'époque statique par device tree, pour EL2 où les variables EFI sont perdues | ce dépôt |
| `0009` | ASoC qdsp6 : échec rapide de la sonde de disponibilité de l'ADSP — 1,5 s de démarrage | ce dépôt |
| `serie-complete/` | **les 16 patchs** séparant le noyau de référence de `next-20260626` — source correspondante complète | mixte, paternité préservée |
| `audio-el2-serie.md` | notes sur la série remoteproc « attach » : mécanisme, pièges, avertissement ABI | Stephan Gerhold (miroir) |
| `registry-next20260626.c` | table de registre SAM | Harrison van der Byl |

## `0007` — le panneau eDP du Surface Pro 12 ✅ accepté en amont

> **Ce patch est dans `drm-misc-next`** — commit `6ed8d820cea9cae226f500d3af86e156eede27f6`,
> `Reviewed-by: Douglas Anderson <dianders@chromium.org>` (2026-08-03). Il descendra vers
> mainline au prochain cycle de fusion. Le fichier est conservé ici pour qui compile avant
> que le correctif ne soit disponible dans son arbre.

`panel_edp_probe()` contient un `WARN_ON` **délibéré** quand le panneau n'est pas dans sa
table : le commentaire au-dessus dit explicitement vouloir « que ce soit vraiment évident
que quelqu'un doit ajouter une entrée ». Ce n'est donc pas un bug à faire taire, c'est une
demande de contribution.

```
WARNING: drivers/gpu/drm/panel/panel-edp.c:814 panel_edp_probe+0x53c/0x56c
panel-simple-dp-aux …: Unknown panel SHP 0x15a7, using conservative timings
```

Notre panneau est un **Sharp `LQ120P1JX51`**, identifiant produit `0x15a7`, 2196×1464 en
60 et 90 Hz.

L'EDID n'est pas là où on le cherche : le connecteur ne l'expose pas
(`/sys/class/drm/card0-eDP-1/edid` fait 0 octet même panneau reconnu), debugfs n'offre que
`edid_override`, et `CONFIG_DRM_DP_AUX_CHARDEV` a disparu des noyaux récents. Mais le bus
AUX est enregistré comme **adaptateur i2c** — identifier le bon via
`/sys/bus/i2c/devices/i2c-N/device`, puis :

```bash
i2ctransfer -y <bus> w1@0x50 0x00 r128
```

⚠️ `i2cdump -y <bus> 0x50 b` **ne marche pas** : les lectures octet par octet ratent un
`ff` de l'en-tête et donnent un bloc à la somme de contrôle invalide — tout en restant
assez lisible pour qu'on y lise le nom du modèle et qu'on s'y fie. Contrôler l'en-tête
(`00 ff ff ff ff ff ff 00`) et la somme de contrôle avant d'exploiter.

**Choix des délais, en toute transparence.** Le repli conservateur applique
`unprepare = 2000` et `enable = 200`. La valeur 2000 est une marge pour panneaux inconnus
— c'est sa **seule occurrence** dans tout le fichier, aucune entrée réelle ne l'utilise.
`delay_200_500_e200` conserve le `enable` généreux de 200 ms et adopte le `unprepare` de
500 ms commun à tous les panneaux de la table. C'est un choix prudent, **pas une valeur
issue d'une fiche technique** : un `enable` plus court passerait probablement, mais ça n'a
pas été validé ici. En cas d'artefact à la reprise de veille, remonter les délais.

## `0008` — l'horloge matérielle en EL2

En EL2, ce noyau n'a pas de `/dev/rtc0` : l'heure n'existe qu'une fois le NTP passé.
La cause n'est pas le RTC, c'est la disparition des variables EFI.

**Le mécanisme, mesuré et non supposé.** Après Secure Launch, TrustZone n'est pas mort —
il répond encore à la requête de version (`TZ_OWNER_SIP` / `INFO_VERSION` renvoie
`0x1402000`). Mais il refuse le gestionnaire de trustlets : `TZ_OWNER_QSEE_OS` /
`APP_LOOKUP` échoue en `-22`. Donc `qcom_qseecom_uefisecapp` ne sonde jamais, `efivars`
ne s'enregistre pas — **0 variable en EL2, contre 110 en EL1 avec le même noyau** — et
`qcomtee` annonce `QTEE version 0.0.0` au lieu de `5.2.0`. Mainline ne sait pas recharger
un trustlet : c'est une impasse constatée.

Ce que cela fait au RTC : `pm8xxx_rtc_probe_offset()` lit son décalage d'époque dans la
variable UEFI `RTCInfo`, et si `efivars` est absent il renvoie `-EPROBE_DEFER` **sans
échappatoire** tant que `CONFIG_EFI=y`. Le pilote se reporte donc indéfiniment.

Le correctif ajoute `qcom,rtc-offset` comme **troisième source**, testée après le nvmem
et avant l'UEFI — l'ordre compte, la branche UEFI ne rendant jamais la main. Il est
volontairement en lecture seule : sans nvmem ni UEFI, `pm8xxx_rtc_update_offset()`
continue de renvoyer `-ENODEV`, donc un réglage d'heure ne peut pas écraser la valeur en
silence puis la perdre à l'extinction.

**Pourquoi pas la voie nvmem**, celle qu'utilisent `sc8280xp-crd`, `-arcata` et
`-blackrock` avec une cellule `rtc_offset@bc` dans un SDAM du PMIC : elle n'est pas
transposable ici. Sur le pmk8550 la fenêtre utilisable d'un SDAM est `0x40..0x7f`
(`SDAM_MEM_START` vaut `0x40`, et le périphérique fait 128 octets) — **`0xbc` n'est même
pas adressable**. Le SDAM 6 est par ailleurs densément écrit par le firmware. Des plages
à zéro subsistent ailleurs, mais lire zéro ne prouve pas qu'un octet est libre : écrire
dans une mémoire persistante que le firmware s'approprie, sur la foi d'une inférence,
n'était pas acceptable.

**Obtenir la valeur** : démarrer une fois en EL1, où la branche UEFI fonctionne, et lire
le `dev_info` que le correctif ajoute au probe.

```
rtc-pm8xxx c42d000.spmi:pmic@0:rtc@6100: offset = 1749233527
```

⚠️ Le décalage vaut `(heure unix - compteur brut)` et reste constant **tant que le PMIC
compte**. Si sa batterie se vide entièrement, le compteur repart et la valeur devient
fausse **sans aucun message** : l'heure sera simplement décalée. Remède : refaire le
relevé en EL1.

⚠️ La valeur stockée par l'UEFI est elle-même approximative — 4,04 s de retard ici,
mesurés au front de seconde du RTC contre une horloge NTP synchronisée. Ce n'est pas un
défaut de la méthode : `update_offset()` ne réécrit qu'au-delà de 30 s de dérive, donc
Windows tolère cet écart. Le DTS publié porte la valeur corrigée.

Non proposé en amont : la propriété n'est pas documentée dans le binding, et le vrai
problème est sans doute que la branche UEFI ne sait pas abandonner.

## `registry-next20260626.c` — le registre SAM

Table des nœuds `software_node` décrivant les périphériques exposés par le Surface
Aggregator. C'est elle qui décide de ce que Linux tente d'instancier.

⚠️ **Ce qui suit décrit notre DTB décompilé, pas l'amont.** Voir la section « Ces patchs
sont périmés » en fin de document : le compatible amont est désormais `microsoft,sp12`,
et c'est `ssam_node_group_sp12` qui fait autorité. Le groupe `sp12in` décrit ci-dessous
ne s'applique qu'à un device tree portant l'ancien compatible.

Avec notre DTB décompilé, la machine annonce `microsoft,surface-pro-12in`
(`/proc/device-tree/compatible`), et c'est donc `ssam_node_group_sp12in` qui est
sélectionné. J'en avais conclu à tort que `ssam_node_group_sp12` était du code mort —
c'est l'inverse : c'est notre device tree qui était périmé.

Le groupe `ssam_node_group_sp12in` a été ramené à ce qui est **observable sur la
machine** :

| UID | Nœud | État constaté |
|---|---|---|
| `00:00:01:0e:00` | `hub_kip` | lié à `surface_aggregator_subsystem_hub` |
| `01:03:01:00:02` | `tmp_sensors` | déclaré, sans erreur (pilote non compilé) |
| `01:15:02:01:00` | `hid_kip_keyboard` | lié à `surface_hid` |
| `01:15:02:03:00` | `hid_kip_touchpad` | lié à `surface_hid` |
| `01:15:02:05:00` | `hid_kip_fwupd` | lié à `surface_hid` |
| `01:0e:01:00:01` | `kip_tablet_switch` | lié, entrée « KIP Tablet Mode Switch » créée |

Retirés : `hid_kip_penstash` (`01:15:02:02:00`) et `hid_sam_sensors`
(`01:15:01:06:00`). SAM leur renvoie un descripteur HID vide (`-EPROTO`), y compris sur
un **rebind manuel à système au repos** — le test qui prouve qu'il ne s'agit pas d'une
course au démarrage :

```bash
echo 01:15:02:02:00 | sudo tee /sys/bus/surface_aggregator/drivers/surface_hid/bind
```

Non repris non plus : `hid_sam_penstash` (`01:15:01:02:00`) et `pos_tablet_switch`
(`01:26:01:00:01`), présents dans la version amont de ce groupe. Ils n'ont jamais été
instanciés ici, donc jamais vérifiés — et le détecteur de mode tablette effectivement
fonctionnel est `kip_tablet_switch`. Les adopter reviendrait à troquer un composant qui
marche contre un pari.

⚠️ Le module installé provenait d'une compilation **extérieure** (GCC 13.3 sous Ubuntu,
arbre `/root/linux-next`) : ses chaînes le trahissent, et son groupe `sp12in` ne
correspondait pas à celui du même nom dans linux-next. Vérifier la provenance d'un
module hors-arbre avant d'en déduire quoi que ce soit de la lecture des sources.

## ⚠️ Le module vit aussi dans l'initramfs

Recompiler et installer `panel-edp.ko` dans `/lib/modules` **ne suffit pas**. Le hook `kms`
de mkinitcpio embarque les pilotes d'affichage dans l'initramfs, et c'est cette copie-là
qui est chargée — vers 3,2 s ici, bien avant que le rootfs ne compte. Symptôme : le
`WARNING` réapparaît intact après un redémarrage, alors que le module sur disque est bon.

```bash
lsinitcpio /boot/votre-initramfs.img | grep panel.edp
```

Le noyau traite les archives cpio **concaténées**, la dernière écrasant les précédentes.
On peut donc ajouter le module neuf sans régénérer l'initramfs — utile quand celui-ci a
été produit avec une configuration qu'on ne sait plus reproduire :

```bash
mkdir -p o/usr/lib/modules/$(uname -r)/kernel/drivers/gpu/drm/panel
cp /lib/modules/$(uname -r)/kernel/drivers/gpu/drm/panel/panel-edp.ko \
   o/usr/lib/modules/$(uname -r)/kernel/drivers/gpu/drm/panel/
( cd o && find usr | cpio -o -H newc --quiet ) | gzip -9 > overlay.cpio.gz
cat initramfs.img overlay.cpio.gz > initramfs-nouveau.img
```

Vérifier la taille (somme exacte des deux) et `gzip -t` sur la queue. Pointer **une seule**
entrée du menu sur le nouveau fichier : si le noyau ignorait le segment ajouté, on
retomberait simplement sur l'ancien module, et les entrées de repli restent intactes.

## ⚠️ Ces patchs sont périmés — l'amont a tout intégré

Harrison van der Byl le confirme (issue #10 de son dépôt, 2026-08-02) : **tous ses patchs
sont passés en amont**, modifiés au fil des retours mainteneurs. Son conseil est net —
travailler sur l'arbre amont et ses DTS, pas sur ces fichiers.

Un changement compte particulièrement : le compatible est passé de
`microsoft,surface-pro-12in` à **`microsoft,sp12`**, pour éviter le conflit avec le
Surface Pro 12 modèle 2026.

### ⚠️ `0005` porte un GPIO tactile erroné — et nous a fait publier un faux

Ce patch est la **v1** de la série de Harrison. Il décrit l'interruption du digitizer sur
`gpio51` et son reset sur `gpio52` :

```dts
interrupts-extended = <&tlmm 51 IRQ_TYPE_LEVEL_LOW>;
int-n-pins   { pins = "gpio51"; };
reset-n-pins { pins = "gpio52"; };
```

C'est **faux**. Harrison l'a corrigé dès sa v2 ; sa
[v4](https://lore.kernel.org/all/20260609145906.40854-2-harrison.vanderbyl@gmail.com/),
attendue en 7.3, décrit **38/48** — le câblage réel de la machine. Le 51 venait
d'appareils voisins, recopié par erreur.

Conséquence si vous appliquez `0005` tel quel : le tactile fonctionne mais **dégradé, sans
événements stylet**. Pas mort, ce qui rend le symptôme d'autant plus facile à ne pas voir.

**Le piège dans lequel nous sommes tombés**, et c'est le plus utile à retenir :
`x1p42100-microsoft-sp12.dts` **n'existe pas** dans `next-20260626` vierge — c'est ce
patch qui le crée. En le lisant dans notre arbre, nous avons cru lire l'amont, conclu à une
variante matérielle, et signalé aux mainteneurs DT une divergence qui n'existait pas.
Un `git log` sur le fichier l'aurait montré :

```bash
git log --oneline -- arch/arm64/boot/dts/qcom/x1p42100-microsoft-sp12.dts
```

Un seul commit, le nôtre. Sur un arbre où l'on a appliqué des patchs, **rien ne distingue
visuellement un fichier amont d'un fichier qu'on a soi-même ajouté** : il faut le demander.

Conséquence directe, et piège dans lequel je suis tombé : le registre SAM contient deux
groupes, `ssam_node_group_sp12` (compatible `microsoft,sp12`, **le courant**) et
`ssam_node_group_sp12in` (l'ancien nom). J'avais conclu que le premier était du code mort
parce que notre DTB décompilé annonce l'ancien compatible. C'était l'inverse : **notre
device tree était périmé**, pas le groupe.

Ce que l'amont fournit déjà, sans rien maintenir à la main :

- `x1p42100-microsoft-sp12.dts` — 23 Ko, propre, contre 258 Ko décompilés
- `x1p42100-microsoft-sp12-el2.dtb` — construit avec l'overlay `x1-el2.dtbo`, et
  contenant **déjà** le SMMUv3 PCIe en `status = "okay"`, le zap-shader désactivé et
  `iris` désactivé

Restent seulement deux différences à porter : `qcom,broken-reset` pour l'audio (patch
hors-arbre de Stephan Gerhold, voir `serie-complete/`) et la zone `ramoops`.

### Le doublon BOE 0x0cc9, pour mémoire

Deux entrées pour le même panneau, avec des délais différents, **toutes deux dans
l'amont** — vérifié sur un arbre `next-20260626` sans aucun patch appliqué :

```
EDP_PANEL_ENTRY('B','O','E', 0x0cc9, &delay_200_500_e80, "NE120DRM-N28"),
EDP_PANEL_ENTRY('B','O','E', 0x0cc9, &delay_200_500_e50, "NE120DRM-N28"),
```

`find_edp_panel()` retourne la première correspondance dans ses deux passes, et les deux
portent le même nom : les délais `e80` gagnent, les `e50` sont inatteignables. Sans
matériel BOE sous la main, impossible de dire lesquels sont justes — signalé, non corrigé.
