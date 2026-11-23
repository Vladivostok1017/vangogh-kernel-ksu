#!/usr/bin/env bash
# Rebuild with KernelSU v0.9.5 (last non-GKI version, has a manager APK)
set -o pipefail
P="http://127.0.0.1:17890"
export http_proxy="$P" https_proxy="$P"
K="$HOME/work/driftwood"
OUT="$HOME/work/out-c4"
LOG="$HOME/work/build-c4.log"
export PATH="$HOME/bin:$PATH"

echo "=== [1] 把 KSU 切到 v0.9.5 ===" | tee "$LOG"
cd "$K/KernelSU" || exit 1
git fetch --depth=1 origin refs/tags/v0.9.5:refs/tags/v0.9.5 >> "$LOG" 2>&1 || echo "fetch tag 失败" | tee -a "$LOG"
git checkout -f v0.9.5 >> "$LOG" 2>&1 || { echo "checkout v0.9.5 失败"; tail -5 "$LOG"; exit 1; }
echo "当前提交: $(git describe --tags 2>/dev/null || git rev-parse --short HEAD)" | tee -a "$LOG"
ls kernel/Kconfig >/dev/null 2>&1 && echo "kernel 目录 OK" | tee -a "$LOG"

echo "=== [2] 编译 ===" | tee -a "$LOG"
cd "$K" || exit 1
rm -rf "$OUT"
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j8 "${MAKE[@]}" vendor/vangogh_user_defconfig >> "$LOG" 2>&1 || { echo "defconfig failed"; exit 1; }
make -j8 "${MAKE[@]}" olddefconfig >> "$LOG" 2>&1
grep -E "^CONFIG_(KSU|KPROBES|QCA_CLD_WLAN)=" "$OUT/.config" | tee -a "$LOG"

make -j16 "${MAKE[@]}" Image >> "$LOG" 2>&1
echo "make exit=$?" | tee -a "$LOG"
grep -nE " error:|undefined symbol" "$LOG" | head -8
IMG="$OUT/arch/arm64/boot/Image"
if [ -f "$IMG" ]; then
  ls -l "$IMG"
  strings -n 5 "$IMG" | grep -c -iE "kernelsu|ksu_"
  python3 /mnt/f/vanilla-build/setup/pack_boot.py \
    --src "/mnt/c/Users/Administrator/Downloads/boot.img" \
    --kernel "$IMG" --out /mnt/f/vanilla-build/out-c4.img --pad 134217728 && echo PACKED
else echo IMAGE_MISSING; fi
