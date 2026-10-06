// SPDX-License-Identifier: GPL-2.0
/*
 * SP12 — lecture seule du PDC (X1E, v3.0) : version, puis toutes les broches
 * dont IRQ_CFG est non nul (type, masque, statut) et les bits d'IRQ_ENABLE_BANK.
 * Cherche un statut collé qui ferait refuser l'état système. Aucune écriture.
 * Le module refuse de rester chargé (retourne -EAGAIN).
 */
#include <linux/module.h>
#include <linux/io.h>

#define PDC_BASE	0x0b220000
#define PDC_SIZE	0x10000
#define PDC_VERSION	0x1000
#define PDC_PARAM	0x100c
#define PDC_EN		0x10
#define PDC_CFG		0x110

static int __init lire_init(void)
{
	void __iomem *b = ioremap(PDC_BASE, PDC_SIZE);
	u32 param, n, i;

	if (!b)
		return -ENOMEM;
	param = readl(b + PDC_PARAM);
	n = (param & 0xff) + ((param >> 8) & 0xff);
	pr_info("sp12_pdc: version=%08x param=%08x (%u broches)\n",
		readl(b + PDC_VERSION), param, n);
	for (i = 0; i < DIV_ROUND_UP(n, 32); i++)
		pr_info("sp12_pdc: enable_bank[%u]=%08x\n", i, readl(b + PDC_EN + 4 * i));
	for (i = 0; i < n; i++) {
		u32 v = readl(b + PDC_CFG + 4 * i);

		if (v)
			pr_info("sp12_pdc: broche %3u cfg=%02x type=%u masque=%u statut=%u\n",
				i, v, v & 7, (v >> 3) & 1, (v >> 4) & 1);
	}
	iounmap(b);
	return -EAGAIN;
}
module_init(lire_init);
MODULE_DESCRIPTION("SP12 lecture du PDC");
MODULE_LICENSE("GPL");
