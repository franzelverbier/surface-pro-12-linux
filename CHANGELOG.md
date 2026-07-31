# Changelog / milestones

All dates 2026. Kernel reference build is **`7.1.0-next-20260626`** unless noted.

## Kernel reference

- **`7.1.0-next-20260626`** — linux-next, compiled 2026-06-26 18:28 (CEST), gcc 13.3.0, GNU ld 2.42. This is *the* reference build carrying `x1p42100` support.
- The stock Arch `linux-aarch64` package (7.1.x) is held in `IgnorePkg`: GRUB boots the custom `/boot/Image`, not the stock kernel/initramfs. A tool reporting "a newer kernel available" is looking at the stock package, not the running kernel.

## Milestones

- **2026-06-26** — First successful boot to root shell on the custom linux-next kernel; console + Bluetooth working.
- **2026-06-28** — KDE desktop shown on the internal panel; Wi-Fi associated, SSH reachable. (Early USB-boot media proved unreliable — a marginal USB flash controller caused ext4 I/O corruption under repeated reboots.)
- **2026-06-30** — Storage-strategy iterations (USB key → Ventoy vdisk → USB SSD); GPT-repair workflow for raw-writing a small image onto a large disk; WPA3-SAE Wi-Fi fix.
- **~2026-07 (early)** — Moved to an **internal ext4 install**, dual-boot with Windows, for full reliability. Internal display + KDE + GPU accel working.
- **2026-07-03** — HW video codec fixed (supplied `qcvss8380_pa.mbn`); `/dev/video0` + `/dev/video1` live. Audio confirmed working (topology now in linux-firmware). Battery telemetry identified as the main remaining issue.
- **2026-07-31** — **Boot cleanup pass.** `sp12-typecover` now waits on real conditions (SAM controller bound, then `surface_aggregator` bus populated) instead of two blind `sleep 1`, with a 3 s guard — longer than the old sleep, so an anomaly waits more, never less. `sp12-usbwifi` shipped disabled (internal Wi-Fi works). `sp12-bootreport` converted from an enabled service to a timer, so its deliberate 20 s settle delay no longer inflates the reported startup time. eDP panel (Sharp SHP 0x15a7) added to `edp_panels[]` to retire the deliberate `WARN_ON` splat and its register dump — note that the module also lives in the initramfs, which is the copy actually loaded, so installing it under `/lib/modules` alone changes nothing (see `patches/README.md`). Empty `modules-load.d/cdrecord.conf` override stops the failing request for the unbuilt `sg` module. Also enabled `CONFIG_BT_RFCOMM=m` — not cosmetic: without it `bluetoothd` cannot start its Hands-Free servers, so Bluetooth headsets with a microphone could not work at all.
- **2026-07-31** — **Audio working at EL2.** ADSP and CDSP are started by qebspil from UEFI before `ExitBootServices`, then *attached* by the kernel instead of started: `qcom,broken-reset` on both remoteproc nodes selects `qcom_pas_ops_no_reset` (no `.start`/`.load`), so the PAS SMC that returns `-22` is never called, and the already-running state is detected by reading the SMP2P IRQ *levels* — the DSPs signalled their boot long before Linux existed, so waiting for an edge could never work. 14 out-of-tree patches; see `patches/audio-el2-serie.md`, including the module-ABI hazard the series introduces.
- **2026-07-30** — **Internal Wi-Fi fixed at EL2.** No MSI was ever delivered — every `ITS-PCI-MSI` counter stayed at zero, PCIe root-port PME included. The cause was in our own DTS: the PCIe SMMUv3 (`iommu@15400000`) was left at `status = "reserved"`. Setting it to `"okay"` fixes it. The SMMU had been "ruled out" days earlier by a test with `arm-smmu.force_stage=1` — a parameter belonging to the SMMUv1/v2 driver, which never touches the SMMUv3. A false negative that cost days.
- **2026-07-14** — Re-established the HW-codec firmware after a restore had dropped it; a hot module reload (`modprobe -r qcom_iris && modprobe qcom_iris`) brings `/dev/video0` + `/dev/video1` back with no reboot. Documented a **safe full `pacman -Syu`** on this device: pin the entire Mesa/Vulkan userspace to a single version (`mesa`, `vulkan-freedreno`, `vulkan-mesa-implicit-layers`) so a partial upgrade can't skew the Adreno/turnip stack, with kernel + systemd held in `IgnorePkg`; cold boot validated. Added an `fstab` recipe to auto-mount the shared data partition with `nofail` + `x-systemd.automount` (see README → Stability notes).

## Upcoming

- **Linux 7.2** integrates the SP12 DTS in mainline → the custom DTB and home-compiled kernel are expected to become unnecessary.
