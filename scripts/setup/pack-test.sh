#!/usr/bin/env bash
OUT="$HOME/vanilla/out-vanilla"
IMG="$OUT/arch/arm64/boot/Image"
echo "=== Image 基本信息 ==="
ls -l "$IMG"
printf "magic: "; xxd -l 8 "$IMG" | head -1
echo "=== 内核版本字符串 ==="
strings -n 10 "$IMG" | grep -m3 "^Linux version 4.19"
echo "=== 配置确认 ==="
grep -E "^CONFIG_(LOCALVERSION|PANIC_ON_REFCOUNT_ERROR|LD_IS_LLD|CC_IS_CLANG)=" "$OUT/.config" || true

echo
echo "=== 打包 boot.img（复用原厂 header + 我们的 kernel）==="
python3 /mnt/f/vanilla-build/setup/pack_boot.py \
  --src "/mnt/c/Users/Administrator/Downloads/boot.img" \
  --kernel "$IMG" \
  --out /tmp/boot-vanilla-test.img --pad 134217728
ls -l /tmp/boot-vanilla-test.img
sha256sum /tmp/boot-vanilla-test.img
