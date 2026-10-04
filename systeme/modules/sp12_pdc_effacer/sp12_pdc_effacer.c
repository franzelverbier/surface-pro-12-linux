// SPDX-License-Identifier: GPL-2.0
/*
 * SP12 — essais d'effacement du bit GPIO_STATUS (bit 4, PDC v3.0) de la
 * broche 113 (GPIO 38, écran tactile), resté à 1 alors que la ligne est
 * haute. Écrire 1 seul ne l'efface pas (essai précédent). Ici :
 *  A) masquer (bit 3), écrire le statut à 0, relire, démasquer ;
 *  B) même écriture à 0 dans la région DRV précédente (bogue matériel X1E
 *     qui touche déjà IRQ_ENABLE_BANK), relire.
 * Ne reste pas chargé.
 */
#include <linux/module.h>
#include <linux/io.h>
#include <linux/delay.h>

#define PDC_BASE	0x0b220000
#define CFG_113		(0x110 + 4 * 113)

static int __init effacer_init(void)
{
	void __iomem *r = ioremap(PDC_BASE + CFG_113, 4);
	void __iomem *p = ioremap(PDC_BASE - 0x10000 + CFG_113, 4);
	u32 v0, a1, a2, a3, b1, b2;

	if (!r || !p)
		return -ENOMEM;
	v0 = readl(r);
	writel(v0 | BIT(3), r);			/* masque */
	a1 = readl(r);
	writel((v0 | BIT(3)) & ~BIT(4), r);	/* statut à 0, masqué */
	udelay(10);
	a2 = readl(r);
	writel(v0 & ~(BIT(3) | BIT(4)), r);	/* démasque */
	udelay(10);
	a3 = readl(r);
	pr_info("sp12_pdc_effacer: A depart=%02x masque=%02x efface_masque=%02x demasque=%02x\n",
		v0, a1, a2, a3);

	b1 = readl(p);
	writel(readl(r) & ~BIT(4), p);
	udelay(10);
	b2 = readl(r);
	pr_info("sp12_pdc_effacer: B prev_avant=%02x principal_apres=%02x prev_apres=%02x\n",
		b1, b2, readl(p));
	iounmap(r);
	iounmap(p);
	return -EAGAIN;
}
module_init(effacer_init);
MODULE_DESCRIPTION("SP12 essais d'effacement du statut PDC");
MODULE_LICENSE("GPL");
