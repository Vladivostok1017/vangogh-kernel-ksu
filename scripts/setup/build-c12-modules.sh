#!/usr/bin/env bash
set -o pipefail
K="$HOME/work/driftwood"
A="$K/techpack/audio"
LOG="$HOME/work/build-c12m.log"
OUT="$HOME/work/out-c12"
export PATH="$HOME/bin:$PATH"
: > "$LOG"
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
       AUDIO_ROOT="$A" "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
cd "$K" || exit 1
echo "=== 编译 modules ===" | tee -a "$LOG"
make -k -j16 "${MAKE[@]}" modules >> "$LOG" 2>&1
echo "modules(-k) exit=$?" | tee -a "$LOG"
echo "--- 错误类别 ---" | tee -a "$LOG"
grep -hE "No rule to make target|fatal error:|error:|undefined symbol" "$LOG" | sed 's/^[[:space:]]*//' | cut -c1-110 | sort | uniq -c | sort -rn | head -10
echo
echo "=== 音频 .ko ===" | tee -a "$LOG"
find "$OUT" -name '*.ko' | grep -iE "audio|snd|wcd|bolero|swr|q6|adsp|machine|mbhc|wsa" | sed "s|$OUT/||" | sort
echo "音频 .ko 数量: $(find "$OUT" -name '*.ko' | grep -icE 'audio|snd|wcd|bolero|swr|q6|adsp|machine|mbhc|wsa')"
echo "总 .ko 数量: $(find "$OUT" -name '*.ko' | wc -l)"
