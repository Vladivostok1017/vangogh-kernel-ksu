#!/usr/bin/env bash
set -o pipefail
K="$HOME/work/driftwood"
echo "=== 上次失败原因 ==="
grep -iE "can't open file|error|No such" /tmp/cfg.log | head -5
echo
echo "=== kernelsu 相关接线 ==="
ls -l "$K/drivers/kernelsu" 2>&1 | head -2
grep -n "kernelsu" "$K/drivers/Makefile" "$K/drivers/Kconfig" 2>/dev/null

echo
echo "=== 临时摘除 KSU 接线（验证 wifi 阶段不需要它）==="
sed -i '/kernelsu/d' "$K/drivers/Makefile" 2>/dev/null
sed -i '/drivers\/kernelsu\/Kconfig/d' "$K/drivers/Kconfig" 2>/dev/null
echo "Makefile: $(grep -c kernelsu "$K/drivers/Makefile" 2>/dev/null) 处 / Kconfig: $(grep -c kernelsu "$K/drivers/Kconfig" 2>/dev/null) 处"

echo
echo "=== 重新生成配置 ==="
export PATH="$HOME/bin:$PATH"
cd "$K" || exit 1
OUT="$HOME/work/out-drift2"
rm -rf "$OUT"; mkdir -p "$OUT"
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 )
make -j8 "${MAKE[@]}" vendor/vangogh_user_defconfig > /tmp/cfg.log 2>&1 && echo "defconfig OK" || { echo "仍失败:"; tail -5 /tmp/cfg.log; exit 1; }
make -j8 "${MAKE[@]}" olddefconfig >> /tmp/cfg.log 2>&1

echo
echo "=== wifi / 音频 关键项 ==="
grep -iE "QCA_CLD|WLAN|WCNSS|SND_SOC_WCD|BOLERO|MACHINE_LITO|EXFAT|RMNET_PERF" "$OUT/.config" | head -20
echo "--- 其中 =m 的 ---"
grep -iE "QCA_CLD|WLAN|SND_SOC|EXFAT|RMNET" "$OUT/.config" | grep "=m$" | head -10
echo
echo "=== =m 总数 ==="
grep -c "=m$" "$OUT/.config"
