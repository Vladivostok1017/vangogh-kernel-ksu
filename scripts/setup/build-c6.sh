#!/usr/bin/env bash
set -o pipefail
K="$HOME/work/driftwood"
OUT="$HOME/work/out-c5"
LOG="$HOME/work/build-c6.log"
export PATH="$HOME/bin:$PATH"

echo "=== [1] 指回 KernelSU v0.9.5 ==="
rm -f "$K/drivers/kernelsu"
ln -sfn "$K/KernelSU/kernel" "$K/drivers/kernelsu"
echo "link -> $(readlink -f "$K/drivers/kernelsu")"
echo "KSU 版本: $(cd "$K/KernelSU" && git describe --tags 2>/dev/null)"
ls "$K/KernelSU/kernel/Kbuild" >/dev/null 2>&1 && echo "Kbuild 存在 OK"

echo
echo "=== [2] 增量重编 ==="
cd "$K" || exit 1
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
time make -j16 "${MAKE[@]}" Image > "$LOG" 2>&1
echo "make exit=$?"
grep -nE " error:|fatal error|undefined symbol" "$LOG" | head -8
IMG="$OUT/arch/arm64/boot/Image"
if [ -f "$IMG" ]; then
  ls -l "$IMG"
  strings -n 10 "$IMG" | grep -m1 "^Linux version 4.19"
  echo "KSU 字符串数: $(strings -n 5 "$IMG" | grep -c -iE 'kernelsu|ksu_')"
  python3 /mnt/f/vanilla-build/setup/pack_boot.py \
    --src "/mnt/c/Users/Administrator/Downloads/boot.img" \
    --kernel "$IMG" --out /mnt/f/vanilla-build/out-c6.img --pad 134217728 && echo PACKED
else echo IMAGE_MISSING; fi
