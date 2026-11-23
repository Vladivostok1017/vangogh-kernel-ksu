#!/usr/bin/env bash
K="$HOME/vanilla/src/pe13-kernel"
echo "=== 树内 rtic 相关 ==="
grep -rn "rtic\|RTIC" "$K/arch/arm64/kernel/vmlinux.lds.S" 2>/dev/null | head -20
echo "--- 全树搜索（限 makefile/lds/Kconfig/c 头文件）---"
grep -rln "rtic" "$K/include" "$K/arch/arm64" "$K/security" 2>/dev/null | head -15
echo
echo "=== 配置里是否有 RTIC ==="
grep -niE "rtic" "$HOME/vanilla/out-vanilla/.config" | head -10
echo
echo "=== lds 中 .bss 附近 ==="
grep -n -A6 "\.bss" "$K/arch/arm64/kernel/vmlinux.lds.S" | head -40
