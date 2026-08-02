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
