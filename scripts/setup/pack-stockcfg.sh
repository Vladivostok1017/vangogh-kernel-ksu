#!/usr/bin/env bash
IMG="$HOME/vanilla/out-stock/arch/arm64/boot/Image"
OUTIMG=/mnt/f/vanilla-build/out/boot-stockcfg-test.img
echo "=== 内核版本字符串（关键：vermagic 是否与原厂一致）==="
strings -n 10 "$IMG" | grep -m3 "^Linux version 4.19"
echo
echo "=== 内核内嵌 vermagic ==="
strings -n 8 "$IMG" | grep -m5 "4.19.113-perf" | head -5
echo
echo "=== 对比信息 ==="
echo "原厂: 4.19.113-perf-ga1b60ef832fb (clang 10.0.6)"
echo
echo "=== 打包 ==="
python3 /mnt/f/vanilla-build/setup/pack_boot.py \
  --src "/mnt/c/Users/Administrator/Downloads/boot.img" \
  --kernel "$IMG" --out "$OUTIMG" --pad 134217728
ls -l "$OUTIMG"
