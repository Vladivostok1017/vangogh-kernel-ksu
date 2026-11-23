#!/usr/bin/env bash
LOG="$HOME/vanilla/logs/image-build.log"
echo "=== 最后 30 行 ==="
tail -30 "$LOG"
echo
echo "=== 所有 Error 行 ==="
grep -nE "Error [0-9]|error:" "$LOG" | tail -15
echo
echo "=== ld/link 相关 ==="
grep -nE "LD |ld: |undefined|No rule|cannot find|Permission" "$LOG" | tail -15
