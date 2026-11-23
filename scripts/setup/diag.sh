#!/usr/bin/env bash
K="$HOME/vanilla/src/pe13-kernel"
echo "=== Kconfig 中调用 python 的位置 ==="
grep -rn "python" --include=Kconfig "$K" 2>/dev/null | head -10
echo
echo "=== 含 py2 风格 print 的 py 脚本 ==="
grep -rln 'print "' --include=*.py "$K/scripts" "$K/arch" "$K/kernel" 2>/dev/null | head -20
echo
echo "=== init/Kconfig 1-25 行 ==="
sed -n '1,25p' "$K/init/Kconfig"
echo
echo "=== 日志中 python 报错上下文 ==="
grep -n -B12 "Missing parentheses" "$HOME/vanilla/logs/build-vanilla.log" | head -40
