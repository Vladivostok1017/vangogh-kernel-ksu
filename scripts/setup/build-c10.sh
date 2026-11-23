#!/usr/bin/env bash
set -o pipefail
K="$HOME/work/driftwood"
LOG="$HOME/work/build-c10.log"
export PATH="$HOME/bin:$PATH"
OUT="$HOME/work/out-c10"

echo "=== [1] 谁引用 default_defconfig / AUDIO_ROOT 定义在哪 ===" | tee "$LOG"
grep -rn "default_defconfig" "$K/techpack/audio" --include=Kbuild --include=Makefile 2>/dev/null | head -5
grep -rn "AUDIO_ROOT" "$K/techpack/audio" --include=Kbuild --include=Makefile 2>/dev/null | grep -v "include\|-include" | head -5

echo
echo "=== [2] 造缺失的片段 ===" | tee -a "$LOG"
mkdir -p "$K/techpack/audio/configs"
[ -f "$K/techpack/audio/configs/default_defconfig" ] || : > "$K/techpack/audio/configs/default_defconfig"
[ -f "$K/techpack/audio/config/litoauto.conf" ] || grep -E "^CONFIG_" "$HOME/work/out-c8/.config" > "$K/techpack/audio/config/litoauto.conf"
ls -l "$K/techpack/audio/config/litoauto.conf" "$K/techpack/audio/config/litoautoconf.h" 2>&1 | head -3

echo
echo "=== [3] 编译（显式传 AUDIO_ROOT）===" | tee -a "$LOG"
cd "$K" || exit 1
rm -rf "$OUT"
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 KERNEL_BUILD=0 \
       AUDIO_ROOT="$K/techpack/audio" \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j8 "${MAKE[@]}" vendor/vangogh_user_defconfig >> "$LOG" 2>&1 || { echo "defconfig 失败"; exit 1; }
make -j8 "${MAKE[@]}" olddefconfig >> "$LOG" 2>&1
make -j16 "${MAKE[@]}" Image >> "$LOG" 2>&1; echo "Image exit=$?" | tee -a "$LOG"
grep -nE "No rule|error:|undefined symbol" "$LOG" | head -8
IMG="$OUT/arch/arm64/boot/Image"
[ -f "$IMG" ] && { ls -l "$IMG"; echo IMAGE_OK; } || echo IMAGE_MISSING
