#!/usr/bin/env bash
MC="$HOME/vanilla/src/micode"      # MiCode vangogh-q-oss (Xiaomi 自家树)
PE="$HOME/vanilla/src/pe13-kernel" # PE 树

echo "=== Xiaomi 自家树里这些驱动的存在情况 ==="
for sym in MIHW MILLET MIGT MI_MEMORY_SYSFS MI_RECLAIM MIUI_ZRAM_MEMORY_TRACKING SF_BINDER PERF_CRITICAL_RT_TASK; do
  hit=$(grep -rl "config $sym" "$MC" --include=Kconfig 2>/dev/null | head -1)
  printf '%-28s %s\n' "$sym" "${hit:-未找到}"
done

echo
echo "=== 对应驱动目录规模 ==="
for d in "$MC/drivers/mihw" "$MC/drivers/millet" "$MC/drivers/migt" "$MC/drivers/mi_memory"; do
  [ -d "$d" ] && echo "$(basename "$d"): $(find "$d" -name '*.c' | wc -l) 个 .c, $(du -sh "$d" | cut -f1)"
done
ls -d "$MC/drivers"/mi* "$MC/drivers"/millet* 2>/dev/null | head

echo
echo "=== PE 树里对应位置 ==="
ls -d "$PE/drivers"/mi* "$PE/drivers"/millet* "$PE/drivers"/migt* 2>/dev/null | head || echo "(PE 树中不存在)"

echo
echo "=== 这些驱动在 micode 树 defconfig 里的状态 ==="
grep -nE "MIHW|MILLET|MIGT|MI_MEMORY|SF_BINDER|PERF_CRITICAL" "$MC/arch/arm64/configs/vendor/vangogh_user_defconfig" 2>/dev/null | head -10
