# Niveau de noir de l'`ov02c10` — mesuré, et pourquoi je n'écris pas de fiche IPA

## La demande et ce qu'elle est devenue

FR : « écris les fiches IPA ». En cherchant à le faire proprement, il est apparu que
**les fiches n'apporteraient rien**. Ce document donne la mesure qui le démontre, pour
qu'on n'y revienne pas.

## La mesure

10 images brutes `SGRBG10_CSI2P` (1928×1092, stride 2416), **objectif frontal masqué par
FR**, décodées par `systeme/bin/mesure-niveau-noir.js`. Une trame est conservée dans
`mesures/ov02c10-trame-noire-20260921.bin`.

| Canal | Moyenne | Médiane | Écart-type | Min | Max |
|---|---|---|---|---|---|
| Gr | 65,06 | 65 | 0,76 | 58 | 80 |
| R  | 65,90 | 66 | 1,10 | 60 | 79 |
| B  | 64,50 | 64 | 0,63 | 58 | 80 |
| Gb | 65,04 | 65 | 0,76 | 58 | 80 |

**Global : 65,13 sur 10 bits**, soit 4168 sur l'échelle 16 bits de libcamera.

La mesure est franche et reproductible : écart-type inférieur à 1,1 LSB, contre 35 à 86 sur
une scène éclairée mesurée par le même outil. Les six trames analysées donnent 65,13 à 65,14
— un piédestal dur, pas du bruit.

⚠️ **Non établi** : que cette valeur soit indépendante de l'exposition et du gain. La capture
longue destinée à le vérifier a trouvé l'objectif découvert. La contribution du courant
d'obscurité à 38 °C et 33 ms est cependant négligeable, et les dix trames à réglages
identiques concordent à 0,01 près.

## Pourquoi une fiche ne servirait à rien

`src/ipa/simple/algorithms/blc.cpp` lit la clé sur 16 bits, puis **la ramène à 8 bits** :

```c
auto blackLevel = tuningData["blackLevel"].get<int16_t>();
if (blackLevel.has_value())
        definedLevel_ = blackLevel.value() >> 8;
...
/* clé absente */ context.configuration.black.level.value_or(16)
```

| | valeur 16 bits | après `>> 8` |
|---|---|---|
| Mesuré | 4168 | **16** |
| Nominal (piédestal 64 en 10 bits) | 4096 | **16** |
| **Défaut de libcamera, sans aucune fiche** | — | **16** |

Les trois donnent la même chose. **Le défaut est déjà exact pour ce capteur** : une fiche
`ov02c10.yaml` portant `blackLevel` serait du décor, et l'avertissement
`Configuration file 'ov02c10.yaml' not found` est, sur ce point, sans conséquence.

La seule chose qu'une fiche apporterait vraiment est une **matrice de correction
colorimétrique** (`Ccm`), explicitement désactivée dans `uncalibrated.yaml` faute de réglage.
Elle exige une mire colorimétrique sous illuminants connus. **Elle ne s'invente pas**, et
aucun nombre ne sera écrit ici tant qu'il n'aura pas été mesuré.

## Ce qui reste, et qui compte

Le vrai manque n'est pas la fiche mais le **sensor helper** de l'`ov02c10`
(`Failed to create camera sensor helper`) : sans lui l'IPA ne convertit pas le code de gain
en gain réel. Modèle dérivé et validé dans `ov02c10-sensor-helper.md` ; il demande de
rebâtir `libcamera`.

---

## Reprise du 2026-09-21 : la vérification manquante, obtenue autrement

La première rédaction laissait un trou : « non établi que cette valeur soit indépendante de
l'exposition et du gain ». FR a masqué l'objectif une seconde fois pour le combler.

### Ce que la capture longue ne prouvait pas

150 images (5 s) donnent un niveau parfaitement plat — 64,53 au début, 64,48 à la fin. J'ai
failli y voir une preuve d'insensibilité à l'AGC. Puis la lecture du sous-périphérique
(`/dev/v4l-subdev19`) a montré `analogue_gain = 16`, c'est-à-dire **l'unité, pendant toute
la capture** : sur le flux `role=raw`, l'AGC ne tourne pas. La platitude ne prouvait donc
rien du tout — voir [[hypothese-ecartee-verifier-le-levier]].

### Ce qui est établi : l'indépendance à l'exposition

En imposant les réglages par `v4l2-ctl` sur le sous-périphérique du capteur :

| Exposition | Gain | Niveau de noir (10 bits) |
|---|---|---|
| 4 lignes | 16 (×1) | **64,16** |
| 1425 lignes | 16 (×1) | **64,50** |

**Un facteur 356 sur le temps d'intégration ne déplace le niveau que de 0,34 LSB.** Le
courant d'obscurité est donc négligeable, et ce que l'on mesure est bien un **piédestal
fixe**, pas un signal thermique accumulé. C'est précisément la question qui restait ouverte.

### Ce qui reste non établi

L'influence du **gain** : la capture à `exposure=4, analogue_gain=248` n'a produit aucune
trame (le capteur ne diffuse pas dans cette combinaison), et celle à gain 248 en exposition
normale était saturée, l'objectif n'étant plus masqué. Sans conséquence sur la conclusion :
la question ouverte portait sur le courant d'obscurité, et elle est tranchée.

### Conséquence : inchangée

64,16 · 64,50 · 65,13 — toutes ces valeurs donnent **16** une fois ramenées aux 8 bits de
l'ISP. C'est exactement le défaut de libcamera. Aucune fiche n'est écrite.

Confirmation directe trouvée dans le journal pendant ces essais :

```
WARN IPAProxy Configuration file 'ov13858.yaml' not found for IPA module 'simple',
              falling back to '/usr/share/libcamera/ipa/simple/uncalibrated.yaml'
```

### ⚠️ Manipuler les contrôles du capteur

`v4l2-ctl -d /dev/v4l-subdev19 -c exposure=…,analogue_gain=…` fonctionne et **persiste à
travers une capture** `cam` sur le flux brut. Utile pour ce genre de mesure, mais il faut
**restaurer les valeurs ensuite** : vérifié après coup par une capture normale
(`1920x1092-ABGR8888/sRGB`, 30 img/s).

## Expérience proposée par Barnabás Pőcze : la consigne du pilote fixe le noir (2026-10-03)

Réponse du mainteneur (02/10/2026, `<72cbf66f-754a-423b-aee0-a253121ee7d5@ideasonboard.com>`) :
le code du helper est jugé correct, et les valeurs concordent avec patchwork 28174.
Pőcze relève que le pilote programme `{0x4002, 0x00}, {0x4003, 0x40}`, les registres
BLC CTRL 02/03 d'autres capteurs OmniVision, et propose de passer `0x40` à `0x80` pour voir
si la mesure suit.

Protocole, sans reconstruire le pilote (`ov02c10` est tenu par camss, refcount 3) :
écriture I²C directe pendant la prise de vue, sur le bus `Qualcomm-CCI` `/dev/i2c-1`,
adresse `0x36`, avec
`i2ctransfer -f -y 1 w3@0x36 0x40 0x03 0x80`. Lecture préalable en prise de vue : `0x40`.
`cam -c 1 -s role=raw -C150`, objectif avant masqué, écriture à t = 1,5 s, relue `0x80`.

| image | t / écriture | moyenne (10 bits) |
|---|---|---|
| 0 à 40 | −1,32 à 0,00 s | **64,19 à 64,20** |
| 41 et suivantes | +0,04 s à +3,5 s | **128,18 à 128,19** |

Par canal (images 20 et 100) : Gr 64,20 → 128,18 ; R 64,77 → 128,74 ; B 64,13 → 128,12 ;
Gb 64,19 → 128,18. **+64 sur les quatre canaux**, effet dès l'image suivante, écart-type
inchangé (0,54 à 0,73). Le niveau de noir mesuré **est** la consigne BLC programmée par le
pilote. À la prise de vue suivante, le pilote réécrit sa table et relit `0x40` : rien
n'est modifié durablement. Images témoins :
`mesures/ov02c10-trame-noire-blc0x40-20261003.bin` et `…-blc0x80-20261003.bin` ;
journal `mesures/ov02c10-blc-experience-cam-20261003.log`.
