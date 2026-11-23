#!/usr/bin/env bash
# Baseline build: PE vangogh kernel source (4.19.113) + vangogh_user_defconfig
# CC must be passed on the make command line (the Makefile hardcodes a gcc-wrapper).
set -o pipefail
SRC="$HOME/vanilla/src/pe13-kernel"
OUT="${OUT:-$HOME/vanilla/out-vanilla}"
LOG="${LOG:-$HOME/vanilla/logs/build-vanilla.log}"
JOBS="${JOBS:-16}"
CCBIN="${CCBIN:-clang-14}"
mkdir -p "$HOME/vanilla/logs" "$OUT"

cd "$SRC" || { echo "no src"; exit 1; }

# one array element per variable => make sees a proper command-line assignment
# CLANG_FLAGS override: keep GNU as (-no-integrated-as) but drop kbuild's bogus
# --prefix=/usr/bin/ which made clang resolve the x86 "as".
ARGS=( O="$OUT" ARCH=arm64 CC="$CCBIN" CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- \
       "CLANG_FLAGS=--target=aarch64-linux-gnu --gcc-toolchain=/usr -no-integrated-as" )

{
echo "=== CC assignment: ${ARGS[3]}"
echo "=== [1/3] defconfig ==="
make -j4 "${ARGS[@]}" ${DEFCONFIG:-vendor/vangogh_user_defconfig} 2>&1 | tail -12
echo "=== [2/3] olddefconfig ==="
make -j4 "${ARGS[@]}" olddefconfig 2>&1 | tail -12
echo "--- key configs ---"
grep -E "^CONFIG_(LOCALVERSION|KALLSYMS_ALL|EXT4_FS|STATIC_USERMODEHELPER|KPROBES|CC_IS_CLANG|LTO_NONE)=" "$OUT/.config" || true
echo "=== [3/3] Image (-j$JOBS) ==="
make -j"$JOBS" "${ARGS[@]}" Image 2>&1 | tail -70
echo "=== make exit: ${PIPESTATUS[0]} ==="
} 2>&1 | tee "$LOG"

if [ -f "$OUT/arch/arm64/boot/Image" ]; then
  ls -l "$OUT/arch/arm64/boot/Image"; echo "IMAGE_OK"
else
  echo "IMAGE_MISSING"
fi
