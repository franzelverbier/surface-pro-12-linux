# Surface Pro 12 — Linux : HANDOFF (reprise de conversation)

> État au 2026-06-28. À coller/résumer au début d'une nouvelle conversation Claude pour reprendre le fil.
> **La machine de build = le Surface Pro 12 lui-même** (hostname `FRANZSURFACE12`, ARM64 Snapdragon X Plus **x1p42100**). Les artefacts de build (image 12 Go, environnement WSL) sont **uniquement sur ce Surface**, dans `C:\sp12-linux\` — pas synchronisés. La **clé USB**, elle, est autonome.

---

## 🟢 MISE À JOUR 2026-06-30 (soir) — LINUX SUR LE SanDisk 2 To, VIDÉOS PRÉSERVÉES

**Pivot décisif.** La SHARGE n'avait pas de Ventoy bootable (juste exFAT), et on ne peut pas réduire l'exFAT depuis Windows. Plan « tout sur la SHARGE » abandonné. **L'utilisateur a branché un 2e SSD : un SanDisk Portable SSD 2 To.**

- **Tentative de sauvegarde des vidéos (SHARGE F: → SanDisk D:) a ÉCHOUÉ** : le contrôleur USB du SP12 **fige sur une copie soutenue entre deux SSD USB simultanément** (burst ~13-22 Go puis blocage total, robocopy en I/O non-tuable). → Confirmé : **ne jamais faire d'I/O lourde sur 2 SSD USB en même temps** sur ce SP12.
- **Nouvelle archi (en place)** :
  - **SanDisk Portable SSD 2 To = disque Linux** 🐧 (image `sp12.img` 12 Go écrite en RAW dessus, 35 Mo/s, sans blocage car **un seul** SSD USB actif + lecture depuis l'interne).
  - **SHARGE 2 To (F:, exFAT « Ventoy ») = disque média, INTACT** (vidéos `Vidéos INP` 181 Go + `StreetParade` 175 Go conservées).
- **GPT « RAW » sous Windows = normal** (image 12 Go sur disque 2 To → en-tête GPT de secours pas en fin de disque). L'UEFI boote quand même (table primaire valide, 55AA OK) — comme la clé 114 Go avant. À corriger sous Linux : `sgdisk -e /dev/sdX` puis agrandir la racine (`parted resizepart` + `resize2fs`).
- **Boot** : éteindre Windows → UEFI (**Vol-Haut + Power**) → **Secure Boot OFF** → booter le **SanDisk**. (Conseil 1er boot : **débrancher la SHARGE**, ne garder que SanDisk + alim, pour la stabilité USB.) → WiFi WPA3 auto → `ssh root@<IP>` (mdp `sp12`) → `claude`.
- **Script d'écriture réutilisable** : `scratchpad/write-linux-sandisk.ps1` (cible le SanDisk par nom, refuse SHARGE/interne). Image source : `C:\sp12-linux\sp12.img`.
- **⚠️ 1er boot a ÉCHOUÉ (retour direct Windows) → CAUSE TROUVÉE : GPT malformée.** Écrire une image 12 Go en RAW sur un disque 2 To laisse l'en-tête GPT primaire qui décrit un disque de 12 Go (`AlternateLBA=25165823`, `LastUsableLBA=25165790`) au lieu du plein 2 To → **l'UEFI du SP12 rejette la table comme corrompue → le SanDisk n'apparaît PAS comme bootable**. (Contrairement à ce que je pensais, ce UEFI n'est PAS tolérant à ça.) **FIX = réparation GPT chirurgicale** : `scratchpad/repair-gpt.ps1` (réécrit en-tête primaire `AlternateLBA`/`LastUsableLBA` au plein disque + écrit en-tête+table de secours en fin de disque, CRC32 zlib recalculé, **auto-test CRC sur l'en-tête existant avant toute écriture**, ne touche pas les partitions/données). Après réparation : Windows lit Part1=ESP(EFI System)+Part2=Linux, `REPARATION REUSSIE`. **À refaire systématiquement après tout `dd`/raw-write d'une petite image sur un grand disque** (ou faire `sgdisk -e /dev/sdX` une fois sous Linux).

---

## 🔴 MISE À JOUR 2026-06-30 — 2 découvertes MAJEURES + nouvelle approche

**1. La clé SanDisk était DÉFAILLANTE.** Après v5→v10 (boots aléatoires, écrans noirs, « gels »), le log écran a révélé `systemd-journald: Input/output error` + `Journal file corrupted` → **erreurs d'I/O du stockage**. Ce n'était JAMAIS la config — la **SanDisk flash était marginale/morte** sur le contrôleur USB du SP12. Tout s'explique par là.

**2. Le WiFi est en WPA3-Personnel (SAE / GCMP-256).** Lu via `netsh wlan show profile` sous Windows. Ma config wpa était en `psk=` (WPA2) → ne s'associait jamais. **SSID exact = `<REDACTED>`** (sans « s »), mot de passe `<REDACTED>`. Fix wpa = `key_mgmt=SAE WPA-PSK` + `ieee80211w=1`.

**Nouvelle approche : SSD SHARGE 2 To (USB, FIABLE) avec Ventoy, NON destructif.**
- L'image est copiée en **fichier** `D:\sp12-linux.img` (12 Go) sur la partition Ventoy de la SHARGE (données existantes intactes : Adobe, ISO, etc.).
- Hook **`vtoyboot`** (aarch64) injecté dans l'initramfs (init **udev**, pas systemd) → l'image boote comme **vdisk Ventoy**.
- **Boot** : démarrer la SHARGE → menu Ventoy → choisir **`sp12-linux.img`**. (Si Ventoy dit « not contiguous » : recopier le fichier / défragmenter.)
- WiFi WPA3-SAE + SSH auto déjà dans l'image → au boot : se connecte au WiFi → `ssh root@<IP>` (mdp `sp12`) → `claude` (pré-installé).
- ⚠️ Écran : le panel SP12 a besoin de `msm` (capricieux). `nomodeset` = écran noir mais boote ; sans = parfois visible. Viser le **headless + SSH** (l'écran importe peu).

**Cmdline image actuelle** : `... console=tty0 loglevel=7` (= la v4 qui bootait visiblement) — sans `nomodeset`/`usbcore`/`regdom` (ces ajouts dégradaient).

**Reste à faire (au retour)** : booter la SHARGE via Ventoy → vérifier WiFi (routeur : `sp12` / MAC `XX:XX:XX:XX:XX:XX`) → SSH → `claude`. Puis : audio (topology), bureau, et à terme **install disque interne** pour une fiabilité totale.

---

## ✅ TL;DR — où on en est

On a **réussi à faire tourner Linux sur le Surface Pro 12** (que rien ne supportait) :
- Noyau **linux-next compilé maison** (`7.1.0-next-20260626`) avec le support **x1p42100** (absent des noyaux stables).
- Image bootable **v5** écrite sur une clé **SanDisk USB 114 Go** (raw `\\.\PhysicalDrive1`).
- **Boot OK → shell root**, écran/console **fonctionnels**, Bluetooth OK.
- **Claude Code v2.1.195 pré-installé** sur la clé, **SSH + réseau RJ45 automatiques**.

**Objectif en cours** : se connecter en SSH depuis une autre machine/téléphone, lancer `claude` sur la tablette, puis installer un **bureau graphique** et finir l'audio/WiFi.

---

## 🔌 Comment accéder à la tablette (clé v5)

1. **Booter la clé** sur le SP12 : éteindre, UEFI (**Volume-Haut + Power**), **Secure Boot OFF**, **USB en tête de boot**. Brancher le **RJ45** (réseau auto via dhcpcd).
   - ⚠️ Boot USB un peu **capricieux** (instabilité USB précoce Snapdragon) : si ça gèle ~30 s sur `qcom-rpmhpd ... sync_state`, **c'est normal, attendre** (la clé fait des I/O lentes, ça repart). Éviter de brancher trop de périphos USB *avant* le boot.
2. **Trouver l'IP** : appareil **`sp12`** dans le routeur, ou en console `ip -br addr`.
3. **SSH** depuis un autre appareil du réseau :
   ```
   ssh root@<IP_DU_SP12>
   ```
   **mot de passe : `sp12`**
4. Lancer **`claude`** (déjà installé). S'authentifier.

Helpers sur la clé : `/root/sp12-setup-gui.sh` (bureau Wayland sway), `/root/sp12-graft/` (audio/capteurs).

---

## 🧩 Détails techniques (image v5)

- **Noyau** : linux-next `7.1.0-next-20260626`, arm64 defconfig + activés en intégré :
  `CLK_X1P42100_GPUCC/CAMCC/VIDEOCC`, `CLK_X1E80100_GCC/DISPCC`, `PINCTRL_X1E80100`. `DRM_MSM`, `ATH12K` en module.
- **DTB** : celui de **harrison** (`github.com/harrisonvanderbyl/surface-pro-12-inch-linux`), `boot/dtb` (196 Ko) — le board SP12 n'est pas encore upstream. Chargé par GRUB (`devicetree`, module `fdt`).
- **Rootfs** : Arch Linux ARM aarch64 + modules + firmware (linux-firmware + qcom/ath12k de harrison).
- **Image** : GPT 12 Go = ESP FAT (`SP12ESP`, GRUB autonome `grub-mkstandalone -O arm64-efi`) + ext4 (`SP12ROOT`). Persistante (les modifs restent).
- **cmdline** : `root=LABEL=SP12ROOT rw rootwait clk_ignore_unused pd_ignore_unused console=tty0 loglevel=7 usbcore.autosuspend=-1`
- **WiFi** : `board.bin` de repli généré (ath12k réclame `00ab/1414/255`, absent du `board-2.bin` → fallback). `wlan0` apparaît.
- **Services auto** : `sshd`, `dhcpcd`. `iwd` **désactivé** (voir problème connu).

---

## ⚠️ Problèmes connus / prochaines étapes

1. **WiFi (iwd) ne démarre pas** : notre noyau (defconfig) **manque** `CONFIG_KEY_DH_OPERATIONS`, `CONFIG_CRYPTO_USER_API_SKCIPHER`, `CONFIG_CRYPTO_USER_API_HASH` qu'**iwd exige**.
   → **Fix** : soit recompiler le noyau avec ces options, soit utiliser **`wpa_supplicant`** (crypto en userspace, pas besoin de ces options) à la place d'iwd. En attendant, **réseau par RJ45**.
2. **Audio KO** : firmware topology manquant (`qcom/x1e80100/X1P42100-Microsoft-Surface-Pro-12in-tplg.bin` et `qcvss8380_pa.mbn` du codec iris). Spammait la console → réglé en laissant les drivers échouer *gentiment* (pas de blacklist : la blacklist d'`qcom_iris` **fige le boot** via sync_state — NE PAS blacklister iris). À terme : build AudioReach topology (`/root/sp12-graft/installaudio-arch.sh`, à adapter pacman).
3. **Pas de bureau** : console only. → `/root/sp12-setup-gui.sh` (sway/mesa Freedreno) ou installer KDE/GNOME via pacman.
4. **Boot USB capricieux** : instabilité USB précoce. `usbcore.autosuspend=-1` ajouté ; à creuser si ça persiste.
5. **CachyOS** : pas un raccourci (mêmes obstacles matériels) → plutôt ajouter un bureau à cette install Arch.

---

## 🛠️ Refabriquer / réécrire l'image (depuis CE Surface uniquement)

Tout est dans `C:\sp12-linux\` sur le Surface :
- `sp12.img` (12 Go, image v5), `build.log`, scripts `build-stageN*.sh`, `graft/` (DTB+firmware+scripts).
- Env de build : **WSL Ubuntu-24.04** (`wsl -d Ubuntu-24.04 -u root`), source noyau dans `/root/linux-next`, rootfs dans `/root/sp12/rootfs`, image `/root/sp12/sp12.img`.

**Écrire l'image sur la clé** (`wsl --mount` indisponible sur Win ARM64 build 26300 ; clé amovible non « offline-able ») :
```
diskpart: select disk 1 / clean   (vérifier d'abord que disk 1 = SanDisk USB !)
puis FileStream raw write de C:\sp12-linux\sp12.img vers \\.\PhysicalDrive1 (blocs 4 Mo)
```
→ script prêt : `C:\sp12-linux\write-usb3.ps1` (élevé, UAC).

**Lire les logs de l'ESP** (clé amovible, pas de lettre possible) : dump raw de la partition 1 → `mtools` (`C:\sp12-linux\dump-esp.ps1` + `extract-logs.sh`). WSL **n'a pas vfat** (ext4 OK seulement).

**Modifier le rootfs** : monter l'ext4 de l'image dans WSL (`losetup -fP sp12.img` ; `mount ...p2`), chroot aarch64 natif pour pacman/npm (DNS : `/etc/resolv.conf` est un symlink → écrire `nameserver 10.255.255.254` ; `SigLevel=Never` pour zapper le keyring).

---

## 📌 Mémo identité matériel
- Modèle : *Microsoft Surface Pro 12in 1st Ed with Snapdragon* — **Snapdragon X Plus 8 cœurs = x1p42100**, ARM64.
- WiFi : Qualcomm **FastConnect 7800 / WCN7850** — SSID PCI `subsystem-vendor=00ab, subsystem-device=1414`.
- Disque interne : KIOXIA UFS ~477 Go (Windows). La clé Linux = SanDisk USB (disque 1).
- Linux 7.2 (qui intègre le DTS SP12 en mainline) : rc1 ~28 juin 2026 → à terme, plus besoin du DTB harrison ni de compiler.
