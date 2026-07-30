#!/bin/bash
set -e
cd /root/linux-next
LOG=/mnt/c/sp12-linux/build.log
exec >> "$LOG" 2>&1
echo "=== STAGE2 config start $(date -u +%H:%M:%S) ==="
make defconfig >/dev/null
echo "--- symboles clk qcom pertinents ---"
CLKS=$(grep -hoE 'config [A-Z0-9_]+' drivers/clk/qcom/Kconfig | awk '{print $2}' | grep -E 'X1P42100|X1E80100|SC8280XP' | sort -u)
echo "$CLKS"
# clocks + pinctrl en INTEGRE (=y) -> boot sans dependre de l'initramfs
for s in $CLKS; do ./scripts/config --enable "$s"; done
PINS=$(grep -hoE 'config [A-Z0-9_]+' drivers/pinctrl/qcom/Kconfig | awk '{print $2}' | grep -E 'X1E80100|X1P42100' | sort -u)
echo "--- pinctrl: $PINS ---"
for s in $PINS; do ./scripts/config --enable "$s"; done
# essentiels plateforme en =y
for s in ARCH_QCOM COMMON_CLK_QCOM QCOM_RPMHPD QCOM_SMD_RPM QCOM_RPMH INTERCONNECT INTERCONNECT_QCOM QCOM_SCM QCOM_TSENS PINCTRL_MSM QCOM_GPI_DMA SPMI SPMI_MSM_PMIC_ARB MFD_QCOM_SPMI_PMIC REGULATOR_QCOM_RPMH PHY_QCOM_QMP COMMON_CLK_QCOM_GDSC; do ./scripts/config --enable "$s" 2>/dev/null || true; done
# peripheriques en module (charges depuis le rootfs)
for s in DRM DRM_MSM DRM_MSM_DP ATH12K MHI_BUS QCOM_Q6V5_PAS QCOM_PIL_INFO SCSI_UFS_QCOM PHY_QCOM_EUSB2 PHY_QCOM_SNPS_EUSB2 TYPEC_QCOM_PMIC QCOM_PMIC_GLINK LEDS_QCOM_LPG; do ./scripts/config --module "$s" 2>/dev/null || true; done
# infos pour debug / IKCONFIG dispo
./scripts/config --enable IKCONFIG --enable IKCONFIG_PROC
make olddefconfig >/dev/null
echo "--- valeurs cles ---"
for s in CLK_X1P42100_GPUCC CLK_X1P42100_CAMCC CLK_X1P42100_VIDEOCC DRM_MSM ATH12K ARCH_QCOM PINCTRL_MSM; do
  printf '  %s=%s\n' "$s" "$(./scripts/config --state "$s" 2>/dev/null)"
done
echo "=== STAGE2 config done $(date -u +%H:%M:%S) ==="
