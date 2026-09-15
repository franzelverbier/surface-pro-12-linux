savedcmd_.module-common.o := gcc -Wp,-MMD,./..module-common.o.d -nostdinc -I/home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include -I/home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated -I/home/franz/sp12-kernel-rebuild/linux-next/include -I/home/franz/sp12-kernel-rebuild/linux-next/include -I/home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/uapi -I/home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/uapi -I/home/franz/sp12-kernel-rebuild/linux-next/include/uapi -I/home/franz/sp12-kernel-rebuild/linux-next/include/generated/uapi -include /home/franz/sp12-kernel-rebuild/linux-next/include/linux/compiler-version.h -include /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kconfig.h -include /home/franz/sp12-kernel-rebuild/linux-next/include/linux/compiler_types.h -D__KERNEL__ -mlittle-endian -DKASAN_SHADOW_SCALE_SHIFT= -fshort-wchar -funsigned-char -fno-common -fno-PIE -fno-strict-aliasing -std=gnu11 -fms-extensions -mgeneral-regs-only -DCONFIG_CC_HAS_K_CONSTRAINT=1 -Wno-psabi -mabi=lp64 -fno-asynchronous-unwind-tables -fno-unwind-tables -mbranch-protection=pac-ret -Wa,-march=armv8.5-a -DARM64_ASM_ARCH='"armv8.5-a"' -DKASAN_SHADOW_SCALE_SHIFT= -fno-delete-null-pointer-checks -O2 -fno-allow-store-data-races -fstack-protector-strong -fno-omit-frame-pointer -fno-optimize-sibling-calls -ftrivial-auto-var-init=zero -fzero-init-padding-bits=all -fno-stack-clash-protection -fdiagnostics-show-context=2 -fmin-function-alignment=4 -fstrict-flex-arrays=3 -fno-strict-overflow -fno-stack-check -fconserve-stack -fno-builtin-wcslen -Wall -Wextra -Wundef -Werror=implicit-function-declaration -Werror=implicit-int -Werror=return-type -Werror=strict-prototypes -Wno-format-security -Wno-trigraphs -Wno-frame-address -Wno-address-of-packed-member -Wmissing-declarations -Wmissing-prototypes -Wframe-larger-than=2048 -Wno-main -Wno-type-limits -Wno-dangling-pointer -Wvla-larger-than=1 -Wno-pointer-sign -Wcast-function-type -Wno-unterminated-string-initialization -Wno-array-bounds -Wno-stringop-overflow -Wno-alloc-size-larger-than -Wimplicit-fallthrough=5 -Werror=date-time -Werror=incompatible-pointer-types -Werror=designated-init -Wenum-conversion -Wunused -Wno-unused-but-set-variable -Wno-unused-const-variable -Wno-packed-not-aligned -Wno-format-overflow -Wno-format-truncation -Wno-stringop-truncation -Wno-override-init -Wno-missing-field-initializers -Wno-shift-negative-value -Wno-maybe-uninitialized -Wno-sign-compare -Wno-unused-parameter -g -fno-var-tracking -femit-struct-debug-baseonly -DGCC_PLUGINS -mstack-protector-guard=sysreg -mstack-protector-guard-reg=sp_el0 -mstack-protector-guard-offset=1344  -DMODULE  -DKBUILD_BASENAME='".module_common"' -DKBUILD_MODNAME='".module_common.o"' -D__KBUILD_MODNAME=.module_common.o -c -o .module-common.o /home/franz/sp12-kernel-rebuild/linux-next/scripts/module-common.c  

source_.module-common.o := /home/franz/sp12-kernel-rebuild/linux-next/scripts/module-common.c

deps_.module-common.o := \
    $(wildcard include/config/UNWINDER_ORC) \
    $(wildcard include/config/MITIGATION_RETPOLINE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/compiler-version.h \
    $(wildcard include/config/CC_VERSION_TEXT) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/generated/gcc-plugins.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kconfig.h \
    $(wildcard include/config/CPU_BIG_ENDIAN) \
    $(wildcard include/config/BOOGER) \
    $(wildcard include/config/FOO) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/compiler_types.h \
    $(wildcard include/config/DEBUG_INFO_BTF) \
    $(wildcard include/config/PAHOLE_HAS_BTF_TAG) \
    $(wildcard include/config/FUNCTION_ALIGNMENT) \
    $(wildcard include/config/CC_HAS_SANE_FUNCTION_ALIGNMENT) \
    $(wildcard include/config/X86_64) \
    $(wildcard include/config/ARM64) \
    $(wildcard include/config/LD_DEAD_CODE_DATA_ELIMINATION) \
    $(wildcard include/config/LTO_CLANG) \
    $(wildcard include/config/HAVE_ARCH_COMPILER_H) \
    $(wildcard include/config/KCSAN) \
    $(wildcard include/config/CC_HAS_ASSUME) \
    $(wildcard include/config/CC_HAS_COUNTED_BY) \
    $(wildcard include/config/FORTIFY_SOURCE) \
    $(wildcard include/config/UBSAN_BOUNDS) \
    $(wildcard include/config/CC_HAS_COUNTED_BY_PTR) \
    $(wildcard include/config/CC_HAS_MULTIDIMENSIONAL_NONSTRING) \
    $(wildcard include/config/CFI) \
    $(wildcard include/config/ARCH_USES_CFI_GENERIC_LLVM_PASS) \
    $(wildcard include/config/CC_HAS_BROKEN_COUNTED_BY_REF) \
    $(wildcard include/config/CC_HAS_ASM_INLINE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/compiler-context-analysis.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/compiler_attributes.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/compiler-gcc.h \
    $(wildcard include/config/ARCH_USE_BUILTIN_BSWAP) \
    $(wildcard include/config/SHADOW_CALL_STACK) \
    $(wildcard include/config/KCOV) \
    $(wildcard include/config/CC_HAS_TYPEOF_UNQUAL) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/compiler.h \
    $(wildcard include/config/ARM64_PTR_AUTH_KERNEL) \
    $(wildcard include/config/ARM64_PTR_AUTH) \
    $(wildcard include/config/BUILTIN_RETURN_ADDRESS_STRIPS_PAC) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/asm/percpu_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/percpu_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/module.h \
    $(wildcard include/config/MODULES) \
    $(wildcard include/config/SYSFS) \
    $(wildcard include/config/MODULES_TREE_LOOKUP) \
    $(wildcard include/config/LIVEPATCH) \
    $(wildcard include/config/STACKTRACE_BUILD_ID) \
    $(wildcard include/config/ARCH_USES_CFI_TRAPS) \
    $(wildcard include/config/MODULE_SIG) \
    $(wildcard include/config/GENERIC_BUG) \
    $(wildcard include/config/KALLSYMS) \
    $(wildcard include/config/SMP) \
    $(wildcard include/config/TRACEPOINTS) \
    $(wildcard include/config/TREE_SRCU) \
    $(wildcard include/config/BPF_EVENTS) \
    $(wildcard include/config/DEBUG_INFO_BTF_MODULES) \
    $(wildcard include/config/JUMP_LABEL) \
    $(wildcard include/config/TRACING) \
    $(wildcard include/config/EVENT_TRACING) \
    $(wildcard include/config/DYNAMIC_FTRACE) \
    $(wildcard include/config/KPROBES) \
    $(wildcard include/config/HAVE_STATIC_CALL_INLINE) \
    $(wildcard include/config/KUNIT) \
    $(wildcard include/config/PRINTK_INDEX) \
    $(wildcard include/config/MODULE_UNLOAD) \
    $(wildcard include/config/CONSTRUCTORS) \
    $(wildcard include/config/FUNCTION_ERROR_INJECTION) \
    $(wildcard include/config/DYNAMIC_DEBUG_CORE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/list.h \
    $(wildcard include/config/LIST_HARDENED) \
    $(wildcard include/config/DEBUG_LIST) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/container_of.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/build_bug.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/compiler.h \
    $(wildcard include/config/TRACE_BRANCH_PROFILING) \
    $(wildcard include/config/PROFILE_ALL_BRANCHES) \
    $(wildcard include/config/OBJTOOL) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/rwonce.h \
    $(wildcard include/config/LTO) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/rwonce.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kasan-checks.h \
    $(wildcard include/config/KASAN_GENERIC) \
    $(wildcard include/config/KASAN_SW_TAGS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/types.h \
    $(wildcard include/config/HAVE_UID16) \
    $(wildcard include/config/UID16) \
    $(wildcard include/config/ARCH_DMA_ADDR_T_64BIT) \
    $(wildcard include/config/PHYS_ADDR_T_64BIT) \
    $(wildcard include/config/64BIT) \
    $(wildcard include/config/ARCH_32BIT_USTAT_F_TINODE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/uapi/asm/types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/asm-generic/types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/int-ll64.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/asm-generic/int-ll64.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/uapi/asm/bitsperlong.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitsperlong.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/asm-generic/bitsperlong.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/posix_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/stddef.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/stddef.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/uapi/asm/posix_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/asm-generic/posix_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kcsan-checks.h \
    $(wildcard include/config/KCSAN_WEAK_MEMORY) \
    $(wildcard include/config/KCSAN_IGNORE_ATOMICS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/poison.h \
    $(wildcard include/config/ILLEGAL_POINTER_VALUE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/const.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/vdso/const.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/const.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/barrier.h \
    $(wildcard include/config/ARM64_PSEUDO_NMI) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/alternative-macros.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/vdso/bits.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/cpucaps.h \
    $(wildcard include/config/ARM64_EPAN) \
    $(wildcard include/config/ARM64_SVE) \
    $(wildcard include/config/ARM64_SME) \
    $(wildcard include/config/ARM64_CNP) \
    $(wildcard include/config/ARM64_MTE) \
    $(wildcard include/config/ARM64_BTI) \
    $(wildcard include/config/ARM64_TLB_RANGE) \
    $(wildcard include/config/ARM64_POE) \
    $(wildcard include/config/ARM64_GCS) \
    $(wildcard include/config/ARM64_HAFT) \
    $(wildcard include/config/UNMAP_KERNEL_AT_EL0) \
    $(wildcard include/config/ARM64_ERRATUM_843419) \
    $(wildcard include/config/ARM64_ERRATUM_1742098) \
    $(wildcard include/config/ARM64_ERRATUM_2645198) \
    $(wildcard include/config/ARM64_ERRATUM_2658417) \
    $(wildcard include/config/CAVIUM_ERRATUM_23154) \
    $(wildcard include/config/ARM64_WORKAROUND_DISABLE_CNP) \
    $(wildcard include/config/ARM64_WORKAROUND_REPEAT_TLBI) \
    $(wildcard include/config/ARM64_ERRATUM_3194386) \
    $(wildcard include/config/ARM64_ERRATUM_4193714) \
    $(wildcard include/config/HW_PERF_EVENTS) \
    $(wildcard include/config/ARM64_LSUI) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/asm/cpucap-defs.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/insn-def.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/brk-imm.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/stringify.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/barrier.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/stat.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/stat.h \
    $(wildcard include/config/COMPAT) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/uapi/asm/stat.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/asm-generic/stat.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/time.h \
    $(wildcard include/config/POSIX_TIMERS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/cache.h \
    $(wildcard include/config/ARCH_HAS_CACHE_LINE_SIZE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/kernel.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/sysinfo.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/vdso/cache.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/cache.h \
    $(wildcard include/config/KASAN_HW_TAGS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/bitops.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/bits.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/bits.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/overflow.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/limits.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/limits.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/vdso/limits.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/typecheck.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/generic-non-atomic.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/bitops.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/builtin-__ffs.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/builtin-ffs.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/builtin-__fls.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/builtin-fls.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/ffz.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/fls64.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/sched.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/hweight.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/arch_hweight.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/const_hweight.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/atomic.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/atomic.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/atomic.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/cmpxchg.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/lse.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/atomic_ll_sc.h \
    $(wildcard include/config/CC_HAS_K_CONSTRAINT) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/export.h \
    $(wildcard include/config/MODVERSIONS) \
    $(wildcard include/config/GENDWARFKSYMS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/linkage.h \
    $(wildcard include/config/ARCH_USE_SYM_ANNOTATIONS) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/linkage.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/alternative.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/init.h \
    $(wildcard include/config/MEMORY_HOTPLUG) \
    $(wildcard include/config/HAVE_ARCH_PREL32_RELOCATIONS) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/atomic_lse.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/atomic/atomic-arch-fallback.h \
    $(wildcard include/config/GENERIC_ATOMIC64) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/atomic/atomic-long.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/atomic/atomic-instrumented.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/instrumented.h \
    $(wildcard include/config/DEBUG_ATOMIC) \
    $(wildcard include/config/DEBUG_ATOMIC_LARGEST_ALIGN) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/bug.h \
    $(wildcard include/config/PRINTK) \
    $(wildcard include/config/BUG_ON_DATA_CORRUPTION) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/bug.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/asm-bug.h \
    $(wildcard include/config/DEBUG_BUGVERBOSE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bug.h \
    $(wildcard include/config/DEBUG_BUGVERBOSE_DETAILED) \
    $(wildcard include/config/BUG) \
    $(wildcard include/config/GENERIC_BUG_RELATIVE_POINTERS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/instrumentation.h \
    $(wildcard include/config/NOINSTR_VALIDATION) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/once_lite.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/panic.h \
    $(wildcard include/config/PANIC_TIMEOUT) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/stdarg.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/printk.h \
    $(wildcard include/config/MESSAGE_LOGLEVEL_DEFAULT) \
    $(wildcard include/config/CONSOLE_LOGLEVEL_DEFAULT) \
    $(wildcard include/config/CONSOLE_LOGLEVEL_QUIET) \
    $(wildcard include/config/EARLY_PRINTK) \
    $(wildcard include/config/DYNAMIC_DEBUG) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kern_levels.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/ratelimit_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/param.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/uapi/asm/param.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/param.h \
    $(wildcard include/config/HZ) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/asm-generic/param.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/spinlock_types_raw.h \
    $(wildcard include/config/DEBUG_SPINLOCK) \
    $(wildcard include/config/DEBUG_LOCK_ALLOC) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/spinlock_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/qspinlock_types.h \
    $(wildcard include/config/NR_CPUS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/qrwlock_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/uapi/asm/byteorder.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/byteorder/little_endian.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/byteorder/little_endian.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/swab.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/swab.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/uapi/asm/swab.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/asm-generic/swab.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/byteorder/generic.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/lockdep_types.h \
    $(wildcard include/config/PROVE_RAW_LOCK_NESTING) \
    $(wildcard include/config/LOCKDEP) \
    $(wildcard include/config/LOCK_STAT) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kmsan-checks.h \
    $(wildcard include/config/KMSAN) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/instrumented-atomic.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/lock.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/instrumented-lock.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/non-atomic.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/non-instrumented-non-atomic.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/le.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/bitops/ext2-atomic-setbit.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kasan-enabled.h \
    $(wildcard include/config/ARCH_DEFER_KASAN) \
    $(wildcard include/config/KASAN) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/static_key.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/jump_label.h \
    $(wildcard include/config/HAVE_ARCH_JUMP_LABEL_RELATIVE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/cleanup.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/err.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/uapi/asm/errno.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/asm-generic/errno.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/asm-generic/errno-base.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/args.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/jump_label.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/insn.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/cputype.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/sysreg.h \
    $(wildcard include/config/BROKEN_GAS_INST) \
    $(wildcard include/config/ARM64_PA_BITS_52) \
    $(wildcard include/config/ARM64_4K_PAGES) \
    $(wildcard include/config/ARM64_16K_PAGES) \
    $(wildcard include/config/ARM64_64K_PAGES) \
    $(wildcard include/config/AMPERE_ERRATUM_AC04_CPU_23) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kasan-tags.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/gpr-num.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/asm/sysreg-defs.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/bitfield.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/mte-def.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/math64.h \
    $(wildcard include/config/ARCH_SUPPORTS_INT128) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/math.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/asm/div64.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/div64.h \
    $(wildcard include/config/CC_OPTIMIZE_FOR_PERFORMANCE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/vdso/math64.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/time64.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/vdso/time64.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/time.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/time_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/time32.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/timex.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/timex.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/timex.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/arch_timer.h \
    $(wildcard include/config/ARM_ARCH_TIMER_OOL_WORKAROUND) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/hwcap.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/uapi/asm/hwcap.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/cpufeature.h \
    $(wildcard include/config/ARM64_SW_TTBR0_PAN) \
    $(wildcard include/config/ARM64_DEBUG_PRIORITY_MASKING) \
    $(wildcard include/config/ARM64_BTI_KERNEL) \
    $(wildcard include/config/ARM64_PA_BITS) \
    $(wildcard include/config/ARM64_HW_AFDBM) \
    $(wildcard include/config/ARM64_AMU_EXTN) \
    $(wildcard include/config/ARM64_LPA2) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kernel.h \
    $(wildcard include/config/PREEMPT_VOLUNTARY_BUILD) \
    $(wildcard include/config/PREEMPT_DYNAMIC) \
    $(wildcard include/config/HAVE_PREEMPT_DYNAMIC_CALL) \
    $(wildcard include/config/HAVE_PREEMPT_DYNAMIC_KEY) \
    $(wildcard include/config/PREEMPT_) \
    $(wildcard include/config/DEBUG_ATOMIC_SLEEP) \
    $(wildcard include/config/MMU) \
    $(wildcard include/config/PROVE_LOCKING) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/align.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/vdso/align.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/array_size.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kstrtox.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/log2.h \
    $(wildcard include/config/ARCH_HAS_ILOG2_U32) \
    $(wildcard include/config/ARCH_HAS_ILOG2_U64) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/minmax.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sprintf.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/static_call_types.h \
    $(wildcard include/config/HAVE_STATIC_CALL) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/util_macros.h \
    $(wildcard include/config/FOO_SUSPEND) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/wordpart.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/cpumask.h \
    $(wildcard include/config/FORCE_NR_CPUS) \
    $(wildcard include/config/HOTPLUG_CPU) \
    $(wildcard include/config/DEBUG_PER_CPU_MAPS) \
    $(wildcard include/config/CPUMASK_OFFSTACK) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/bitmap.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/errno.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/errno.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/find.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/string.h \
    $(wildcard include/config/BINARY_PRINTF) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/string.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/string.h \
    $(wildcard include/config/ARCH_HAS_UACCESS_FLUSHCACHE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/bitmap-str.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/cpumask_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/threads.h \
    $(wildcard include/config/BASE_SMALL) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/gfp_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/numa.h \
    $(wildcard include/config/NUMA_KEEP_MEMINFO) \
    $(wildcard include/config/NUMA) \
    $(wildcard include/config/HAVE_ARCH_NODE_DEV_GROUP) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/nodemask.h \
    $(wildcard include/config/HIGHMEM) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/nodemask_types.h \
    $(wildcard include/config/NODES_SHIFT) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/random.h \
    $(wildcard include/config/VMGENID) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/random.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/ioctl.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/uapi/asm/ioctl.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/ioctl.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/asm-generic/ioctl.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/irqnr.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/irqnr.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/sparsemem.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/pgtable-prot.h \
    $(wildcard include/config/HAVE_ARCH_USERFAULTFD_WP) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/memory.h \
    $(wildcard include/config/ARM64_VA_BITS) \
    $(wildcard include/config/KASAN_SHADOW_OFFSET) \
    $(wildcard include/config/RANDOMIZE_BASE) \
    $(wildcard include/config/DEBUG_VIRTUAL) \
    $(wildcard include/config/EFI) \
    $(wildcard include/config/ARM_GIC_V3_ITS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sizes.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/page-def.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/vdso/page.h \
    $(wildcard include/config/PAGE_SHIFT) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/mmdebug.h \
    $(wildcard include/config/DEBUG_VM) \
    $(wildcard include/config/DEBUG_VM_IRQSOFF) \
    $(wildcard include/config/DEBUG_VM_PGFLAGS) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/boot.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/sections.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/sections.h \
    $(wildcard include/config/HAVE_FUNCTION_DESCRIPTORS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/memory_model.h \
    $(wildcard include/config/FLATMEM) \
    $(wildcard include/config/SPARSEMEM_VMEMMAP) \
    $(wildcard include/config/SPARSEMEM) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/pfn.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/pgtable-hwdef.h \
    $(wildcard include/config/PGTABLE_LEVELS) \
    $(wildcard include/config/ARM64_CONT_PTE_SHIFT) \
    $(wildcard include/config/ARM64_CONT_PMD_SHIFT) \
    $(wildcard include/config/ARM64_VA_BITS_52) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/pgtable-types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/rsi.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/rsi_cmds.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/arm-smccc.h \
    $(wildcard include/config/HAVE_ARM_SMCCC) \
    $(wildcard include/config/ARM) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/uuid.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/rsi_smc.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/asm/kernel-hwcap.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/percpu.h \
    $(wildcard include/config/KMALLOC_PARTITION_CACHES) \
    $(wildcard include/config/PAGE_SIZE_4KB) \
    $(wildcard include/config/NEED_PER_CPU_PAGE_FIRST_CHUNK) \
    $(wildcard include/config/HAVE_SETUP_PER_CPU_AREA) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/alloc_tag.h \
    $(wildcard include/config/MEM_ALLOC_PROFILING_DEBUG) \
    $(wildcard include/config/MEM_ALLOC_PROFILING) \
    $(wildcard include/config/ARCH_MODULE_NEEDS_WEAK_PER_CPU) \
    $(wildcard include/config/MEM_ALLOC_PROFILING_ENABLED_BY_DEFAULT) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/codetag.h \
    $(wildcard include/config/CODE_TAGGING) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/preempt.h \
    $(wildcard include/config/PREEMPT_RT) \
    $(wildcard include/config/PREEMPT_COUNT) \
    $(wildcard include/config/DEBUG_PREEMPT) \
    $(wildcard include/config/TRACE_PREEMPT_TOGGLE) \
    $(wildcard include/config/PREEMPTION) \
    $(wildcard include/config/PREEMPT_NOTIFIERS) \
    $(wildcard include/config/PREEMPT_NONE) \
    $(wildcard include/config/PREEMPT_VOLUNTARY) \
    $(wildcard include/config/PREEMPT) \
    $(wildcard include/config/PREEMPT_LAZY) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/preempt.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/thread_info.h \
    $(wildcard include/config/THREAD_INFO_IN_TASK) \
    $(wildcard include/config/GENERIC_ENTRY) \
    $(wildcard include/config/ARCH_HAS_PREEMPT_LAZY) \
    $(wildcard include/config/HAVE_ARCH_WITHIN_STACK_FRAMES) \
    $(wildcard include/config/SH) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/restart_block.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/current.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/thread_info.h \
    $(wildcard include/config/ARM64_MPAM) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/stack_pointer.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/percpu.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/percpu.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/percpu-defs.h \
    $(wildcard include/config/DEBUG_FORCE_WEAK_PER_CPU) \
    $(wildcard include/config/AMD_MEM_ENCRYPT) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/smp.h \
    $(wildcard include/config/UP_LATE_INIT) \
    $(wildcard include/config/CSD_LOCK_WAIT_DEBUG) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/smp_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/llist.h \
    $(wildcard include/config/ARCH_HAVE_NMI_SAFE_CMPXCHG) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/smp.h \
    $(wildcard include/config/ARM64_ACPI_PARKING_PROTOCOL) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/irqflags.h \
    $(wildcard include/config/TRACE_IRQFLAGS) \
    $(wildcard include/config/IRQSOFF_TRACER) \
    $(wildcard include/config/PREEMPT_TRACER) \
    $(wildcard include/config/DEBUG_IRQFLAGS) \
    $(wildcard include/config/TRACE_IRQFLAGS_SUPPORT) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/irqflags_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/irqflags.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/ptrace.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/uapi/asm/ptrace.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/uapi/asm/sve_context.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/irqchip/arm-gic-v3-prio.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/stacktrace/frame.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sched.h \
    $(wildcard include/config/VIRT_CPU_ACCOUNTING_NATIVE) \
    $(wildcard include/config/SCHED_INFO) \
    $(wildcard include/config/SCHEDSTATS) \
    $(wildcard include/config/SCHED_CORE) \
    $(wildcard include/config/FAIR_GROUP_SCHED) \
    $(wildcard include/config/RT_GROUP_SCHED) \
    $(wildcard include/config/RT_MUTEXES) \
    $(wildcard include/config/UCLAMP_TASK) \
    $(wildcard include/config/UCLAMP_BUCKETS_COUNT) \
    $(wildcard include/config/KMAP_LOCAL) \
    $(wildcard include/config/SCHED_CLASS_EXT) \
    $(wildcard include/config/CGROUP_SCHED) \
    $(wildcard include/config/CFS_BANDWIDTH) \
    $(wildcard include/config/BLK_DEV_IO_TRACE) \
    $(wildcard include/config/PREEMPT_RCU) \
    $(wildcard include/config/TASKS_RCU) \
    $(wildcard include/config/TASKS_TRACE_RCU) \
    $(wildcard include/config/TRIVIAL_PREEMPT_RCU) \
    $(wildcard include/config/MEMCG_V1) \
    $(wildcard include/config/LRU_GEN) \
    $(wildcard include/config/COMPAT_BRK) \
    $(wildcard include/config/CGROUPS) \
    $(wildcard include/config/BLK_CGROUP) \
    $(wildcard include/config/PSI) \
    $(wildcard include/config/PAGE_OWNER) \
    $(wildcard include/config/EVENTFD) \
    $(wildcard include/config/ARCH_HAS_CPU_PASID) \
    $(wildcard include/config/X86_BUS_LOCK_DETECT) \
    $(wildcard include/config/TASK_DELAY_ACCT) \
    $(wildcard include/config/STACKPROTECTOR) \
    $(wildcard include/config/ARCH_HAS_SCALED_CPUTIME) \
    $(wildcard include/config/VIRT_CPU_ACCOUNTING_GEN) \
    $(wildcard include/config/NO_HZ_FULL) \
    $(wildcard include/config/POSIX_CPUTIMERS) \
    $(wildcard include/config/POSIX_CPU_TIMERS_TASK_WORK) \
    $(wildcard include/config/KEYS) \
    $(wildcard include/config/SYSVIPC) \
    $(wildcard include/config/DETECT_HUNG_TASK) \
    $(wildcard include/config/IO_URING) \
    $(wildcard include/config/AUDIT) \
    $(wildcard include/config/AUDITSYSCALL) \
    $(wildcard include/config/DETECT_HUNG_TASK_BLOCKER) \
    $(wildcard include/config/UBSAN) \
    $(wildcard include/config/UBSAN_TRAP) \
    $(wildcard include/config/COMPACTION) \
    $(wildcard include/config/TASK_XACCT) \
    $(wildcard include/config/CPUSETS) \
    $(wildcard include/config/X86_CPU_RESCTRL) \
    $(wildcard include/config/PERF_EVENTS) \
    $(wildcard include/config/NUMA_BALANCING) \
    $(wildcard include/config/SCHED_CACHE) \
    $(wildcard include/config/ARCH_HAS_LAZY_MMU_MODE) \
    $(wildcard include/config/FAULT_INJECTION) \
    $(wildcard include/config/LATENCYTOP) \
    $(wildcard include/config/FUNCTION_GRAPH_TRACER) \
    $(wildcard include/config/MEMCG) \
    $(wildcard include/config/UPROBES) \
    $(wildcard include/config/BCACHE) \
    $(wildcard include/config/VMAP_STACK) \
    $(wildcard include/config/SECURITY) \
    $(wildcard include/config/BPF_SYSCALL) \
    $(wildcard include/config/KSTACK_ERASE) \
    $(wildcard include/config/KSTACK_ERASE_METRICS) \
    $(wildcard include/config/X86_MCE) \
    $(wildcard include/config/KRETPROBES) \
    $(wildcard include/config/RETHOOK) \
    $(wildcard include/config/ARCH_HAS_PARANOID_L1D_FLUSH) \
    $(wildcard include/config/RV) \
    $(wildcard include/config/RV_PER_TASK_MONITORS) \
    $(wildcard include/config/USER_EVENTS) \
    $(wildcard include/config/UNWIND_USER) \
    $(wildcard include/config/SCHED_PROXY_EXEC) \
    $(wildcard include/config/SCHED_MM_CID) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/sched.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/processor.h \
    $(wildcard include/config/KUSER_HELPERS) \
    $(wildcard include/config/ARM64_FORCE_52BIT) \
    $(wildcard include/config/HAVE_HW_BREAKPOINT) \
    $(wildcard include/config/ARM64_TAGGED_ADDR_ABI) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/vdso/processor.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/vdso/processor.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/hw_breakpoint.h \
    $(wildcard include/config/CPU_PM) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/virt.h \
    $(wildcard include/config/KVM) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/kasan.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/mte-kasan.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/pointer_auth.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/prctl.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/spectre.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/fpsimd.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/uapi/asm/sigcontext.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/futex_types.h \
    $(wildcard include/config/FUTEX) \
    $(wildcard include/config/FUTEX_PRIVATE_HASH) \
    $(wildcard include/config/FUTEX_ROBUST_UNLOCK) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/mutex_types.h \
    $(wildcard include/config/MUTEX_SPIN_ON_OWNER) \
    $(wildcard include/config/DEBUG_MUTEXES) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/osq_lock.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/spinlock_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rwlock_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/pid_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sem_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/shm.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/page.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/personality.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/personality.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/getorder.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/shmparam.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/shmparam.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kmsan_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/plist_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/hrtimer_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/timerqueue_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rbtree_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/timer_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/seccomp_types.h \
    $(wildcard include/config/SECCOMP) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/refcount_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/resource.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/resource.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/uapi/asm/resource.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/resource.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/asm-generic/resource.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/latencytop.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sched/prio.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sched/types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/signal_types.h \
    $(wildcard include/config/OLD_SIGACTION) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/signal.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/signal.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/uapi/asm/signal.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/signal.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/asm-generic/signal.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/asm-generic/signal-defs.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/uapi/asm/siginfo.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/asm-generic/siginfo.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/spinlock.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/bottom_half.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/instruction_pointer.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/lockdep.h \
    $(wildcard include/config/DEBUG_LOCKING_API_SELFTESTS) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/asm/mmiowb.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/mmiowb.h \
    $(wildcard include/config/MMIOWB) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/spinlock.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/asm/qspinlock.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/qspinlock.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/asm/qrwlock.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/qrwlock.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rwlock.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/spinlock_api_smp.h \
    $(wildcard include/config/INLINE_SPIN_LOCK) \
    $(wildcard include/config/INLINE_SPIN_LOCK_BH) \
    $(wildcard include/config/INLINE_SPIN_LOCK_IRQ) \
    $(wildcard include/config/INLINE_SPIN_LOCK_IRQSAVE) \
    $(wildcard include/config/INLINE_SPIN_TRYLOCK) \
    $(wildcard include/config/INLINE_SPIN_TRYLOCK_BH) \
    $(wildcard include/config/UNINLINE_SPIN_UNLOCK) \
    $(wildcard include/config/INLINE_SPIN_UNLOCK_BH) \
    $(wildcard include/config/INLINE_SPIN_UNLOCK_IRQ) \
    $(wildcard include/config/INLINE_SPIN_UNLOCK_IRQRESTORE) \
    $(wildcard include/config/GENERIC_LOCKBREAK) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rwlock_api_smp.h \
    $(wildcard include/config/INLINE_READ_LOCK) \
    $(wildcard include/config/INLINE_WRITE_LOCK) \
    $(wildcard include/config/INLINE_READ_LOCK_BH) \
    $(wildcard include/config/INLINE_WRITE_LOCK_BH) \
    $(wildcard include/config/INLINE_READ_LOCK_IRQ) \
    $(wildcard include/config/INLINE_WRITE_LOCK_IRQ) \
    $(wildcard include/config/INLINE_READ_LOCK_IRQSAVE) \
    $(wildcard include/config/INLINE_WRITE_LOCK_IRQSAVE) \
    $(wildcard include/config/INLINE_READ_TRYLOCK) \
    $(wildcard include/config/INLINE_WRITE_TRYLOCK) \
    $(wildcard include/config/INLINE_READ_UNLOCK) \
    $(wildcard include/config/INLINE_WRITE_UNLOCK) \
    $(wildcard include/config/INLINE_READ_UNLOCK_BH) \
    $(wildcard include/config/INLINE_WRITE_UNLOCK_BH) \
    $(wildcard include/config/INLINE_READ_UNLOCK_IRQ) \
    $(wildcard include/config/INLINE_WRITE_UNLOCK_IRQ) \
    $(wildcard include/config/INLINE_READ_UNLOCK_IRQRESTORE) \
    $(wildcard include/config/INLINE_WRITE_UNLOCK_IRQRESTORE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/syscall_user_dispatch_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/mm_types_task.h \
    $(wildcard include/config/ARCH_WANT_BATCHED_UNMAP_TLB_FLUSH) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/tlbbatch.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/netdevice_xmit.h \
    $(wildcard include/config/NET_ACT_MIRRED) \
    $(wildcard include/config/NET_EGRESS) \
    $(wildcard include/config/NF_DUP_NETDEV) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/task_io_accounting.h \
    $(wildcard include/config/TASK_IO_ACCOUNTING) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/posix-timers_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rseq_types.h \
    $(wildcard include/config/RSEQ) \
    $(wildcard include/config/RSEQ_SLICE_EXTENSION) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/irq_work_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/workqueue_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/seqlock_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kcsan.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rv.h \
    $(wildcard include/config/RV_LTL_MONITOR) \
    $(wildcard include/config/RV_HA_MONITOR) \
    $(wildcard include/config/RV_REACTORS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/uidgid_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/tracepoint-defs.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/unwind_deferred_types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/asm/kmap_size.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/kmap_size.h \
    $(wildcard include/config/DEBUG_KMAP_LOCAL) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/generated/rq-offsets.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sched/ext.h \
    $(wildcard include/config/EXT_GROUP_SCHED) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/clocksource/arm_arch_timer.h \
    $(wildcard include/config/ARM_ARCH_TIMER) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/timecounter.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/timex.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/vdso/time32.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/vdso/time.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/compat.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/compat.h \
    $(wildcard include/config/COMPAT_FOR_U64_ALIGNMENT) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sched/task_stack.h \
    $(wildcard include/config/STACK_GROWSUP) \
    $(wildcard include/config/DEBUG_STACK_USAGE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/magic.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/refcount.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kasan.h \
    $(wildcard include/config/KASAN_STACK) \
    $(wildcard include/config/KASAN_VMALLOC) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/stat.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/uidgid.h \
    $(wildcard include/config/MULTIUSER) \
    $(wildcard include/config/USER_NS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/highuid.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/buildid.h \
    $(wildcard include/config/VMCORE_INFO) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kmod.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/umh.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/gfp.h \
    $(wildcard include/config/ZONE_DMA) \
    $(wildcard include/config/ZONE_DMA32) \
    $(wildcard include/config/ZONE_DEVICE) \
    $(wildcard include/config/CONTIG_ALLOC) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/mmzone.h \
    $(wildcard include/config/ARCH_FORCE_MAX_ORDER) \
    $(wildcard include/config/PAGE_BLOCK_MAX_ORDER) \
    $(wildcard include/config/HAVE_GIGANTIC_FOLIOS) \
    $(wildcard include/config/HUGETLB_PAGE) \
    $(wildcard include/config/HUGETLB_PAGE_OPTIMIZE_VMEMMAP) \
    $(wildcard include/config/CMA) \
    $(wildcard include/config/MEMORY_ISOLATION) \
    $(wildcard include/config/ZSMALLOC) \
    $(wildcard include/config/UNACCEPTED_MEMORY) \
    $(wildcard include/config/IOMMU_SUPPORT) \
    $(wildcard include/config/SWAP) \
    $(wildcard include/config/TRANSPARENT_HUGEPAGE) \
    $(wildcard include/config/LRU_GEN_STATS) \
    $(wildcard include/config/LRU_GEN_WALKS_MMU) \
    $(wildcard include/config/MEMORY_FAILURE) \
    $(wildcard include/config/PAGE_EXTENSION) \
    $(wildcard include/config/DEFERRED_STRUCT_PAGE_INIT) \
    $(wildcard include/config/HAVE_MEMORYLESS_NODES) \
    $(wildcard include/config/SPARSEMEM_EXTREME) \
    $(wildcard include/config/SPARSEMEM_VMEMMAP_PREINIT) \
    $(wildcard include/config/HAVE_ARCH_PFN_VALID) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/list_nulls.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/wait.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/seqlock.h \
    $(wildcard include/config/CC_IS_GCC) \
    $(wildcard include/config/GCC_VERSION) \
    $(wildcard include/config/UBSAN_ALIGNMENT) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/mutex.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/debug_locks.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/pageblock-flags.h \
    $(wildcard include/config/HUGETLB_PAGE_SIZE_VARIABLE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/page-flags-layout.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/generated/bounds.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/mm_types.h \
    $(wildcard include/config/HAVE_ALIGNED_STRUCT_PAGE) \
    $(wildcard include/config/SLAB_OBJ_EXT) \
    $(wildcard include/config/HUGETLB_PMD_PAGE_TABLE_SHARING) \
    $(wildcard include/config/SLAB_FREELIST_HARDENED) \
    $(wildcard include/config/USERFAULTFD) \
    $(wildcard include/config/ANON_VMA_NAME) \
    $(wildcard include/config/PER_VMA_LOCK) \
    $(wildcard include/config/HAVE_ARCH_COMPAT_MMAP_BASES) \
    $(wildcard include/config/MEMBARRIER) \
    $(wildcard include/config/ARCH_HAS_ELF_CORE_EFLAGS) \
    $(wildcard include/config/AIO) \
    $(wildcard include/config/MMU_NOTIFIER) \
    $(wildcard include/config/SPLIT_PMD_PTLOCKS) \
    $(wildcard include/config/IOMMU_MM_DATA) \
    $(wildcard include/config/KSM) \
    $(wildcard include/config/MM_ID) \
    $(wildcard include/config/CORE_DUMP_DEFAULT_ELF_HEADERS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/auxvec.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/auxvec.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/uapi/asm/auxvec.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kref.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rbtree.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rcupdate.h \
    $(wildcard include/config/TINY_RCU) \
    $(wildcard include/config/RCU_STRICT_GRACE_PERIOD) \
    $(wildcard include/config/RCU_LAZY) \
    $(wildcard include/config/RCU_STALL_COMMON) \
    $(wildcard include/config/VIRT_XFER_TO_GUEST_WORK) \
    $(wildcard include/config/RCU_NOCB_CPU) \
    $(wildcard include/config/TASKS_RCU_GENERIC) \
    $(wildcard include/config/TASKS_RUDE_RCU) \
    $(wildcard include/config/TREE_RCU) \
    $(wildcard include/config/DEBUG_OBJECTS_RCU_HEAD) \
    $(wildcard include/config/PROVE_RCU) \
    $(wildcard include/config/ARCH_WEAK_RELEASE_ACQUIRE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/context_tracking_irq.h \
    $(wildcard include/config/CONTEXT_TRACKING_IDLE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rcutree.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/maple_tree.h \
    $(wildcard include/config/MAPLE_RCU_DISABLED) \
    $(wildcard include/config/DEBUG_MAPLE_TREE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rwsem.h \
    $(wildcard include/config/RWSEM_SPIN_ON_OWNER) \
    $(wildcard include/config/DEBUG_RWSEMS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/completion.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/swait.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/uprobes.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/timer.h \
    $(wildcard include/config/DEBUG_OBJECTS_TIMERS) \
    $(wildcard include/config/NO_HZ_COMMON) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/ktime.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/jiffies.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/vdso/jiffies.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/generated/timeconst.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/vdso/ktime.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/timekeeping.h \
    $(wildcard include/config/POSIX_AUX_CLOCKS) \
    $(wildcard include/config/GENERIC_CMOS_UPDATE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/clocksource_ids.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/debugobjects.h \
    $(wildcard include/config/DEBUG_OBJECTS) \
    $(wildcard include/config/DEBUG_OBJECTS_FREE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/workqueue.h \
    $(wildcard include/config/DEBUG_OBJECTS_WORK) \
    $(wildcard include/config/FREEZER) \
    $(wildcard include/config/WQ_WATCHDOG) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/percpu_counter.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/mmu.h \
    $(wildcard include/config/ARM64_E0PD) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/page-flags.h \
    $(wildcard include/config/PAGE_IDLE_FLAG) \
    $(wildcard include/config/ARCH_USES_PG_ARCH_2) \
    $(wildcard include/config/ARCH_USES_PG_ARCH_3) \
    $(wildcard include/config/MIGRATION) \
    $(wildcard include/config/DEBUG_KMAP_LOCAL_FORCE_MAP) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/local_lock.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/local_lock_internal.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/zswap.h \
    $(wildcard include/config/ZSWAP) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/memory_hotplug.h \
    $(wildcard include/config/ARCH_HAS_ADD_PAGES) \
    $(wildcard include/config/MEMORY_HOTREMOVE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/notifier.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/srcu.h \
    $(wildcard include/config/TINY_SRCU) \
    $(wildcard include/config/NEED_SRCU_NMI_SAFE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rcu_segcblist.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/srcutree.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rcu_node_tree.h \
    $(wildcard include/config/RCU_FANOUT) \
    $(wildcard include/config/RCU_FANOUT_LEAF) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/asm/mmzone.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/mmzone.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/topology.h \
    $(wildcard include/config/USE_PERCPU_NUMA_NODE_ID) \
    $(wildcard include/config/SCHED_SMT) \
    $(wildcard include/config/GENERIC_ARCH_TOPOLOGY) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/arch_topology.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/topology.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/numa.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/numa.h \
    $(wildcard include/config/NUMA_EMU) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/topology.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sysctl.h \
    $(wildcard include/config/SYSCTL) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/sysctl.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/elf.h \
    $(wildcard include/config/ARCH_HAVE_EXTRA_ELF_NOTES) \
    $(wildcard include/config/ARCH_USE_GNU_PROPERTY) \
    $(wildcard include/config/ARCH_HAVE_ELF_PROT) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/elf.h \
    $(wildcard include/config/COMPAT_VDSO) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/generated/asm/user.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/user.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/elf.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/elf-em.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/fs.h \
    $(wildcard include/config/FANOTIFY_ACCESS_PERMISSIONS) \
    $(wildcard include/config/FS_POSIX_ACL) \
    $(wildcard include/config/CGROUP_WRITEBACK) \
    $(wildcard include/config/IMA) \
    $(wildcard include/config/FILE_LOCKING) \
    $(wildcard include/config/FSNOTIFY) \
    $(wildcard include/config/EPOLL) \
    $(wildcard include/config/FS_DAX) \
    $(wildcard include/config/BLOCK) \
    $(wildcard include/config/UNICODE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/fs/super.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/fs/super_types.h \
    $(wildcard include/config/QUOTA) \
    $(wildcard include/config/FS_ENCRYPTION) \
    $(wildcard include/config/FS_VERITY) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/fs_dirent.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/errseq.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/list_lru.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/shrinker.h \
    $(wildcard include/config/SHRINKER_DEBUG) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/xarray.h \
    $(wildcard include/config/XARRAY_MULTI) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sched/mm.h \
    $(wildcard include/config/MMU_LAZY_TLB_REFCOUNT) \
    $(wildcard include/config/ARCH_HAS_MEMBARRIER_CALLBACKS) \
    $(wildcard include/config/ARCH_HAS_SYNC_CORE_BEFORE_USERMODE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sync_core.h \
    $(wildcard include/config/ARCH_HAS_PREPARE_SYNC_CORE_CMD) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sched/coredump.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/list_bl.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/bit_spinlock.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/percpu-rwsem.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rcuwait.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sched/signal.h \
    $(wildcard include/config/SCHED_AUTOGROUP) \
    $(wildcard include/config/BSD_PROCESS_ACCT) \
    $(wildcard include/config/TASKSTATS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rculist.h \
    $(wildcard include/config/PROVE_RCU_LIST) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/signal.h \
    $(wildcard include/config/DYNAMIC_SIGFRAME) \
    $(wildcard include/config/PROC_FS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sched/jobctl.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sched/task.h \
    $(wildcard include/config/HAVE_EXIT_THREAD) \
    $(wildcard include/config/ARCH_WANTS_DYNAMIC_TASK_STRUCT) \
    $(wildcard include/config/HAVE_ARCH_THREAD_STRUCT_WHITELIST) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/uaccess.h \
    $(wildcard include/config/ARCH_HAS_SUBPAGE_FAULTS) \
    $(wildcard include/config/ARCH_MEMORY_ORDER_TSO) \
    $(wildcard include/config/HARDENED_USERCOPY) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/fault-inject-usercopy.h \
    $(wildcard include/config/FAULT_INJECTION_USERCOPY) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/nospec.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/ucopysize.h \
    $(wildcard include/config/HARDENED_USERCOPY_DEFAULT_ON) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/uaccess.h \
    $(wildcard include/config/CC_HAS_ASM_GOTO_OUTPUT) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/kernel-pgtable.h \
    $(wildcard include/config/RELOCATABLE) \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/asm-extable.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/mte.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/extable.h \
    $(wildcard include/config/BPF_JIT) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/access_ok.h \
    $(wildcard include/config/ALTERNATE_USER_ADDRESS_SPACE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/cred.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/capability.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/capability.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/key.h \
    $(wildcard include/config/KEY_NOTIFICATIONS) \
    $(wildcard include/config/NET) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/assoc_array.h \
    $(wildcard include/config/ASSOCIATIVE_ARRAY) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sched/user.h \
    $(wildcard include/config/VFIO_PCI_ZDEV_KVM) \
    $(wildcard include/config/IOMMUFD) \
    $(wildcard include/config/WATCH_QUEUE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/ratelimit.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/pid.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rhashtable-types.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/posix-timers.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/alarmtimer.h \
    $(wildcard include/config/RTC_CLASS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/hrtimer.h \
    $(wildcard include/config/HIGH_RES_TIMERS) \
    $(wildcard include/config/TIME_LOW_RES) \
    $(wildcard include/config/TIMERFD) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/hrtimer_defs.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/timerqueue.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/hrtimer_rearm.h \
    $(wildcard include/config/HRTIMER_REARM_DEFERRED) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rcuref.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rcu_sync.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/quota.h \
    $(wildcard include/config/QUOTA_NETLINK_INTERFACE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/dqblk_xfs.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/dqblk_v1.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/dqblk_v2.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/dqblk_qtree.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/projid.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/quota.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/unicode.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/dcache.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rculist_bl.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/lockref.h \
    $(wildcard include/config/ARCH_USE_CMPXCHG_LOCKREF) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/stringhash.h \
    $(wildcard include/config/DCACHE_WORD_ACCESS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/hash.h \
    $(wildcard include/config/HAVE_ARCH_HASH) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/vfsdebug.h \
    $(wildcard include/config/DEBUG_VFS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/wait_bit.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kdev_t.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/kdev_t.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/path.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/radix-tree.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/semaphore.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/fcntl.h \
    $(wildcard include/config/ARCH_32BIT_OFF_T) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/fcntl.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/uapi/asm/fcntl.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/asm-generic/fcntl.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/openat2.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/migrate_mode.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/delayed_call.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/ioprio.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sched/rt.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/iocontext.h \
    $(wildcard include/config/BLK_ICQ) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/ioprio.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/mount.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/mnt_idmapping.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/slab.h \
    $(wildcard include/config/FAILSLAB) \
    $(wildcard include/config/KFENCE) \
    $(wildcard include/config/SLUB_TINY) \
    $(wildcard include/config/SLUB_DEBUG) \
    $(wildcard include/config/KMALLOC_PARTITION_RANDOM) \
    $(wildcard include/config/KMALLOC_PARTITION_TYPED) \
    $(wildcard include/config/SLAB_BUCKETS) \
    $(wildcard include/config/KVFREE_RCU_BATCHED) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/percpu-refcount.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rw_hint.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/file_ref.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/uapi/linux/fs.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kobject.h \
    $(wildcard include/config/UEVENT_HELPER) \
    $(wildcard include/config/DEBUG_KOBJECT_RELEASE) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/sysfs.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kernfs.h \
    $(wildcard include/config/KERNFS) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/idr.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/kobject_ns.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/moduleparam.h \
    $(wildcard include/config/ALPHA) \
    $(wildcard include/config/PPC64) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/rbtree_latch.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/error-injection.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/error-injection.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/dynamic_debug.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/module.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/asm-generic/module.h \
    $(wildcard include/config/HAVE_MOD_ARCH_SPECIFIC) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/build-salt.h \
    $(wildcard include/config/BUILD_SALT) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/elfnote.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/elfnote-lto.h \
  /home/franz/sp12-kernel-rebuild/linux-next/include/linux/vermagic.h \
    $(wildcard include/config/PREEMPT_BUILD) \
  /home/franz/sp12-kernel-rebuild/linux-next/include/generated/utsrelease.h \
  /home/franz/sp12-kernel-rebuild/linux-next/arch/arm64/include/asm/vermagic.h \

.module-common.o: $(deps_.module-common.o)

$(deps_.module-common.o):
