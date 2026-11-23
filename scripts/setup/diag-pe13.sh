#!/usr/bin/env bash
LOG="$HOME/vanilla/logs/build-pe13.log"
echo "=== 首个错误上下文 ==="
first=$(grep -nE " error:|Error [0-9]+|unrecognized|No rule" "$LOG" | head -1 | cut -d: -f1)
echo "first_error_line=$first (total $(wc -l < "$LOG"))"
if [ -n "$first" ]; then
  s=$((first-15)); [ $s -lt 1 ] && s=1
  sed -n "${s},$((first+3))p" "$LOG"
fi
echo
echo "=== 末尾 12 行 ==="
tail -12 "$LOG"
