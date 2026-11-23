#!/usr/bin/env bash
K="$HOME/vanilla/src/pe13-kernel"
echo "=== techpack 下所有 Werror ==="
grep -rn "Werror" "$K/techpack" 2>/dev/null | head -20
echo
echo "=== techpack/audio/Makefile 头部 ==="
sed -n '1,40p' "$K/techpack/audio/Makefile"
