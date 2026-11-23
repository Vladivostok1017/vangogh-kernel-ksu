#!/usr/bin/env bash
K="$HOME/work/driftwood"
CFG="$HOME/work/out-c7/.config"
echo "=== 当前值 ==="
grep -E "^CONFIG_(MSM_ULTRASOUND|SND_SOC_WSA883X|SND_SOC_WSA881X)=" "$CFG" || echo "(未出现在 .config)"
grep -E "MSM_ULTRASOUND|WSA883X" "$CFG" | head -5
echo
echo "=== codecs/Kbuild 里所有硬编码 obj-y 目录 ==="
grep -n "^	obj-y\|^obj-y" "$K/techpack/audio/asoc/codecs/Kbuild" | head -30
echo
echo "=== dsp/Kbuild 里 obj-y 硬编码 ==="
grep -n "^obj-y\|^	obj-y" "$K/techpack/audio/dsp/Kbuild" | head -15
