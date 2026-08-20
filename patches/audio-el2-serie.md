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

## ⚠️ Si un DSP plante, le noyau prend un oops et le DSP ne revient pas

Constaté le 2026-08-11, sur une compilation de noyau de 28 minutes — le CDSP a lâché de
lui-même, sans provocation :

```
qcom_q6v5_pas 32300000.remoteproc: fatal error received: sleep_statsi.c:537:
remoteproc remoteproc1: crash detected in cdsp: type fatal error
remoteproc remoteproc1: recovering cdsp
remoteproc remoteproc1: stopped remote processor cdsp
Unable to handle kernel NULL pointer dereference at virtual address 0000000000000000
Internal error: Oops: 0000000086000004 [#1]  SMP
pc : 0x0
lr : rproc_start+0xc0/0x164
Call trace:
 rproc_trigger_recovery+0x148/0x164
 rproc_crash_handler_work+0xb4/0xb8
```

**La chaîne, vérifiée pas à pas** — registre de lien, désassemblage du `vmlinux`
correspondant au noyau en service, puis source :

1. `rproc_trigger_recovery()` choisit sa branche ainsi :
   ```c
   if (rproc_has_feature(rproc, RPROC_FEAT_ATTACH_ON_RECOVERY))
           ret = rproc_attach_recovery(rproc);
   else
           ret = rproc_boot_recovery(rproc);
   ```
2. `qcom_q6v5_pas.c` **ne déclare jamais** `RPROC_FEAT_ATTACH_ON_RECOVERY` — dans cet arbre,
   seul `imx_rproc.c` le fait. La branche `boot` est donc prise.
3. `rproc_boot_recovery()` appelle `rproc_start()`, qui fait, sans aucun test
   (`remoteproc_core.c:1292`) :
   ```c
   ret = rproc->ops->start(rproc);
   ```
4. Or `qcom_pas_ops_no_reset` — celui que `qcom,broken-reset` sélectionne — ne fournit que
   `.attach`, `.da_to_va`, `.stop` et `.panic`. **`.start` est nul.** Saut vers l'adresse 0.

**Conséquences** : le worker de récupération meurt, le DSP reste `offline` jusqu'au
redémarrage, et rien ne le relance. Ici l'ADSP n'était pas touché — l'audio a continué de
fonctionner et la compilation s'est terminée normalement — mais un plantage de l'ADSP
coûterait le son jusqu'au redémarrage.

### ✅ Le correctif, vérifié sur la machine

J'avais d'abord proposé `RPROC_FEAT_ATTACH_ON_RECOVERY`, pour que la récupération passe par
`rproc_attach_recovery()`. **Stephan Gerhold a répondu que c'était le mauvais raisonnement** :
on ne sait pas relancer ce DSP, et rattacher un processeur planté n'a aucun sens. Sa
proposition — `rproc->recovery_disabled = true`.

J'avais aussi écrit que le plantage n'était pas déclenchable à la demande. **Faux** :
`debugfs` l'expose. Deux essais sur le même démarrage, même déclencheur, une seule variable :

```bash
echo disabled > /sys/kernel/debug/remoteproc/remoteproc1/recovery
echo 2        > /sys/kernel/debug/remoteproc/remoteproc1/crash
```

```
remoteproc remoteproc1: crash detected in cdsp: type fatal error
remoteproc remoteproc1: handling crash #1 in cdsp
```

Rien d'autre. Aucune tentative de récupération, **aucun oops**, noyau non tainté, et l'état
passe à `crashed` plutôt qu'`offline` — plus honnête, puisque rien n'a arrêté le DSP.

Le témoin, en réactivant la récupération sur ce même DSP planté :

```
remoteproc remoteproc1: recovering cdsp
remoteproc remoteproc1: stopped remote processor cdsp
Unable to handle kernel NULL pointer dereference at virtual address 0
pc : 0x0
lr : rproc_start+0xc0/0x164
```

Signature identique au plantage spontané, seul le point d'entrée diffère. **`recovery_disabled`
règle le problème**, c'est vérifié.

⚠️ Reste que `rproc_start()` appelle `ops->start` sans le tester, et `rproc_boot_recovery()`
fait de même pour `ops->coredump`. Même avec le drapeau correctement posé par tous les
pilotes, un `rproc_ops` sans `.start` reste à une écriture debugfs d'un appel nul.

Stephan précise par ailleurs que **toute l'approche `qcom,broken-reset` est discutée** et
qu'il n'est pas certain de la proposer un jour en amont en l'état. À savoir avant de bâtir
dessus.

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

## Le coût caché de la voie « attach » : 5 s d'attente au démarrage

```
qcom-apm gprsvc:service:2:1: CMD timeout for [1001021] opcode
```

`0x01001021` est `APM_CMD_GET_SPF_STATE` (`sound/soc/qcom/qdsp6/audioreach.h:40`), et le
délai d'attente est de `5 * HZ` — **cinq secondes** — dans `audioreach.c:603`. La chaîne
causale, mesurée :

1. `q6apm` interroge l'ADSP vers 3,7 s
2. aucune réponse → délai dépassé à 8,675 s
3. `q6prm` avait renvoyé `-EPROBE_DEFER` (`q6prm.c:215`) ; il réessaie et **réussit**
4. la carte son s'enregistre à 8,709 s
5. tout service qui scrute `/proc/asound/cards` se débloque alors — ici
   `sp12-audio-ucm.service`, 4,4 s d'attente, le service le plus lent du démarrage

**Il n'y a qu'un seul message de délai dépassé.** La seconde interrogation obtient donc sa
réponse : l'ADSP répond, simplement pas à 3,7 s. C'est une **course**, pas un refus.

Hypothèse — non démontrée : en attachant l'ADSP au lieu de le démarrer, le pilote saute la
poignée de main de démarrage qui précède normalement tout trafic GPR, et la première
interrogation part avant que le service GPR de l'ADSP ne soit joignable. Impossible à
vérifier par comparaison sur cette machine : l'entrée EL1 du menu blackliste
`qcom_q6v5_pas`, donc pas d'audio, donc pas de démarrage témoin.

**Ce que ça coûte réellement** : le chiffre de `systemd-analyze` (8,8 s) est presque
entièrement cette attente, mais la chaîne critique atteint `graphical.target` à **2,95 s**
— le bureau n'attend pas. Le gain d'un correctif serait l'audio disponible ~4 s plus tôt,
pas un bureau plus rapide.

Un correctif propre voudrait attendre la disponibilité du service GPR plutôt
qu'interroger à l'aveugle. C'est du travail amont, pas un réglage.

### ✅ Contournement mesuré — `patches/0009`

Puisque l'ADSP répond à la seconde tentative, il suffit de rater la première **vite**.
`patches/0009` donne 1 seconde à cette seule requête, en laissant les `5 * HZ` à toutes les
autres commandes — celles-là s'exécutent contre un ADSP qui a déjà répondu, et les tronquer
pourrait interrompre une lecture en cours.

```c
unsigned long timeout = (hdr->opcode == APM_CMD_GET_SPF_STATE) ? HZ : 5 * HZ;
```

Mesuré sur la machine :

| | avant | après |
|---|---|---|
| délai dépassé | 8,68 s | 5,70 s |
| carte son enregistrée | 8,71 s | 5,74 s |
| service en attente de la carte | 4,40 s | **0,37 s** |
| démarrage total | 8,21 s | 6,74 s |

Les 0,37 s du service sont la mesure la plus fiable : il ne fait qu'attendre la carte, donc
son temps est celui du délai, sans dépendre du niveau de journalisation ni du reste du
démarrage. La ligne d'erreur, elle, subsiste — la course est inchangée, seule son attente
est raccourcie.

## Vérifier

```bash
cat /sys/class/remoteproc/remoteproc*/state         # attendu : attached
cat /proc/asound/cards
dmesg | grep -c "error -22 initializing firmware"   # attendu : 0
dmesg | grep -c "CMD timeout for \[1001021\]"       # 1 = la course ci-dessus, sans gravite
```
