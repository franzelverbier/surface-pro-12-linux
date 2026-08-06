# Reconstruction du noyau SP12 (7.1.0-next-20260626)

## ✅ Un arbre utilisable existe (corrigé le 2026-08-05)

> La version précédente de ce document affirmait qu'aucun arbre source complet ne
> subsistait. **C'est faux.** L'arbre d'origine `/root/linux-next` (build WSL) a bien
> disparu — et le lien `/lib/modules/7.1.0-next-20260626/build` pointe toujours dessus,
> donc dans le vide — mais il y a `/home/franz/sp12-kernel-rebuild/linux-next`, qui est :
>
> - **identique en configuration** au noyau en service : `diff` entre `/proc/config.gz`
>   et son `.config` donne **zéro ligne**
> - déjà construit : `vmlinux` présent, 1665 modules
> - et vérifié à l'usage — il a produit `rtc-pm8xxx.ko` puis `ip_tables.ko`, tous deux
>   chargés sans erreur sur le noyau qui tourne
>
> Conséquence pratique : **on n'a pas besoin d'un rebuild complet pour ajouter un module.**
> Il suffit que l'option soit un `tristate` et qu'elle ne modifie aucune structure
> partagée — voir « Deux pièges d'ABI » plus bas.
>
> Le `.config` de référence, à ne pas confondre avec celui de travail, est conservé en
> `linux-next/.config.reference-noyau-en-service`.
>
> ⚠️ Compiler un module depuis cet arbre exige `KERNELRELEASE=7.1.0-next-20260626` :
> `scripts/setlocalversion` n'honore **plus** `.scmversion`, et comme l'arbre est un dépôt
> git dont HEAD n'est pas une étiquette, il ajoute un `+` au `vermagic`. Sans
> `CONFIG_MODVERSIONS`, le module refuse alors de se charger.

**Tout le nécessaire pour reconstruire de zéro est aussi DANS CE DÉPÔT :**
- `patches/0001`..`0006` : les 6 patches SP12 de la série d'origine (SAM, panel eDP
  NE120DRM, ASoC speaker, qcom-scm, DTS `x1p42100-microsoft-sp12`, makefile)
  + `patches/registry-next20260626.c`
- `kernel/config-7.1.0-next-20260626` : le `.config`
- `kernel/sp12.dtb`    : DTB compilé de référence
- `build-scripts/`     : scripts de build par étapes (référence)

## Recette re-clone + build
1. `git clone --depth 1 -b next-20260626 https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git linux-next`
   (si le tag `next-20260626` est élagué de kernel.org : prendre le commit le plus proche)
2. `cd linux-next && git apply ../patches/000[1-6]-*.patch`
   (borne `[1-6]` volontaire : `patches/0007-drm-panel-edp-Add-Sharp-SHP-…` ne fait PAS
   partie de la série qui a produit ce noyau. `patches/serie-complete/` non plus — c'est
   la série EL2/remoteproc, à part.)
3. `cp ../kernel/config-7.1.0-next-20260626 .config && make olddefconfig`
4. `make -j$(nproc) Image modules` — **sans `dtbs`**

   Le portage n'utilise pas les DTB du noyau mais un DTB dérivé de celui du constructeur.
   Et si `patches/serie-complete/0016` est appliqué, `dtbs` échoue sur une constante non
   définie (`QCOM_SCM_VMID_SELF_OWNER`) — l'échec survient **avant** la production
   d'`Image` et des modules, donc on ne récupère rien. Voir `serie-complete/README.md`.
5. Installer : `Image` → `/boot/Image` ; `make modules_install` ; DTB → `/boot/sp12.dtb`

## ⚠️ Avant toute recompilation : inventorier `updates/`

`/lib/modules/<version>/updates/` prime sur `kernel/`, et peut contenir des modules posés à
la main qu'**aucune option de configuration ne décrit**. Ils disparaissent du noyau
reconstruit, en silence.

Sur cette machine, `uhid.ko` s'y trouvait alors que `CONFIG_UHID` n'est activé nulle part :
la souris Bluetooth s'appairait ensuite sans qu'aucune commande ne remonte. Voir
`systeme/README.md` pour la commande d'inventaire et la liste complète.

## Netfilter — ✅ résolu dans `7.1.0-next-20260626-nft`

> **État au 2026-08-06.** Le noyau de référence `7.1.0-next-20260626` n'a **aucune pile
> netfilter utilisable** : `iptables` échoue (`Failed to initialize nft: Protocol not
> supported`), `iptables-legacy` aussi (`Table does not exist`), et `ip rule` renvoie
> `Operation not supported`.
>
> Un noyau `-nft` a été reconstruit depuis le même arbre avec les options ci-dessous ;
> `iptables v1.8.13 (nf_tables)` et `ip rule` y fonctionnent, et Tailscale y câble enfin
> ses chaînes `ts-*` (4 règles, contre 0 sans policy routing). Les deux noyaux coexistent :
> `CONFIG_LOCALVERSION="-nft"` leur donne des `/lib/modules` distincts, et une entrée GRUB
> séparée pointe sur chacun.
>
> La section qui suit reste la référence pour reproduire ces options.

### Le symbole a changé de nom — le piège principal

`CONFIG_IP_NF_IPTABLES=m` est **déjà** dans ce `.config` et ne construit **plus**
`ip_tables.ko`. Le Makefile teste un autre symbole :

```make
obj-$(CONFIG_IP_NF_IPTABLES_LEGACY) += ip_tables.o
```

Corollaire : le module absent n'est **pas** le signe d'un `make modules_install`
incomplet. Un `make modules` complet ne produit rien de plus — il n'avait jamais à être
construit. Ne pas partir en chasse d'un bug d'installation.

```
CONFIG_NETFILTER_XTABLES_LEGACY=y     # booleen, la porte ; depend de !PREEMPT_RT
CONFIG_IP_NF_IPTABLES_LEGACY=m        # c'est LUI qui construit ip_tables.ko
CONFIG_IP_NF_FILTER=m
CONFIG_IP_NF_MANGLE=m
CONFIG_IP6_NF_IPTABLES_LEGACY=m
CONFIG_IP6_NF_FILTER=m
CONFIG_IP6_NF_MANGLE=m

# les deux qui exigent vraiment un rebuild complet (voir pieges d'ABI)
CONFIG_NF_TABLES=m                    # ce que parle l'iptables d'Arch (iptables-nft)
CONFIG_NFT_COMPAT=m
CONFIG_IP_MULTIPLE_TABLES=y           # booleen -> integre : policy routing, `ip rule`

# NAT, si exit node / subnet router Tailscale souhaites
CONFIG_IP_NF_NAT=m
CONFIG_IP_NF_TARGET_MASQUERADE=m
```

### Deux pièges d'ABI — à vérifier avant tout ajout de module à chaud

Ajouter une option en `=m` sur un noyau déjà en service n'est sûr que si elle ne modifie
aucune structure partagée. Deux options de cette liste en modifient une :

| Option | Effet | Conséquence |
|---|---|---|
| `NF_TABLES` | ajoute `struct netns_nftables nft` à **`struct net`** (`include/net/net_namespace.h:153`) | rebuild complet obligatoire |
| `NF_NAT` | ajoute `struct hlist_node nat_bysource` à **`struct nf_conn`** (`include/net/netfilter/nf_conntrack.h:103`) | discorde avec le `nf_conntrack.ko` installé |

Le contrôle qui tranche, à faire pour chaque option envisagée :

```bash
grep -rl "CONFIG_<OPTION>" include/net/ include/linux/ include/uapi/ | wc -l
```

Zéro en-tête partagé = ajoutable en module sans redémarrer. Les sept options `LEGACY`
ci-dessus donnent toutes zéro.

### `olddefconfig` conserve un symbole que plus rien ne sélectionne

`NF_NAT` est arrivé en effet de bord de `IP_NF_NAT`, puis **a survécu** à la
désactivation de celui-ci : `olddefconfig` garde la valeur d'un symbole déjà posé même
quand plus aucun `select` ne le justifie. Il faut l'éteindre explicitement
(`scripts/config --disable NF_NAT`) et **revérifier**. Sans ce contrôle, on installe des
modules discordants avec le conntrack en place.

### Contournement en place, à retirer après le rebuild

En attendant `NF_TABLES`, les sept options `LEGACY` ont été compilées et installées à
chaud (modules seuls, sans redémarrage), et `tailscaled` tourne en mode TUN grâce à un
`PATH` qui lui présente `iptables-legacy` sous le nom `iptables` :

- `/usr/local/lib/tailscale-iptables-legacy/` — liens vers les binaires `*-legacy`
- `/etc/systemd/system/tailscaled.service.d/iptables-legacy.conf` — `Environment=PATH=…`

Limite connue : sans `IP_MULTIPLE_TABLES`, Tailscale crée ses chaînes `ts-input` et
`ts-forward` mais ne les câble pas — le tunnel fonctionne, le filtrage tailnet non.
**Les deux réglages ci-dessus sont à supprimer** une fois `NF_TABLES` et
`IP_MULTIPLE_TABLES` compilés dans le noyau.

## Debug EL2 / ramoops
Pour capturer un hang au boot EL2 (via slbounce), activer AVANT le build :
`scripts/config -e PSTORE -e PSTORE_RAM -e PSTORE_CONSOLE -e PSTORE_PMSG && make olddefconfig`
puis réserver une région ramoops (nœud `reserved-memory` dans le DTS, ou cmdline
`ramoops.mem_address=.../mem_size=...`). Après un boot EL2 figé + reset, relire `/sys/fs/pstore`.
