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
