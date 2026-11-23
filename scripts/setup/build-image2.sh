#!/usr/bin/env bash
# incremental Image build with full logging
cd "$HOME/vanilla/src/pe13-kernel" || exit 1
OUT="$HOME/vanilla/out-vanilla"
LOG="$HOME/vanilla/logs/image-build.log"
mkdir -p "$HOME/vanilla/logs"
ARGS=( O="$OUT" ARCH=arm64 CC=clang-14 CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- \
       "CLANG_FLAGS=--target=aarch64-linux-gnu --gcc-toolchain=/usr -no-integrated-as" \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )

make -j16 "${ARGS[@]}" Image > "$LOG" 2>&1
echo "make exit=$?"
echo "=== 错误 ==="
grep -nE " error:|Error [12]\b" "$LOG" | head -10
echo "=== Image ==="
ls -l "$OUT/arch/arm64/boot/Image" 2>/dev/null && echo IMAGE_OK || echo IMAGE_MISSING
