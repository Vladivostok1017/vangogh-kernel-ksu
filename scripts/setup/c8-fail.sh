#!/usr/bin/env bash
LOG="$HOME/work/build-c8.log"
echo "=== 含 Error 的行 ==="
grep -n "Error" "$LOG" | head -10
echo
echo "=== 首次失败前后 ==="
n=$(grep -n "Error" "$LOG" | head -1 | cut -d: -f1)
echo "line=$n / total=$(wc -l < "$LOG")"
if [ -n "$n" ]; then
  s=$((n-22)); [ "$s" -lt 1 ] && s=1
  sed -n "${s},$((n+2))p" "$LOG"
fi
