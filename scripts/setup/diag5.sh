#!/usr/bin/env bash
cd "$HOME/vanilla/src/pe13-kernel" || exit 1
OUT="$HOME/vanilla/out-vanilla"

echo "=== 检查 Makefile 是否支持 LLVM_IAS ==="
grep -n "LLVM_IAS" Makefile | head -5

echo
echo "=== 用 LLVM_IAS=1 单独编 vdso 目标 ==="
ARGS=( O="$OUT" ARCH=arm64 "CC=clang-14 --target=aarch64-linux-gnu" \
       CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-gnu- LLVM_IAS=1 )
make -j1 V=1 "${ARGS[@]}" arch/arm64/kernel/vdso/gettimeofday.o > /tmp/ias_test.log 2>&1
echo "exit=$?"
tail -6 /tmp/ias_test.log
