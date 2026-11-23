#!/usr/bin/env bash
set -o pipefail
K="$HOME/work/driftwood"
A="$K/techpack/audio"
LOG="$HOME/work/build-c13m.log"
OUT="$HOME/work/out-c12"
export PATH="$HOME/bin:$PATH"
: > "$LOG"

echo "=== [1] 清空平台 autoconf.h（避免与内核 autoconf.h 重复定义）===" | tee -a "$LOG"
for f in "$A"/config/*autoconf.h; do : > "$f"; done
ls -l "$A"/config/litoautoconf.h
echo "  已清空 $(ls "$A"/config/*autoconf.h 2>/dev/null | wc -l) 个 autoconf.h"

echo
echo "=== [2] 重新编译模块（增量）===" | tee -a "$LOG"
cd "$K" || exit 1
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
       AUDIO_ROOT="$A" "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -k -j16 "${MAKE[@]}" modules >> "$LOG" 2>&1
echo "modules(-k) exit=$?" | tee -a "$LOG"
echo "--- 错误类别 ---" | tee -a "$LOG"
grep -hE "No rule to make target|fatal error:|error:|undefined symbol|duplicate symbol" "$LOG" | sed 's/^[[:space:]]*//' | cut -c1-110 | sort | uniq -c | sort -rn | head -12
echo
echo "=== .ko 产出 ===" | tee -a "$LOG"
find "$OUT" -name '*.ko' | sed "s|$OUT/||" | sort | head -40
echo "总数: $(find "$OUT" -name '*.ko' | wc -l)"
