#!/usr/bin/env bash
C1="$HOME/work/out-c/arch/arm64/boot/Image"
C3="$HOME/work/out-c3/arch/arm64/boot/Image"
echo "=== 大小对比 ==="
ls -l "$C1" "$C3"
echo "=== 是否同一文件 ==="
sha256sum "$C1" "$C3"
echo
echo "=== c3 里的 KSU 符号 ==="
strings -n 5 "$C3" | grep -icE "ksu_|kernelsu"
strings -n 5 "$C3" | grep -iE "kernelsu|ksu_handle" | head -5
echo
echo "=== c3 编译日志里有没有 kernelsu 目标 ==="
grep -c "kernelsu" "$HOME/work/build-c3.log"
grep -m5 "kernelsu" "$HOME/work/build-c3.log"
echo
echo "=== 源码里 kernelsu 接线是否还在 ==="
ls -l "$HOME/work/driftwood/drivers/kernelsu" 2>&1 | head -2
grep -c kernelsu "$HOME/work/driftwood/drivers/Makefile" "$HOME/work/driftwood/drivers/Kconfig"
