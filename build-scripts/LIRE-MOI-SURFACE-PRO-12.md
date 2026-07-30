# Clé d'installation Linux — Surface Pro 12" Gen 1 (Snapdragon X Plus / X1P42100)

> Clé préparée le 2026-06-26. Base : **archboot aarch64** (installeur Arch Linux UEFI) sur **Ventoy 1.1.16 (ARM64)**.
> Greffe matérielle Pro 12 incluse (DTB + firmware qcom + scripts) depuis
> https://github.com/harrisonvanderbyl/surface-pro-12-inch-linux

---

## ⚠️ AVANT TOUT — la machine cible EST ce Surface Pro 12

Le dual-boot se fera sur le **disque interne UFS (KIOXIA ~477 Go)** de CETTE tablette.
Ne saute PAS la Phase 0 :

- [ ] **Image système Windows complète** sur disque externe
- [ ] **Clé de récupération BitLocker** sauvegardée (compte Microsoft) — vérifie : `manage-bde -protectors -get C:`
- [ ] **Suspendre/désactiver BitLocker** avant toute modif de partition ou de Secure Boot
      (`manage-bde -protectors -disable C:`), sinon invite de clé voire verrouillage
- [ ] Réduire la partition Windows depuis **Gestion des disques Windows** (pas depuis Linux)
- [ ] Ne PAS toucher à l'ESP ni aux partitions de récupération
- [x] WiFi : **plus besoin** d'adaptateur Ethernet — `fixwifi-arch.sh` est désormais
      **offline** (firmware embarqué sur la clé). Un adaptateur USB-C Ethernet reste un
      filet utile si le WiFi résiste, mais n'est plus indispensable au démarrage.

---

## 1. Contenu de la clé

```
D:\  (partition Ventoy, exFAT)
├── archboot-2026.06.26-aarch64-local.iso   <- installeur Arch aarch64 (hors-ligne)
├── LIRE-MOI-SURFACE-PRO-12.md              <- ce fichier
└── surface-pro-12-graft\                    <- la greffe Pro 12
    ├── boot\dtb                  <- Device Tree X1P42100 (a pointer dans GRUB)
    ├── lib\firmware\qcom\...      <- firmware DSP/GPU (x1p42100 + Adreno gen71500_*)
    ├── lib\firmware\ath12k\WCN7850\hw2.0\  <- firmware WiFi (amss/m3/board-2.bin) [OFFLINE]
    ├── usr\...                    <- donnees plateforme (sensors)
    ├── ath12k-bdencoder           <- extracteur board file (pour fixwifi offline)
    ├── vendor\                    <- audioreach-topology, hexagonrpc, iio-sensor-proxy (offline)
    ├── fixwifi-arch.sh            <- WiFi Arch + OFFLINE
    ├── setup-keyboard-frch.sh     <- clavier Suisse romand (fr-CH)
    ├── installaudio-arch.sh       <- audio Arch
    ├── installsensors-arch.sh     <- capteurs Arch
    ├── LISEZMOI-ARCH.md           <- ordre d'execution + traductions apt->pacman
    ├── fixwifi.sh / installaudio.sh / installsensors.sh / wireupcameras.sh  <- originaux (Ubuntu)
    └── readme.md                  <- readme original du depot
```

## 2. Entrer dans l'UEFI Surface

1. Éteindre complètement, attendre ~10 s.
2. Maintenir **Volume-Haut**, appuyer/relâcher **Power**, garder Volume-Haut jusqu'à l'UEFI.
3. **Désactiver Secure Boot** (l'avertissement est normal : noyau non signé).
4. Mettre l'**USB en tête de priorité de boot**.
5. (Conseil du dépôt) activer la **limite de charge batterie** dans l'UEFI.

## 3. Démarrer l'installeur

- Booter sur la clé -> le menu **Ventoy** s'affiche (c'est le seul menu qui répond bien au
  clavier sur ces Surface — d'où Ventoy plutôt que Rufus/Etcher).
- Choisir l'ISO **archboot ... aarch64-local.iso**.

> ⚠️ **Risque connu de boucle de boot.** archboot utilise un noyau Arch *mainline* qui ne
> contient pas forcément le support X1P42100. Si l'écran reboucle après quelques
> secondes (symptôme « pas de DTB »), c'est attendu : voir §6 (injection DTB au boot) ou
> bascule sur une autre base. **Le boot live n'est PAS garanti — c'est l'étape à tester.**
> En revanche, la greffe §4 sur le système installé, elle, est la partie fiable.

## 4. Greffe Pro 12 sur le système installé  -- coeur fiable, agnostique distro

Une fois une base Arch installée (ou tout système aarch64), monter la clé puis :

```sh
# 0) Passer sur un noyau linux-next recent (le DTB suppose linux-next ; cf. readme du depot)
#    -> sur Arch : paquet linux-next AUR, ou compilation. Garder un noyau de repli.

GRAFT=/run/media/$USER/Ventoy/surface-pro-12-graft   # adapter le point de montage

# 1) DTB
sudo cp "$GRAFT/boot/dtb" /boot/dtb

# 2) GRUB : pointer le devicetree
#    Ajouter dans l'entree de boot (ou via une entree custom) :
#        devicetree /boot/dtb
#    Sur Arch/GRUB : editer /etc/grub.d/40_custom ou l'entree generee, puis
sudo grub-mkconfig -o /boot/grub/grub.cfg
#    Verifier que la ligne `devicetree /boot/dtb` est bien presente dans /boot/grub/grub.cfg

# 3) Firmware qcom (recursif)
sudo cp -r "$GRAFT/lib/." /lib/

# 4) Reboot
sudo reboot
```

## 5. Scripts — versions Arch + OFFLINE fournies  ⭐

> **Le plus simple : `bash autoexec-sp12.sh`** — orchestrateur tout-en-un, idempotent,
> à relancer après chaque reboot (firmware+DTB, bootloader, clavier, WiFi, audio, capteurs).
> Détail + lancement manuel pas-à-pas dans **`LISEZMOI-ARCH.md`**.
>
> Les `*.sh` d'origine supposaient **Ubuntu/apt** ; des versions **Arch + hors-ligne** ont été
> ajoutées. Comme ton **seul** accès réseau sera le WiFi, l'ordre (manuel) est :

1. **`fixwifi-arch.sh`** — WiFi, **100 % OFFLINE**. Le firmware WCN7850 (`amss/m3/board-2.bin`)
   et l'extracteur `ath12k-bdencoder` sont **pré-stockés sur la clé** ; aucun réseau requis.
   Auto-détecte le board-id via `dmesg`, repli SP11 (`board-id=255`, vérifié présent) sinon.
   ```sh
   cd .../surface-pro-12-graft && bash fixwifi-arch.sh && sudo reboot
   # puis : nmcli device wifi connect "<SSID>" password "<pass>"   (ou iwctl)
   ```
2. **`setup-keyboard-frch.sh`** — clavier **Suisse romand (fr-CH)**, OFFLINE. Configure la
   console (`KEYMAP=fr_CH`) ET X11/Wayland (`XkbLayout=ch`, `XkbVariant=fr`).
3. *(WiFi monté)* **`installaudio-arch.sh`** puis **`installsensors-arch.sh`** — réseau requis
   (pacman + build ; dépôts aussi pré-clonés dans `vendor/` en repli offline).
   - 🔊 Audio : si pas de son et `sudo dmesg | grep clsh` dit **`bus clsh`** → `alsamixer`,
     **mute `SpkrLeft CPS` et `SpkrRight CPS`**, reboot.
- **`wireupcameras.sh`** — config caméra via `media-ctl` (runtime, pas d'apt). ⚠️ patches
  caméras encore « in flux » côté kernel — **ne pas en dépendre**.

> **Clavier dans le live archboot** : 1ʳᵉ commande = `loadkeys fr_CH` (ou `loadkeys ch-fr`).
> Le menu Ventoy/GRUB reste en QWERTY US (inévitable, n'affecte que la navigation du menu).

## 6. Si l'installeur boucle (pas de DTB au boot live)

Pistes, par ordre de simplicité :
1. Dans le menu **GRUB de l'ISO** (touche `c` pour la console, ou `e` sur l'entrée), charger
   le DTB avant le noyau : `devicetree (hdX,Y)/surface-pro-12-graft/boot/dtb` puis `boot`.
   (Le chemin dépend de la détection Ventoy ; tâtonner avec `ls`.)
2. Essayer une base dont le noyau gère déjà X1P (Ubuntu 25.10 aarch64 en secours), puis
   greffer §4.
3. Suivre l'upstreaming : le travail **DT-ACPI hybride** (Hans de Goede, Qualcomm) vise un
   boot ACPI-only qui rendrait ce DTB manuel inutile — exactement cette machine.

## 7. Durabilité

- Garder une **entrée GRUB de repli** sur un noyau connu-bon (linux-next peut casser le DTB
  ou un pilote à une mise à jour).
- Après chaque grosse maj firmware Surface depuis Windows : revérifier que **Secure Boot**
  ne s'est pas réactivé.
- Surveiller https://github.com/harrisonvanderbyl/surface-pro-12-inch-linux (upstream + ISO).

## 8. État matériel déclaré (dépôt, juin 2026)

Clavier/Touchpad/Lid OK · Tactile OK · Backlight OK · GPU OK (mesa 25.3.0) · Stylet OK ·
WiFi OK (fixwifi.sh) · BT OK · HP OK · Suspend OK · UFS OK · Batterie/boutons OK ·
ADSP/CDSP OK · Caméras OK (patches en flux) · **Hibernation : inconnue**.

---
*Sources : dépôt harrison (readme.md inclus dans surface-pro-12-graft\), linux-surface #1962.*
