#!/usr/bin/env bash
# Route C step 2: wifi(built-in) + audio(built-in) + KernelSU
set -o pipefail
P="http://127.0.0.1:17890"
export http_proxy="$P" https_proxy="$P"
K="$HOME/work/driftwood"
OUT="$HOME/work/out-c2"
LOG="$HOME/work/build-c2.log"
export PATH="$HOME/bin:$PATH"
mkdir -p "$HOME/bin"

echo "=== [1] KernelSU 子模块（父级同级 + 钉住的提交）===" | tee "$LOG"
SUBSHA=$(cd "$K" && git ls-tree HEAD KernelSU 2>/dev/null | awk '{print $3}')
echo "pinned commit: ${SUBSHA:-（未取到）}" | tee -a "$LOG"
if [ -n "$SUBSHA" ] && [ ! -d "$K/KernelSU/kernel" ]; then
  rm -rf "$K/KernelSU"
  git clone --filter=blob:none https://github.com/tiann/KernelSU.git "$K/KernelSU" >> "$LOG" 2>&1
  (cd "$K/KernelSU" && git checkout "$SUBSHA" >> "$LOG" 2>&1) || echo "checkout 失败" | tee -a "$LOG"
fi
ln -sfn "$K/KernelSU" "$HOME/work/KernelSU"
ln -sfn "$K/KernelSU/kernel" "$K/drivers/kernelsu" 2>/dev/null || true
ls "$K/KernelSU/kernel/Kconfig" >/dev/null 2>&1 && echo "KSU kernel dir OK" | tee -a "$LOG"
grep -q "kernelsu" "$K/drivers/Makefile" || printf '\nobj-$(CONFIG_KSU) += kernelsu/\n' >> "$K/drivers/Makefile"
grep -q 'drivers/kernelsu/Kconfig' "$K/drivers/Kconfig" || \
  sed -i '0,/^endmenu$/s//source "drivers\/kernelsu\/Kconfig"\nendmenu/' "$K/drivers/Kconfig"

echo "=== [2] defconfig 追加：wifi + 音频 + KSU ===" | tee -a "$LOG"
CFG="$K/arch/arm64/configs/vendor/vangogh_user_defconfig"
add(){ grep -q "^CONFIG_$1=y" "$CFG" || echo "CONFIG_$1=y" >> "$CFG"; }
for o in MIHW MIGT MILLET MIGT_ENERGY_MODEL SF_BINDER PERF_CRITICAL_RT_TASK \
         QCA_CLD_WLAN KPROBES KPROBE_EVENTS KRETPROBES KSU \
         PINCTRL_LPI AUDIO_EXT_CLK MSM_CDC_PINCTRL SND_SOC_WCD_MBHC SND_SOC_WCD_MBHC_ADC \
         WCD9XXX_CODEC_CORE_V2 MSM_QDSP6V2_CODECS MSM_QDSP6_APRV2_RPMSG MSM_ADSP_LOADER \
         REGMAP_SWR MSM_QDSP6_SSR MSM_QDSP6_PDR MSM_QDSP6_NOTIFIER SND_SOC_MSM_HOSTLESS_PCM \
         SND_SOC_MSM_QDSP6V2_INTF SOUNDWIRE SOUNDWIRE_MSTR_CTRL SND_SOC_QDSP6V2 \
         SND_SOC_MSM_HDMI_CODEC_RX SND_SOC_MSM_STUB MSM_AVTIMER SND_SOC_BOLERO \
         WSA_MACRO VA_MACRO RX_MACRO TX_MACRO SND_SOC_WCD_IRQ SND_SOC_WCD938X \
         SND_SOC_WCD938X_SLAVE SND_SOC_WSA881X SND_EVENT SND_SOC_LITO MSM_CSPL; do add "$o"; done
echo "  已追加 $(grep -cE '^CONFIG_(SND_SOC|MSM_QDSP|MSM_ADSP|WSA_|VA_MACRO|RX_MACRO|TX_MACRO|AUDIO_EXT|PINCTRL_LPI|REGMAP_SWR|SOUNDWIRE|WCD9XXX|MSM_CSPL|SND_EVENT)' "$CFG") 条音频配置" | tee -a "$LOG"

echo "=== [3] 生成配置 ===" | tee -a "$LOG"
cd "$K" || exit 1
rm -rf "$OUT"
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j8 "${MAKE[@]}" vendor/vangogh_user_defconfig >> "$LOG" 2>&1 || { echo "defconfig failed"; tail -8 "$LOG"; exit 1; }
make -j8 "${MAKE[@]}" olddefconfig >> "$LOG" 2>&1
echo "--- 关键项生效情况 ---" | tee -a "$LOG"
grep -E "^CONFIG_(KSU|QCA_CLD_WLAN|SND_SOC_LITO|SND_SOC_WCD938X|SND_SOC_BOLERO|MSM_QDSP6V2_CODECS|SND_SOC_MSM_QDSP6V2_INTF|SOUNDWIRE)=" "$OUT/.config" | tee -a "$LOG"

echo "=== [4] 编译 ===" | tee -a "$LOG"
make -j16 "${MAKE[@]}" Image >> "$LOG" 2>&1
echo "make exit=$?" | tee -a "$LOG"
grep -nE " error:|Error [12]\b|undefined symbol" "$LOG" | head -10
IMG="$OUT/arch/arm64/boot/Image"
if [ -f "$IMG" ]; then
  ls -l "$IMG"; strings -n 10 "$IMG" | grep -m1 "^Linux version 4.19"
  python3 /mnt/f/vanilla-build/setup/pack_boot.py \
    --src "/mnt/c/Users/Administrator/Downloads/boot.img" \
    --kernel "$IMG" --out /mnt/f/vanilla-build/out-c2.img --pad 134217728 && echo PACKED
else
  echo IMAGE_MISSING
fi
