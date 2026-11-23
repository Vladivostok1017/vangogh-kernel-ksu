#!/usr/bin/env bash
# Baseline kernel build: PE twelve tree + stock (device) config, no KSU yet
set -o pipefail
SRC="$HOME/vanilla/src/pe"
OUT="$HOME/vanilla/out-base"
JOBS="${JOBS:-16}"
CCBIN="${CCBIN:-clang-14}"

export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CLANG_TRIPLE=aarch64-linux-gnu-

mkdir -p "$OUT"
if [ ! -f "$OUT/.config" ]; then
  gzip -dc /mnt/f/vanilla-build/stock_config.gz > "$OUT/.config"
fi

cd "$SRC" || exit 1
MAKEFLAGS="O=$OUT ARCH=arm64 CC=$CCBIN CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-gnu-"

echo "=== [1/2] olddefconfig with $CCBIN ==="
make -j4 $MAKEFLAGS olddefconfig 2>&1 | tail -30 || { echo "OLDDEFCONFIG FAILED"; exit 2; }

echo "=== config sanity ==="
grep -E "^CONFIG_(CC_IS_CLANG|ARM64|KALLSYMS_ALL|EXT4_FS)=" "$OUT/.config" || true

echo "=== [2/2] build Image (-j$JOBS) ==="
time make -j"$JOBS" $MAKEFLAGS Image 2>&1 | tail -80
RC=$?
echo "=== exit code: $RC ==="
ls -l "$OUT/arch/arm64/boot/Image" 2>/dev/null && echo "IMAGE_OK" || echo "IMAGE_MISSING"
