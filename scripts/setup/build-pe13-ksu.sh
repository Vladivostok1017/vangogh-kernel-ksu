#!/usr/bin/env bash
# Build KSU kernel from the EXACT commit PE13 shipped (6b5f9dd7a) so that
# our kernel's symbol CRCs match PE13's vendor modules.
set -o pipefail
SRC="$HOME/vanilla/src/pe13-kernel-6b5f"
KSU="$HOME/vanilla/ksu/sukisu-main"
OUT="$HOME/vanilla/out-pe13"
LOG="$HOME/vanilla/logs/build-pe13.log"
JOBS="${JOBS:-16}"
export PATH="$HOME/bin:$PATH"
mkdir -p "$HOME/vanilla/logs"

echo "=== [1] 接入 SukiSU (kprobe, main 分支) ===" | tee "$LOG"
rm -rf "$SRC/drivers/kernelsu"
cp -a "$KSU/kernel" "$SRC/drivers/kernelsu"
grep -q "kernelsu" "$SRC/drivers/Makefile" || printf '\nobj-$(CONFIG_KSU) += kernelsu/\n' >> "$SRC/drivers/Makefile"
grep -q 'drivers/kernelsu/Kconfig' "$SRC/drivers/Kconfig" || \
  sed -i '0,/^endmenu$/s//source "drivers\/kernelsu\/Kconfig"\nendmenu/' "$SRC/drivers/Kconfig"
echo "  Makefile: $(grep -c kernelsu "$SRC/drivers/Makefile") 处" | tee -a "$LOG"
echo "  Kconfig : $(grep -c kernelsu "$SRC/drivers/Kconfig") 处" | tee -a "$LOG"

echo "=== [2] 去掉 techpack 的 -Werror（clang14 会报警告）===" | tee -a "$LOG"
grep -rl -- "-Werror" "$SRC/techpack" --include=Kbuild --include=Makefile 2>/dev/null | while read -r f; do
  sed -i 's/-Werror/-Wno-error/g' "$f"
done
echo "  完成" | tee -a "$LOG"

echo "=== [3] 配置 ===" | tee -a "$LOG"
cd "$SRC" || exit 1
rm -rf "$OUT"
MAKE=( O="$OUT" ARCH=arm64 CC=clang-14 CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LD=ld.lld-14 \
       "CLANG_FLAGS=--target=aarch64-linux-gnu --gcc-toolchain=/usr -no-integrated-as" \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j4 "${MAKE[@]}" vendor/vangogh_user_defconfig >> "$LOG" 2>&1 || { echo "defconfig 失败"; tail -10 "$LOG"; exit 1; }

# 版本串对齐 PE13 发布版；并启用 KSU
sed -i 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION="-PixelExperience-g6b5f9dd7a"/' "$OUT/.config"
sed -i 's/^CONFIG_LOCALVERSION_AUTO=.*/# CONFIG_LOCALVERSION_AUTO is not set/' "$OUT/.config"
cat >> "$OUT/.config" <<'EOF'
CONFIG_KSU=y
CONFIG_KPROBES=y
CONFIG_KPROBE_EVENTS=y
CONFIG_KRETPROBES=y
# CONFIG_STATIC_USERMODEHELPER is not set
EOF
make -j4 "${MAKE[@]}" olddefconfig >> "$LOG" 2>&1
echo "--- 关键配置 ---" | tee -a "$LOG"
grep -E "^CONFIG_(KSU|KPROBES|KRETPROBES|LOCALVERSION|STATIC_USERMODEHELPER|MODVERSIONS)=" "$OUT/.config" | tee -a "$LOG"

echo "=== [4] 编译 ===" | tee -a "$LOG"
make -j"$JOBS" "${MAKE[@]}" Image >> "$LOG" 2>&1
echo "make exit=$?" | tee -a "$LOG"
grep -nE " error:|Error [12]\b|undefined symbol" "$LOG" | head -8
IMG="$OUT/arch/arm64/boot/Image"
if [ -f "$IMG" ]; then
  ls -l "$IMG"
  strings -n 10 "$IMG" | grep -m1 "^Linux version 4.19"
  strings -n 8 "$IMG" | grep -m1 "SMP preempt mod_unload"
  ls -l "$OUT/Module.symvers"
  echo IMAGE_OK
else
  echo IMAGE_MISSING
fi
