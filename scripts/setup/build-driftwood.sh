#!/usr/bin/env bash
# Build Driftwood (community sm7250 kernel with MIUI drivers + KernelSU) for vangogh
set -o pipefail
P="http://127.0.0.1:17890"
export http_proxy="$P" https_proxy="$P"
K="$HOME/vanilla/src/driftwood"
OUT="$HOME/vanilla/out-drift"
LOG="$HOME/vanilla/logs/build-drift.log"
mkdir -p "$HOME/vanilla/logs"

echo "=== [1] 取出 KernelSU 子模块钉的提交 ===" | tee "$LOG"
SUBSHA=$(cd "$K" && git ls-tree HEAD KernelSU | awk '{print $3}')
echo "KernelSU commit: $SUBSHA" | tee -a "$LOG"

echo "=== [2] 按该提交拉取 KernelSU ===" | tee -a "$LOG"
if [ ! -d "$K/KernelSU/kernel" ]; then
  rm -rf "$K/KernelSU"
  git clone --filter=blob:none https://github.com/tiann/KernelSU.git "$K/KernelSU" >> "$LOG" 2>&1
  (cd "$K/KernelSU" && git checkout "$SUBSHA" >> "$LOG" 2>&1) || echo "checkout 失败" | tee -a "$LOG"
fi
ls "$K/KernelSU/kernel" | head -5 | tee -a "$LOG"
echo "--- KernelSU 版本 ---" | tee -a "$LOG"
grep -m2 -rn "KSU_VERSION" "$K/KernelSU/kernel/"*.c "$K/KernelSU/kernel/"*.h 2>/dev/null | head -3 | tee -a "$LOG"

echo "=== [3] 准备 LLVM 工具链（LLVM=1 需要 clang/ld.lld 在 PATH）===" | tee -a "$LOG"
mkdir -p "$HOME/bin"
cd "$HOME/bin"
for pair in "clang:clang-14" "clang++:clang++-14" "ld.lld:ld.lld-14" "llvm-ar:llvm-ar-14" \
            "llvm-nm:llvm-nm-14" "llvm-objcopy:llvm-objcopy-14" "llvm-objdump:llvm-objdump-14" \
            "llvm-strip:llvm-strip-14" "llvm-readelf:llvm-readelf-14" "llvm-size:llvm-size-14" \
            "llvm-strings:llvm-strings-14" "llvm-symbolizer:llvm-symbolizer-14"; do
  name="${pair%%:*}"; target="${pair##*:}"
  [ -x "$(command -v $target)" ] && ln -sf "$(command -v $target)" "$HOME/bin/$name"
done
export PATH="$HOME/bin:$PATH"
clang --version | head -1 | tee -a "$LOG"
ld.lld --version | head -1 | tee -a "$LOG"

echo "=== [4] 配置：vangogh_user_defconfig + KSU ===" | tee -a "$LOG"
CFG="$K/arch/arm64/configs/vendor/vangogh_user_defconfig"
if ! grep -q "^CONFIG_KSU=y" "$CFG"; then
cat >> "$CFG" <<'EOF'

# ---- KernelSU (kprobe hook, no source patch) ----
CONFIG_KSU=y
CONFIG_KPROBES=y
CONFIG_KPROBE_EVENTS=y
CONFIG_KRETPROBES=y
# CONFIG_STATIC_USERMODEHELPER is not set
EOF
fi
grep -E "^CONFIG_(KSU|KPROBES|KRETPROBES|MILLET|MIHW)=" "$CFG" | tee -a "$LOG"

echo "=== [5] 构建（LLVM=1 集成汇编器 + lld）===" | tee -a "$LOG"
cd "$K" || exit 1
rm -rf "$OUT"
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
       LLVM=1 LLVM_IAS=1 "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j4 "${MAKE[@]}" vendor/vangogh_user_defconfig >> "$LOG" 2>&1
make -j4 "${MAKE[@]}" olddefconfig >> "$LOG" 2>&1
echo "--- 生效的配置 ---" | tee -a "$LOG"
grep -E "^CONFIG_(KSU|KPROBES|MILLET|MIHW|LOCALVERSION)=" "$OUT/.config" | tee -a "$LOG"
make -j16 "${MAKE[@]}" Image >> "$LOG" 2>&1
echo "make exit=$?" | tee -a "$LOG"
grep -nE " error:|Error [12]\b" "$LOG" | head -8
ls -l "$OUT/arch/arm64/boot/Image" 2>/dev/null && echo IMAGE_OK || echo IMAGE_MISSING
