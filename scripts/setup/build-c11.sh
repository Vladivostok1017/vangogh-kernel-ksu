#!/usr/bin/env bash
set -o pipefail
K="$HOME/work/driftwood"
A="$K/techpack/audio"
LOG="$HOME/work/build-c11.log"
OUT="$HOME/work/out-c11"
export PATH="$HOME/bin:$PATH"
: > "$LOG"

echo "=== [1] 批量创建所有被引用的 config 片段（空壳即可，靠 -include 提供定义） ===" | tee -a "$LOG"
mkdir -p "$A/config" "$A/configs"
for name in lito litoauto sm8150 kona sm6150 bengal sa8155 sa6155 qcs405 sdm660 sdm670 lahaiha lahaina sdxpoorwills; do
  :
done
# 由 .config 生成 lito 的两个片段
SRC="$HOME/work/out-c8/.config"
[ -f "$SRC" ] || SRC="$HOME/work/out-c5/.config"
grep -E "^CONFIG_" "$SRC" > "$A/config/litoauto.conf"
awk -F= '/^CONFIG_/ { v=$2; n=$1;
  if (v=="y") print "#define " n " 1";
  else if (v=="m") print "#define " n "_MODULE 1";
  else { gsub(/"/,"",v); print "#define " n " " v } }' "$SRC" > "$A/config/litoautoconf.h"
# 其余平台的片段：凡是代码里 include 到的，都建空文件兜底
grep -rhoE 'config/[a-z0-9_]+auto\.(conf|h)' "$A" --include=Kbuild --include=Makefile 2>/dev/null | sort -u | while read -r rel; do
  f="$A/$rel"
  [ -f "$f" ] || : > "$f"
done
[ -f "$A/configs/default_defconfig" ] || : > "$A/configs/default_defconfig"
echo "  config 目录文件数: $(ls "$A/config" | wc -l)" | tee -a "$LOG"

echo "=== [2] 屏蔽 KBUILD_EXTRA_SYMBOLS（小米 OUT 路径，本构建不需要） ===" | tee -a "$LOG"
grep -rl "KBUILD_EXTRA_SYMBOLS" "$A" --include=Kbuild --include=Makefile 2>/dev/null | while read -r f; do
  sed -i 's|^\([[:space:]]*\)KBUILD_EXTRA_SYMBOLS|\1# KBUILD_EXTRA_SYMBOLS|' "$f"
done
echo "  已注释行数: $(grep -rc "KBUILD_EXTRA_SYMBOLS" "$A" --include=Kbuild 2>/dev/null | awk -F: '{s+=$2} END{print s}')" | tee -a "$LOG"

echo "=== [3] 编译 Image（-k 收集全部错误）===" | tee -a "$LOG"
cd "$K" || exit 1
rm -rf "$OUT"
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 KERNEL_BUILD=0 \
       AUDIO_ROOT="$A" "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j8 "${MAKE[@]}" vendor/vangogh_user_defconfig >> "$LOG" 2>&1 || { echo "defconfig 失败"; tail -5 "$LOG"; exit 1; }
make -j8 "${MAKE[@]}" olddefconfig >> "$LOG" 2>&1
make -k -j16 "${MAKE[@]}" Image >> "$LOG" 2>&1
echo "Image(-k) exit=$?" | tee -a "$LOG"

echo
echo "=== [4] 错误类别汇总 ===" | tee -a "$LOG"
grep -hE "No rule to make target|fatal error:|error:|undefined symbol" "$LOG" \
  | sed 's/^[[:space:]]*//' | sed 's/.*\(No rule to make target[^ ]*\).*/\1/' \
  | sort | uniq -c | sort -rn | head -20
IMG="$OUT/arch/arm64/boot/Image"
[ -f "$IMG" ] && { ls -l "$IMG"; echo IMAGE_OK; } || echo IMAGE_MISSING
