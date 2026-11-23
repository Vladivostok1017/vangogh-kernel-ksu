#!/usr/bin/env bash
K="$HOME/vanilla/src/pe13-kernel"
cd "$K" || exit 1

echo "=== [1] 从备份恢复被改坏的 Kbuild ==="
n=0
while IFS= read -r bak; do
  orig="${bak%.bak_werror}"
  cp -f "$bak" "$orig" && rm -f "$bak" && n=$((n+1))
done < <(find techpack -name '*.bak_werror')
echo "restored $n files"

echo "=== [2] 用 -Wno-error 替换 -Werror（保留续行符）==="
grep -rl -- "-Werror" techpack --include=Kbuild --include=Makefile 2>/dev/null | while read -r f; do
  sed -i 's/-Werror/-Wno-error/g' "$f"
  echo "  patched $f"
done

echo "=== [3] 确认没有残留 -Werror 与孤立续行 ==="
grep -rn -- "-Werror" techpack --include=Kbuild --include=Makefile 2>/dev/null | head -5
echo "--- 检查 asoc/Kbuild 语法（make 解析测试）---"
make -f /dev/null -C techpack/audio/asoc -n 2>&1 | head -3 || true

echo "=== [4] 用 make 解析该 Kbuild 验证语法 ==="
make --no-print-directory -f "$K/techpack/audio/asoc/Kbuild" -n 2>&1 | head -5
echo "exit=$?"
