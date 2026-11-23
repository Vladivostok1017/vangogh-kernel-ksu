#!/usr/bin/env bash
K="$HOME/vanilla/src/driftwood"
echo "=== 源码里是否已有 KSU hook 调用（手动集成）==="
for f in fs/exec.c fs/open.c fs/stat.c fs/read_write.c kernel/reboot.c drivers/input/input.c; do
  n=$(grep -c "ksu_handle_" "$K/$f" 2>/dev/null || echo 0)
  printf '%-28s ksu_handle_ 出现 %s 次\n' "$f" "$n"
done
echo
echo "=== 抽样看 exec.c 的 hook ==="
grep -n -A3 "ksu_handle_execveat" "$K/fs/exec.c" 2>/dev/null | head -12
echo
echo "=== Kconfig 里 KSU 依赖 ==="
ls "$K/drivers/kernelsu/" 2>/dev/null | head -3
grep -n "config KSU" -A6 "$K/KernelSU/kernel/Kconfig" 2>/dev/null | head -10 || echo "(KernelSU 子模块尚未初始化)"
echo
echo "=== 该树相对 PE 树多出来的 MIUI 驱动目录 ==="
ls -d "$K/drivers/mihw" 2>/dev/null && echo "  mihw ✓"
grep -rn "MILLET\|millet" "$K/init/Kconfig" 2>/dev/null | head -5
