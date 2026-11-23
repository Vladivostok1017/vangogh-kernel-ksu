#!/usr/bin/env bash
D="$HOME/vanilla/dl/pe13"
Z="$D/PixelExperience_vangogh-13.0-20231028-2241-OFFICIAL.zip"
W="$HOME/vanilla/pe13-work"

echo "=== 包内全部条目（前 40）==="
unzip -l "$Z" | head -40

echo
echo "=== 内核版本串（修正路径）==="
strings -n 10 "$W/boot_unpacked/kernel.bin" 2>/dev/null | grep -m3 "^Linux version 4.19"
echo "=== vermagic ==="
strings -n 8 "$W/boot_unpacked/kernel.bin" 2>/dev/null | grep -m2 "SMP preempt"

echo
echo "=== dynamic_partitions_op_list ==="
cd "$W" && unzip -o -j "$Z" dynamic_partitions_op_list -d "$W" >/dev/null 2>&1 && cat dynamic_partitions_op_list | head -20
