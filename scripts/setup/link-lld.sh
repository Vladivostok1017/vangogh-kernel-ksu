#!/usr/bin/env bash
cd "$HOME/vanilla/src/pe13-kernel" || exit 1
OUT="$HOME/vanilla/out-vanilla"
COMMON=( O="$OUT" ARCH=arm64 CC=clang-14 CLANG_TRIPLE=aarch64-linux-gnu- \
         CROSS_COMPILE=aarch64-linux-gnu- \
         "CLANG_FLAGS=--target=aarch64-linux-gnu --gcc-toolchain=/usr -no-integrated-as" \
         "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )

echo "=== 方案A: LD=ld.lld-14 仅重链接 ==="
make -j16 "${COMMON[@]}" LD=ld.lld-14 Image > /tmp/lld_link.log 2>&1
echo "exit=$?"
grep -nE "error|Error|relocation|truncated" /tmp/lld_link.log | head -8
ls -l "$OUT/arch/arm64/boot/Image" 2>/dev/null && echo IMAGE_OK || echo IMAGE_MISSING
