# SP12 — État des drivers & chemin vers l'ISO (2026-07-02)

> ✅ **MISE À JOUR : écran ET audio confirmés fonctionnels le 2026-07-02.** Le SP12 tourne sur le **SSD 1,8 To** (`0781:55bb`), noyau `-next`, systemd 260, 0 service en échec, Tailscale connecté.

## 🎯 Découverte majeure : le dépôt `sp12-graft` est un portage quasi complet

`/root/sp12-graft/` (sur le SP12) = le dépôt de **harrisonvanderbyl/surface-pro-12-inch-linux**, celui qui fournit déjà notre DTB. Son propre README affiche :

| Hardware | État (harrison) |
|---|---|
| Clavier, Touchpad, Lid, Écran tactile, Backlight | ✓ |
| **GPU** | ✓ (mesa 25.3.0) |
| Pen | ✓ |
| WiFi | ✓ |
| Bluetooth | ✓ |
| **Haut-parleurs** | ✓ |
| Veille | ✓ |
| UFS (disque interne) | ✓ |
| Batterie, Boutons | ✓ |
| ADSP/CDSP | ✓ |
| Caméras | ✓ |

**Tâches restantes listées par l'auteur amont : "1) needs to be upstreamed 2) create iso"** — exactement l'objectif visé ici.

Le dossier contient un script maître **`autoexec-sp12.sh`**, idempotent et prudent (aucune opération de partition, sauvegarde le bootloader), conçu pour être **relancé depuis la tablette elle-même** après chaque boot tant qu'il n'a pas tout réussi. Il gère : copie firmware+DTB, câblage GRUB/systemd-boot du devicetree, clavier fr-CH, WiFi offline, audio+capteurs (ces deux derniers nécessitant réseau + DTB actif).

**⚠️ Ce script n'a JAMAIS été exécuté** sur l'image actuelle (`/var/lib/sp12-setup/` absent) — seuls les *fichiers* ont été copiés en dur pendant le build (stage4c/6a), pas la logique d'installation.

## 🖥️ Écran (msm_dpu / GPU Adreno) — ✅ RÉSOLU (validé par cold boot)

**Cause exacte identifiée** (pas un "pilote capricieux" — un vrai bug de format) :
- Les firmwares GPU (`gen71500_sqe.fw`, `gen71500_gmu.bin`, `gen71500_zap.mbn`) sont présents dans `/usr/lib/firmware/qcom/` mais **compressés en `.zst`**.
- Ce noyau custom (`7.1.0-next-20260626`) **n'a PAS `CONFIG_FW_LOADER_COMPRESS`** → il ne sait pas les décompresser à la volée → `Direct firmware load for qcom/gen71500_sqe.fw failed with error -2`.

**Fix appliqué (2026-07-02, persisté sur le SSD 1,8 To)** :
```bash
cd /usr/lib/firmware/qcom
zstd -d gen71500_sqe.fw.zst -o gen71500_sqe.fw
zstd -d gen71500_gmu.bin.zst -o gen71500_gmu.bin
zstd -d gen71500_zap.mbn.zst -o gen71500_zap.mbn
```

**✅ VALIDÉ sur cold boot réel** (dmesg du boot confirmé) :
```
[7.314497] msm_dpu: loaded qcom/gen71500_sqe.fw from new location
[7.315072] msm_dpu: loaded qcom/gen71500_gmu.bin from new location
[8.939074] msm_dpu ae01000.display-controller: [drm] fb0: msmdrmfb frame buffer device
```
`msmdrmfb` = le vrai framebuffer accéléré (a remplacé le `efifb` de base qu'on voyait avant sur toutes les captures d'écran). Utilisateur confirme : écran allumé avec logs de démarrage visibles.

**Pour les futurs builds noyau** : activer `CONFIG_FW_LOADER_COMPRESS=y` dans le `.config` (`/root/linux-next/.config`) pour que ce problème ne se reproduise plus.

## 🔊 Audio — ✅ RÉSOLU (carte + lecture PCM confirmées, sans reboot)

- `vendor/audioreach-topology` pré-cloné en local dans la greffe → compilé offline avec `cmake`/`make`/`make install` via `installaudio-arch.sh`.
- Dépendances installées avec supervision (2026-07-02) : `pacman -Syu --needed base-devel cmake alsa-ucm-conf alsa-utils` — **préconditions vérifiées d'abord** (DNS OK, 7,2 Go libres, `SigLevel=Never`, `IgnorePkg` protège noyau+systemd). Aucune casse : `/boot/Image` et `grub.cfg` inchangés après coup (vérifié).
- Le build a installé **tous** les fichiers topologie de `audioreach-topology`, dont exactement le nôtre : `/lib/firmware/qcom/x1e80100/X1P42100-Microsoft-Surface-Pro-12in-tplg.bin`.
- **Rechargement à chaud du module** (`modprobe -r/modprobe snd_soc_x1e80100`, sans reboot) → carte son **`X1P42100Microso`** instanciée avec succès (visible dans `/proc/asound/cards`, `aplay -l`), jack casque détecté, contrôles mixer WSA884x présents (`SpkrLeft/Right BOOST/COMP/CPS/DAC/PA...`).
- **Lecture PCM testée et confirmée** : `aplay -D plughw:1,0 ...` a ouvert le flux et joué sans erreur (nécessitait d'abord activer le profil UCM : `alsaucm -c x1e80100 set _verb HiFi` — sans ça, erreur *"no backend DAIs enabled... missing UCM profile"*).
- **Persistance au boot** : service `sp12-audio-ucm.service` créé et activé (`ExecStart=alsaucm -c x1e80100 set _verb HiFi`), testé en live (exit 0). Le profil sera donc appliqué automatiquement à chaque démarrage, plus besoin de le faire à la main.

## ⌨️ Type Cover (clavier + trackpad) — CAUSE TROUVÉE, nécessite une recompilation noyau

**Ce n'est PAS un problème d'attache physique ni de hotplug.** Le Type Cover sur les Surface récentes ne communique pas en USB HID classique — il passe par le **Surface Aggregator Module (SAM)**, protocole série propriétaire Microsoft. Notre `.config` noyau (`linux-next-config-20260626`) a bien `CONFIG_SERIAL_DEV_BUS=y` mais **`CONFIG_SURFACE_AGGREGATOR` est complètement absent** (`# not set`) → aucune des couches qui en dépendent n'existe.

**Chaîne de dépendances complète à activer** (confirmée via le Kconfig officiel du noyau) :
```
CONFIG_SURFACE_AGGREGATOR=y              # cœur du driver SAM
CONFIG_SURFACE_AGGREGATOR_BUS=y
CONFIG_SURFACE_AGGREGATOR_REGISTRY=y     # provisionne les devices HID
CONFIG_SURFACE_HID=y                     # transport HID clavier+trackpad ("integrated touchpad and keyboard, 7th-gen Surface")
CONFIG_SURFACE_AGGREGATOR_HUB=y          # gère le hub des périphériques détachables (Surface Pro 8/X)
CONFIG_SURFACE_AGGREGATOR_TABLET_SWITCH  # optionnel : détection mode tablette
```
Source : [drivers/platform/surface/Kconfig](https://github.com/torvalds/linux/blob/master/drivers/platform/surface/Kconfig), [drivers/hid/surface-hid/Kconfig](https://github.com/torvalds/linux/blob/master/drivers/hid/surface-hid/Kconfig).

**Ce que l'écran tactile Elan (`hid-over-i2c 04F3:4377`) qu'on voit dans `/proc/bus/input/devices` N'EST PAS** : c'est le digitizer écran + stylet, câblé en I2C direct sur la carte mère — totalement indépendant du Type Cover. Zéro événement mesuré sur ses 8 canaux pendant un test de frappe/trackpad confirme qu'aucun device SAM n'est actif.

**➡️ Nécessite une vraie recompilation** (~1h, comme documenté) avec ces options ajoutées au `.config` dans `/root/linux-next` (WSL). Pas de fix à chaud possible cette fois.

**✅ RECOMPILÉ le 2026-07-02 :**
- Vérifié d'abord que le DTB de harrison contient bien le nœud requis : `compatible = "microsoft,surface-sam"` sous un `qcom,geni-uart` actif (`status = "okay"`) — donc le driver aurait bien quelque chose à quoi se lier.
- Monté `C:\` en écriture (bloqué une première fois par l'hibernation Windows/démarrage rapide — corrigé en désactivant le démarrage rapide côté Windows), puis le `.vhdx` WSL via `qemu-nbd -c /dev/nbd0` en lecture-écriture.
- Options activées via `scripts/config` + `make olddefconfig` : `SURFACE_AGGREGATOR`, `SURFACE_AGGREGATOR_BUS`, `SURFACE_AGGREGATOR_REGISTRY`, `SURFACE_AGGREGATOR_HUB`, `SURFACE_HID`, `SURFACE_AGGREGATOR_TABLET_SWITCH` — toutes en `=y` (intégré, pas de module séparé).
- Build natif aarch64 (chroot dans le rootfs WSL Ubuntu, même architecture que le SP12) : `make -j8 Image modules`, ~13 400 lignes de log, exit 0.
- **Vérifié dans `System.map`** : tous les symboles `surface_hid_*` (probe, open, close, suspend, resume...) bien présents dans le noyau compilé.
- Déployé sur le système actif : `/boot/Image` remplacé (ancien sauvegardé en `Image.bak-avant-surface-aggregator`), modules installés via `make INSTALL_MOD_PATH=<bind-mount de /> modules_install` (1651 fichiers), initramfs régénéré (blacklist UAS toujours embarqué, vérifié).

**❌ ÉCHEC AU BOOT — noyau SA restauré (2026-07-02 après-midi).** Le noyau avec `SURFACE_AGGREGATOR=y` **casse le boot** : 4 cold boots consécutifs morts (journaux s'arrêtant après ~930-980 lignes = quelques secondes, réseau jamais monté, écran figé sur curseur puis plus rien). Fausses pistes éliminées au passage (une variable à la fois) : retrait `usbcore.autosuspend=-1` → échec ; sans Type Cover → échec ; `dwc3.maximum_speed=high` en cmdline → **ignoré** (dwc3 compilé en dur, param module inopérant) ; `maximum-speed = "high-speed"` dans le DTB → écran totalement noir (pire). **Restauration complète de l'état connu-bon** (Image + initramfs + DTB + modules + cmdline depuis les `.bak`) → **premier cold boot OK immédiat** (0 échec, 0 -EIO, son + WiFi) → coupable confirmé par élimination : le noyau SA.

**Hypothèse cause** : `SURFACE_AGGREGATOR=y` (intégré) s'initialise très tôt, s'attache au nœud `embedded-controller` (`microsoft,surface-sam`) du DTB et bloque/plante pendant le boot (EC qui ne répond pas comme attendu, ou conflit avec la console geni-uart).

**➡️ Prochaine tentative clavier — méthode sûre : recompiler avec `SURFACE_AGGREGATOR=m` (et toute la chaîne en `=m`)**, pas `=y`. Les modules ne se chargent pas au boot → système démarre normalement → on charge `modprobe surface_aggregator` À LA MAIN via SSH sur système vivant → si ça plante, on le voit dans dmesg en direct au lieu de tuer le boot, et un simple reboot sans le module suffit à récupérer. Leçon générale : **tout driver expérimental sur cette machine doit être en module, jamais intégré.**

## ⌨️ Type Cover — ✅ RÉSOLU (2026-07-02 soir)

**Passe 1 (modules `=m`) :** chaîne SAM chargée à la main → EC répond (fw 14.103.139), clavier+touchpad détectés → **crash à la première frappe**. Indice clé dans le dmesg : « Microsoft Surface **POS** Tablet Mode Switch ».

**Passe 2 — la cause, trouvée dans les archives git de harrison :** son repo a eu un dossier `/patches` (commits "add forward patches" → "remove patches") récupéré au commit `52eab23f794a` et **archivé ici dans `patches-harrison/`**. Le patch `0001` (registre SAM testé "Keyboard ✓") **diffère de ce qui a été intégré dans linux-next 20260626** sur 3 nœuds du groupe `ssam_node_group_sp12in[]` :
| Nœud | Harrison (testé ✓) | Upstream (crashait) |
|---|---|---|
| penstash | `hid_kip_penstash` | `hid_sam_penstash` |
| capteurs | `hid_sam_sensors` présent | absent |
| tablet switch | `kip_tablet_switch` | `pos_tablet_switch` |

**Fix :** groupe remis à la version harrison dans `surface_aggregator_registry.c` (commit local dans le WSL `/root/linux-next`), module recompilé → installé dans `/usr/lib/modules/7.1.0-next-20260626/updates/`. ⚠️ Le `.ko` a le **vermagic patché en binaire** (NUL-pad, l'arbre git ayant bougé) + **BTF strippé** — à refaire proprement à la prochaine recompilation complète. Signature du succès : « Microsoft Surface **KIP** Tablet Mode Switch ». **Clavier + touchpad fonctionnels à la frappe, stable.**

**Persistance :** `sp12-typecover.service` (oneshot, `After=multi-user.target`) charge la chaîne en fin de boot ; le blacklist early-boot (`blacklist-surface-sam.conf`) **reste en place** (sécurité : le chargement précoce crashait le boot).

## 🖥️ KDE Plasma + crashs idle — RÉSOLU (2026-07-02 soir)

**Symptôme :** après l'installation de KDE (536 paquets, Plasma 6.7.2 + SDDM + Mesa 26.1), crashs/reboots spontanés systématiques à **5-7 min d'inactivité au greeter SDDM**. Une session active ne crashait pas.

**Cause (confirmée par A/B)** : la **mise en veille de l'écran (DPMS)** après idle → chemin de suspend du GPU/GMU (`msm`/Adreno) → crash du SoC entier (reset watchdog, aucun log persisté — capturé grâce au pattern d'uptime). Console pure (jamais de blanking) = stable ; greeter avec DPMS = mort à 5-7 min ; greeter avec DPMS désactivé = **26 min idle sans crash**.

**Fix appliqué (à graver dans toute image future) :**
- `/etc/X11/xorg.conf.d/10-no-blank.conf` : `ServerFlags` Blank/Standby/Suspend/OffTime = 0 + `Extensions` `DPMS Disable`
- `~alarm/.config/powerdevilrc` : `TurnOffDisplayIdleTimeoutSec=-1`, `DimDisplayWhenIdle=false` (AC/Battery/LowBattery)
- `~alarm/.config/kscreenlockerrc` : `Autolock=false`, `LockOnResume=false`
- Règle : **rien ne doit jamais éteindre le panneau** sur ce DTB (complète l'anti-veille système déjà en place).

**Résiduel bénin :** erreurs GMU HFI dans dmesg (`HFI_H2F_MSG_GX_BW_PERF_VOTE timed out`) — la gestion de perf GPU reste fragile mais sans conséquence tant que l'écran ne s'éteint pas.

**Aussi fait :** partition agrandie **en ligne** 12 Go → 1,8 To (GPT déjà saine ; `parted resizepart 2 100%` + `resize2fs` à chaud, zéro erreur). Locale `fr_CH.UTF-8` + clavier `ch-fr` (console + X11 + KDE). Service **`crash-capture`** (dmesg → ESP avec sync/ligne) actif en permanence.

## 🎥 Vidéo (codec Iris, `qcvss8380_pa.mbn`)

**Non couvert par la greffe harrison** (absent de `vendor/`, pas dans le README de statut) — probablement pas prioritaire (décodage matériel, pas l'affichage). À investiguer séparément si besoin un jour ; sans conséquence sur l'objectif écran/audio/ISO.

## 🗺️ Chemin vers une ISO installable

Le README amont confirme que c'est un objectif reconnu mais non abouti même côté harrison ("create iso" listé comme restant). Étapes réalistes :

1. ~~Court terme : valider le fix écran, puis construire l'audio.~~ **✅ FAIT (2026-07-02)** — écran + audio confirmés, système de référence complet (écran + audio + réseau + SSH + Tailscale).
2. **Prochaine étape : figer cette référence.** Backup complet déjà pris (`~/sp12-backups/20260702-*-ecran-ET-audio-fonctionnels/`, rootfs `tar.zst`). Reste à en faire une **image disque bootable propre** (comme `sp12.img`, mais avec écran+audio), à documenter comme "v11".
3. **Construire un vrai installeur** à partir de cette référence : ce n'est plus un `dd` d'image figée, il faut un environnement d'amorçage (type `archboot` déjà téléchargé, ou un initramfs custom) qui partitionne le disque cible (interne UFS ou USB), copie le rootfs, installe GRUB avec le bon DTB/cmdline, configure WiFi/utilisateur en interactif. C'est un projet à part entière, mais la **base matérielle est enfin stable et complète** pour s'y attaquer.
4. **Moyen terme (fin août 2026)** : Linux 7.2 stable intègre le DTS SP12 en mainline → simplifie radicalement l'ISO (plus de DTB harrison à charger séparément, potentiellement plus de firmware `.zst` custom si les blobs sont packagés officiellement dans `linux-firmware`).

## 📌 Repères techniques (état au 2026-07-02, fin de session)
| | |
|---|---|
| Écran | ✅ RÉSOLU — décompression `.zst` GPU, validé cold boot, `msmdrmfb` actif |
| Audio | ✅ RÉSOLU — topologie compilée+installée, carte + lecture PCM confirmées, `sp12-audio-ucm.service` pour persistance au boot |
| Vidéo (Iris codec) | ❌ toujours KO, non couvert par la greffe, non prioritaire |
| Backups versionnés | `~/sp12-backups/` sur CachyOS (hors OneDrive), script `scripts/backup-sp12.sh`, snapshot post-fix pris |
| Script graft | `/root/sp12-graft/autoexec-sp12.sh` — toujours jamais exécuté dans son ensemble (clavier fr-CH, capteurs restent à faire si besoin) |
| Système | 0 service en échec, noyau `-next` + systemd 260 protégés par `IgnorePkg`, quirk UAS actif (SSD 1,8 To stable) |
