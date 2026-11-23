#!/usr/bin/env bash
gzip -dc /mnt/f/vanilla-build/stock_config.gz > /tmp/stock.config
echo "=== 原厂配置 =m（模块）总数 ==="
grep -c "=m$" /tmp/stock.config
echo
echo "=== 其中与 wifi / 音频 / MIUI 相关的 ==="
grep "=m$" /tmp/stock.config | grep -iE "WLAN|CLD|SND_SOC|AUDIO|ADSP|BOLERO|WCD|MBHC|SWR|MIHW|MIGT|MILLET|EXFAT|RMNET" | head -40
echo
echo "=== 全部 =m 列表 ==="
grep "=m$" /tmp/stock.config
