#!/usr/bin/env bash
S="$HOME/work/driftwood/SukiSU/kernel"
echo "=== Kconfig 里的禁用开关 ==="
grep -nE "^config KSU_[A-Z_]*(DISABLE|POLICY|MANAGER|SECCOMP|SULOG|KPM)[A-Z_]*" "$S/Kconfig" | head -20
echo
echo "=== sepolicy.c / seccomp / pkg_observer 是否被 CONFIG 门控 ==="
grep -rn "sepolicy\|seccomp_cache\|pkg_observer\|su_mount_ns" "$S/Makefile" "$S/Kbuild" 2>/dev/null | head -10
echo "--- 子目录 Makefile ---"
find "$S" -name "Makefile" -o -name "Kbuild" | head -8
echo
echo "=== 各文件对应的 obj- 行 ==="
grep -rn "obj-" "$S/Makefile" 2>/dev/null | head -25
