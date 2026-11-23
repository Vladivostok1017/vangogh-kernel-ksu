#!/usr/bin/env bash
K="$HOME/vanilla/src/driftwood"
echo "=== 错误1: kernel/sched/tune.c:850 ==="
grep -n "boost_write_wrapper\|prefer_idle_write_wrapper" "$K/kernel/sched/tune.c" | head -10
echo "--- 这些 wrapper 定义处的条件 ---"
grep -n -B8 "static.*boost_write_wrapper" "$K/kernel/sched/tune.c" | head -20

echo
echo "=== 错误2: qpnp-smb5.c use_bq_pump ==="
grep -n "use_bq_pump\|use_smb_pump" "$K/drivers/power/supply/qcom/qpnp-smb5.c" "$K/drivers/power/supply/qcom/smb5-lib.h" 2>/dev/null | head -10
echo "--- 相关条件编译 ---"
grep -n -B4 "use_bq_pump" "$K/drivers/power/supply/qcom/qpnp-smb5.c" | head -16

echo
echo "=== 这两个特性对应的配置项 ==="
grep -nE "CONFIG_SCHED_TUNE|CONFIG_CPU_BOOST|CONFIG_BQ_PUMP|CONFIG_SMB5" "$HOME/vanilla/out-drift/.config" | head -10
