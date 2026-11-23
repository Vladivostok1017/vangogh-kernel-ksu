#!/usr/bin/env bash
set -o pipefail
K="$HOME/vanilla/src/driftwood"
LOG="$HOME/vanilla/logs/build-drift.log"
export PATH="$HOME/bin:$PATH"

python3 /mnt/f/vanilla-build/setup/patch-driftwood.py
echo
echo "=== 继续编译（增量）==="
cd "$K" || exit 1
MAKE=( O="$HOME/vanilla/out-drift" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
       LLVM=1 LLVM_IAS=1 "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j16 "${MAKE[@]}" Image > "$LOG" 2>&1
echo "make exit=$?"
echo "=== 错误汇总 ==="
grep -nE " error:|Error [12]\b" "$LOG" | head -15
echo "=== 结果 ==="
ls -l "$HOME/vanilla/out-drift/arch/arm64/boot/Image" 2>/dev/null && echo IMAGE_OK || echo IMAGE_MISSING
