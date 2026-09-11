# Le PHY PCIe échoue un démarrage sur huit, et il n'y a aucun rattrapage

> État au 2026-09-11 : **diagnostic en place, cause non établie.**

## Le symptôme

Pas de carte WiFi du tout. Pas « ath12k ne s'associe pas » : **aucune ligne `ath12k`**,
le périphérique n'est jamais énuméré.

```
qcom-qmp-pcie-phy 1c0e000.phy: phy initialization timed-out
phy phy-1c0e000.phy.0: phy poweron failed --> -110
qcom-pcie 1c08000.pci: error -ETIMEDOUT: cannot initialize host
qcom-pcie 1c08000.pci: probe with driver qcom-pcie failed with error -110
```

Le PHY ne s'initialise pas, donc le contrôleur PCIe échoue, donc la carte `wcn7850`
n'existe pas pour le noyau.

## La fréquence, sur 135 démarrages

Le journal remonte au 28 juillet. **16 échecs sur 135 démarrages, soit 11,9 %** :
boots `-129 -127 -105 -89 -86 -83 -81 -65 -50 -48 -36 -29 -19 -16 -9 -1`, étalés du
28 juillet au 11 septembre. Panne ancienne, pas une régression récente.

## Il n'y a pas de rattrapage possible à chaud

```
$ ls -a /sys/bus/platform/drivers/qcom-pcie/
.  ..  1c08000.pci  module  uevent
```

Ni `bind` ni `unbind` — le pilote pose `.suppress_bind_attrs = true`, et `CONFIG_PCIE_QCOM=y`
le rend intégré, donc rien à décharger non plus. Le noyau ne réessaie un probe que sur
`-EPROBE_DEFER` ; un `-ETIMEDOUT` est définitif. **Le seul remède est le redémarrage.**
Une unité systemd de récupération est donc impossible, contrairement à ce qu'on avait
d'abord envisagé.

## L'hypothèse : l'état laissé par le firmware

```c
/*
 *  1. The PHY supports the nocsr_reset that preserves the PHY config.
 *  2. The PHY was started (and not powered down again) by the
 *     bootloader, with all of the expected bits set correctly.
 */
qmp->skip_init = qmp->nocsr_reset &&
	qphy_checkbits(pcs, cfg->regs[QPHY_START_CTRL], SERDES_START | PCS_START) &&
	qphy_checkbits(pcs, cfg->regs[QPHY_PCS_POWER_DOWN_CONTROL], cfg->pwrdn_ctrl);
```

Le pilote **décide de sauter toute la séquence d'initialisation en fonction de l'état où le
firmware a laissé le PHY**. Notre nœud a ce qu'il faut pour que ce chemin soit vivant :

```dts
reset-names = "phy", "phy_nocsr";
```

Si le firmware pose les bits « démarré » sans que le matériel soit réellement fonctionnel,
Linux n'initialise rien et attend un statut qui ne viendra pas — 10 ms, puis abandon
(`PHY_INIT_COMPLETE_TIMEOUT`, scrutation toutes les 200 µs).

## Ce qui a été testé et écarté

FR avait observé que la panne suivait « systématiquement » une erreur à l'extinction des
services. Testé aux deux niveaux, avec le contrôle des non-échecs :

| fin du démarrage précédent | suivants | PHY perdu | taux |
|---|---|---|---|
| extinction propre | 93 | 11 | 11,8 % |
| redémarrage propre | 25 | 4 | 16,0 % |
| coupure | 16 | 1 | 6,3 % |

Taux de fond 11,9 % : les trois cases sont dessus. Par message d'arrêt précis, le meilleur
candidat est `sddm-helper exited` (3 échecs sur 10), probabilité par hasard **11 %** ;
les autres entre 10 et 40 %. Aucun n'approche 5 %.

**Pourquoi l'impression de systématicité** : les erreurs de fermeture de session sont très
fréquentes — `kwin_wayland: atomic commit failed` apparaît sur **54 des 134 arrêts**.
Presque chaque démarrage sans WiFi suit une erreur d'arrêt ; presque chaque démarrage
normal aussi.

L'intuition reste juste sur le fond — l'état laissé compte — mais il est laissé par le
firmware, pas par les services, et c'est pour cela que le journal n'en montre rien.

## Le diagnostic en place

Ajouté dans `drivers/phy/qualcomm/phy-qcom-qmp-pcie.c`, juste après le calcul :

```c
dev_info(qmp->dev,
	 "sp12: skip_init=%d (nocsr=%d start_ctrl=%d pwrdn=%d)\n",
	 qmp->skip_init, !!qmp->nocsr_reset,
	 qphy_checkbits(pcs, cfg->regs[QPHY_START_CTRL], SERDES_START | PCS_START),
	 qphy_checkbits(pcs, cfg->regs[QPHY_PCS_POWER_DOWN_CONTROL], cfg->pwrdn_ctrl));
```

Les trois termes séparément : le jour où le WiFi manquera, on saura **lequel** des deux
registres le firmware avait laissé tomber.

Sur un démarrage réussi (2026-09-11 15:18) :

```
qcom-qmp-pcie-phy 1c0e000.phy: sp12: skip_init=1 (nocsr=1 start_ctrl=1 pwrdn=1)
```

Donc le raccourci est le cas **normal**. Ce n'est pas le prendre qui casse.

## ⚠️ Le piège : installer le module ne suffit pas

`CONFIG_PHY_QCOM_QMP_PCIE=m`, donc reconstruction de 12 secondes. Mais le module est
**aussi dans l'initramfs**, et c'est cette copie qui est chargée :

```
usr/lib/modules/7.1.0-next-20260626-nft/kernel/drivers/phy/qualcomm/phy-qcom-qmp-pcie.ko
```

Première tentative : module posé dans `/lib/modules`, `depmod`, redémarrage — **aucune
ligne**. La copie de l'initramfs (376 152 o, sans la chaîne) l'emportait sur celle du
disque (378 624 o, avec).

⚠️ Un raisonnement de chronologie avait conclu l'inverse (bus PCIe à 2,804 s, juste après
`Reached target Basic System`, donc chargé depuis la racine). Il était faux. Le test a
coûté un redémarrage, l'inférence aurait coûté des jours.

## Comment l'initramfs a été traité

⚠️ `file` annonce « ASCII cpio archive » : il ne lit que le **premier** segment. L'image a
10 Kio de cpio initial puis le gros, **compressé en gzip**.

Régénéré par `mkinitcpio -k 7.1.0-next-20260626-nft -g …`. L'analyse est identique
(même version d'outil, mêmes 32 modules, mêmes 13 binaires, mêmes hooks) mais
**ce n'est pas la même image plus un module** : elle embarque aussi cinq semaines de mises
à jour d'`util-linux`, d'OpenSSL et de la base `udev`, plus
`etc/modprobe.d/sp12-pstore-blk.conf` ajouté depuis août.

D'où le choix : **fichier séparé**, `/boot/initramfs-nft-diag.img`, utilisé par la seule
entrée 5. `initramfs-nft.img` (entrée 0) et le secours figé restent intacts à l'octet.

## Pistes non explorées

- Refaire la séquence complète quand le statut expire alors que `skip_init` était vrai,
  au lieu de croire le bootloader. Correctif défendable en amont si le diagnostic confirme.
- Allonger les 10 ms : probablement faux. Si le PHY n'a jamais été démarré, aucune attente
  ne le fera répondre.
