#!/usr/bin/env bash
mkdir -p "$HOME/vanilla/vendor-ko"
cd "$HOME/vanilla/vendor-ko"
# 从 Windows 侧复制 .ko（容错各种嵌套）
find /mnt/f/vanilla-build/backup -name '*.ko' -exec cp -f {} . \; 2>/dev/null
echo "=== 本地模块 ==="
ls -l *.ko 2>/dev/null | head
echo
python3 /mnt/f/vanilla-build/setup/crc-compare.py "$HOME/vanilla/out-drift/Module.symvers" *.ko
