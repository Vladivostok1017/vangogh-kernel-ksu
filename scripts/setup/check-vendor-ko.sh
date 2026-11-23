#!/usr/bin/env bash
set -e
DST="$HOME/vanilla/vendor-ko"
mkdir -p "$DST"
cd "$DST"

echo "=== 设备 vendor 模块目录 ==="
adb shell "ls /vendor/lib/modules/ 2>&1 | head -10"
echo
KO=$(adb shell "ls /vendor/lib/modules/*.ko 2>/dev/null | head -1" | tr -d '\r')
echo "取样模块: $KO"
adb pull "$KO" ./sample.ko 2>&1 | tail -1
ls -l sample.ko

echo
echo "=== 该模块的 vermagic ==="
strings -n 8 sample.ko | grep -E "^4\.19|SMP preempt" | head -3
echo
echo "=== 它依赖的符号里，取几个看 CRC 是否存在 ==="
strings sample.ko | grep -c "__crc_" || echo "0"
echo "--- 前 5 个 __crc_ 符号 ---"
strings sample.ko | grep "__crc_" | head -5
