#!/usr/bin/env bash
# Back up non-recoverable partitions using Magisk root.
set -u
STAMP=$(date +%Y%m%d-%H%M%S)
DEV_DIR="/sdcard/bk-$STAMP"
LOCAL_DIR="/mnt/f/vanilla-build/backup/$STAMP"
mkdir -p "$LOCAL_DIR"

PARTS="modemst1 modemst2 fsg persist sec misc devcfg devinfo boot dtbo vbmeta"

echo "=== 创建设备端目录 ==="
adb shell "su -c 'mkdir -p $DEV_DIR && echo ok'"

for p in $PARTS; do
  echo "--- $p ---"
  out=$(adb shell "su -c 'dd if=/dev/block/by-name/$p of=$DEV_DIR/$p.img bs=1M 2>&1'" 2>&1 | tail -1)
  echo "  $out"
done

echo
echo "=== 设备端结果 ==="
adb shell "su -c 'ls -l $DEV_DIR'"

echo
echo "=== 拉取到 PC: $LOCAL_DIR ==="
adb pull "$DEV_DIR" "$LOCAL_DIR" 2>&1 | tail -2

echo
echo "=== 校验 ==="
ls -l "$LOCAL_DIR"/ 2>/dev/null | head -20
