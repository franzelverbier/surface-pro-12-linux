# Série complète — source correspondante du noyau

Les **16 patchs** qui séparent le noyau de référence de sa base amont. Avec eux, le
`.config` publié dans `systeme/` et la base ci-dessous, la source du binaire est complète
et reproductible sans dépendre d'aucun tiers.

## Base

```bash
git clone https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git
cd linux-next && git checkout next-20260626
git am /chemin/vers/patches/serie-complete/*.patch
```

Le tag **`next-20260626`** est publié et immuable. Version obtenue : `7.1.0-next-20260626`.

## Contenu

| # | Sujet | Auteur |
|---|---|---|
| 0001–0002 | `irqchip/gic-v3` : paramètres `gicv3_nov4` / `its_nov4` pour masquer GICv4 | ce dépôt |
| 0003–0008 | `soc/qcom/smp2p` : reprise des items SMEM du firmware de démarrage, `irq_get_irqchip_state()` | Stephan Gerhold |
| 0009–0014 | `remoteproc` : `.attach`, détection de l'état détaché, `qcom,broken-reset` | Stephan Gerhold |
| 0015–0016 | `arm64: dts: qcom: x1-el2` | Stephan Gerhold |

Les métadonnées d'auteur d'origine sont préservées. Voir [`../audio-el2-serie.md`](../audio-el2-serie.md)
pour le détail du mécanisme, les pièges et l'avertissement sur l'ABI des modules.

## Pourquoi ces patchs sont recopiés ici

Les branches d'origine (`git.codelinaro.org/stephan.gerhold/linux`) **ont disparu** — cet
utilisateur n'existe plus dans l'API du service. Le miroir
[`jglathe/linux_ms_dev_kit`](https://github.com/jglathe/linux_ms_dev_kit) a permis de les
récupérer, mais un manifeste pointant vers un miroir n'est pas une source : il peut
disparaître à son tour, exactement comme l'original. D'où la copie.

## Note sur `0016`

`arm64: dts: qcom: x1-el2: Set correct owner for SCM SHM bridge` est conservé par
souci d'intégralité mais **ne s'applique pas** sur linux-next tel quel : il référence
`QCOM_SCM_VMID_SELF_OWNER`, constante absente de l'arbre, et son code consommateur
(`shm-bridge-vmid`) n'existe pas non plus. Il dépend d'autres correctifs de la même
série. Le sauter n'a aucune conséquence ici.
