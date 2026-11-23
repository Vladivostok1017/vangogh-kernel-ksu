#!/usr/bin/env bash
K="$HOME/vanilla/src/driftwood"
M="$K/kernel/module.c"
echo "=== vermagic 校验 ==="
grep -n -A12 "static int check_modinfo" "$M" | head -30
echo
echo "=== CRC 校验（check_version）==="
grep -n -A18 "static int check_version" "$M" | head -35
