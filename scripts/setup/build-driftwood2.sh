#!/usr/bin/env bash
set -o pipefail
K="$HOME/vanilla/src/driftwood"
LOG="$HOME/vanilla/logs/build-drift.log"

echo "=== 修正 KernelSU 路径（父级同级）==="
ls -l "$K/drivers/kernelsu"
ln -sfn "$K/KernelSU" "$HOME/vanilla/src/KernelSU"
echo "父级软链: $(ls -ld "$HOME/vanilla/src/KernelSU")"
echo "解析后: $(readlink -f "$K/drivers/kernelsu")"
test -f "$(readlink -f "$K/drivers/kernelsu")/Kconfig" && echo "Kconfig 可达 ✓" || echo "Kconfig 仍不可达 ✗"

echo
echo "=== KernelSU 版本信息 ==="
grep -rn "KSU_VERSION" "$K/KernelSU/kernel/"*.h "$K/KernelSU/kernel/"*.c 2>/dev/null | head -3
grep -n "KPROBES" "$K/KernelSU/kernel/Kconfig" | head -5
ls "$K/KernelSU/kernel/hook" 2>/dev/null | head -5

echo
echo "=== 重新配置 + 构建 ==="
export PATH="$HOME/bin:$PATH"
cd "$K" || exit 1
rm -rf "$HOME/vanilla/out-drift"
MAKE=( O="$HOME/vanilla/out-drift" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
       LLVM=1 LLVM_IAS=1 "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
: > "$LOG"
make -j4 "${MAKE[@]}" vendor/vangogh_user_defconfig >> "$LOG" 2>&1 || { echo "defconfig 失败"; tail -15 "$LOG"; exit 1; }
make -j4 "${MAKE[@]}" olddefconfig >> "$LOG" 2>&1
echo "--- 生效配置 ---"
grep -E "^CONFIG_(KSU|KPROBES|KRETPROBES|MILLET|MIHW|LOCALVERSION)=" "$HOME/vanilla/out-drift/.config"
make -j16 "${MAKE[@]}" Image >> "$LOG" 2>&1
echo "make exit=$?"
grep -nE " error:|Error [12]\b" "$LOG" | head -8
ls -l "$HOME/vanilla/out-drift/arch/arm64/boot/Image" 2>/dev/null && echo IMAGE_OK || echo IMAGE_MISSING
