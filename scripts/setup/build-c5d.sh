#!/usr/bin/env bash
set -o pipefail
K="$HOME/work/driftwood"
OUT="$HOME/work/out-c5"
LOG="$HOME/work/build-c5.log"
export PATH="$HOME/bin:$PATH"
KS="$K/drivers/kernelsu"

echo "=== [1] 确认 SukiSU 的构建文件 ==="
ls "$KS" | grep -iE "^(Kbuild|Makefile)$"
echo

echo "=== [2] 写 4.19 兼容头 ==="
cat > "$K/include/linux/ksu_419_compat.h" <<'EOF'
/* Compatibility helpers so that SukiSU (written for 5.x+) builds on 4.19.
 * The *_nofault family only appeared in 5.8; untagged_addr in 5.4. */
#ifndef _LINUX_KSU_419_COMPAT_H
#define _LINUX_KSU_419_COMPAT_H

#include <linux/version.h>
#include <linux/uaccess.h>
#include <linux/string.h>

#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 8, 0)
static inline long ksu_compat_strncpy_from_user_nofault(char *dst,
		const void __user *src, long count)
{
	return strncpy_from_user(dst, src, count);
}
static inline long ksu_compat_copy_from_user_nofault(void *dst,
		const void __user *src, unsigned long size)
{
	return copy_from_user(dst, src, size);
}
static inline long ksu_compat_copy_to_user_nofault(void __user *dst,
		const void *src, unsigned long size)
{
	return copy_to_user(dst, src, size);
}
static inline long ksu_compat_copy_kernel_nofault(void *dst, const void *src,
		unsigned long size)
{
	memcpy(dst, src, size);
	return 0;
}
#define strncpy_from_user_nofault ksu_compat_strncpy_from_user_nofault
#define copy_from_user_nofault ksu_compat_copy_from_user_nofault
#define copy_to_user_nofault ksu_compat_copy_to_user_nofault
#define copy_to_kernel_nofault ksu_compat_copy_kernel_nofault
#define copy_from_kernel_nofault ksu_compat_copy_kernel_nofault
#endif /* < 5.8 */

#ifndef untagged_addr
#define untagged_addr(addr) (addr)
#endif

#endif
EOF
ls -l "$K/include/linux/ksu_419_compat.h"

echo
echo "=== [3] 挂进 kernelsu 的编译（-include）==="
for f in "$KS/Kbuild" "$KS/Makefile"; do
  if [ -f "$f" ]; then
    grep -q "ksu_419_compat" "$f" || printf '\nccflags-y += -include $(srctree)/include/linux/ksu_419_compat.h\n' >> "$f"
    echo "patched: $f"
  fi
done

echo
echo "=== [4] 重编 ==="
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
