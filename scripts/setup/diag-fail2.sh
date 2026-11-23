#!/usr/bin/env bash
LOG="$HOME/vanilla/logs/image-build.log"
echo "=== 首个 Error/error 出现的行号 ==="
first=$(grep -nE "Error [0-9]| error:|Error 1|recipe commences|No rule" "$LOG" | head -1 | cut -d: -f1)
echo "first_error_line=$first  (total $(wc -l < "$LOG"))"
if [ -n "$first" ]; then
  start=$((first-25)); [ $start -lt 1 ] && start=1
  echo "=== 上下文 ($start .. $((first+3))) ==="
  sed -n "${start},$((first+3))p" "$LOG"
fi
echo
echo "=== 所有 Error 行（末尾 8）==="
grep -nE "Error [0-9]" "$LOG" | tail -8
