# `ov02c10` — sensor helper manquant dans libcamera

## Le problème

```
WARN IPASoft soft_simple.cpp:104 IPASoft: Failed to create camera sensor helper for ov02c10
```

libcamera 0.7.2 embarque des *sensor helpers* compilés pour 29 capteurs, dont **`ov13858`**
(notre caméra arrière) — mais **pas `ov02c10`** (la frontale, celle qui sert en
visioconférence). Sans helper, l'IPA ne sait pas convertir le code de gain du capteur en
gain réel : l'exposition automatique travaille à l'aveugle.

Ce n'est **pas** réparable par un fichier de réglage : le helper est du C++ compilé dans
`src/ipa/libipa/camera_sensor_helper.cpp`.

## Le modèle de gain, dérivé du pilote

`drivers/media/i2c/ov02c10.c` (amont 7.3) :

```c
#define OV02C10_REG_ANALOG_GAIN     CCI_REG16(0x3508)
#define OV02C10_ANAL_GAIN_MIN       0x10
#define OV02C10_ANAL_GAIN_MAX       0xf8
#define OV02C10_ANAL_GAIN_STEP      1
#define OV02C10_ANAL_GAIN_DEFAULT   0x10
...
case V4L2_CID_ANALOGUE_GAIN:
        cci_write(ov02c10->regmap, OV02C10_REG_ANALOG_GAIN, ctrl->val << 4, &ret);
```

Deux déductions **indépendantes** qui concordent :

1. Le défaut du contrôle vaut `0x10` = 16, et le gain par défaut d'un capteur est l'unité :
   donc **gain = code / 16**. Le maximum `0xf8` = 248 donne 15,5×, plafond plausible.
2. Le pilote écrit `val << 4` dans un registre 16 bits gradué en 1/256 : le gain réel vaut
   `reg / 256 = (val × 16) / 256 = val / 16`. **Même résultat.**

Confirmé par le journal de libcamera lui-même : `IPASoft: Exposure 4-2320, gain 16-248 (1)`.

## Vérification de la méthode sur un cas connu

Appliquée à `ov13858`, dont libcamera possède déjà le helper :
`OV13858_ANA_GAIN_DEFAULT` = `0x80` = 128 ⇒ gain = code / 128.

Or l'amont écrit exactement :

```cpp
gain_ = AnalogueGainLinear{ 1, 0, 0, 128 };   // ov13858
```

La méthode reproduit donc le résultat officiel sur un cas indépendant.

## Le correctif

À insérer dans `src/ipa/libipa/camera_sensor_helper.cpp`, par ordre alphabétique
(entre `ov13858` et les suivants, en suivant la forme des classes voisines) :

```cpp
class CameraSensorHelperOv02c10 : public CameraSensorHelper
{
public:
	CameraSensorHelperOv02c10()
	{
		gain_ = AnalogueGainLinear{ 1, 0, 0, 16 };
	}
};
REGISTER_CAMERA_SENSOR_HELPER("ov02c10", CameraSensorHelperOv02c10)
```

⚠️ **`blackLevel_` est volontairement absent.** Plusieurs helpers OmniVision le renseignent
(`ov5640` : 1024, `ov5675` : 4096, `ov4689` : 1024, sur une échelle 16 bits), mais cette
valeur **se mesure, elle ne se déduit pas**. Voir `niveau-de-noir.md`.

## Ce que ça coûte

Le helper étant compilé, il faut **rebâtir le paquet `libcamera`**. Sur cette tablette sans
ventilateur, compiler à `-j3`. Tant que ce n'est pas fait, la frontale garde son AGC
approximatif — sans empêcher quoi que ce soit de fonctionner.
