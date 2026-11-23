#!/usr/bin/env bash
K=~/vanilla/src/driftwood
echo "=== vangogh_user_defconfig 里的 MIUI/KSU 关键项 ==="
grep -nE "MIHW|MILLET|MIGT|SF_BINDER|PERF_CRITICAL|MI_MEMORY|KSU|KPROBES|MODVERSIONS|LOCALVERSION" \
  "$K/arch/arm64/configs/vendor/vangogh_user_defconfig" 2>/dev/null | head -25

echo
echo "=== MIHW 驱动规模（说明它确实带实现）==="
ls "$K/drivers/mihw" 2>/dev/null | head -10
echo "文件数: $(find "$K/drivers/mihw" -type f | wc -l)"
du -sh "$K/drivers/mihw" 2>/dev/null

echo
echo "=== KernelSU 版本/形态 ==="
ls "$K/drivers/kernelsu" | head
grep -m3 -rn "KSU_VERSION\|KSU_GIT_VERSION" "$K/drivers/kernelsu/"*.c "$K/drivers/kernelsu/"*.h 2>/dev/null | head -5

echo
echo "=== drivers/Makefile 是否已接线 kernelsu ==="
grep -n "kernelsu" "$K/drivers/Makefile" "$K/drivers/Kconfig" 2>/dev/null

echo
echo "=== 构建方式线索（workflow / 脚本）==="
find "$K/.github" -name "*.yml" 2>/dev/null | head -5
ls "$K"/*.sh 2>/dev/null | head -5
