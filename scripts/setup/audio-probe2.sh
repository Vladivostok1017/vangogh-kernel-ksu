#!/usr/bin/env bash
K="$HOME/work/driftwood"
echo "=== 主 Kconfig 链里是否 source 了 techpack ==="
grep -rn "techpack" "$K/Kconfig" "$K/drivers/Kconfig" 2>/dev/null | head -10
echo "--- techpack/Makefile ---"
cat "$K/techpack/Makefile" 2>/dev/null | head -20
echo
echo "=== techpack/audio/Kconfig 顶层项与依赖 ==="
grep -nE "^config |^	depends on|^	bool|^	tristate|^	default" "$K/techpack/audio/Kconfig" | head -60
