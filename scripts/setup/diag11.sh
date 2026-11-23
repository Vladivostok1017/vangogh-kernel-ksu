#!/usr/bin/env bash
cd "$HOME/vanilla/src/pe13-kernel" || exit 1
OUT="$HOME/vanilla/out-vanilla"
BASE=( O="$OUT" ARCH=arm64 CC=clang-14 CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- \
       "CLANG_FLAGS=--target=aarch64-linux-gnu --gcc-toolchain=/usr -no-integrated-as" )

echo "=== 方案A: KCFLAGS 关闭 unused-but-set-variable ==="
rm -f "$OUT/techpack/audio/ipc/apr.o"
make -j4 "${BASE[@]}" "KCFLAGS=-Wno-unused-but-set-variable" techpack/audio/ipc/apr.o > /tmp/kcflags.log 2>&1
echo "exit=$?"
grep -E "error|warning: variable" /tmp/kcflags.log | head -4
echo
echo "=== 方案B（若A失败）: 直接删 techpack Kbuild 里的 -Werror ==="
grep -n -- "-Werror" "$HOME/vanilla/src/pe13-kernel/techpack/audio/ipc/Kbuild" | head -3
sed -n '140,155p' "$HOME/vanilla/src/pe13-kernel/techpack/audio/ipc/Kbuild"
