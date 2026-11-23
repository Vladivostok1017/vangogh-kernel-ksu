#!/usr/bin/env bash
K="$HOME/work/driftwood/techpack/audio"
echo "=== 所有 include 的 conf 片段 ==="
grep -rn "\.conf" "$K" --include=Kbuild --include=Makefile 2>/dev/null | head -20
echo
echo "=== asoc/Kbuild 40-60 ==="
sed -n '40,60p' "$K/asoc/Kbuild"
echo
echo "=== asoc/Kbuild 里 AUDIO_ROOT / MODNAME 相关 ==="
grep -n "AUDIO_ROOT\|MODNAME\|CONFIG_" "$K/asoc/Kbuild" | head -15
