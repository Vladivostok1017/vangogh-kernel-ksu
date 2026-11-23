#!/usr/bin/env bash
W="$HOME/vanilla/pe13-vendor"
OUT="$HOME/vanilla/pe13-ko"
mkdir -p "$OUT"
cd "$W" || exit 1

echo "=== 用 debugfs 导出 /lib/modules ==="
debugfs -R "rdump /lib/modules $OUT" vendor.img 2>&1 | tail -3
ls -l "$OUT"/lib/modules/ 2>/dev/null || find "$OUT" -name '*.ko' -exec ls -l {} \;

echo
echo "=== 各模块 vermagic ==="
find "$OUT" -name '*.ko' | while read -r f; do
  echo "--- $(basename "$f")"
  strings "$f" | grep -m1 "SMP preempt"
done

echo
echo "=== modules.dep / softdep ==="
cat "$OUT"/lib/modules/modules.dep 2>/dev/null
cat "$OUT"/lib/modules/modules.softdep 2>/dev/null
