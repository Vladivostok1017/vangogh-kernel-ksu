#!/system/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
echo "=== pstore 文件 ==="
ls -l /sys/fs/pstore/ 2>&1
echo
for f in /sys/fs/pstore/*; do
  case "$f" in
    *console-ramoops*) echo "===== $f (末尾 60 行) ====="; tail -60 "$f" 2>&1;;
  esac
done
echo
echo "=== 搜 panic / oops / 音频相关 ==="
for f in /sys/fs/pstore/console-ramoops*; do
  [ -f "$f" ] || continue
  grep -inE "panic|oops|BUG|Call trace|wcd|bolero|swr|asoc|snd_|adsp|q6|Unable to handle" "$f" 2>/dev/null | tail -40
done
