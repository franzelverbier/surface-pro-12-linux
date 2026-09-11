// SPDX-License-Identifier: GPL-2.0
/*
 * sp12_pdcver - lit, en lecture seule, le registre de version du PDC.
 *
 * Pourquoi : qcom-pdc n'emprunte le chemin IRQ_ENABLE_BANK — donc le
 * contournement matériel x1e — que si pdc_version < PDC_VERSION_3_2. Le pilote
 * ne journalise pas cette version et /dev/mem refuse la région. Sans ce chiffre,
 * on ne sait pas si le contournement est seulement actif sur cette machine.
 *
 * Une seule lecture 32 bits. Aucune écriture.
 */
#include <linux/module.h>
#include <linux/io.h>

#define PDC_BASE	0x0b220000
#define PDC_VERSION_REG	0x1000

static int __init sp12_pdcver_init(void)
{
	void __iomem *base;
	u32 v;

	base = ioremap(PDC_BASE, PDC_VERSION_REG + 4);
	if (!base)
		return -ENOMEM;

	v = readl_relaxed(base + PDC_VERSION_REG);
	iounmap(base);

	pr_info("sp12_pdcver: PDC_VERSION = 0x%08x -> %u.%u.%u\n",
		v, (v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff);
	pr_info("sp12_pdcver: seuil 3.2.0 = 0x%08x ; chemin BANK (et contournement x1e) %s\n",
		0x00030200, (v < 0x00030200) ? "ACTIF" : "inutilise");

	return 0;
}

static void __exit sp12_pdcver_exit(void) { }

module_init(sp12_pdcver_init);
module_exit(sp12_pdcver_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Lecture seule du registre de version du PDC (Surface Pro 12in)");
