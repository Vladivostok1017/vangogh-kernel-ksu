#!/system/bin/sh
# 备份 PE13 安装脚本会覆盖的全部固件/引导分区（不可恢复）
D=/sdcard/bk-firmware
mkdir -p "$D"
echo "output: $D"

for p in abl xbl xbl_config aop tz hyp devcfg keymaster qupfw storsec uefisecapp \
         imagefv featenabler bluetooth dsp modem logo sbl1 vbmeta_system; do
  if [ -e "/dev/block/by-name/$p" ]; then
    dd if=/dev/block/by-name/$p of="$D/$p.img" bs=1048576 2>&1 | tail -1
  else
    echo "  (无 $p 分区，跳过)"
  fi
done

echo
echo "=== 清单 ==="
ls -l "$D"
