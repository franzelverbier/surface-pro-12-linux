// SPDX-License-Identifier: GPL-2.0
/*
 * sp12_fwdump - expose les regions de vidage firmware du X1P42100 via debugfs.
 *
 * Ces regions sont declarees "no-map" dans le device-tree et n'ont aucun
 * "compatible", donc aucun pilote ne s'y lie et le noyau ne les mappe pas.
 * CONFIG_STRICT_DEVMEM=y interdit par ailleurs /dev/mem.
 *
 * Motivation : sur cette machine, des coupures franches surviennent sans que
 * le noyau emette quoi que ce soit. La cause est donc sous Linux. Ces regions
 * -- journaux XBL, TME, UEFI et CPUCP -- sont le seul endroit ou le firmware
 * pourrait avoir laisse une trace.
 *
 * STRICTEMENT EN LECTURE. Rien n'est ecrit dans ces zones.
 */

#include <linux/module.h>
#include <linux/debugfs.h>
#include <linux/io.h>
#include <linux/slab.h>

struct fw_zone {
	const char *nom;
	phys_addr_t base;
	size_t taille;
	void __iomem *va;
	struct debugfs_blob_wrapper blob;
	void *copie;
};

static struct fw_zone zones[] = {
	{ "cpucp-log",      0x80e00000, 0x40000  },
	{ "xbl-dtlog",      0x81a00000, 0x40000  },
	{ "xbl-ramdump",    0x81a40000, 0x1c0000 },
	{ "tme-crash-dump", 0x81ca0000, 0x40000  },
	{ "tme-log",        0x81ce0000, 0x4000   },
	{ "uefi-log",       0x81ce4000, 0x10000  },
};

static struct dentry *rep;

static int __init sp12_fwdump_init(void)
{
	int i;

	rep = debugfs_create_dir("sp12_fwdump", NULL);

	for (i = 0; i < ARRAY_SIZE(zones); i++) {
		struct fw_zone *z = &zones[i];

		z->va = ioremap(z->base, z->taille);
		if (!z->va) {
			pr_warn("sp12_fwdump: ioremap %s (%pa, %zu) a echoue\n",
				z->nom, &z->base, z->taille);
			continue;
		}

		/* Copie unique au chargement : le blob debugfs veut de la memoire
		 * normale, et on evite de relire du MMIO a chaque lecture. */
		z->copie = kvmalloc(z->taille, GFP_KERNEL);
		if (!z->copie) {
			iounmap(z->va);
			z->va = NULL;
			continue;
		}
		memcpy_fromio(z->copie, z->va, z->taille);

		z->blob.data = z->copie;
		z->blob.size = z->taille;
		debugfs_create_blob(z->nom, 0400, rep, &z->blob);

		pr_info("sp12_fwdump: %s mappe a %pa, %zu octets\n",
			z->nom, &z->base, z->taille);
	}
	return 0;
}

static void __exit sp12_fwdump_exit(void)
{
	int i;

	debugfs_remove_recursive(rep);
	for (i = 0; i < ARRAY_SIZE(zones); i++) {
		kvfree(zones[i].copie);
		if (zones[i].va)
			iounmap(zones[i].va);
	}
}

module_init(sp12_fwdump_init);
module_exit(sp12_fwdump_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Lecture seule des regions de vidage firmware du X1P42100");
