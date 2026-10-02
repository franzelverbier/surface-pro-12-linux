// SP12 — 02/10/2026 : désactive le minuteur VIRTUEL EL1 (CNTV_*_EL02) laissé armé
// par la chaîne de démarrage sur le CPU 0. En EL2/VHE Linux ne l'utilise pas ;
// KVM le charge avec l'état d'un vCPU seulement pendant qu'une VM tourne. Armé et
// échu, il garde une interruption en attente qui ferait refuser par le firmware
// l'état de repos « système » (le GIC ne peut pas s'éteindre).
// ⚠️ À ne charger que sans VM en cours. N'écrit que sur les CPU où ENABLE=1.
#include <linux/module.h>
#include <linux/smp.h>
#include <asm/sysreg.h>
#include <asm/virt.h>

static void couper(void *unused)
{
	u64 avant = read_sysreg_s(SYS_CNTV_CTL_EL02);

	if (avant & 1) {	/* ENABLE */
		write_sysreg_s(0, SYS_CNTV_CTL_EL02);
		isb();
		pr_info("sp12_vtimer_off: cpu%d minuteur virtuel EL1 ctl=%llx -> %llx\n",
			smp_processor_id(), avant, read_sysreg_s(SYS_CNTV_CTL_EL02));
	}
}

static int __init sp12_vtimer_off_init(void)
{
	if (!is_kernel_in_hyp_mode())
		return -ENODEV;
	on_each_cpu(couper, NULL, 1);
	return -EAGAIN;
}
module_init(sp12_vtimer_off_init);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("SP12 : coupe le minuteur virtuel EL1 laissé armé au démarrage (EL2)");
