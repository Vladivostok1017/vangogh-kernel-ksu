#!/usr/bin/env bash
#
# vangogh-kernel-ksu — 一键构建：为小米10青春版 (vangogh) 的 MIUI 13 构建带 KernelSU 的内核
#
# 用法:
#   ./build.sh                      # 构建 Image
#   ./build.sh --pack <boot.img>    # 构建并打包成可 fastboot 的 boot.img
#   ./build.sh --audio-wip          # 额外应用音频 dlkm 实验补丁（WIP，不保证可用）
#   ./build.sh --clean              # 清空 work/ 与 out/ 后重建
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${WORK:-$ROOT/work}"
OUT="${OUT:-$ROOT/out}"

KERNEL_REPO="https://github.com/WeeAris/Driftwood_kernel_xiaomi_sm7250.git"
KERNEL_BRANCH="android-4.19-standalone"
KERNEL_COMMIT="3f1ef13491d16039a3eca412237cb5f8ddf5800b"

KSU_REPO="https://github.com/tiann/KernelSU.git"
KSU_TAG="v0.9.5"          # 最后一个支持非 GKI 的官方版本
DEFCONFIG="vendor/vangogh_user_defconfig"

JOBS="${JOBS:-$(nproc)}"
PACK_SRC=""
AUDIO_WIP=0

while [ $# -gt 0 ]; do
  case "$1" in
    --pack)      PACK_SRC="${2:-}"; shift 2 ;;
    --audio-wip) AUDIO_WIP=1; shift ;;
    --clean)     rm -rf "$WORK" "$OUT"; shift ;;
    -h|--help)   sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "未知参数: $1"; exit 2 ;;
  esac
done

log() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

log "准备编译器"
mkdir -p "$WORK/toolbin"

# Ubuntu/Debian 的 clang-14/lld-14 只提供带版本号的二进制（clang-14、ld.lld-14、
# llvm-ar-14…），不带版本号的 clang / ld.lld 属于 meta 包 clang / lld。
# 而 kbuild 在 LLVM=1 下调用的是不带版本号的名字，所以先在 work/toolbin 里补一层软链，
# 再检查依赖 —— 顺序反了会在裸机上直接报“缺少依赖: clang”。
pick() {
  name="$1"; shift
  if command -v "$name" >/dev/null 2>&1; then return 0; fi
  for cand in "$@"; do
    if command -v "$cand" >/dev/null 2>&1; then
      ln -sf "$(command -v "$cand")" "$WORK/toolbin/$name"
      return 0
    fi
  done
  return 1
}
VERS="21 20 19 18 17 16 15 14 13 12"
for n in clang ld.lld llvm-ar llvm-nm llvm-objcopy llvm-objdump \
         llvm-strip llvm-readelf llvm-size llvm-ranlib; do
  cands=""
  for v in $VERS; do cands="$cands $n-$v"; done
  pick "$n" $cands || true      # 建不起来就让下面的依赖检查去报错
done
export PATH="$WORK/toolbin:$PATH"

# ---------------------------------------------------------------- 依赖检查
log "检查依赖"
for t in clang ld.lld llvm-ar make python3 bc bison flex cpio rsync git aarch64-linux-gnu-gcc; do
  command -v "$t" >/dev/null 2>&1 || die "缺少依赖: $t（Debian/Ubuntu: apt install clang-14 lld-14 llvm-14 gcc-aarch64-linux-gnu bc bison flex cpio rsync libssl-dev libelf-dev）"
done

# ---------------------------------------------------------------- 源码
mkdir -p "$WORK"
KERNEL_DIR="$WORK/kernel"

if [ ! -d "$KERNEL_DIR/.git" ]; then
  log "克隆内核树 (Driftwood $KERNEL_BRANCH)"
  git clone --filter=blob:none -b "$KERNEL_BRANCH" "$KERNEL_REPO" "$KERNEL_DIR"
fi
log "检出固定提交 ${KERNEL_COMMIT:0:12}"
git -C "$KERNEL_DIR" fetch --all --tags -q || true
git -C "$KERNEL_DIR" checkout -f "$KERNEL_COMMIT"

# KernelSU 必须位于内核树的**父级**（drivers/kernelsu 是指向 ../../KernelSU/kernel 的相对软链）
if [ ! -d "$WORK/KernelSU/.git" ]; then
  log "克隆 KernelSU ($KSU_TAG)"
  git clone --filter=blob:none "$KSU_REPO" "$WORK/KernelSU"
fi
git -C "$WORK/KernelSU" fetch --tags -q || true
git -C "$WORK/KernelSU" checkout -f "$KSU_TAG"
[ -d "$WORK/KernelSU/kernel" ] || die "KernelSU kernel 目录缺失"

# ---------------------------------------------------------------- 打补丁
log "应用核心补丁"
git -C "$KERNEL_DIR" checkout -f -- . 2>/dev/null || true
git -C "$KERNEL_DIR" apply --whitespace=nowarn "$ROOT/patches/0001-core-build-fixes.patch"
git -C "$KERNEL_DIR" apply --whitespace=nowarn "$ROOT/patches/0003-vangogh-defconfig.patch" || true

if [ "$AUDIO_WIP" = "1" ]; then
  log "应用音频 dlkm 实验补丁（WIP）"
  git -C "$KERNEL_DIR" apply --whitespace=nowarn "$ROOT/patches/0002-techpack-audio-dlkm-wip.patch" || \
    log "音频补丁应用失败（可能与其他改动冲突），继续"
fi

# ---------------------------------------------------------------- 配置
log "写入 defconfig 片段"
FRAG="$ROOT/config/vangogh_ksu.fragment"
CFG="$KERNEL_DIR/arch/arm64/configs/$DEFCONFIG"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  key="${line%%=*}"
  grep -q "^${key}=" "$CFG" || echo "$line" >> "$CFG"
done < "$FRAG"

# 确保 KernelSU 驱动已接线
KS="$KERNEL_DIR/drivers"
[ -e "$KS/kernelsu" ] || ln -sfn "$WORK/KernelSU/kernel" "$KS/kernelsu"
grep -q "kernelsu" "$KS/Makefile" || printf '\nobj-$(CONFIG_KSU) += kernelsu/\n' >> "$KS/Makefile"
grep -q 'drivers/kernelsu/Kconfig' "$KS/Kconfig" || \
  sed -i '0,/^endmenu$/s//source "drivers\/kernelsu\/Kconfig"\nendmenu/' "$KS/Kconfig"

# ---------------------------------------------------------------- 编译
log "生成 .config"
mkdir -p "$OUT"
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -C "$KERNEL_DIR" -j8 "${MAKE[@]}" "$DEFCONFIG"
make -C "$KERNEL_DIR" -j8 "${MAKE[@]}" olddefconfig

log "校验关键配置"
for k in CONFIG_KSU CONFIG_QCA_CLD_WLAN CONFIG_MIHW CONFIG_KPROBES; do
  grep -q "^${k}=y" "$OUT/.config" || die "配置项未生效: $k"
done

log "编译内核（-j$JOBS）"
make -C "$KERNEL_DIR" -j"$JOBS" "${MAKE[@]}" Image

IMG="$OUT/arch/arm64/boot/Image"
[ -f "$IMG" ] || die "Image 未生成"
log "完成: $IMG"
ls -l "$IMG"
strings -n 10 "$IMG" | grep -m1 "^Linux version" || true

# ---------------------------------------------------------------- 打包
if [ -n "$PACK_SRC" ]; then
  [ -f "$PACK_SRC" ] || die "找不到原厂 boot.img: $PACK_SRC"
  log "打包 boot.img（复用原厂 header/dtb）"
  python3 "$ROOT/scripts/pack_boot.py" --src "$PACK_SRC" --kernel "$IMG" \
          --out "$ROOT/boot-ksu.img" --pad 134217728
  log "产物: $ROOT/boot-ksu.img"
fi

cat <<EOF

下一步：
  fastboot boot  boot-ksu.img         # 临时验证（不写分区，重启即恢复）
  fastboot flash boot boot-ksu.img    # 确认无误后持久化
  回滚: fastboot flash boot <原厂boot.img>

EOF
