#!/usr/bin/env bash
# Rebuild with STOCK config + faked vermagic so MIUI's vendor kernel modules load.
set -o pipefail
SRC="$HOME/vanilla/src/pe13-kernel"
OUT="$HOME/vanilla/out-stock"
LOG="$HOME/vanilla/logs/build-stock.log"
JOBS="${JOBS:-16}"
mkdir -p "$HOME/vanilla/logs" "$OUT"

ARGS=( O="$OUT" ARCH=arm64 CC=clang-14 CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LD=ld.lld-14 \
       "CLANG_FLAGS=--target=aarch64-linux-gnu --gcc-toolchain=/usr -no-integrated-as" \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )

cd "$SRC" || exit 1
rm -rf "$OUT"; mkdir -p "$OUT"

echo "=== [1/4] 载入原厂配置 ===" | tee "$LOG"
gzip -dc /mnt/f/vanilla-build/stock_config.gz > "$OUT/.config"

echo "=== [2/4] 伪造与原厂一致的 vermagic ===" | tee -a "$LOG"
# stock: CONFIG_LOCALVERSION="-perf" + LOCALVERSION_AUTO => 4.19.113-perf-ga1b60ef832fb
sed -i 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION="-perf-ga1b60ef832fb"/' "$OUT/.config"
sed -i 's/^CONFIG_LOCALVERSION_AUTO=.*/# CONFIG_LOCALVERSION_AUTO is not set/' "$OUT/.config"
grep -E "^CONFIG_(LOCALVERSION|LOCALVERSION_AUTO|MODVERSIONS)=" "$OUT/.config" | tee -a "$LOG"

echo "=== [3/4] olddefconfig ===" | tee -a "$LOG"
make -j4 "${ARGS[@]}" olddefconfig >> "$LOG" 2>&1
echo "--- after olddefconfig ---" | tee -a "$LOG"
grep -E "^CONFIG_(LOCALVERSION|LOCALVERSION_AUTO|MODVERSIONS)=" "$OUT/.config" | tee -a "$LOG"

echo "=== [4/4] build Image ===" | tee -a "$LOG"
make -j"$JOBS" "${ARGS[@]}" Image >> "$LOG" 2>&1
echo "make exit=$?" | tee -a "$LOG"
grep -nE " error:|Error [12]\b|relocation truncated" "$LOG" | head -8
ls -l "$OUT/arch/arm64/boot/Image" 2>/dev/null && echo IMAGE_OK || echo IMAGE_MISSING
