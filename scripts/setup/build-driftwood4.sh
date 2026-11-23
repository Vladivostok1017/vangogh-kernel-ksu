#!/usr/bin/env bash
set -o pipefail
K="$HOME/vanilla/src/driftwood"
LOG="$HOME/vanilla/logs/build-drift.log"
export PATH="$HOME/bin:$PATH"

echo "=== 原厂配置里这几项的状态 ==="
gzip -dc /mnt/f/vanilla-build/stock_config.gz > /tmp/stock.config
grep -E "^CONFIG_(MIHW|MIGT|MILLET|MIGT_ENERGY_MODEL|MI_MEMORY_SYSFS|SF_BINDER|PERF_CRITICAL_RT_TASK)=" /tmp/stock.config

echo
echo "=== 在 defconfig 里补齐 ==="
CFG="$K/arch/arm64/configs/vendor/vangogh_user_defconfig"
for opt in MIHW MIGT MILLET MIGT_ENERGY_MODEL SF_BINDER PERF_CRITICAL_RT_TASK; do
  if ! grep -q "^CONFIG_$opt=y" "$CFG"; then
    echo "CONFIG_$opt=y" >> "$CFG"
    echo "  + CONFIG_$opt=y"
  fi
done

echo
echo "=== 重新 olddefconfig + 编译 ==="
cd "$K" || exit 1
MAKE=( O="$HOME/vanilla/out-drift" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
       LLVM=1 LLVM_IAS=1 "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j4 "${MAKE[@]}" olddefconfig >> "$LOG" 2>&1
grep -E "^CONFIG_(MIHW|MIGT|MILLET|MIGT_ENERGY_MODEL|KSU|KPROBES)=" "$HOME/vanilla/out-drift/.config"

make -j16 "${MAKE[@]}" Image >> "$LOG" 2>&1
echo "make exit=$?"
echo "=== 错误 ==="
grep -nE " error:|Error [12]\b|undefined symbol" "$LOG" | head -10
ls -l "$HOME/vanilla/out-drift/arch/arm64/boot/Image" 2>/dev/null && echo IMAGE_OK || echo IMAGE_MISSING
