#!/usr/bin/env bash
IMG="$HOME/vanilla/out-drift/arch/arm64/boot/Image"
OUTIMG=/mnt/f/vanilla-build/out/boot-driftwood-ksu.img

echo "=== 内核版本 ==="
strings -n 10 "$IMG" | grep -m3 "^Linux version 4.19"
echo
echo "=== vermagic ==="
strings -n 8 "$IMG" | grep -m2 "SMP preempt mod_unload"
echo
echo "=== KSU 是否真编进去了 ==="
strings -n 6 "$IMG" | grep -iE "kernelsu|ksu_" | head -8
echo
echo "=== MIUI 私有驱动是否编进去 ==="
for s in migt millet mihw; do
  printf '%-10s ' "$s"; strings -n 6 "$IMG" | grep -ci "$s"
done
echo
echo "=== 打包 boot.img ==="
python3 /mnt/f/vanilla-build/setup/pack_boot.py \
  --src "/mnt/c/Users/Administrator/Downloads/boot.img" \
  --kernel "$IMG" --out "$OUTIMG" --pad 134217728
ls -l "$OUTIMG"
