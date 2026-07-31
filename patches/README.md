# Patchs noyau

Appliqués sur `linux-next` 7.1.0-next-20260626. Les fichiers conservent leur paternité
d'origine ; voir le README racine pour la licence.

| Patch | Objet | Origine |
|---|---|---|
| `0001` … `0006` | SAM, panneau eDP BOE, ASoC, qcom-scm, DTS SP12 | Harrison van der Byl |
| `0007` | panneau eDP Sharp SHP 0x15a7 (voir plus bas) | ce dépôt |
| `serie-complete/` | **les 16 patchs** séparant le noyau de référence de `next-20260626` — source correspondante complète | mixte, paternité préservée |
| `audio-el2-serie.md` | notes sur la série remoteproc « attach » : mécanisme, pièges, avertissement ABI | Stephan Gerhold (miroir) |
| `registry-next20260626.c` | table de registre SAM | Harrison van der Byl |

## `0007` — le panneau eDP du Surface Pro 12

`panel_edp_probe()` contient un `WARN_ON` **délibéré** quand le panneau n'est pas dans sa
table : le commentaire au-dessus dit explicitement vouloir « que ce soit vraiment évident
que quelqu'un doit ajouter une entrée ». Ce n'est donc pas un bug à faire taire, c'est une
demande de contribution.

```
WARNING: drivers/gpu/drm/panel/panel-edp.c:814 panel_edp_probe+0x53c/0x56c
panel-simple-dp-aux …: Unknown panel SHP 0x15a7, using conservative timings
```

Notre panneau est un **Sharp, identifiant produit `0x15a7`**. Le modèle exact reste
inconnu : le device tree utilise le `compatible` générique `edp-panel`, et le pilote
n'expose pas l'EDID qu'il lit (`/sys/class/drm/card0-eDP-1/edid` fait 0 octet). L'entrée
est donc nommée `"Unknown"`, comme 32 autres de la table. Pour obtenir le vrai modèle il
faudrait activer `CONFIG_DRM_DP_AUX_CHARDEV` et relire l'EDID via `/dev/drm_dp_aux*`.

**Choix des délais, en toute transparence.** Le repli conservateur applique
`unprepare = 2000` et `enable = 200`. La valeur 2000 est une marge pour panneaux inconnus
— c'est sa **seule occurrence** dans tout le fichier, aucune entrée réelle ne l'utilise.
`delay_200_500_e200` conserve le `enable` généreux de 200 ms et adopte le `unprepare` de
500 ms commun à tous les panneaux de la table. C'est un choix prudent, **pas une valeur
issue d'une fiche technique** : un `enable` plus court passerait probablement, mais ça n'a
pas été validé ici. En cas d'artefact à la reprise de veille, remonter les délais.

## `registry-next20260626.c` — le registre SAM

Table des nœuds `software_node` décrivant les périphériques exposés par le Surface
Aggregator. C'est elle qui décide de ce que Linux tente d'instancier.

**Le compatible qui compte est `microsoft,surface-pro-12in`** — c'est ce qu'annonce la
machine (`/proc/device-tree/compatible`). Le fichier contient aussi un
`ssam_node_group_sp12` associé au compatible `microsoft,sp12`, que ce modèle n'annonce
jamais : ce groupe est **du code mort**, il ne sert à rien de l'éditer. Piège coûteux —
c'est le groupe qu'on modifie spontanément parce qu'il porte le bon nom.

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

## ⚠️ Doublon dans `0002`

Le patch `0002` ajoute `EDP_PANEL_ENTRY('B','O','E', 0x0cc9, &delay_200_500_e80,
"NE120DRM-N28")`. Depuis, **le noyau amont a ajouté ce même panneau** avec des délais
différents (`&delay_200_500_e50`). Les deux entrées coexistent maintenant dans la même
table `edp_panels[]`, et `find_edp_panel()` retourne la première trouvée : celle du patch
masque celle d'amont.

Sans conséquence sur le Surface Pro 12 1ʳᵉ édition, dont le panneau est un Sharp — mais
c'est à corriger pour toute variante équipée du BOE, et le patch `0002` est probablement
devenu inutile en entier.
