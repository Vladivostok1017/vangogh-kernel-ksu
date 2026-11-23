#!/usr/bin/env bash
set -euo pipefail
K="$HOME/work/driftwood"
P="/mnt/f/vangogh-kernel-ksu"
mkdir -p "$P"/{patches,scripts,config,docs,ci}
cd "$K"

echo "=== 1) 生成核心补丁（非 techpack）==="
git add -N include/linux/pgtable.h include/linux/ksu_419_compat.h 2>/dev/null || true
git diff -- kernel/sched/tune.c \
            drivers/power/supply/qcom/smb5-lib.h \
            drivers/soc/qcom/msm_bus/msm_bus_core.h \
            include/linux/pgtable.h \
            include/linux/ksu_419_compat.h \
  > "$P/patches/0001-core-build-fixes.patch"
wc -l "$P/patches/0001-core-build-fixes.patch"

echo "=== 2) 生成 techpack 补丁（-Wno-error + 音频 dlkm WIP）==="
git diff -- techpack/ > "$P/patches/0002-techpack-audio-dlkm-wip.patch"
wc -l "$P/patches/0002-techpack-audio-dlkm-wip.patch"

echo "=== 3) 生成 defconfig 补丁 ==="
git diff -- arch/arm64/configs/vendor/vangogh_user_defconfig > "$P/patches/0003-vangogh-defconfig.patch" || true
wc -l "$P/patches/0003-vangogh-defconfig.patch"

echo "=== 4) 提炼 defconfig 片段（只保留我们新增的 KSU/MIUI/wifi 项）==="
grep -E "^CONFIG_(MIHW|MIGT|MILLET|MIGT_ENERGY_MODEL|SF_BINDER|PERF_CRITICAL_RT_TASK|QCA_CLD_WLAN|KPROBES|KPROBE_EVENTS|KRETPROBES|KSU)=" \
  "$K/arch/arm64/configs/vendor/vangogh_user_defconfig" > "$P/config/vangogh_ksu.fragment" || true
cat "$P/config/vangogh_ksu.fragment"

echo "=== 5) 拷贝脚本 ==="
cp /mnt/f/vanilla-build/setup/pack_boot.py            "$P/scripts/"
cp /mnt/f/vanilla-build/setup/dump-dtb.py             "$P/scripts/" 2>/dev/null || true
cp /mnt/f/vanilla-build/setup/read-pstore.sh          "$P/scripts/" 2>/dev/null || true
cp /mnt/f/vanilla-build/setup/device-backup.sh        "$P/scripts/device-backup-partitions.sh" 2>/dev/null || true
cp /mnt/f/vanilla-build/setup/device-backup-fw.sh     "$P/scripts/device-backup-firmware.sh" 2>/dev/null || true
cp /mnt/f/vanilla-build/boottest.ps1                  "$P/scripts/boottest.ps1" 2>/dev/null || true
cp /mnt/f/vanilla-build/HANDOFF.md                    "$P/docs/HANDOFF.md"
ls -R "$P" | head -40
