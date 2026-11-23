#!/usr/bin/env bash
K="$HOME/vanilla/src/driftwood"
H="$K/drivers/soc/qcom/msm_bus/msm_bus_core.h"
C="$K/drivers/soc/qcom/msm_bus/msm_bus_dbg_rpmh.c"

echo "=== 头文件里这些函数的条件（搜索定义位置）==="
grep -n "msm_bus_dbg_add_client\|msm_bus_dbg_rec_transaction\|msm_bus_dbg_remove_client" "$H" | head -10
echo
echo "--- 头文件中桩函数所在的条件块（取附近 40 行）---"
START=$(grep -n "msm_bus_dbg_remove_client" "$H" | head -1 | cut -d: -f1)
[ -n "$START" ] && sed -n "$((START-25)),$((START+45))p" "$H"

echo
echo "=== .c 文件里的条件 ==="
grep -n "^#if\|^#ifdef\|^#ifndef\|^#else\|^#endif\|^static.*msm_bus_dbg_add_client" "$C" | head -25
