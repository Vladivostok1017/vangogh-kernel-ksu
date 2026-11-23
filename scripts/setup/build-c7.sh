#!/usr/bin/env bash
# Build kernel with audio drivers as MODULES (=m) instead of built-in,
# so the kernel cannot crash early on ADSP-dependent probes.
set -o pipefail
K="$HOME/work/driftwood"
OUT="$HOME/work/out-c7"
LOG="$HOME/work/build-c7.log"
export PATH="$HOME/bin:$PATH"

AUDIO="PINCTRL_LPI AUDIO_EXT_CLK MSM_CDC_PINCTRL SND_SOC_WCD_MBHC SND_SOC_WCD_MBHC_ADC WCD9XXX_CODEC_CORE_V2 MSM_QDSP6V2_CODECS MSM_QDSP6_APRV2_RPMSG MSM_ADSP_LOADER REGMAP_SWR MSM_QDSP6_SSR MSM_QDSP6_PDR MSM_QDSP6_NOTIFIER SND_SOC_MSM_HOSTLESS_PCM SND_SOC_MSM_QDSP6V2_INTF SOUNDWIRE SOUNDWIRE_MSTR_CTRL SND_SOC_QDSP6V2 SND_SOC_MSM_HDMI_CODEC_RX SND_SOC_MSM_STUB MSM_AVTIMER SND_SOC_BOLERO WSA_MACRO VA_MACRO RX_MACRO TX_MACRO SND_SOC_WCD_IRQ SND_SOC_WCD938X SND_SOC_WCD938X_SLAVE SND_SOC_WSA881X SND_EVENT SND_SOC_LITO MSM_CSPL"

echo "=== [1] defconfig: 音频全部改为 =m ===" | tee "$LOG"
CFG="$K/arch/arm64/configs/vendor/vangogh_user_defconfig"
# 先删掉可能存在的 =y 音频行
sed -i -E "/^CONFIG_($(echo $AUDIO | tr ' ' '|'))=y$/d" "$CFG"
# 再追加 =m
for o in $AUDIO; do grep -q "^CONFIG_$o=m" "$CFG" || echo "CONFIG_$o=m" >> "$CFG"; done
echo "  音频 =m 行数: $(grep -cE '^CONFIG_(PINCTRL_LPI|AUDIO_EXT_CLK|MSM_CDC_PINCTRL|SND_SOC_|MSM_QDSP6|MSM_ADSP_LOADER|REGMAP_SWR|SOUNDWIRE|WCD9XXX|WSA_MACRO|VA_MACRO|RX_MACRO|TX_MACRO|SND_EVENT|MSM_CSPL|MSM_AVTIMER)=m' "$CFG")" | tee -a "$LOG"
grep -E "^CONFIG_(KSU|QCA_CLD_WLAN)=" "$CFG" | tee -a "$LOG"

echo "=== [2] 配置 ===" | tee -a "$LOG"
cd "$K" || exit 1
rm -rf "$OUT"
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j8 "${MAKE[@]}" vendor/vangogh_user_defconfig >> "$LOG" 2>&1 || { echo "defconfig 失败"; tail -8 "$LOG"; exit 1; }
make -j8 "${MAKE[@]}" olddefconfig >> "$LOG" 2>&1
echo "--- 音频生效情况 ---" | tee -a "$LOG"
grep -cE "^CONFIG_(SND_SOC|MSM_QDSP6|WSA_MACRO|SND_EVENT|AUDIO_EXT_CLK|REGMAP_SWR|SOUNDWIRE|WCD9XXX)=m$" "$OUT/.config" | tee -a "$LOG"
grep -E "^CONFIG_(SND_SOC_LITO|MSM_QDSP6V2_CODECS|SND_SOC_WCD938X|SND_SOC_BOLERO)=" "$OUT/.config" | tee -a "$LOG"

echo "=== [3] 编 Image + modules ===" | tee -a "$LOG"
make -j16 "${MAKE[@]}" Image >> "$LOG" 2>&1; echo "Image exit=$?" | tee -a "$LOG"
make -j16 "${MAKE[@]}" modules >> "$LOG" 2>&1; echo "modules exit=$?" | tee -a "$LOG"
grep -nE " error:|fatal error" "$LOG" | head -6
IMG="$OUT/arch/arm64/boot/Image"
if [ -f "$IMG" ]; then
  ls -l "$IMG"
  echo "编出的 .ko 数量: $(find "$OUT" -name '*.ko' | wc -l)"
  find "$OUT" -name '*.ko' | grep -iE "snd|audio|wcd|bolero|swr|q6|adsp" | head -20
  python3 /mnt/f/vanilla-build/setup/pack_boot.py \
    --src "/mnt/c/Users/Administrator/Downloads/boot.img" \
    --kernel "$IMG" --out /mnt/f/vanilla-build/out-c7.img --pad 134217728 && echo PACKED
else echo IMAGE_MISSING; fi
