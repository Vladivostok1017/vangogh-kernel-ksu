#!/usr/bin/env bash
K="$HOME/work/driftwood"
CFG="$HOME/work/out-drift2/.config"

echo "=== qcacld 的 Kconfig 符号名 ==="
grep -rn "^config " "$K/drivers/staging/qcacld-3.0/Kconfig" 2>/dev/null | head -10
echo "--- 该驱动在 .config 里的状态 ---"
grep -iE "qcacld|qca_cld|cld_" "$CFG" | head -10 || echo "(无)"

echo
echo "=== techpack/audio 的 Kconfig 顶层符号 ==="
grep -rn "^config " "$K/techpack/audio/Kconfig" 2>/dev/null | head -15
echo "--- .config 中已开的音频项 ---"
grep -E "^CONFIG_SND_SOC_.*=y$" "$CFG" | head -20
echo "--- 音频项总数 ---"
echo "y: $(grep -cE '^CONFIG_SND_SOC_.*=y$' "$CFG")  m: $(grep -cE '^CONFIG_SND_SOC_.*=m$' "$CFG")"

echo
echo "=== 该驱动是否被 Kconfig 依赖挡住 ==="
grep -n -B3 -A6 "config QCA_CLD_WLAN\|config WLAN_FEATURE" "$K/drivers/staging/qcacld-3.0/Kconfig" 2>/dev/null | head -30

echo
echo "=== picasso 的 defconfig 里这些项 ==="
for f in picasso_user_defconfig monet_user_defconfig lito_defconfig; do
  echo "--- $f"
  grep -iE "QCA_CLD|SND_SOC_WCD937X=|SND_SOC_BOLERO=|SND_SOC_MACHINE_LITO=|AUDIO_" "$K/arch/arm64/configs/vendor/$f" 2>/dev/null | head -8
done
