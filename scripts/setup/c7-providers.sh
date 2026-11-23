#!/usr/bin/env bash
K="$HOME/work/driftwood"
echo "=== msm_audio_ion 实现在哪个目录/配置 ==="
grep -rln "msm_audio_ion_alloc" "$K/techpack/audio" 2>/dev/null | grep -v "\.h$" | head -5
echo "--- 该文件在 Kbuild 里的归属 ---"
f=$(grep -rln "msm_audio_ion_alloc" "$K/techpack/audio" 2>/dev/null | grep -v "\.h$" | head -1)
echo "file: $f"
[ -n "$f" ] && grep -rn "$(basename "$f" .c).o" "$K/techpack/audio" --include=Kbuild 2>/dev/null | head -5

echo
echo "=== 各 provider 的配置符号 ==="
for s in MSM_QDSP6_APRV2_RPMSG REGMAP_SWR MSM_CDC_PINCTRL MSM_AUDIO_ION MSM_QDSP6V2_CODECS; do
  printf '%-28s ' "$s"
  grep -m1 "^CONFIG_${s}=" "$HOME/work/out-c7/.config" || echo "(不存在)"
done
