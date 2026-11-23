#!/usr/bin/env bash
set -o pipefail
K="$HOME/work/driftwood"
OUT="$HOME/work/out-drift2"
export PATH="$HOME/bin:$PATH"
mkdir -p "$HOME/bin"
for pair in "clang:clang-14" "ld.lld:ld.lld-14" "llvm-ar:llvm-ar-14" "llvm-nm:llvm-nm-14" \
            "llvm-objcopy:llvm-objcopy-14" "llvm-objdump:llvm-objdump-14" \
            "llvm-strip:llvm-strip-14" "llvm-readelf:llvm-readelf-14" \
            "llvm-size:llvm-size-14"; do
  n="${pair%%:*}"; t="${pair##*:}"
  [ -x "$(command -v $t)" ] && ln -sf "$(command -v $t)" "$HOME/bin/$n"
done

echo "=== 树内是否有 qcacld（wifi 驱动）==="
ls -d "$K/drivers/staging/qcacld-3.0" 2>/dev/null && echo "有 qcacld ✓" || echo "无 qcacld ✗"
ls -d "$K/techpack/audio" 2>/dev/null && echo "有 techpack/audio ✓" || echo "无 techpack/audio ✗"

echo
echo "=== 生成 .config（只做配置，不编译）==="
cd "$K" || exit 1
rm -rf "$OUT"; mkdir -p "$OUT"
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 )
make -j8 "${MAKE[@]}" vendor/vangogh_user_defconfig > /tmp/cfg.log 2>&1 && echo "defconfig ok"
make -j8 "${MAKE[@]}" olddefconfig >> /tmp/cfg.log 2>&1 && echo "olddefconfig ok"

echo
echo "=== 实际生效的 wifi / 音频 / MIUI 配置 ==="
for pat in QCA_CLD_WLAN WLAN_FEATURE WCNSS SND_SOC_WCD937x SND_SOC_BOLERO \
           SND_SOC_MACHINE_LITO SND_SOC_MSM8952 SND_SOC_LITO AUDIO_QCOM EXFAT_FS \
           RMNET_PERF RMNET_SHS MIHW MIGT MILLET KSU; do
  hit=$(grep -iE "^(CONFIG_${pat}[A-Z0-9_]*=|# CONFIG_${pat}[A-Z0-9_]* is not set)" "$OUT/.config" 2>/dev/null | head -4)
  if [ -n "$hit" ]; then echo "$hit"; else echo "(无 ${pat})"; fi
done
echo
echo "=== .config 中所有 =m 的项 ==="
grep -c "=m$" "$OUT/.config"
grep "=m$" "$OUT/.config" | head -20
