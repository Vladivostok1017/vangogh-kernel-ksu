#!/usr/bin/env bash
K="$HOME/vanilla/src/driftwood"
echo "=== drivers/mihw/Kconfig 里的选项 ==="
grep -nE "^config|^	depends|^	bool|^	tristate|^	default" "$K/drivers/mihw/Kconfig" | head -40

echo
echo "=== drivers/mihw/Makefile ==="
cat "$K/drivers/mihw/Makefile"

echo
echo "=== 谁定义 migt_hook / get_cur_render_uid / mi_uid_type ==="
grep -rn "migt_hook\|get_cur_render_uid\|mi_uid_type" "$K/drivers/mihw/" 2>/dev/null | head -10
echo "--- 引用方 ---"
grep -rn "migt_hook\|get_cur_render_uid" "$K/kernel/sched/migt_sched.c" | head -5

echo
echo "=== 当前配置里的 MIHW/MIGT/MILLET ==="
grep -E "^CONFIG_(MIHW|MIGT|MILLET|MIHW_)" "$HOME/vanilla/out-drift/.config" | head -10
