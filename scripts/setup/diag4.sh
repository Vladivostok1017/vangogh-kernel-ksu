#!/usr/bin/env bash
cd "$HOME/vanilla/src/pe13-kernel" || exit 1
OUT="$HOME/vanilla/out-vanilla"
ARGS=( O="$OUT" ARCH=arm64 "CC=clang-14 --target=aarch64-linux-gnu" \
       CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-gnu- )

echo "=== 单线程复现 empty.o ==="
make -j1 V=1 "${ARGS[@]}" scripts/mod/empty.o > /tmp/empty_build.log 2>&1
echo "exit=$?"
echo "--- 最后 12 行 ---"
tail -12 /tmp/empty_build.log
echo
echo "=== 报错前的那条命令 ---"
grep -n "unrecognized option" /tmp/empty_build.log | head -3
awk '/unrecognized option/{print NR": "$0}' /tmp/empty_build.log | head -3
echo
echo "=== 手工测试：.S + -EL + --target ==="
printf '.text\n.global f\nf:\n ret\n' > /tmp/t.S
clang-14 --target=aarch64-linux-gnu -no-integrated-as -EL -c /tmp/t.S -o /tmp/tS.o 2>&1 | head -5
echo "exit=$?"
echo
echo "=== 手工测试：不带 --target 时 as 是谁 ==="
clang-14 -no-integrated-as -print-prog-name=as
