#!/usr/bin/env bash
set -o pipefail
K="$HOME/work/driftwood"
OUT="$HOME/work/out-c5"
LOG="$HOME/work/build-c5.log"
export PATH="$HOME/bin:$PATH"

python3 - <<'PY'
K="/root/work/driftwood"
p=f"{K}/drivers/kernelsu/core/init.c"
s=open(p).read()
old = """#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 13, 0)
MODULE_IMPORT_NS("VFS_internal_I_am_really_a_filesystem_and_am_NOT_a_driver");
#else
MODULE_IMPORT_NS(VFS_internal_I_am_really_a_filesystem_and_am_NOT_a_driver);
#endif"""
new = """#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 4, 0)
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 13, 0)
MODULE_IMPORT_NS("VFS_internal_I_am_really_a_filesystem_and_am_NOT_a_driver");
#else
MODULE_IMPORT_NS(VFS_internal_I_am_really_a_filesystem_and_am_NOT_a_driver);
#endif
#endif /* MODULE_IMPORT_NS only exists on >= 5.4 */"""
if "MODULE_IMPORT_NS only exists on" in s:
    print("已打过补丁")
elif old in s:
    open(p,"w").write(s.replace(old,new,1)); print("init.c 已修补（老内核跳过 MODULE_IMPORT_NS）")
else:
    print("未匹配，需人工检查")
PY

echo "=== 增量重编 ==="
cd "$K" || exit 1
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j16 "${MAKE[@]}" Image > "$LOG" 2>&1
echo "make exit=$?"
grep -nE " error:|undefined symbol|Error [12]\b" "$LOG" | head -10
IMG="$OUT/arch/arm64/boot/Image"
if [ -f "$IMG" ]; then
  ls -l "$IMG"
  echo "KSU 字符串: $(strings -n 5 "$IMG" | grep -c -iE 'sukisu|kernelsu|ksu_')"
  python3 /mnt/f/vanilla-build/setup/pack_boot.py \
    --src "/mnt/c/Users/Administrator/Downloads/boot.img" \
    --kernel "$IMG" --out /mnt/f/vanilla-build/out-c5.img --pad 134217728 && echo PACKED
else echo IMAGE_MISSING; fi
