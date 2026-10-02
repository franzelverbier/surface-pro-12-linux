// SP12 — 02/10/2026 : diagnostic EN LECTURE SEULE des minuteurs générique ARM
// sur chaque CPU, pour savoir si un minuteur que Linux ne gère pas (le virtuel
// EL2, CNTHV, absent du device tree) est resté armé par la chaîne de démarrage
// EL2 et pourrait faire refuser au firmware l'état de repos « système ».
// Sous VHE (noyau en EL2, HCR_EL2.E2H=1), CNTV_*_EL0 désigne CNTHV_*_EL2 et
// CNTP_*_EL0 désigne CNTHP_*_EL2 ; les minuteurs EL1 réels sont les *_EL02.
#include <linux/module.h>
#include <linux/smp.h>
#include <asm/sysreg.h>
#include <asm/virt.h>

static void lire(void *unused)
{
	u64 hv_ctl = read_sysreg(cntv_ctl_el0), hv_cval = read_sysreg(cntv_cval_el0);
	u64 hp_ctl = read_sysreg(cntp_ctl_el0), hp_cval = read_sysreg(cntp_cval_el0);
	u64 v1_ctl = read_sysreg_s(SYS_CNTV_CTL_EL02), v1_cval = read_sysreg_s(SYS_CNTV_CVAL_EL02);
	u64 p1_ctl = read_sysreg_s(SYS_CNTP_CTL_EL02), p1_cval = read_sysreg_s(SYS_CNTP_CVAL_EL02);
	u64 now = read_sysreg(cntpct_el0), isr = read_sysreg(isr_el1);

	/* CTL : bit0 ENABLE, bit1 IMASK, bit2 ISTATUS (condition remplie) */
	pr_info("sp12_timers: cpu%d EL2virt(CNTHV) ctl=%llx cval-now=%lld | EL2phys(CNTHP, Linux) ctl=%llx cval-now=%lld | EL1virt ctl=%llx cval-now=%lld | EL1phys ctl=%llx cval-now=%lld | ISR_EL1=%llx\n",
		smp_processor_id(), hv_ctl, (s64)(hv_cval - now), hp_ctl, (s64)(hp_cval - now),
		v1_ctl, (s64)(v1_cval - now), p1_ctl, (s64)(p1_cval - now), isr);
}

static int __init sp12_timers_init(void)
{
	if (!is_kernel_in_hyp_mode()) {
		pr_info("sp12_timers: noyau pas en EL2 (VHE), rien à lire\n");
		return -ENODEV;
	}
	on_each_cpu(lire, NULL, 1);
	return -EAGAIN;	/* lecture faite : le module ne reste pas chargé */
}
module_init(sp12_timers_init);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("SP12 : lecture des minuteurs ARM (diagnostic, lecture seule)");
