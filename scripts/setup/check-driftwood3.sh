#!/usr/bin/env bash
K="$HOME/vanilla/src/driftwood"
echo "=== build.sh 内容 ==="
if [ -f "$K/build.sh" ]; then cat "$K/build.sh"; else echo "(build.sh 不在根目录)"; find "$K" -maxdepth 2 -name "build.sh" 2>/dev/null; fi
echo
echo "=== drivers/kernelsu 内容（是否为空目录/子模块）==="
ls -la "$K/drivers/kernelsu" 2>&1 | head -12
echo
echo "=== .gitmodules ==="
cat "$K/.gitmodules" 2>/dev/null || echo "(无 .gitmodules)"
echo
echo "=== configs 目录里 MIHW/KSU/MILLET 出现情况 ==="
grep -rn "MIHW\|CONFIG_KSU\|MILLET" "$K/arch/arm64/configs/" 2>/dev/null | head -10
echo
echo "=== vangogh_user_defconfig 行数 & 前 5 行 ==="
wc -l "$K/arch/arm64/configs/vendor/vangogh_user_defconfig"
head -5 "$K/arch/arm64/configs/vendor/vangogh_user_defconfig"
