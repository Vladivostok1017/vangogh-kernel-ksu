#!/usr/bin/env bash
# Force techpack/audio into MODULE mode (:=KERNEL_BUILD=0) so nothing lands in vmlinux
set -o pipefail
K="$HOME/work/driftwood"
LOG="$HOME/work/build-c8.log"
export PATH="$HOME/bin:$PATH"
which clang || { echo "clang 不在 PATH"; exit 1; }

echo "=== [1] 改写 techpack/audio 的 Kbuild 分支 ===" | tee "$LOG"
cd "$K/techpack/audio" || exit 1
# 让 KERNEL_BUILD==1 的分支失效（阻止 obj-y 内置列表）
grep -rl "ifeq (\$(KERNEL_BUILD), 1)" . --include=Kbuild --include=Makefile 2>/dev/null | while read -r f; do
  sed -i 's/ifeq (\$(KERNEL_BUILD), 1)/ifeq ($(KERNEL_BUILD), 1_DISABLED)/g' "$f"
done
# 让 KERNEL_BUILD==0 的分支生效（模块定义）
grep -rl "ifeq (\$(KERNEL_BUILD), 0)" . --include=Kbuild --include=Makefile 2>/dev/null | while read -r f; do
  sed -i 's/ifeq (\$(KERNEL_BUILD), 0)/ifeq (0, 0)/g' "$f"
done
changed=$(grep -rl "KERNEL_BUILD), 1_DISABLED\|ifeq (0, 0)" . --include=Kbuild --include=Makefile 2>/dev/null | wc -l)
echo "  改写文件数: $changed" | tee -a "$LOG"

echo "=== [2] codec 子目录改用 obj-m 下降 ===" | tee -a "$LOG"
CB="$K/techpack/audio/asoc/codecs/Kbuild"
# 在文件末尾追加显式下降（避开原 ifeq 块）
if ! grep -q "obj-m	+= wcd938x/" "$CB"; then
cat >> "$CB" <<'EOF'

# ---- 强制以模块方式下降（本项目适配）----
obj-m += wcd934x/
obj-m += wcd937x/
obj-m += wcd938x/
obj-m += bolero/
obj-m += cs35l41/
obj-m += rouleur/
obj-m += wsa883x/
obj-m += sdm660_cdc/
obj-m += tfa98xx/
EOF
fi
tail -12 "$CB"

echo "=== [3] 重新生成配置并编译（含 modules）===" | tee -a "$LOG"
cd "$K" || exit 1
OUT="$HOME/work/out-c8"
rm -rf "$OUT"
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 KERNEL_BUILD=0 \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j8 "${MAKE[@]}" vendor/vangogh_user_defconfig >> "$LOG" 2>&1 || { echo "defconfig 失败"; exit 1; }
make -j8 "${MAKE[@]}" olddefconfig >> "$LOG" 2>&1
make -j16 "${MAKE[@]}" Image >> "$LOG" 2>&1; echo "Image exit=$?" | tee -a "$LOG"
grep -nE " error:|undefined symbol|fatal error" "$LOG" | head -8
IMG="$OUT/arch/arm64/boot/Image"
[ -f "$IMG" ] && ls -l "$IMG" && echo IMAGE_OK || echo IMAGE_MISSING

echo "=== [4] 编译模块 ===" | tee -a "$LOG"
make -j16 "${MAKE[@]}" modules >> "$LOG" 2>&1; echo "modules exit=$?" | tee -a "$LOG"
grep -nE " error:|undefined symbol|fatal error" "$LOG" | tail -8
echo "--- 生成的 .ko ---" | tee -a "$LOG"
find "$OUT" -name '*.ko' | sed "s|$OUT/||" | sort | head -40
echo "总数: $(find "$OUT" -name '*.ko' | wc -l)"
