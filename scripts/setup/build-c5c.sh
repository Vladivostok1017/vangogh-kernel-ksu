#!/usr/bin/env bash
set -o pipefail
K="$HOME/work/driftwood"
OUT="$HOME/work/out-c5"
LOG="$HOME/work/build-c5.log"
export PATH="$HOME/bin:$PATH"

echo "=== 补 linux/pgtable.h 兼容头（4.19 无此头，内容来自 asm/pgtable.h）==="
cat > "$K/include/linux/pgtable.h" <<'EOF'
/* Compatibility shim for pre-5.0 kernels: linux/pgtable.h was split out of
 * asm/pgtable.h in Linux 5.x.  Needed by SukiSU. */
#ifndef _LINUX_PGTABLE_COMPAT_H
#define _LINUX_PGTABLE_COMPAT_H
#include <asm/pgtable.h>
#endif
EOF
ls -l "$K/include/linux/pgtable.h"

echo
echo "=== 增量重编 ==="
cd "$K" || exit 1
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j16 "${MAKE[@]}" Image > "$LOG" 2>&1
echo "make exit=$?"
grep -nE " error:|fatal error|undefined symbol" "$LOG" | head -8
IMG="$OUT/arch/arm64/boot/Image"
if [ -f "$IMG" ]; then
  ls -l "$IMG"
  echo "KSU 字符串: $(strings -n 5 "$IMG" | grep -c -iE 'sukisu|kernelsu|ksu_')"
  python3 /mnt/f/vanilla-build/setup/pack_boot.py \
    --src "/mnt/c/Users/Administrator/Downloads/boot.img" \
    --kernel "$IMG" --out /mnt/f/vanilla-build/out-c5.img --pad 134217728 && echo PACKED
else echo IMAGE_MISSING; fi
