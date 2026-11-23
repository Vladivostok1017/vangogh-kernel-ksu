#!/usr/bin/env bash
KSK="$HOME/vanilla/ksu/sukisu-builtin/kernel"
echo "=== Kconfig 中与 hook 方式相关的选项 ==="
grep -nE "^config KSU_[A-Z_]*(HOOK|BRANCH|TAMPER|PROBES|KSUD|MANUAL)[A-Z_]*" "$KSK/Kconfig" | head -20
echo
echo "=== 各选项默认值 ==="
grep -nE "^(config|	default )" "$KSK/Kconfig" | grep -A1 -E "config KSU_(HACK|TAMPER|KPROBES|MANUAL)" | head -20
echo
echo "=== 源码里是否已有 hook 入口定义（ksu_handle_*） ==="
grep -rn "int ksu_handle_execveat\|ksu_handle_faccessat\|ksu_handle_stat" "$KSK" --include=*.h --include=*.c | head -10
echo
echo "=== CONFIG_KSU 的依赖声明 ==="
grep -n "config KSU$" -A12 "$KSK/Kconfig" | head -20
