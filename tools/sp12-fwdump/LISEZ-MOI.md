# `sp12_fwdump` — lire les journaux du firmware

Module de **lecture seule** exposant, via debugfs, les six régions de vidage firmware du
X1P42100. Écrit le 2026-09-05, quand l'instrumentation côté noyau a atteint sa limite :
les coupures franches surviennent sans que le noyau émette la moindre ligne, donc la cause
est sous Linux.

## Pourquoi un module

Ces régions sont déclarées `no-map` dans le device-tree et **sans `compatible`** : aucun
pilote ne s'y lie, et le noyau ne les mappe pas. `CONFIG_STRICT_DEVMEM=y` interdit par
ailleurs `/dev/mem`. Un `ioremap` depuis un module est la seule voie.

## Ce qu'on y trouve

| région | taille | contenu |
|---|---|---|
| `xbl-dtlog` | 256 Kio | **texte clair** — journal du chargeur d'amorçage, horodaté |
| `uefi-log` | 64 Kio | **texte clair** — versions firmware, initialisation |
| `xbl-ramdump` | 1,75 Mio | binaire |
| `tme-crash-dump` | 256 Kio | haute entropie — chiffré ou compressé |
| `tme-log` | 16 Kio | haute entropie |
| `cpucp-log` | 256 Kio | quasi vide (115 octets non nuls) |

Les « chaînes » trouvées dans les régions TME sont du bruit imprimable, pas du texte.

## Le fait le plus utile

```
B - 304664 - PM: Reset by PSHOLD
B - 304664 - PM: Reset Type: Hard Reset
B - 304664 - PM: PON by CBLPWR
B - 488762 - ddr_init = 1 cold boot
```

**`ddr_init = 1 cold boot`** : le firmware réinitialise la DRAM à chaque démarrage. C'est
l'explication, au niveau firmware, de l'échec de ramoops sur 64 démarrages — redémarrages
propres compris. **Aucune capture en DRAM ne peut fonctionner sur cette machine.**

⚠️ **`Reset by PSHOLD` ne discrimine pas.** Un `reboot` normal sous Qualcomm passe aussi par
PSHOLD. Pour que cette ligne signifie quelque chose, il faut le contrôle : redémarrer
proprement, recapturer, comparer. Non fait à ce jour.

## Usage

```bash
make && sudo insmod sp12_fwdump.ko
sudo dd if=/sys/kernel/debug/sp12_fwdump/xbl-dtlog bs=64k status=none | strings -n 6
```

⚠️ **Ces journaux contiennent le numéro de série de la machine.** Les copies vivent dans
`/data/sp12data/fwdump/`, hors du dépôt. Ne jamais les publier tels quels.

Le module marque le noyau `tainted` (module hors-arbre). Il se décharge proprement.
