# Série remoteproc « attach » — audio en EL2

Ces 14 patchs permettent au noyau de se **rattacher** à des DSP déjà démarrés, au lieu
d'essayer de les démarrer lui-même — ce que TrustZone refuse dès que Linux possède EL2.
Ils forment la moitié noyau ; l'autre moitié est [qebspil](https://github.com/stephan-gh/qebspil),
qui démarre les DSP depuis l'UEFI avant `ExitBootServices`. Contexte complet et pièges
dans [`../EL2-KVM.md`](../EL2-KVM.md).

Auteur : Stephan Gerhold. Ils ne sont pas recopiés ici : les branches d'origine
(`git.codelinaro.org/stephan.gerhold/linux`, `wip/x1e80100-6.16-el2` et
`wip/qcom-laptops-6.17-el2`) ont disparu, et le miroir vivant est
[`jglathe/linux_ms_dev_kit`](https://github.com/jglathe/linux_ms_dev_kit). Un manifeste
reste juste ; des copies divergeraient en silence.

## Ordre d'application

Appliqués ici sur `linux-next` 7.1.0-next-20260626.

| # | Patch |
|---|---|
| 1 | soc: qcom: smp2p: Kick after requesting interrupt |
| 2 | soc: qcom: smp2p: Ensure there is enough space for outbound entries |
| 3 | soc: qcom: smp2p: Use length limited strncmp() for comparing entry names |
| 4 | soc: qcom: smp2p: Drop redundant stack copies of entry names |
| 5 | soc: qcom: smp2p: Take over outgoing SMEM items from boot firmware |
| 6 | soc: qcom: smp2p: Add support for `irq_get_irqchip_state()` |
| 7 | remoteproc: core: Allow restarting detached remoteprocs with new firmware |
| 8 | remoteproc: qcom_q6v5: Allow detecting detached state during boot |
| 9 | remoteproc: qcom_q6v5: Add `qcom_q6v5_attach()` |
| 10 | remoteproc: qcom_q6v5: Send SMP2P stop signal in attached/detached state |
| 11 | remoteproc: qcom_q6v5_pas: Attach running remoteproc if firmware is missing |
| 12 | wip: remoteproc: qcom_q6v5_pas: Avoid using broken reset when running bare-metal |
| 13 | arm64: dts: qcom: x1-el2: Add `qcom,broken-reset` for remoteprocs |
| 14 | arm64: dts: qcom: x1-el2: Set correct owner for SCM SHM bridge |

## Ce qu'il faut savoir avant d'appliquer

**Le patch 14 est à écarter** sur linux-next : il ajoute
`#include <dt-bindings/firmware/qcom,scm.h>` pour `QCOM_SCM_VMID_SELF_OWNER`, constante
absente de l'arbre, et son code consommateur (`shm-bridge-vmid`) n'existe pas non plus.
Il dépend d'autres correctifs de la même série. Dans un DTS aplati, il casse simplement
la compilation — et il serait sans effet de toute façon.

**Le patch 13 ne suffit pas si vous gardez votre propre DTB** : il ne touche que
l'overlay `x1-el2.dtso`. Il faut ajouter `qcom,broken-reset` à la main sur les deux nœuds
`remoteproc@6800000` et `remoteproc@32300000`. Voir
[`../kernel/sp12-el2.dts.diff`](../kernel/sp12-el2.dts.diff).

**Seul conflit rencontré**, sur le patch 7, dans `drivers/remoteproc/xlnx_r5_remoteproc.c` :
trois affectations de `auto_boot` là où le patch en attendait une. Résolution :

```c
r5_rproc->auto_boot      = RPROC_AUTO_BOOT_DISABLED;           /* ~944  */
r5_rproc->auto_boot      = RPROC_AUTO_BOOT_ATTACH_OR_START;    /* ~948  */
r5_core->rproc->auto_boot = RPROC_AUTO_BOOT_ATTACH_OR_START;   /* ~1291 */
```

Pilote Xilinx, non compilé sur cette plateforme.

## ⚠️ Rupture d'ABI des modules

Le patch 7 change `bool auto_boot` en `enum rproc_auto_boot` dans `struct rproc`. Le champ
passe de 1 à 4 octets alignés : **la structure grandit de 8 octets** et tout ce qui suit
est décalé.

`CONFIG_REMOTEPROC=y` étant intégré au noyau, un `qcom_q6v5_pas.ko` neuf chargé par une
**ancienne** `Image` écrit au-delà de la structure allouée. Sans `CONFIG_MODVERSIONS`,
rien ne l'en empêche et **aucun message n'apparaît**.

Plusieurs `Image` de même version partagent `/lib/modules` : il n'existe pas de sélection
de modules par image. Deux issues, pas trois :

- changer `CONFIG_LOCALVERSION` pour obtenir un arbre de modules distinct — mais il faut
  alors reconstruire *tous* les modules hors-arbre, dont la vermagic est figée ;
- ou ajouter `modprobe.blacklist=qcom_q6v5_pas` à **toutes** les autres entrées du menu
  de démarrage.

## Vérifier

```bash
cat /sys/class/remoteproc/remoteproc*/state         # attendu : attached
cat /proc/asound/cards
dmesg | grep -c "error -22 initializing firmware"   # attendu : 0
```
