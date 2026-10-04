// SPDX-License-Identifier: GPL-2.0
/*
 * SP12 — lit le mode du pilote PDC (passage direct ou secondaire). Le
 * pointeur statique « pdc » n'est pas exporté : son adresse est passée en
 * paramètre depuis /proc/kallsyms. Lecture seule ; ne reste pas chargé.
 * Décalages pour struct pdc_desc de 7.3-rc3.
 */
#include <linux/module.h>

static unsigned long adresse;
module_param(adresse, ulong, 0);

static int __init mode_init(void)
{
	u8 *d;

	if (!adresse)
		return -EINVAL;
	d = *(u8 **)adresse;
	if (!d)
		return -ENODEV;
	pr_info("sp12_pdc_mode: version=%08x num_spis=%u region_cnt=%d x1e_quirk=%u mode=%u (0 = passage direct, 1 = secondaire) unmask_gpio=%ps clear_gpio=%ps\n",
		*(u32 *)(d + 16), *(u32 *)(d + 20), *(int *)(d + 32), d[36], d[37],
		*(void **)(d + 72), *(void **)(d + 80));
	return -EAGAIN;
}
module_init(mode_init);
MODULE_DESCRIPTION("SP12 lecture du mode PDC");
MODULE_LICENSE("GPL");
