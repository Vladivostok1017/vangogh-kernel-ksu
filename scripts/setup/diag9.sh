#!/usr/bin/env bash
K="$HOME/vanilla/src/pe13-kernel"
echo "=== 树内 -Werror 定义（Makefile / Kbuild） ==="
grep -rn -- "-Werror" --include=Makefile --include=Kbuild "$K" 2>/dev/null | grep -v "^.*techpack/audio/.*\.c" | head -20
echo
echo "=== 配置里的 WERROR ==="
grep -nE "WERROR|WERROR_" "$HOME/vanilla/out-vanilla/.config" | head -10
echo
echo "=== apr.o 的编译命令（从日志找） ==="
grep -n "apr.o" /tmp/image_build.log | head -5
