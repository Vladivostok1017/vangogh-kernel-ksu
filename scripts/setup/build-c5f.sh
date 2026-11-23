#!/usr/bin/env bash
set -o pipefail
K="$HOME/work/driftwood"
OUT="$HOME/work/out-c5"
LOG="$HOME/work/build-c5.log"
export PATH="$HOME/bin:$PATH"

python3 /mnt/f/vanilla-build/setup/su-patch-filewrapper.py
echo
echo "=== 增量重编 ==="
cd "$K" || exit 1
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j16 "${MAKE[@]}" Image > "$LOG" 2>&1
echo "make exit=$?"
grep -nE " error:|fatal error|undefined symbol" "$LOG" | head -10
IMG="$OUT/arch/arm64/boot/Image"
if [ -f "$IMG" ]; then
  ls -l "$IMG"
  echo "KSU 字符串: $(strings -n 5 "$IMG" | grep -c -iE 'sukisu|kernelsu|ksu_')"
  python3 /mnt/f/vanilla-build/setup/pack_boot.py \
    --src "/mnt/c/Users/Administrator/Downloads/boot.img" \
    --kernel "$IMG" --out /mnt/f/vanilla-build/out-c5.img --pad 134217728 && echo PACKED
else echo IMAGE_MISSING; fi
