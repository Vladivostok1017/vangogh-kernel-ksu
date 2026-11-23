#!/usr/bin/env bash
OUT="$HOME/vanilla/out-vanilla"
cd "$OUT" || exit 1

# grab the failing clang command line from the log
CMD=$(grep -m1 "^  clang-14 --target=aarch64-linux-gnu .*gettimeofday.S" /tmp/ias_test.log | sed 's/^  //')
echo "=== 原始命令（截断显示） ==="
echo "${CMD:0:200}..."
echo
echo "=== 用 -### 看子命令 ==="
MODCMD=$(echo "$CMD" | sed 's#-c -o [^ ]*#-c -o /tmp/x.o#')
$MODCMD -### 2>&1 | grep -E '"as"|as_dash|aarch64-linux-gnu-as|/usr/bin/as' | head -5
echo
echo "=== 直接跑该命令（完整） ==="
$MODCMD 2>&1 | tail -4
echo
echo "=== vdso Makefile 关键行 ==="
sed -n '40,60p' "$HOME/vanilla/src/pe13-kernel/arch/arm64/kernel/vdso/Makefile"
