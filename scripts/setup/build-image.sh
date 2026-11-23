#!/usr/bin/env bash
cd "$HOME/vanilla/src/pe13-kernel" || exit 1
OUT="$HOME/vanilla/out-vanilla"
ARGS=( O="$OUT" ARCH=arm64 CC=clang-14 CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- \
       "CLANG_FLAGS=--target=aarch64-linux-gnu --gcc-toolchain=/usr -no-integrated-as" )

make -j16 "${ARGS[@]}" Image > /tmp/image_build.log 2>&1
echo "exit=$?"
echo "=== 错误行 ==="
grep -nE "error|Error|undefined|cannot|No such" /tmp/image_build.log | grep -v "warning" | head -20
echo
echo "=== 最后 25 行 ==="
tail -25 /tmp/image_build.log
