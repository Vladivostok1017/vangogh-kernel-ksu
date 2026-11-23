#!/usr/bin/env bash
OUT="$HOME/vanilla/out-vanilla"
echo "out dir: $OUT"
du -sh "$OUT" 2>/dev/null
echo "objs: $(find "$OUT" -name '*.o' 2>/dev/null | wc -l)"
echo "built-in.a: $(find "$OUT" -name 'built-in.a' 2>/dev/null | wc -l)"
echo "Image: $(ls -l "$OUT/arch/arm64/boot/Image" 2>/dev/null || echo MISSING)"
echo "--- log lines: $(wc -l < "$HOME/vanilla/logs/image-build.log" 2>/dev/null) ---"
echo "--- last 2 ---"
tail -2 "$HOME/vanilla/logs/image-build.log"
echo "--- any error ---"
grep -cE " error:" "$HOME/vanilla/logs/image-build.log" 2>/dev/null
echo "--- make still running? ---"
pgrep -af "make.*Image" | head -3
