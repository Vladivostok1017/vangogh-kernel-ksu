#!/usr/bin/env bash
set -e
W="$HOME/work/dtbcheck"
mkdir -p "$W"
# 从原厂 boot.img 里取 dtb（之前解出来的还在）
if [ ! -f /tmp/unpacked/dtb ]; then
  echo "(重新解包 boot.img 取 dtb)"
  python3 /mnt/f/vanilla-build/setup/parse_boot.py "/mnt/c/Users/Administrator/Downloads/boot.img" /tmp/unpacked >/dev/null 2>&1 || true
fi
ls -l /tmp/unpacked/dtb 2>/dev/null || { echo "没有 dtb 文件"; exit 1; }

echo "=== dtb 里搜 ramoops / pstore ==="
strings -n 5 /tmp/unpacked/dtb | grep -iE "ramoops|pstore|ramoops_mem" | head -10
echo
echo "=== 原厂内核配置里的 PSTORE 选项 ==="
gzip -dc /mnt/f/vanilla-build/stock_config.gz > /tmp/stock.config
grep -iE "CONFIG_PSTORE" /tmp/stock.config | head -10
