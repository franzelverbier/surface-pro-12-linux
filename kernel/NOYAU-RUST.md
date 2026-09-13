# Un noyau avec Rust, à côté de celui qui tourne

> Fait le 2026-09-13. Entrée GRUB 6, `7.1.0-next-20260626-rust`.
> **Ce noyau n'apporte rien au reste du projet** : il n'y a aucun pilote Rust dans les
> chemins qui nous concernent. Il est là pour expérimenter.

## Ce qu'il fallait installer

`make rustavailable` dit exactement ce qui manque. Ici, trois paquets :

| paquet | version | pourquoi |
|---|---|---|
| `rust-bindgen` | 0.73.2 | le noyau exige ≥ 0.71.1 (`scripts/min-tool-version.sh`) |
| `rust-src` | 1:1.98.1-1 | la source de `core`, absente du paquet `rust` |
| `clang` | 22.1.8-1 | dépendance de bindgen ; s'accorde avec `llvm-libs 22.1.8-2` |

`rustc` 1.98.1 était déjà là, et le minimum de ce noyau est 1.85.0 — pas de contrainte
de version haute. **Aucun paquet retenu (`IgnorePkg`) n'a été touché** : vérifié par
`pacman -S --print-format` avant d'installer.

    Rust is available!

## ⚠️ Ne pas bâtir dans l'arbre en service

`make O=<ailleurs>` est **refusé** sur un arbre déjà bâti en place :

    *** The source tree is not clean, please run 'make mrproper'

Et `mrproper` détruirait la capacité à produire des modules pour le noyau courant —
c'est cet arbre qui a fabriqué `rtc-pm8xxx.ko`, `ip_tables.ko` et le module PHY
instrumenté. **Copier l'arbre** (8,7 Go, 50 s) et bâtir dans la copie :

```bash
cp -a /home/franz/sp12-kernel-rebuild/linux-next /data/linux-next-rust
cd /data/linux-next-rust
./scripts/config --set-str LOCALVERSION "-rust" --enable RUST \
                 --enable SAMPLES --enable SAMPLES_RUST \
                 --module SAMPLE_RUST_MINIMAL --module SAMPLE_RUST_PRINT
make olddefconfig
make -j8 KERNELRELEASE=7.1.0-next-20260626-rust Image modules
sudo make -j8 KERNELRELEASE=7.1.0-next-20260626-rust modules_install
```

La copie porte nos correctifs hors-arbre — **vérifié avant de lancer**, sinon le noyau
ne démarre pas correctement sur cette machine :

```bash
grep -c "recovery_disabled = true" drivers/remoteproc/qcom_q6v5_pas.c   # 0010
grep -c "qcom,rtc-offset"          drivers/rtc/rtc-pm8xxx.c             # 0008
```

## ⚠️ `KERNELRELEASE` à chaque appel

`make kernelrelease` annonce `7.1.0-next-20260626-nft+` — le `+` que
`scripts/setlocalversion` ajoute sur un dépôt git dont HEAD n'est pas une étiquette.
Sans `MODVERSIONS`, un module portant ce `+` refuse de se charger, **en silence**.
Passer `KERNELRELEASE=` explicitement au build **et** au `modules_install`.

## ⚠️ Arbre de modules propre, et c'est vital

`CONFIG_LOCALVERSION="-rust"` donne `/lib/modules/7.1.0-next-20260626-rust` (388 Mo),
distinct des trois autres. La série remoteproc « attach » agrandit `struct rproc` de
8 octets et `MODVERSIONS` est désactivé : un module chargé dans le mauvais noyau écrit
au-delà de la structure allouée, sans le moindre message. Ne jamais faire pointer une
autre entrée GRUB sur cet arbre.

## Vérification

```
$ sudo modprobe rust_minimal && sudo rmmod rust_minimal && dmesg | tail -5
rust_minimal: Rust minimal sample (init)
rust_minimal: Am I built-in? false
rust_minimal: test_parameter: 1
rust_minimal: My numbers are [72, 108, 200]
rust_minimal: Rust minimal sample (exit)
```

`rust_print` parcourt les huit niveaux de gravité — dont Alert et Critical, ce qui
**gonfle le compte d'erreurs du journal** sans rien signifier. Au premier démarrage,
17 erreurs noyau contre 15 sur l'entrée courante : les deux de plus sont ces messages.

Matériel vérifié sur ce noyau : WiFi, audio, ADSP **et** CDSP `attached`, rétroéclairage,
diagnostic PHY PCIe présent. 48 lignes `i2c … EACCES` en espace utilisateur apparaissent
en plus — powerdevil qui sonde le DDC/CI d'écrans externes. Sans effet sur la luminosité
interne ; **ne pas ajouter l'utilisateur au groupe `i2c` pour les faire taire**, l'accès
i2c brut aux bus système est un privilège réel.
