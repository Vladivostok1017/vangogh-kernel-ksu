#!/system/bin/sh
# 以 root 运行：把 vendor 内核模块复制到 /sdcard 便于拉取
D=/sdcard/ko
mkdir -p "$D"
echo "=== /vendor/lib/modules 内容 ==="
ls /vendor/lib/modules/

for m in wlan.ko audio_machine_lito.ko audio_apr.ko exfat.ko rmnet_perf.ko; do
  if [ -f "/vendor/lib/modules/$m" ]; then
    cp -f "/vendor/lib/modules/$m" "$D/$m" && echo "copied $m"
  fi
done

echo "=== 复制结果 ==="
ls -l "$D"
