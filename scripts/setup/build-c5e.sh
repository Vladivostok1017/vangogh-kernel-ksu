#!/usr/bin/env bash
# Switch KSU source back to KernelSU v0.9.5 and rebuild INCREMENTALLY in out-c5
set -o pipefail
K="$HOME/work/driftwood"
OUT="$HOME/work/out-c5"
LOG="$HOME/work/build-c5e.log"
export PATH="$HOME/bin:$PATH"

echo "=== [1] 确认 KernelSU 仓库在 v0.9.5 ==="
cd "$K/KernelSU" && git describe --tags 2>/dev/null || git rev-parse --short HEAD
git checkout -f v0.9.5 >/dev/null 2>&1 && echo "checkout v0.9.5 OK"
ls kernel/Kconfig >/dev/null && echo "kernel 目录 OK"

echo
echo "=== [2] 接线指回 KernelSU/kernel ==="
rm -f "$K/drivers/kernelsu"
ln -sfn "$K/KernelSU/kernel" "$K/drivers/kernelsu"
readlink -f "$K/drivers/kernelsu"

echo
echo "=== [3] 增量重编（只重编 kernelsu + 链接）==="
cd "$K" || exit 1
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
time make -j16 "${MAKE[@]}" Image > "$LOG" 2>&1
echo "make exit=$?"
grep -nE " error:|fatal error|undefined symbol" "$LOG" | head -10
IMG="$OUT/arch/arm64/boot/Image"
if [ -f "$IMG" ]; then
  ls -l "$IMG"
  echo "KSU 字符串数: $(strings -n 5 "$IMG" | grep -c -iE 'kernelsu|ksu_')"
  python3 /mnt/f/vanilla-build/setup/pack_boot.py \
    --src "/mnt/c/Users/Administrator/Downloads/boot.img" \
    --kernel "$IMG" --out /mnt/f/vanilla-build/out-c5.img --pad 134217728 && echo PACKED
else echo IMAGE_MISSING; fi
