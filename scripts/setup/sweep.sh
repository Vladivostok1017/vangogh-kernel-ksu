#!/usr/bin/env bash
K="$HOME/work/driftwood/techpack/audio"
echo "=== [A] 所有 include 引用的文件是否存在 ==="
grep -rhn "^[[:space:]]*include \$(AUDIO_ROOT)/config/\|^[[:space:]]*include \$(srctree)/techpack/audio/config/" "$K" --include=Kbuild --include=Makefile 2>/dev/null \
 | sed 's/^[[:space:]]*include //' | sort -u | while read -r p; do
    f=$(echo "$p" | sed "s|\$(AUDIO_ROOT)|$K|; s|\$(srctree)|$HOME/work/driftwood|")
    [ -f "$f" ] && echo "OK      $p" || echo "MISSING $p"
 done

echo
echo "=== [B] -include 的 autoconf.h ==="
grep -rh "\-include \$(AUDIO_ROOT)/config/" "$K" --include=Kbuild --include=Makefile 2>/dev/null | sed 's/.*-include //' | sort -u | while read -r p; do
  f=$(echo "$p" | sed "s|\$(AUDIO_ROOT)|$K|")
  [ -f "$f" ] && echo "OK      $p" || echo "MISSING $p"
done

echo
echo "=== [C] KBUILD_EXTRA_SYMBOLS 引用（构建系统特有路径）==="
grep -rn "KBUILD_EXTRA_SYMBOLS" "$K" --include=Kbuild --include=Makefile 2>/dev/null | head -10

echo
echo "=== [D] 其他 \$() 变量引用（可能未定义）==="
grep -rhoE '\$\((AUDIO_ROOT|MODNAME|OUT|KERNEL_BUILD|CONFIG_AUDIO_ROOT|TARGET_BOARD_PLATFORM)\)' "$K" --include=Kbuild --include=Makefile 2>/dev/null | sort | uniq -c | sort -rn

echo
echo "=== [E] configs/*_defconfig 引用 ==="
grep -rn "configs/.*_defconfig" "$K" --include=Kbuild --include=Makefile 2>/dev/null | head -5
