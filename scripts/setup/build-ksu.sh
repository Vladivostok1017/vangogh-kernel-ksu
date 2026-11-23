#!/usr/bin/env bash
# Integrate SukiSU (main branch, kprobe-based => no source hooks needed) into a
# copy of the vangogh kernel tree, then build Image.
set -o pipefail
SRC="$HOME/vanilla/src/pe13-kernel"
KSU="$HOME/vanilla/src/pe13-ksu"
KSUSRC="$HOME/vanilla/ksu/sukisu-main"
OUT="${OUT:-$HOME/vanilla/out-ksu}"
LOG="$HOME/vanilla/logs/build-ksu.log"
JOBS="${JOBS:-16}"
mkdir -p "$HOME/vanilla/logs"

echo "=== [1/5] 复制内核树（保留原树干净）==="
if [ ! -d "$KSU" ]; then
  cp -a "$SRC" "$KSU"
  echo "copied"
else
  echo "exists, skip copy"
fi

echo "=== [2/5] 接入 kernelsu 驱动 ==="
rm -rf "$KSU/drivers/kernelsu"
cp -a "$KSUSRC/kernel" "$KSU/drivers/kernelsu"
grep -q "kernelsu" "$KSU/drivers/Makefile" || printf '\nobj-$(CONFIG_KSU) += kernelsu/\n' >> "$KSU/drivers/Makefile"
grep -q 'drivers/kernelsu/Kconfig' "$KSU/drivers/Kconfig" || \
  sed -i '0,/^endmenu$/s//source "drivers\/kernelsu\/Kconfig"\nendmenu/' "$KSU/drivers/Kconfig"
echo "--- drivers/Makefile tail ---"; tail -3 "$KSU/drivers/Makefile"
echo "--- drivers/Kconfig 尾部 ---"; tail -4 "$KSU/drivers/Kconfig"

echo "=== [3/5] 追加 KSU 配置 ==="
CFG="$KSU/arch/arm64/configs/vendor/vangogh_user_defconfig"
if ! grep -q "^CONFIG_KSU=y" "$CFG"; then
cat >> "$CFG" <<'EOF'
# ---- KernelSU (SukiSU main, kprobe hooks) ----
CONFIG_KSU=y
CONFIG_KPROBES=y
CONFIG_KPROBE_EVENTS=y
CONFIG_KRETPROBES=y
# CONFIG_STATIC_USERMODEHELPER is not set
# CONFIG_KSU_SUSFS is not set
CONFIG_KSU_DEBUG=n
EOF
fi
echo "--- 追加后的 KSU 相关配置 ---"; grep -E "KSU|KPROBES|STATIC_USERMODEHELPER" "$CFG" | tail -10

echo "=== [4/5] 配置 + 编译 ==="
cd "$KSU" || exit 1
ARGS=( O="$OUT" ARCH=arm64 CC=clang-14 CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- \
       "CLANG_FLAGS=--target=aarch64-linux-gnu --gcc-toolchain=/usr -no-integrated-as" \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )

make -j4 "${ARGS[@]}" vendor/vangogh_user_defconfig > "$LOG" 2>&1
make -j4 "${ARGS[@]}" olddefconfig >> "$LOG" 2>&1
grep -E "^CONFIG_(KSU|KPROBES|KRETPROBES|STATIC_USERMODEHELPER)=" "$OUT/.config" || echo "(no KSU in .config!)"

make -j"$JOBS" "${ARGS[@]}" Image >> "$LOG" 2>&1
echo "make exit=$?"

echo "=== [5/5] 结果 ==="
grep -nE " error:|Error [12]\b" "$LOG" | head -10
ls -l "$OUT/arch/arm64/boot/Image" 2>/dev/null && echo IMAGE_OK || echo IMAGE_MISSING
