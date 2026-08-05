# Configuration système

Ce qui vit hors du noyau : unités systemd, listes noires de modules, menu de démarrage.
C'est ici que se trouvent la plupart des contournements — le noyau seul ne suffit pas à
faire tourner cette machine.

| Chemin | Rôle |
|---|---|
| `grub.cfg` | menu de référence, 6 entrées (EL2+audio par défaut, repli EL2, EL1, Rescue, ramoops, Shell UEFI) |
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
alors qu'elle se noyait dans le bruit. Les entrées « verbeux / debug » et « Rescue »
gardent `loglevel=7`.

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

`pstore` n'a jamais été affecté — il tourne depuis le code intégré :

```
[    0.019995] pstore: Registered ramoops as persistent store backend
```

Correctif appliqué : les deux `.ko` renommés en `*.etranger-inutilisable`, puis
`sudo depmod -a`. `grep -c "reed_solomon\|ramoops" /lib/modules/$(uname -r)/modules.dep`
doit alors renvoyer 0.

⚠️ **Le réflexe général** : devant un module qui se comporte mal, vérifier d'abord d'où
vient le binaire — `strings … | grep GCC:` — avant de raisonner sur les sources. Sur cette
machine, une partie de `/lib/modules` provient d'un arbre qui n'existe plus.

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
