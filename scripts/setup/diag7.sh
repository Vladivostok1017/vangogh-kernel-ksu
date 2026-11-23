#!/usr/bin/env bash
cd "$HOME/vanilla/src/pe13-kernel" || exit 1
OUT="$HOME/vanilla/out-vanilla"

echo "=== Makefile 中 CLANG_FLAGS 定义 ==="
grep -n "CLANG_FLAGS" Makefile | head -10

echo
echo "=== 测试：覆盖 CLANG_FLAGS 后编 vdso ==="
ARGS=( O="$OUT" ARCH=arm64 "CC=clang-14" CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- "CLANG_FLAGS=--target=aarch64-linux-gnu" )
rm -f "$OUT/arch/arm64/kernel/vdso/gettimeofday.o"
make -j1 V=1 "${ARGS[@]}" arch/arm64/kernel/vdso/gettimeofday.o > /tmp/clangflags_test.log 2>&1
echo "exit=$?"
tail -5 /tmp/clangflags_test.log
echo
echo "=== 若成功，看 as 调用 ==="
grep -c "gettimeofday.o" /tmp/clangflags_test.log
