#!/system/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
# 在设备上以 root 运行：备份不可恢复分区
set -u
D=/sdcard/bk-partitions
mkdir -p "$D"
echo "output dir: $D"

for p in modemst1 modemst2 fsg persist sec misc devcfg devinfo boot dtbo vbmeta; do
  echo "--- $p ---"
  dd if=/dev/block/by-name/$p of="$D/$p.img" bs=1048576 2>&1 | tail -1
  ls -l "$D/$p.img" 2>/dev/null
done

echo
echo "=== 结果清单 ==="
ls -l "$D"
