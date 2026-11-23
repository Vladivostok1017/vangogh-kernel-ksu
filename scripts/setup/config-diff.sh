#!/usr/bin/env bash
gzip -dc /mnt/f/vanilla-build/stock_config.gz > /tmp/stock.config
BUILT="$HOME/vanilla/out-stock/.config"

echo "=== 配置项数量 ==="
echo "原厂: $(wc -l < /tmp/stock.config)"
echo "我们: $(wc -l < "$BUILT")"

echo
echo "=== 原厂有 =y 但我们的编译结果里没有/为 n 的项（前 40）==="
# stock 里 =y 的符号
grep -E "^CONFIG_[A-Z0-9_]+=y$" /tmp/stock.config | sed 's/=y$//' | sort > /tmp/stock_y.txt
grep -E "^CONFIG_[A-Z0-9_]+=y$" "$BUILT" | sed 's/=y$//' | sort > /tmp/built_y.txt
comm -23 /tmp/stock_y.txt /tmp/built_y.txt | head -40
echo "--- 丢失总数 ---"
comm -23 /tmp/stock_y.txt /tmp/built_y.txt | wc -l

echo
echo "=== 其中是否含 MIUI/高通关键项 ==="
comm -23 /tmp/stock_y.txt /tmp/built_y.txt | grep -iE "MI_|MIUI|QCOM|MSM|RTIC|XIAOMI|SEC" | head -20
