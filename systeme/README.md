# Configuration système

Ce qui vit hors du noyau : unités systemd, listes noires de modules, menu de démarrage.
C'est ici que se trouvent la plupart des contournements — le noyau seul ne suffit pas à
faire tourner cette machine.

| Chemin | Rôle |
|---|---|
| `grub.cfg` | menu de référence, 5 entrées (EL2+audio+nftables par défaut, secours figé daté, EL2 du 31 juillet, EL1, Shell UEFI) |
| `config-running-*.gz` | `.config` du noyau de référence |
| `systemd/` | services SP12 et leurs drop-ins, plus le correctif `onedriver@.service.d` |
| `modprobe.d/` | listes noires de modules |
| `modules-load.d/` | neutralisations de demandes de chargement |
| `bin/` | scripts appelés par les unités |

## Les services, et pourquoi ils existent

**`sp12-typecover.service`** — charge les modules Surface Aggregator. Indispensable :
`modprobe.d/blacklist-surface-sam.conf` met ces modules en liste noire, et **seul un
`modprobe` explicite passe outre**. Ne pas croire qu'un fichier `modules-load.d` ferait
l'affaire : il respecte la liste noire et resterait sans effet — erreur commise ici, au
prix du clavier.

Le drop-in `20-condition.conf` remplace deux `sleep 1` en aveugle par une attente de
condition réelle (contrôleur SAM lié, puis bus `surface_aggregator` peuplé), via
`bin/sp12-typecover-load`. Délai de garde de 3 s, soit **plus long** que l'ancien `sleep` :
en cas d'anomalie on attend davantage, jamais moins.

**`sp12-audio-ucm.service`** — applique le profil UCM `HiFi`. Attend l'apparition de la
carte, désormais toutes les 100 ms au lieu d'une seconde.

**`sp12-wifi-watchdog.service`** — recharge `ath12k` si `wlan0` manque au démarrage.
Devenu inutile depuis le correctif SMMUv3 (voir `EL2-KVM.md`), mais coûte ~1 s et sert de
filet ; il constate simplement que tout va bien.

**`sp12-usbwifi.service`** — charge tardivement `rtl8xxxu` pour une clé WiFi USB.
**Livré désactivé** : le WiFi interne fonctionne. À réactiver seulement si le PCIe pose
problème. L'initialisation RF de ce chip échoue quand le module est chargé tôt dans le
démarrage, d'où le chargement tardif avec réessai.

**`sp12-bootreport.timer`** — capture l'état du système 20 s après le démarrage, dans
`/data/bootreports/`. C'est un **timer**, pas un service activé : sinon ses 20 s
d'attente entrent dans la transaction de démarrage et gonflent le temps rapporté par
`systemd-analyze` sans rien retarder de réel.

**`sp12-temoin.service`** — relevé périodique `fsync`'é, dans
`/data/sp12data/temoin/temoin.jsonl`. Ajouté le 2026-08-27 après deux redémarrages
spontanés sans aucune trace (26 août 20:43:54, 27 août 08:38:34).

Il existe parce que **ramoops ne retient rien sur cette machine** (voir plus bas). Il ne
remplace pas un vidage noyau et **ne dira jamais pourquoi** la machine est tombée. Il
établit deux choses : l'état juste avant — température maximale, énergie et tension
batterie, alimentation, fréquences CPU, charge, mémoire — échantillonné toutes les 30 s ;
et surtout **la nature de l'arrêt**. Le script écrit une ligne `"type":"stop"` sur SIGTERM :
sa présence en fin de boot signe une extinction volontaire, son absence une coupure. C'est
le seul fait qu'il garantit.

Chaque ligne est écrite puis `fsync`'ée — sans quoi la dernière, justement celle qui
compte, resterait dans un tampon perdu à la coupure. Le service tourne en `Nice=10` /
`IOSchedulingClass=idle` et son `TimeoutStopSec=10` lui laisse le temps d'écrire son
marqueur, pas davantage. Écrit en **Node** comme le reste de l'outillage du projet.

## Drop-ins `10-nonblocking.conf`

Plusieurs unités portent `After=multi-user.target` : elles sont ordonnées **après** la
cible qui les réclame, donc celle-ci ne les attend pas. C'est ce qui garde le chemin
critique court alors que ces services prennent plusieurs secondes.

## `loglevel` par entrée

L'entrée d'usage courant utilise **`loglevel=3`** : la console n'affiche que les erreurs.
Ce n'est pas une façon de cacher la poussière — les 42 avertissements masqués ont été
identifiés un par un et sont bénins :

- **24 lignes** `qcom-pcie … supply vdda / vddpe-3v3 not found, using dummy regulator`.
  Ces alimentations sont réellement absentes de ce design : le DTS officiel amont
  (`x1p42100-microsoft-sp12.dts`) ne les déclare pas davantage, et le WiFi tire les
  siennes des `vddrfa*`/`vddpcie*` du nœud `wifi@0`. Les 12 répétitions par alimentation
  viennent des reprises de sondage différé. Attention : d'autres cartes x1e déclarent
  bien `vddpe-3v3-supply`, mais sur `&pcie6a` (connecteur NVMe) — pas sur le `pcie4` du
  WiFi. Ne pas s'y laisser prendre.
- le reste : régulateurs optionnels absents (`adreno`, `i2c_hid_of`, `wcn7850-pmu`),
  messages informatifs (`clk: Not disabling unused clocks`, `Zap shader not enabled`),
  quirks du firmware (`[Firmware Bug]` psci, arch_timer).

Rien n'est perdu : `dmesg`, le journal et `sp12-bootreport` capturent toujours tout. Un
écran réduit à 7 lignes rend au contraire une anomalie nouvelle immédiatement visible,
alors qu'elle se noyait dans le bruit. L'entrée de secours figée garde `loglevel=7` :
si on y recourt, c'est que quelque chose ne va pas, autant tout voir.

## `systemd/onedriver@.service.d/` — OneDrive qui redemande une connexion

Symptôme : à chaque démarrage, `onedriver` réclame une réauthentification. On croit à un
jeton expiré ; le jeton se porte très bien.

**La cause est l'horloge.** Cette machine n'a pas d'horloge matérielle en EL2 : le pilote
RTC (`rtc@6100`, pm8xxx) exige les variables EFI via `qcom,uefi-rtc-info`, or Secure Launch
coupe l'accès à TrustZone qui les héberge — le pilote reste en `-EPROBE_DEFER`, `/dev/rtc`
n'existe pas. L'heure est donc fausse jusqu'à ce que NTP la corrige, ce qui exige le
réseau.

Or OAuth est signé temporellement. Mesuré ici :

| | |
|---|---|
| onedriver démarrait | 21,5 s |
| NTP synchronisait | 33,9 s |

Douze secondes à négocier avec Microsoft avec une horloge décalée. Le serveur rejette
(`InvalidAuthenticationToken`), onedriver force une réauthentification, la fenêtre
apparaît. Une fois l'heure juste, les renouvellements horaires passent tous.

Le drop-in attend **deux** conditions — réseau connecté *et* `NTPSynchronized=yes` — avec
un délai de garde de 120 s : au pire on démarre quand même, jamais on ne bloque la session.
Après correction, onedriver démarre à 34,0 s, soit 0,3 s après l'heure juste. Zéro
réauthentification, zéro redémarrage du service.

⚠️ **`network-online.target` n'existe pas dans le gestionnaire utilisateur** — un `Wants=`
dessus est sans effet. D'où le test explicite via `nmcli`.

Il contient aussi `ExecStopPost=-/usr/bin/fusermount -uz %f`. Sans ça, un redémarrage après
plantage échoue en silence : le point de montage FUSE reste en place, sale, et la nouvelle
instance ne peut pas s'y greffer. Le processus tourne alors sans qu'aucun montage
n'existe — ce qui ressemble, là encore, à une déconnexion de compte.

Le drop-in est au niveau du **gabarit** (`onedriver@.service.d`), pas de l'instance : il
s'applique quel que soit le point de montage. Rien à adapter pour le réutiliser ailleurs.

## `pstore-blk` — remplacer une DRAM effacée par le disque

Mis en place le 2026-09-03. ramoops ne retient **rien** ici (voir plus bas) : les vidages
noyau allaient dans une zone DRAM que la chaîne UEFI/slbounce réinitialise. `pstore-blk`
écrit sur un périphérique bloc à la place.

**Sans recompiler le noyau.** `PSTORE_BLK` et `PSTORE_ZONE` sont `tristate`, donc
constructibles en modules contre l'arbre existant — 17 secondes, contre ~28 minutes pour
une reconstruction complète. Audit ABI passé : 0 en-tête partagé.

⚠️ Le `+` de `setlocalversion`. L'arbre annonce `7.1.0-next-20260626-nft+` alors que le
noyau courant est `…-nft`. Sans `KERNELRELEASE=7.1.0-next-20260626-nft` explicite au
`make`, le vermagic ne correspond pas et les modules refusent de se charger.

**Partition dédiée obligatoire** : `pstore-blk` écrit en **brut** sur le périphérique qu'on
lui désigne. `/dev/sda4` (`SP12PSTORE`, 32 Mio) a été taillée dans l'espace libre de fin de
disque ; table de partitions sauvegardée dans `/data/sp12data/gpt-sda.avant-pstore-20260903`.

Deux pièges rencontrés au chargement :

- `blkdev=PARTUUID=…` échoue en `-2`. Cette forme n'est résolue qu'au démarrage précoce,
  pas depuis un module chargé à chaud. Utiliser un chemin réel — ici
  `/dev/disk/by-partuuid/…`.
- `pstore: backend 'ramoops' already in use: ignoring 'pstore_blk'`. Le noyau n'accepte
  **qu'un** backend pstore, et ramoops, intégré et déclaré par le DTB, prend la place.
  D'où `pstore.backend=pstore_blk` sur la ligne de commande — ajouté à la **seule** entrée
  d'usage courant, l'entrée de secours figée restant inchangée.

⚠️ **Ce que cela ne résoudra pas.** Les coupures observées ne produisent aucune panique :
le noyau ne tombe pas, il s'arrête. `max_reason=2` ne déclenche que sur Oops et Panic, donc
aucun vidage ne sera écrit pour ce type d'événement. C'est la **zone console**
(`console_size=2048`) qui a une chance d'être utile : elle enregistre en continu la sortie
console du noyau, et devrait donc conserver les derniers messages avant une coupure franche.
Avec `best_effort=1` — le pilote UFS n'expose pas de support pstore dédié — l'écriture passe
par la couche bloc ordinaire, sans garantie que les tout derniers octets atteignent le disque.

## `/etc/UPower/UPower.conf` — la machine n'avait aucune protection batterie

Constaté le 2026-09-03 : laissée débranchée, la machine descend jusqu'à la **coupure
matérielle** au lieu de s'arrêter proprement. Relevé par le témoin, décharge du 1er au
2 septembre : 33,74 Wh à 09:39, puis décroissance régulière sur 19 h jusqu'à 0,00 Wh, la
tension tombant à **6,07 V** — 3,03 V par cellule, le seuil de coupure.

La chaîne causale, vérifiée de bout en bout :

| | |
|---|---|
| `CanSuspend` / `CanHibernate` / `CanHybridSleep` | **no** — aucun état de veille ne fonctionne ici |
| `resume=` dans la ligne de commande | absent, malgré un swapfile de 4 Go |
| `CriticalPowerAction` | `Auto` |
| `AllowRiskyCriticalPowerAction` | `false` |

`Auto` tente HybridSleep, puis Hibernate, puis PowerOff. Les deux premiers sont impossibles
sur cette machine ; le troisième est **refusé** par le drapeau « risky ». upower n'avait
donc **aucune action possible** au seuil de 2 % et ne faisait rien.

Correctif — deux lignes :

```
CriticalPowerAction=PowerOff
AllowRiskyCriticalPowerAction=true
```

Sauvegarde en `UPower.conf.avant-criticalaction-20260903`. Le drapeau s'appelle « risky »
parce qu'une extinction forcée perd le travail non enregistré : c'est exactement ce que
faisait déjà la coupure à 6,07 V, en y ajoutant le risque pour le système de fichiers et
l'usure de la batterie.

⚠️ Ne pas lire ceci comme « les redémarrages spontanés sont résolus ». Une seule des trois
coupures récentes s'explique par la batterie ; les deux autres survenaient **sur secteur**,
sans aucun précurseur.

## `modules-load.d/cdrecord.conf`

Surcharge vide masquant `/usr/lib/modules-load.d/cdrecord.conf`, qui réclame le module
SCSI générique `sg`. `CONFIG_CHR_DEV_SG` n'est pas construit et la machine n'a pas de
lecteur optique : la demande échouait à chaque démarrage.

## Modules fantômes de la compilation perdue

```
reed_solomon: exports duplicate symbol decode_rs8 (owned by kernel)
```

Un module qui exporte un symbole **déjà détenu par le noyau** signale un `.ko` en trop :
l'option est compilée en dur, et pourtant un module du même nom traîne dans
`/lib/modules`. Ici `CONFIG_REED_SOLOMON=y` et `CONFIG_PSTORE_RAM=y`, mais
`/lib/modules/…/kernel/lib/reed_solomon/reed_solomon.ko` et
`kernel/fs/pstore/ramoops.ko` existaient encore, avec `modules.dep` déclarant le premier
comme dépendance du second. Le chargement de `ramoops` au démarrage tirait
`reed_solomon`, qui échouait — deux fois par démarrage.

Leur origine est identifiable, et c'est la leçon à retenir :

```bash
strings /lib/modules/$(uname -r)/kernel/lib/reed_solomon/reed_solomon.ko | grep GCC:
# GCC: (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0
```

Ils viennent de la **compilation WSL d'origine**, celle dont l'arbre `/root/linux-next` a
disparu — exactement la même provenance que le module SAM qui avait faussé une analyse en
juillet (voir `patches/README.md`). Notre arbre, lui, ne les construit pas : les options
sont `=y`.

`pstore` n'a jamais été affecté par ce problème de modules — il tourne depuis le code
intégré :

```
[    0.019995] pstore: Registered ramoops as persistent store backend
```

⚠️ **Mais s'enregistrer n'est pas retenir.** Constaté le 2026-08-27 : ramoops ne conserve
rien sur cette machine. `ramoops: uncorrectable error in header` apparaît à **chaque**
démarrage — y compris après un redémarrage propre, donc après un simple reset à chaud.
Vérifié sur 7 démarrages consécutifs, `/sys/fs/pstore` et `/var/lib/systemd/pstore` sont
restés vides : **aucune trace n'a jamais été capturée**. Le contenu de la zone réservée
`0xa0000000` ne survit pas à la chaîne UEFI/slbounce. Conséquence directe : un `pstore`
vide après un incident **ne prouve rien** et ne doit jamais servir d'élément de preuve.
Voir `/data/sp12data/temoin/LISEZ-MOI.md` pour le relevé mis en place à la place.

Correctif appliqué : les deux `.ko` renommés en `*.etranger-inutilisable`, puis
`sudo depmod -a`. `grep -c "reed_solomon\|ramoops" /lib/modules/$(uname -r)/modules.dep`
doit alors renvoyer 0.

⚠️ **Le réflexe général** : devant un module qui se comporte mal, vérifier d'abord d'où
vient le binaire — `strings … | grep GCC:` — avant de raisonner sur les sources. Sur cette
machine, une partie de `/lib/modules` provient d'un arbre qui n'existe plus.

### Et le pire : `updates/`, que la configuration ne décrit pas

Les deux modules ci-dessus étaient inoffensifs. Le répertoire `updates/` — qui **prime sur
`kernel/`** dans l'ordre de recherche de `modprobe` — en contenait un qui, lui, portait une
fonction réelle :

```
/lib/modules/7.1.0-next-20260626/updates/uhid.ko   ← GCC (Ubuntu 13.3.0)
```

Or `CONFIG_UHID` **n'est pas activé** dans le `.config` de ce noyau, ni dans aucune de nos
configurations. La souris Bluetooth fonctionnait uniquement grâce à ce fichier posé à la
main : `bluetoothd` crée les périphériques HID Bluetooth via `/dev/uhid`, et sans le module
l'appairage réussit mais **aucune commande ne remonte** — symptôme déroutant, puisque tout
paraît connecté.

Le problème est resté invisible pendant des semaines et n'est apparu qu'à la première
recompilation, un noyau fidèle à sa configuration ne pouvant pas produire ce module.

Contenu complet du répertoire sur ce système, avec l'état de l'option correspondante :

| Module | Option |
|---|---|
| `surface_aggregator`, `surface_hid`, `surface_hid_core`, `surface_aggregator_hub`, `surface_aggregator_registry`, `surface_aggregator_tabletsw` | `=m` — décrits par la config |
| `uhid` | **`# CONFIG_UHID is not set`** — décrit nulle part |

⚠️ **Avant toute recompilation**, inventorier `updates/` et vérifier que chaque module y
figurant a bien une option activée :

```bash
find /lib/modules/$(uname -r)/updates -name '*.ko*' | while read f; do
  m=$(basename "$f" | sed 's/\.ko.*//')
  echo "$m : $(zcat /proc/config.gz | grep -E "^CONFIG_${m^^}=|^# CONFIG_${m^^} is not set")"
done
```

Tout module dont l'option est absente ou à `not set` disparaîtra du noyau reconstruit.
`surface_aggregator_registry` mérite une mention à part : la version d'`updates/` portait un
groupe `sp12in` élagué à la main, là où l'arbre contient la version amont. Les deux
fonctionnent ici — le détecteur de mode tablette existe simplement sous un autre nom,
`POS Tablet Mode Switch` au lieu de `KIP` — mais l'écart n'était documenté nulle part.

## WiFi — les 15,6 s avant connexion, et pourquoi on n'y peut rien

Au démarrage, le réseau n'est utilisable qu'à ~22 s alors que le bureau est là à 2,95 s.
L'association elle-même prend 35 ms : tout le temps passe **avant**.

### La cause, mesurée

Journal NetworkManager en mode `DEBUG` (domaines `WIFI,WIFI_SCAN,DEVICE`) :

```
+ 6,09 s   (wlan0): wifi-scan: start periodic scan (0 SSIDs to probe scan)
           (wlan0): wifi-scan: scanning-state: scanning
+21,72 s   (wlan0): wifi-scan: scanning-state: idle
+21,72 s   policy: auto-activating connection
```

**Un seul balayage passif de 15,63 s**, et NM déclenche son auto-connexion à la
milliseconde où il se termine. `0 SSIDs to probe` = pas de sondage actif : l'interface
écoute les balises canal par canal. Le pilote démarre en domaine réglementaire `WORLD`, où
l'émission est interdite sur la plupart des canaux, donc le balayage ne *peut pas* être
actif. Avec la 6 GHz, cela fait une centaine de canaux à ~150 ms — le compte y est.

Le domaine n'est appris (`CH`/`FR` selon la borne) que depuis les balises du point d'accès,
c'est-à-dire **après** l'association. Trop tard pour le balayage qui la précède.

⚠️ En journalisation `INFO` — le réglage par défaut — NM n'écrit **rien** pendant ces
15 s et wpa_supplicant non plus. L'intervalle paraît vide, ce qui envoie chercher la cause
partout sauf au bon endroit. Passer NM en `DEBUG` est le premier geste.

### Quatre pistes essayées, toutes mortes

| Tentative | Résultat |
|---|---|
| `802-11-wireless.band a` | S'applique bien (le `freq_list` passé à wpa_supplicant devient 5 GHz seul) mais contraint la **connexion**, pas le balayage périodique du **périphérique**. Aucun effet. |
| `cfg80211.ieee80211_regdom=CH` en ligne de commande noyau | Le domaine global devient `CH`, et pourtant wpa_supplicant journalise toujours `CTRL-EVENT-REGDOM-CHANGE init=DRIVER type=WORLD`. **ath12k impose son propre domaine initial** depuis son firmware. Balayage inchangé à 15,62 s. Retiré. |
| Paramètre de module ath12k | Le pilote n'expose que `debug_mask` et `ftm_mode`. Aucun réglage de bande ni de balayage. |
| `freq_list` global de wpa_supplicant | Jamais lu : le service tourne en `-u -s -O` **sans `-c`**, donc piloté uniquement par D-Bus. |

À noter aussi : `iw reg set` ne modifie pas les drapeaux des canaux du phy (30 passifs sur
102, identiques en `WORLD` et en `FR`), et `/etc/conf.d/wireless-regdom` est **inerte** —
aucun service ne le lit sur ce système, `wireless-regdom.service` n'existant pas.

### Ce qui ne marcherait pas non plus

Épingler `802-11-wireless.bssid` sur la borne. NM attend la **fin** du balayage avant même
d'évaluer l'auto-connexion — `scanning-state: idle` puis `auto-activating` dans la même
milliseconde. Le contenu du profil n'y change rien.

### Où chercher, si quelqu'un veut reprendre

Le verrou est que NM bloque son auto-connexion sur un balayage complet, et que le balayage
est passif faute d'un domaine réglementaire connu à ce moment-là. Deux angles, tous deux
en amont : faire qu'ath12k adopte le domaine réglementaire global au lieu du sien, ou
qu'NM évalue l'auto-connexion sur des résultats partiels. Rien ne se règle par
configuration.

**Le symptôme n'est pas grave** : le bureau ne l'attend pas, seuls les services réseau
arrivent tard. Documenté pour éviter de refaire les quatre tentatives ci-dessus.

## WiFi — déconnexions périodiques `reason=34`, et pourquoi ce n'était pas le réseau

Symptôme : la liaison tombait puis se rétablissait toutes les quarante minutes environ.
Mesuré sur un démarrage de référence : **8 coupures en 5 h 41**, soit 1,41 par heure.

### Lire le motif plutôt que supposer

Le journal de `wpa_supplicant` donne la réponse directement :

```bash
journalctl -b -u wpa_supplicant | grep -o "CTRL-EVENT-DISCONNECTED.*reason=[0-9]*"
```

Les huit coupures portaient **toutes** `reason=34` — `DISASSOC_LOW_ACK` dans la norme
IEEE 802.11 : *le point d'accès éjecte la station parce qu'il ne reçoit plus ses accusés de
réception*. C'est donc la borne qui coupe, mais pas parce que le réseau va mal.

Le signal était à **−46 dBm**, c'est-à-dire excellent. Une station à portée idéale qui cesse
d'acquitter, c'est une radio qui s'endort — pas une liaison qui faiblit.

### Deux suspects écartés avant de conclure

- **`sp12-wifi-watchdog`** : c'est un `Type=oneshot` lié à `multi-user.target`, donc il
  s'exécute une fois au démarrage et rien de plus. `systemctl is-active` le donne
  `inactive` en session, et il avait déclenché **0 fois** sur le démarrage étudié.
- **NetworkManager** : il *subit*. Le journal montre `supplicant interface state:
  disconnected -> scanning` **après** l'éjection, jamais avant. Il n'initie rien.

### Le correctif

Désactiver l'économie d'énergie WiFi, pour cette connexion seulement :

```bash
sudo nmcli connection modify "<connexion>" 802-11-wireless.powersave 2
sudo nmcli connection up "<connexion>"
```

Les valeurs sont `0` défaut, `1` ignorer, `2` désactiver, `3` activer. Le réglage est
persistant et survit aux redémarrages — vérifié sur deux reboots.

### Résultat, mesuré

| | |
|---|---|
| Avant | 1,41 coupure par heure |
| Attendu sur 93 h à ce rythme | **131** |
| Observé sur 93 h | **0** `reason=34` |
| Signal pendant l'observation | descendu à −63 dBm, sans effet |

Les seules déconnexions restantes sont des `reason=3` — la station qui part d'elle-même,
c'est-à-dire les extinctions avant redémarrage. Le résultat est d'autant plus net que le
signal était **plus faible** pendant l'observation qu'au moment du diagnostic.

⚠️ **Le coût énergétique n'a pas pu être mesuré, et il ne faut pas prétendre le contraire.**
L'ordre de grandeur attendu pour une puce moderne est de 0,1 à 0,3 W. Sur cette machine les
relevés de consommation s'échelonnaient sur ±1 W à cause d'un processus occupant un cœur
entier, soit cinq à dix fois le signal cherché. À comparer aux 0,9 W mesurés du passage
90 → 60 Hz, qui reste le levier dominant. Une coupure toutes les quarante minutes coûte de
toute façon plus cher en usage qu'un dixième de watt.

Script de contrôle : `verifier-wifi-stabilite.sh` (hors dépôt) classe les coupures par
motif et refuse de conclure avant deux heures d'observation.
