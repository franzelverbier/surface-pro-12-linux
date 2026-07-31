# Configuration système

Ce qui vit hors du noyau : unités systemd, listes noires de modules, menu de démarrage.
C'est ici que se trouvent la plupart des contournements — le noyau seul ne suffit pas à
faire tourner cette machine.

| Chemin | Rôle |
|---|---|
| `grub.cfg` | menu de référence, 9 entrées (EL1, secours, EL2/KVM, EL2 + audio) |
| `config-running-*.gz` | `.config` du noyau de référence |
| `systemd/` | services SP12 et leurs drop-ins |
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

## `modules-load.d/cdrecord.conf`

Surcharge vide masquant `/usr/lib/modules-load.d/cdrecord.conf`, qui réclame le module
SCSI générique `sg`. `CONFIG_CHR_DEV_SG` n'est pas construit et la machine n'a pas de
lecteur optique : la demande échouait à chaque démarrage.
