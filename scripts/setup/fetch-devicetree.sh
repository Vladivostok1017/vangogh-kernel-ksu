#!/usr/bin/env bash
P="http://127.0.0.1:17890"
export http_proxy="$P" https_proxy="$P"
set -e
mkdir -p ~/vanilla/dl ~/vanilla/src
cd ~/vanilla/dl
echo "== PE vangogh device tree @ thirteen =="
curl -L --retry 3 -o pe-vangogh-dt.tar.gz \
  https://codeload.github.com/PixelExperience-Devices/device_xiaomi_vangogh/tar.gz/refs/heads/thirteen
ls -lh pe-vangogh-dt.tar.gz
rm -rf ~/vanilla/src/pe13-devicetree
mkdir -p ~/vanilla/src/pe13-devicetree
tar -xzf pe-vangogh-dt.tar.gz -C ~/vanilla/src/pe13-devicetree --strip-components=1
D=~/vanilla/src/pe13-devicetree
echo "== 内容 =="
ls "$D" | head -25
echo "== roomservice / 内核引用 =="
grep -rn "kernel" "$D/roomservice.xml" 2>/dev/null | head -10 || echo "(no roomservice)"
ls "$D"/*.mk 2>/dev/null
echo "== 是否预编译内核 =="
grep -rniE "TARGET_KERNEL_SOURCE|kernel/prebuilt|LOCAL_KERNEL" "$D" 2>/dev/null | head -10
