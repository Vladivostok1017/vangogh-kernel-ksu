#!/usr/bin/env bash
K="$HOME/vanilla/src/driftwood"
M="$K/kernel/module.c"
echo "=== check_modinfo 主体（3060-3110）==="
sed -n '3060,3110p' "$M"
echo
echo "=== check_version 的 CRC 比较段（1300-1350）==="
sed -n '1300,1350p' "$M"
