// SPDX-License-Identifier: GPL-2.0
/*
 * SP12 — lecture seule des registres IRQ_CFG du PDC (X1E, v3.2) pour
 * comprendre la tempête d'IRQ de l'écran tactile (GPIO 38 -> broche PDC 113)
 * sous 7.3. Échantillonne chaque registre N fois et compte les valeurs vues.
 * Aucune écriture. Le module refuse de rester chargé (retourne -EAGAIN).
 */
#include <linux/module.h>
#include <linux/io.h>

#define PDC_BASE	0x0b220000
#define PDC_SIZE	0x10000
#define PDC_VERSION	0x1000
#define PDC_PARAM	0x100c
#define PDC_CFG		0x110
#define N		20000

static const struct { int gpio, pin; } broches[] = {
	{ 38, 113 }, { 148, 97 }, { 2, 70 }, { 91, 157 },
};

static int __init lire_init(void)
{
	void __iomem *b = ioremap(PDC_BASE, PDC_SIZE);
	int i, k;

	if (!b)
		return -ENOMEM;
	pr_info("sp12_pdc: version=%08x param=%08x\n",
		readl(b + PDC_VERSION), readl(b + PDC_PARAM));
	for (k = 0; k < ARRAY_SIZE(broches); k++) {
		u32 vals[8] = { 0 }, cnt[8] = { 0 };
		int nv = 0, j;

		for (i = 0; i < N; i++) {
			u32 v = readl(b + PDC_CFG + 4 * broches[k].pin);

			for (j = 0; j < nv && vals[j] != v; j++)
				;
			if (j == nv && nv < 8)
				vals[nv++] = v;
			if (j < 8)
				cnt[j]++;
		}
		for (j = 0; j < nv; j++)
			pr_info("sp12_pdc: gpio%d pin%d cfg=%02x (type=%u en=%u mask=%u sts=%u) x%u\n",
				broches[k].gpio, broches[k].pin, vals[j], vals[j] & 7,
				(vals[j] >> 3) & 1, (vals[j] >> 4) & 1,
				(vals[j] >> 5) & 1, cnt[j]);
	}
	iounmap(b);
	{
		/* TLMM : GPIO 38, registres io (bit0 = entrée), intr_cfg, intr_status */
		void __iomem *t = ioremap(0x0f100000 + 38 * 0x1000, 0x10);
		u32 bas = 0, st = 0;

		if (!t)
			return -ENOMEM;
		for (i = 0; i < N; i++) {
			if (!(readl(t + 0x4) & 1))
				bas++;
			if (readl(t + 0xc) & 1)
				st++;
		}
		pr_info("sp12_pdc: tlmm gpio38 ctl=%08x intr_cfg=%08x : ligne basse %u/%u, intr_status %u/%u\n",
			readl(t), readl(t + 0x8), bas, N, st, N);
		iounmap(t);
	}
	return -EAGAIN;
}
module_init(lire_init);
MODULE_LICENSE("GPL");
