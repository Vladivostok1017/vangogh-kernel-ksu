#!/usr/bin/env bash
K="$HOME/work/driftwood"
gzip -dc /mnt/f/vanilla-build/stock_config.gz > /tmp/stock.config

echo "=== 原厂配置里 wifi / 音频 的状态 ==="
for s in QCA_CLD_WLAN WLAN_FEATURE_SAP AUDIO_EXT_CLK MSM_ADSP_LOADER MSM_QDSP6V2_CODECS \
         MSM_QDSP6_APRV2_RPMSG SND_SOC_WCD937X SND_SOC_WCD938X SND_SOC_BOLERO \
         SND_SOC_MACHINE_LITO SND_SOC_WSA883X SND_SOC_WSA881X MSM_CDC_PINCTRL \
         WCD9XXX_CODEC_CORE_V2 SND_SOC_WCD_MBHC; do
  hit=$(grep -m1 "^CONFIG_${s}=" /tmp/stock.config || grep -m1 "^# CONFIG_${s} is not set" /tmp/stock.config)
  printf '%-28s %s\n' "$s" "${hit:-（不存在该符号）}"
done

echo
echo "=== vangogh DTS 里的音频 codec ==="
grep -rhoiE "wcd937x|wcd938x|wsa883x|wsa881x|bolero|wcd9375|wcd9385" \
  "$K/arch/arm64/boot/dts/vendor/"*/*vangogh* 2>/dev/null | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head

echo
echo "=== vangogh DTS 里 wifi 相关节点 ==="
grep -rhoiE "qca6390|wcn3990|icnss|wlan" "$K/arch/arm64/boot/dts/vendor/"*/*vangogh* 2>/dev/null | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head
