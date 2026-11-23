#!/usr/bin/env bash
K="$HOME/work/driftwood"
echo "=== q6usm / wsa883x 出现在哪些构建文件 ==="
grep -rn "q6usm\|wsa883x" "$K/techpack/audio" --include=Kbuild --include=Makefile 2>/dev/null | head -10
echo
echo "=== dsp 目录里 obj-y 硬编码情况 ==="
grep -nE "^obj-y|^obj-\\\$" "$K/techpack/audio/dsp/Kbuild" 2>/dev/null | head -20
echo
echo "=== 相关配置当前值 ==="
grep -E "^CONFIG_(SND_SOC_QDSP6V2|WSA883X|MSM_QDSP6V2_CODECS|MSM_QDSP6_APRV2_RPMSG|REGMAP_SWR|MSM_CDC_PINCTRL|MSM_AUDIO_ION)" "$HOME/work/out-c7/.config" 2>/dev/null
echo
echo "=== audio_ion 的符号名 ==="
grep -rn "msm_audio_ion_alloc" "$K/techpack/audio" --include=Kbuild --include=Makefile 2>/dev/null | head -3
grep -rn "msm_audio_ion_alloc" "$K/techpack" 2>/dev/null | grep -v "\.c:" | head -3
