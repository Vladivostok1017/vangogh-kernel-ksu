#!/usr/bin/env bash
set -o pipefail
K="$HOME/vanilla/src/driftwood"
LOG="$HOME/vanilla/logs/build-drift.log"
export PATH="$HOME/bin:$PATH"
MAKE=( O="$HOME/vanilla/out-drift" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
       LLVM=1 LLVM_IAS=1 "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
cd "$K" || exit 1

echo "=== 重新生成 .config（从含 MIGT/MILLET 的 defconfig）==="
: > "$LOG"
make -j4 "${MAKE[@]}" vendor/vangogh_user_defconfig >> "$LOG" 2>&1 || { echo "defconfig 失败"; tail -10 "$LOG"; exit 1; }
make -j4 "${MAKE[@]}" olddefconfig >> "$LOG" 2>&1
echo "--- 关键配置生效情况 ---"
grep -E "^CONFIG_(MIHW|MIGT|MILLET|MIGT_ENERGY_MODEL|SF_BINDER|PERF_CRITICAL_RT_TASK|KSU|KPROBES|KRETPROBES)=" "$HOME/vanilla/out-drift/.config"

echo
echo "=== 编译 ==="
make -j16 "${MAKE[@]}" Image >> "$LOG" 2>&1
echo "make exit=$?"
echo "=== 错误 ==="
grep -nE " error:|Error [12]\b|undefined symbol" "$LOG" | head -10
ls -l "$HOME/vanilla/out-drift/arch/arm64/boot/Image" 2>/dev/null && echo IMAGE_OK || echo IMAGE_MISSING
