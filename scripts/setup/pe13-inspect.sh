#!/usr/bin/env bash
set -o pipefail
D="$HOME/vanilla/dl/pe13"
Z="$D/PixelExperience_vangogh-13.0-20231028-2241-OFFICIAL.zip"
W="$HOME/vanilla/pe13-work"
mkdir -p "$W"

echo "=== 包内关键文件 ==="
unzip -l "$Z" | grep -E "boot\.img|vendor\.img|system\.img|product\.img|dynamic|payload|dtbo" | head -15

echo
echo "=== 解出 boot.img ==="
cd "$W" || exit 1
unzip -o -j "$Z" "*/boot.img" -d "$W" >/dev/null 2>&1 || unzip -o -j "$Z" "boot.img" -d "$W" >/dev/null 2>&1
ls -lh "$W"/boot.img 2>/dev/null || echo "boot.img 未找到"

if [ -f "$W/boot.img" ]; then
  echo
  echo "=== PE13 boot.img 头部信息 ==="
  python3 /mnt/f/vanilla-build/setup/parse_boot.py "$W/boot.img" "$W/boot_unpacked" 2>&1 | head -20
  echo
  echo "=== 其内核版本串（含 git 哈希）==="
  strings -n 10 "$W/boot_unpacked/kernel" 2>/dev/null | grep -m2 "^Linux version 4.19"
  echo "=== vermagic ==="
  strings -n 8 "$W/boot_unpacked/kernel" 2>/dev/null | grep -m1 "SMP preempt"
fi
