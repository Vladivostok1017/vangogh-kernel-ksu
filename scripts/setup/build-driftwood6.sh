#!/usr/bin/env bash
set -o pipefail
K="$HOME/vanilla/src/driftwood"
LOG="$HOME/vanilla/logs/build-drift.log"
export PATH="$HOME/bin:$PATH"
MAKE=( O="$HOME/vanilla/out-drift" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
       LLVM=1 LLVM_IAS=1 "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )

python3 /mnt/f/vanilla-build/setup/patch-modcrc.py
echo
echo "=== 增量编译 + 打包 ==="
cd "$K" || exit 1
make -j16 "${MAKE[@]}" Image > "$LOG" 2>&1
echo "make exit=$?"
grep -nE " error:|Error [12]\b" "$LOG" | head -5
IMG="$HOME/vanilla/out-drift/arch/arm64/boot/Image"
if [ -f "$IMG" ]; then
  echo IMAGE_OK; ls -l "$IMG"
  strings -n 10 "$IMG" | grep -m1 "^Linux version 4.19"
  python3 /mnt/f/vanilla-build/setup/pack_boot.py \
    --src "/mnt/c/Users/Administrator/Downloads/boot.img" \
    --kernel "$IMG" --out /mnt/f/vanilla-build/out/boot-driftwood-ksu.img --pad 134217728
else
  echo IMAGE_MISSING
fi
