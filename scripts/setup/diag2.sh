#!/usr/bin/env bash
K="$HOME/vanilla/src/pe13-kernel"
echo "=== 引用 gcc-wrapper 的位置 ==="
grep -rn "gcc-wrapper" "$K/Makefile" "$K/scripts/Makefile"* "$K/scripts/Kbuild.include" 2>/dev/null | head
echo
echo "=== Makefile 中 CC / REAL_CC 相关 ==="
grep -n "REAL_CC\|^CC\s*=\|CC_IS_CLANG\|gcc-wrapper" "$K/Makefile" | head -20
