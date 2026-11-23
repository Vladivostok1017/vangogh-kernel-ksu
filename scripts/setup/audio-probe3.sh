#!/usr/bin/env bash
K="$HOME/work/driftwood"
echo "=== 关键音频符号的依赖/select 关系 ==="
for s in SND_SOC_LITO SND_SOC_WCD938X SND_SOC_BOLERO WSA_MACRO MSM_QDSP6V2_CODECS AUDIO_EXT_CLK; do
  echo "--- $s"
  awk -v sym="config $s" '$0 ~ "^"sym"$" {f=1;next} f && /^config /{f=0} f' "$K/techpack/audio/Kconfig" | head -12
done

echo
echo "=== Kconfig 由谁 source ==="
grep -rn "techpack/audio/Kconfig\|techpack/Kconfig" "$K" --include=Kconfig 2>/dev/null | head -5
grep -rn "techpack" "$K/Makefile" | head -5
