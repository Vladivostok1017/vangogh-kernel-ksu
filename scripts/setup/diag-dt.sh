#!/usr/bin/env bash
D="$HOME/vanilla/src/pe13-devicetree"
echo "=== BoardConfig 内核/分区相关 ==="
grep -nE "TARGET_KERNEL|KERNEL_|BOARD_BOOTIMAGE|BOARD_DTB|LZ4|GZIP|AVB|SELINUX" "$D/BoardConfig.mk" | head -30
echo
echo "=== aosp.dependencies ==="
cat "$D/aosp.dependencies" 2>/dev/null | head -30
echo
echo "=== README ==="
head -20 "$D/README.md" 2>/dev/null
