# Reconstruire libcamera avec le helper `ov02c10`

`PKGBUILD` est celui d'Arch en 0.7.2-4, avec quatre écarts, **tous extérieurs au correctif** :

| Écart | Pourquoi |
|---|---|
| `arch=(x86_64 aarch64)` | l'officiel ne déclare que x86_64 |
| doc, liaisons Python et tests désactivés | évite `texlive-core`, `doxygen`, `sphinx`, `pybind11` ; seuls `python-jinja`, `python-ply`, `python-yaml` restent nécessaires |
| `-D rpi-awb-nn=disabled` | `arch-meson` passe `--auto-features enabled`, ce qui rend `tensorflow-lite` obligatoire pour le pipeline Raspberry Pi |
| `-D werror=false` | **GCC 16.1.1 émet un faux positif** `-Warray-bounds` sur `std::mutex` dans `log.cpp` ; le paquet officiel a été bâti avec un compilateur plus ancien |

Les paquets `libcamera-docs`, `python-libcamera` et `gst-plugin-libcamera` ne sont plus
produits : aucun n'était installé sur cette machine.

## Recette

```bash
git clone https://gitlab.archlinux.org/archlinux/packaging/packages/libcamera.git
cd libcamera
cp <ce dépôt>/libcamera/paquet/PKGBUILD .
cp <ce dépôt>/libcamera/libcamera-add-ov02c10-sensor-helper.patch .
makepkg -f --nocheck        # meson compile -C build -j 3 : tablette sans ventilateur
sudo pacman -U libcamera{,-ipa,-tools}-0.7.2-4-aarch64.pkg.tar.xz
systemctl --user restart wireplumber
```

⚠️ **Mettre les paquets officiels à l'abri AVANT d'installer.** Les nôtres portent le même
nom de fichier : `pacman -U` les recopie dans `/var/cache/pacman/pkg` et **écrase la voie de
retour**. Les officiels du 21/09 sont dans
`/data/sp12data/archives/libcamera-officiel-0.7.2-4/`, les nôtres dans
`/data/sp12data/archives/libcamera-ov02c10-20260921/`.

## Ce que le correctif change, mesuré

```
avant :  IPASoft: Exposure 4-2320, gain 16-248 (1)
après :  IPASoft: Exposure 4-2320, gain 1-15.5 (0.145)
```

L'IPA exprime le gain en multiplicateur réel au lieu de codes de registre bruts, et
248/16 = 15,5 confirme le modèle dérivé. `Failed to create camera sensor helper for
ov02c10` a disparu.

## Durée de vie

Ce paquet porte le **même numéro de version que l'officiel** (0.7.2-4), donc `pacman -Syu`
ne le remplacera pas tant que l'amont n'a pas publié de nouvelle version. **Le jour où
libcamera passe en 0.7.3 ou 0.7.2-5, notre correctif disparaît** — il faudra rejouer la
recette, ou mieux : que le helper soit accepté en amont.
