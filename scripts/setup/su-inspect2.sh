#!/usr/bin/env bash
F="$HOME/work/driftwood/SukiSU/kernel/infra/file_wrapper.c"
echo "=== 所有 .iopoll / .remap_file_range 赋值 ==="
grep -n "\.iopoll\|\.remap_file_range\|ksu_wrapper_iopoll\|ksu_wrapper_remap_file_range\|REMAP_FILE_DEDUP" "$F"
echo
echo "=== iopoll 函数上方的守卫（85-100）==="
sed -n '85,100p' "$F"
echo
echo "=== fops 结构附近（找 static const struct file_operations）==="
grep -n "file_operations" "$F" | head -5
