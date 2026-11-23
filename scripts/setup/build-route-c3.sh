#!/usr/bin/env bash
# Variant: wifi + KSU, NO audio (bisect why c2 failed to boot)
set -o pipefail
K="$HOME/work/driftwood"
OUT="$HOME/work/out-c3"
LOG="$HOME/work/build-c3.log"
export PATH="$HOME/bin:$PATH"

echo "=== [1] 从 defconfig 中移除音频选项 ===" | tee "$LOG"
CFG="$K/arch/arm64/configs/vendor/vangogh_user_defconfig"
cp "$CFG" /tmp/defconfig.before-audio-removal
sed -i -E '/^CONFIG_(PINCTRL_LPI|AUDIO_EXT_CLK|MSM_CDC_PINCTRL|SND_SOC_WCD_MBHC|SND_SOC_WCD_MBHC_ADC|WCD9XXX_CODEC_CORE_V2|MSM_QDSP6V2_CODECS|MSM_QDSP6_APRV2_RPMSG|MSM_ADSP_LOADER|REGMAP_SWR|MSM_QDSP6_SSR|MSM_QDSP6_PDR|MSM_QDSP6_NOTIFIER|SND_SOC_MSM_HOSTLESS_PCM|SND_SOC_MSM_QDSP6V2_INTF|SOUNDWIRE|SOUNDWIRE_MSTR_CTRL|SND_SOC_QDSP6V2|SND_SOC_MSM_HDMI_CODEC_RX|SND_SOC_MSM_STUB|MSM_AVTIMER|SND_SOC_BOLERO|WSA_MACRO|VA_MACRO|RX_MACRO|TX_MACRO|SND_SOC_WCD_IRQ|SND_SOC_WCD938X|SND_SOC_WCD938X_SLAVE|SND_SOC_WSA881X|SND_EVENT|SND_SOC_LITO|MSM_CSPL)=y$/d' "$CFG"
echo "剩余音频相关行: $(grep -cE '^CONFIG_(SND_SOC|MSM_QDSP|MSM_ADSP|WSA_|AUDIO_EXT|PINCTRL_LPI|REGMAP_SWR|SOUNDWIRE|WCD9XXX)=y' "$CFG" || true)" | tee -a "$LOG"
echo "保留的 KSU/wifi 项:" | tee -a "$LOG"
grep -E "^CONFIG_(KSU|KPROBES|KRETPROBES|QCA_CLD_WLAN)=" "$CFG" | tee -a "$LOG"

echo "=== [2] 配置 + 编译 ===" | tee -a "$LOG"
cd "$K" || exit 1
rm -rf "$OUT"
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j8 "${MAKE[@]}" vendor/vangogh_user_defconfig >> "$LOG" 2>&1 || { echo "defconfig failed"; exit 1; }
make -j8 "${MAKE[@]}" olddefconfig >> "$LOG" 2>&1
grep -E "^CONFIG_(KSU|QCA_CLD_WLAN|SND_SOC_LITO)=" "$OUT/.config" | tee -a "$LOG"

make -j16 "${MAKE[@]}" Image >> "$LOG" 2>&1
echo "make exit=$?" | tee -a "$LOG"
grep -nE " error:|undefined symbol" "$LOG" | head -6
IMG="$OUT/arch/arm64/boot/Image"
if [ -f "$IMG" ]; then
  ls -l "$IMG"
  python3 /mnt/f/vanilla-build/setup/pack_boot.py \
    --src "/mnt/c/Users/Administrator/Downloads/boot.img" \
    --kernel "$IMG" --out /mnt/f/vanilla-build/out-c3.img --pad 134217728 && echo PACKED
else echo IMAGE_MISSING; fi
