#!/usr/bin/env bash
K="$HOME/work/driftwood"
echo "=== lito_defconfig 里的音频相关 =y 项 ==="
grep -E "^CONFIG_(SND_SOC|MSM_|WCD9XXX|AUDIO_EXT|REGMAP_SWR|SWR_)" "$K/arch/arm64/configs/vendor/lito_defconfig" 2>/dev/null | head -40

echo
echo "=== vangogh_user_defconfig 里现有的音频项 ==="
grep -E "SND_SOC|MSM_QDSP|MSM_ADSP|WCD9|AUDIO_EXT|BOLERO|WSA8" "$K/arch/arm64/configs/vendor/vangogh_user_defconfig" 2>/dev/null | head -20
echo "(以上为空则说明完全没配)"

echo
echo "=== techpack/audio 里 machine 驱动（找 lito/vangogh 对应符号）==="
grep -rn "config SND_SOC_.*MACHINE\|config SND_SOC_LITO\|config SND_SOC_.*LITO" "$K/techpack/audio/asoc/Kbuild" "$K/techpack/audio/asoc/machine/Kconfig" 2>/dev/null | head -10
ls "$K/techpack/audio/asoc/machine" 2>/dev/null | head -10
