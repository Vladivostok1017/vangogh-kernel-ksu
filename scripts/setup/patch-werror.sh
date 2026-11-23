#!/usr/bin/env bash
K="$HOME/vanilla/src/pe13-kernel"
cd "$K" || exit 1
echo "=== 打补丁前，含 -Werror 的 Kbuild 文件数 ==="
grep -rl -- "-Werror" techpack 2>/dev/null | wc -l
echo "=== 备份并删除只有 -Werror\ 的行 ==="
for f in $(grep -rl -- "-Werror" techpack 2>/dev/null); do
  cp "$f" "$f.bak_werror" 2>/dev/null
  sed -i -e 's/^[[:space:]]*-Werror\\[[:space:]]*$//' "$f"
  sed -i -e 's/[[:space:]]-Werror\\$//' "$f"
  sed -i -e 's/-Werror\\//' "$f"
  sed -i -e 's/[[:space:]]-Werror[[:space:]]*$//' "$f"
done
echo "=== 补丁后仍含 -Werror 的行 ==="
grep -rn -- "-Werror" techpack 2>/dev/null | head -5
echo "(以上应为空或仅注释)"
