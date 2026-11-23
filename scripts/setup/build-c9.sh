#!/usr/bin/env bash
set -o pipefail
K="$HOME/work/driftwood"
LOG="$HOME/work/build-c9.log"
export PATH="$HOME/bin:$PATH"
OUT="$HOME/work/out-c9"

echo "=== [1] 检查 config 目录 ===" | tee "$LOG"
ls "$K/techpack/audio/config/" 2>/dev/null | head -10
ls "$K/techpack/audio/config/lito"* 2>/dev/null || echo "  lito 片段缺失 → 将生成"

echo
echo "=== [2] 由 .config 生成 litoauto.conf 与 litoautoconf.h ===" | tee -a "$LOG"
SRC="$HOME/work/out-c8/.config"
[ -f "$SRC" ] || SRC="$HOME/work/out-c5/.config"
echo "源配置: $SRC" | tee -a "$LOG"
# auto.conf 形式
grep -E "^CONFIG_" "$SRC" > "$K/techpack/audio/config/litoauto.conf"
# autoconf.h 形式
awk -F= '/^CONFIG_/ {
  v=$2; name=$1;
  if (v=="y") print "#define " name " 1";
  else if (v=="m") print "#define " name "_MODULE 1";
  else { gsub(/"/,"",v); print "#define " name " " v }
}' "$SRC" > "$K/techpack/audio/config/litoautoconf.h"
wc -l "$K/techpack/audio/config/litoauto.conf" "$K/techpack/audio/config/litoautoconf.h"

echo
echo "=== [3] 编译 Image（内核不含音频）===" | tee -a "$LOG"
cd "$K" || exit 1
rm -rf "$OUT"
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 KERNEL_BUILD=0 \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j8 "${MAKE[@]}" vendor/vangogh_user_defconfig >> "$LOG" 2>&1 || { echo "defconfig 失败"; tail -6 "$LOG"; exit 1; }
make -j8 "${MAKE[@]}" olddefconfig >> "$LOG" 2>&1
make -j16 "${MAKE[@]}" Image >> "$LOG" 2>&1; echo "Image exit=$?" | tee -a "$LOG"
grep -nE "No rule|error:|undefined symbol" "$LOG" | head -8
IMG="$OUT/arch/arm64/boot/Image"
[ -f "$IMG" ] && { ls -l "$IMG"; echo IMAGE_OK; } || echo IMAGE_MISSING
