# `sp12_pdcver` — lire la version du PDC

Module de **lecture seule**. Une seule lecture 32 bits, à `0xb221000`
(`PDC_VERSION_REG`, décalage `0x1000` dans la première région du PDC), puis il se tait.

## Pourquoi

`drivers/irqchip/qcom-pdc.c` n'emprunte le chemin `IRQ_ENABLE_BANK` — et donc le
contournement matériel x1e — que sous condition :

```c
static void __pdc_enable_intr(int pin_out, bool on)
{
	if (pdc_version < PDC_VERSION_3_2)
		pdc_enable_intr_bank(pin_out, on);
	else
		pdc_enable_intr_cfg(pin_out, on);
}
```

Le pilote **ne journalise pas** cette version, et `CONFIG_STRICT_DEVMEM=y` fait échouer
la lecture par `/dev/mem` (`EFAULT`). Sans ce chiffre, impossible de savoir si le
contournement est seulement actif sur cette machine — donc impossible de savoir si
l'écarter change quoi que ce soit.

## Résultat sur Surface Pro 12in (2026-09-11)

```
sp12_pdcver: PDC_VERSION = 0x00030000 -> 3.0.0
sp12_pdcver: seuil 3.2.0 = 0x00030200 ; chemin BANK (et contournement x1e) ACTIF
```

**3.0.0, sous le seuil.** Le contournement est bien emprunté. Si la version avait été
3.2 ou plus, tout le raisonnement de `kernel/PDC-X1E-CONTOURNEMENT.md` serait tombé.

## Usage

```bash
make
sudo insmod sp12_pdcver.ko && sudo rmmod sp12_pdcver
journalctl -k -n 3 | grep sp12_pdcver
```

Le module n'a pas vocation à rester chargé : il imprime au `module_init` et sort.

⚠️ `KERNELRELEASE` est imposé dans le `Makefile` : `scripts/setlocalversion` n'honore plus
`.scmversion`, et un module bâti depuis un arbre git hérite d'un `+` dans son `vermagic`,
ce qui le fait refuser en silence sans `MODVERSIONS`. Voir `kernel/RECETTE-REBUILD.md`.
