#!/usr/bin/env bash
set -o pipefail
P="http://127.0.0.1:17890"
export http_proxy="$P" https_proxy="$P"
mkdir -p ~/vanilla/src
cd ~/vanilla/src
if [ ! -d driftwood ]; then
  git clone --depth=1 -b android-4.19-standalone \
    https://github.com/WeeAris/Driftwood_kernel_xiaomi_sm7250.git driftwood 2>&1 | tail -3
fi
K=~/vanilla/src/driftwood
echo "=== 版本 ==="
head -5 "$K/Makefile"
echo
echo "=== defconfig ==="
ls "$K/arch/arm64/configs/vendor/" 2>/dev/null | head -20
echo
echo "=== 是否有 KernelSU ==="
ls -d "$K/drivers/kernelsu" 2>/dev/null || echo "无 drivers/kernelsu"
grep -rl "KernelSU\|KSU" "$K/arch/arm64/configs/" 2>/dev/null | head -3
echo
echo "=== 关键：MIUI 私有驱动是否在内 ==="
for sym in MIHW MILLET MIGT MI_MEMORY_SYSFS MI_RECLAIM SF_BINDER PERF_CRITICAL_RT_TASK; do
  hit=$(grep -rl "config $sym" "$K" --include=Kconfig 2>/dev/null | head -1)
  printf '%-26s %s\n' "$sym" "${hit:-❌ 无}"
done
echo
echo "=== 设备树里有没有 vangogh ==="
find "$K/arch/arm64/boot/dts" -iname "*vangogh*" 2>/dev/null | head -5
echo
echo "=== 构建脚本 ==="
ls "$K" | grep -iE "build|\.sh$" | head -10
