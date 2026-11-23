#!/usr/bin/env bash
PE=~/vanilla/src/pe
MC=~/vanilla/src/micode

echo "########## PE twelve (Android 12, 4.19.241) ##########"
echo "--- top-level build scripts ---"
ls "$PE" | grep -iE 'build|makefile|readme|\.sh$' | head -20
echo "--- .github workflows ---"
find "$PE/.github" -name '*.yml' -o -name '*.yaml' 2>/dev/null | head
echo "--- any vangogh in configs/dts ---"
ls "$PE/arch/arm64/configs/vendor/" | head -30
echo "--- existing kernelsu? ---"
ls -d "$PE/drivers/kernelsu" 2>/dev/null || echo "no drivers/kernelsu"
grep -rl "KSU" "$PE/arch/arm64/configs/vendor/" 2>/dev/null | head
echo "--- KPROBE/OVERLAY in lito defconfig ---"
for c in KPROBES MODULES OVERLAY_FS NAMESPACES SECURITY_SELINUX; do
  printf '  %-18s ' "$c"; grep -m1 "CONFIG_$c=" "$PE/arch/arm64/configs/vendor/lito_defconfig" 2>/dev/null || echo "(not set)"
done

echo
echo "########## MiCode vangogh-q-oss (Android 10, 4.19.81) ##########"
echo "--- vangogh_user_defconfig key options ---"
D="$MC/arch/arm64/configs/vendor/vangogh_user_defconfig"
ls -lh "$D"
for c in LOCALVERSION KPROBES MODULES OVERLAY_FS NAMESPACES SECURITY_SELINUX KSU; do
  printf '  %-18s ' "$c"; grep -m2 "CONFIG_$c" "$D" 2>/dev/null | tr '\n' ' '; echo
done
echo "--- build scripts ---"
ls "$MC" | grep -iE 'build|Makefile|README|\.sh$' | head -20
echo "--- existing kernelsu? ---"
ls -d "$MC/drivers/kernelsu" 2>/dev/null || echo "no drivers/kernelsu"
echo
echo "########## device tree check (vangogh dts present?) ##########"
for t in "$PE" "$MC"; do
  printf '%s -> ' "$t"
  find "$t/arch/arm64/boot/dts" -iname '*vangogh*' 2>/dev/null | wc -l
done
