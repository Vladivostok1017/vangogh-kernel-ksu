#!/usr/bin/env bash
cd "$HOME/vanilla/src/pe13-kernel" || exit 1
OUT="$HOME/vanilla/out-vanilla"
ARGS=( O="$OUT" ARCH=arm64 CC=clang-14 CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- \
       "CLANG_FLAGS=--target=aarch64-linux-gnu --gcc-toolchain=/usr -no-integrated-as" )

rm -f "$OUT/arch/arm64/kernel/vdso/gettimeofday.o"
echo "=== 测试 vdso gettimeofday.o（GNU as，无 prefix）==="
make -j1 V=1 "${ARGS[@]}" arch/arm64/kernel/vdso/gettimeofday.o > /tmp/vdso_fix.log 2>&1
echo "exit=$?"
tail -4 /tmp/vdso_fix.log
echo
echo "=== clang 子命令里的 as 路径 ==="
CMD=$(grep -m1 "^  clang-14 .*gettimeofday.S" /tmp/vdso_fix.log | sed 's/^  //')
echo "$CMD" | sed 's#-c -o [^ ]*#-c -o /tmp/y.o#' > /tmp/cmd.sh
bash -c "$(cat /tmp/cmd.sh) -###" 2>&1 | grep -oE '"/usr/bin/[a-z0-9-]*as"' | head -3
