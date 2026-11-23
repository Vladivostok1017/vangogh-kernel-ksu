#!/system/bin/sh
D=/sdcard/ko
mkdir -p "$D"
cp -f /vendor/lib/modules/qca_cld3_wlan.ko "$D/" && echo "copied qca_cld3_wlan.ko"
cp -f /vendor/lib/modules/lcd.ko "$D/" && echo "copied lcd.ko"
echo "=== 模块清单 ==="
ls -l "$D"
echo
echo "=== 各模块 vermagic ==="
for f in "$D"/*.ko; do
  echo "--- $f"
  strings "$f" | grep -m1 "SMP preempt"
done
