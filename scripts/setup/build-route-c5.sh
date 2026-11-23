#!/usr/bin/env bash
# Build with SukiSU-Nova (main branch, kprobe => no source hooks) instead of old KernelSU
set -o pipefail
P="http://127.0.0.1:17890"
export http_proxy="$P" https_proxy="$P"
K="$HOME/work/driftwood"
OUT="$HOME/work/out-c5"
LOG="$HOME/work/build-c5.log"
export PATH="$HOME/bin:$PATH"

echo "=== [1] 拉 SukiSU-Nova (main) ===" | tee "$LOG"
if [ ! -d "$K/SukiSU/kernel" ]; then
  git clone --depth=1 -b main https://github.com/SukiSU-Nova/SukiSU-Nova.git "$K/SukiSU" >> "$LOG" 2>&1
fi
ls "$K/SukiSU/kernel/Kconfig" >/dev/null 2>&1 && echo "SukiSU kernel 目录 OK" | tee -a "$LOG" || { echo "SukiSU 拉取失败"; exit 1; }
echo "版本: $(grep -m1 -r 'KSU_VERSION' "$K/SukiSU/kernel/" 2>/dev/null | head -1)" | tee -a "$LOG"

echo "=== [2] 接线：drivers/kernelsu -> SukiSU/kernel ===" | tee -a "$LOG"
rm -f "$K/drivers/kernelsu"
ln -sfn "$K/SukiSU/kernel" "$K/drivers/kernelsu"
ls -l "$K/drivers/kernelsu"
grep -q "kernelsu" "$K/drivers/Makefile" || printf '\nobj-$(CONFIG_KSU) += kernelsu/\n' >> "$K/drivers/Makefile"
grep -q 'drivers/kernelsu/Kconfig' "$K/drivers/Kconfig" || \
  sed -i '0,/^endmenu$/s//source "drivers\/kernelsu\/Kconfig"\nendmenu/' "$K/drivers/Kconfig"
grep -c kernelsu "$K/drivers/Makefile" "$K/drivers/Kconfig" | tee -a "$LOG"

echo "=== [3] 配置 + 编译 ===" | tee -a "$LOG"
cd "$K" || exit 1
rm -rf "$OUT"
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j8 "${MAKE[@]}" vendor/vangogh_user_defconfig >> "$LOG" 2>&1 || { echo "defconfig failed"; tail -8 "$LOG"; exit 1; }
make -j8 "${MAKE[@]}" olddefconfig >> "$LOG" 2>&1
grep -E "^CONFIG_(KSU|KPROBES|KRETPROBES|QCA_CLD_WLAN)=" "$OUT/.config" | tee -a "$LOG"

make -j16 "${MAKE[@]}" Image >> "$LOG" 2>&1
echo "make exit=$?" | tee -a "$LOG"
echo "--- 错误 ---"
grep -nE " error:|undefined symbol|Error [12]\b" "$LOG" | head -12
IMG="$OUT/arch/arm64/boot/Image"
if [ -f "$IMG" ]; then
  ls -l "$IMG"
  echo "KSU 字符串数: $(strings -n 5 "$IMG" | grep -c -iE 'kernelsu|sukisu|ksu_')"
  python3 /mnt/f/vanilla-build/setup/pack_boot.py \
    --src "/mnt/c/Users/Administrator/Downloads/boot.img" \
    --kernel "$IMG" --out /mnt/f/vanilla-build/out-c5.img --pad 134217728 && echo PACKED
else echo IMAGE_MISSING; fi
