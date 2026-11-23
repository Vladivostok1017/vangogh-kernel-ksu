#!/usr/bin/env bash
set -o pipefail
K="$HOME/work/driftwood"
A="$K/techpack/audio"
LOG="$HOME/work/build-c12.log"
OUT="$HOME/work/out-c12"
export PATH="$HOME/bin:$PATH"
: > "$LOG"

echo "=== 确认 techpack 的模块分支补丁仍在 ===" | tee -a "$LOG"
echo "  KERNEL_BUILD==0 被改成恒真: $(grep -rc 'ifeq (0, 0)' "$A" --include=Kbuild 2>/dev/null | awk -F: '{s+=$2} END{print s+0}') 处" | tee -a "$LOG"
echo "  KERNEL_BUILD==1 已禁用: $(grep -rc 'KERNEL_BUILD), 1_DISABLED' "$A" --include=Kbuild 2>/dev/null | awk -F: '{s+=$2} END{print s+0}') 处" | tee -a "$LOG"
echo "  audio config 片段: $(ls "$A/config" | wc -l) 个" | tee -a "$LOG"

echo
echo "=== 编译 Image（不传 KERNEL_BUILD）===" | tee -a "$LOG"
cd "$K" || exit 1
rm -rf "$OUT"
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
       AUDIO_ROOT="$A" "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j8 "${MAKE[@]}" vendor/vangogh_user_defconfig >> "$LOG" 2>&1 || { echo "defconfig 失败"; exit 1; }
make -j8 "${MAKE[@]}" olddefconfig >> "$LOG" 2>&1
make -k -j16 "${MAKE[@]}" Image >> "$LOG" 2>&1
echo "Image(-k) exit=$?" | tee -a "$LOG"
echo "--- 错误类别 ---" | tee -a "$LOG"
grep -hE "No rule to make target|fatal error:|error:|undefined symbol" "$LOG" | sed 's/^[[:space:]]*//' | cut -c1-120 | sort | uniq -c | sort -rn | head -12
IMG="$OUT/arch/arm64/boot/Image"
if [ -f "$IMG" ]; then ls -l "$IMG"; echo IMAGE_OK; else echo IMAGE_MISSING; fi
