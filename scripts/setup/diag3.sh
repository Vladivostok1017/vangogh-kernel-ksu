#!/usr/bin/env bash
cd "$HOME/vanilla/src/pe13-kernel" || exit 1
OUT="$HOME/vanilla/out-vanilla"
ARGS=( O="$OUT" ARCH=arm64 "CC=clang-14 --target=aarch64-linux-gnu" \
       CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-gnu- )
rm -f "$OUT/scripts/mod/empty.o"
echo "=== V=1 build of scripts/mod/empty.o ==="
make V=1 "${ARGS[@]}" scripts/mod/empty.o 2>&1 | grep -E "clang|as |EL|error" | head -20
echo
echo "=== direct clang test (with target) ==="
echo 'int x;' > /tmp/t.c
clang-14 --target=aarch64-linux-gnu -c /tmp/t.c -o /tmp/t.o -EL 2>&1 | head -5
echo "exit=$?"
echo
echo "=== which as does clang use for aarch64 target ==="
clang-14 --target=aarch64-linux-gnu -print-prog-name=as
echo "=== for plain clang ==="
clang-14 -print-prog-name=as
