#!/usr/bin/env bash
P="http://127.0.0.1:17890"
export http_proxy="$P" https_proxy="$P"
set -e
mkdir -p ~/vanilla/dl ~/vanilla/src
cd ~/vanilla/dl
echo "== PE vangogh kernel @ thirteen =="
curl -L --retry 3 -o pe-vangogh-thirteen.tar.gz \
  https://codeload.github.com/PixelExperience-Devices/kernel_xiaomi_vangogh/tar.gz/refs/heads/thirteen
ls -lh pe-vangogh-thirteen.tar.gz
rm -rf ~/vanilla/src/pe13-kernel
mkdir -p ~/vanilla/src/pe13-kernel
tar -xzf pe-vangogh-thirteen.tar.gz -C ~/vanilla/src/pe13-kernel --strip-components=1
K=~/vanilla/src/pe13-kernel
echo "== version =="
head -5 "$K/Makefile"
echo "== defconfigs =="
ls "$K/arch/arm64/configs/vendor/" 2>/dev/null | head -20
echo "== vangogh dts =="
find "$K/arch/arm64/boot/dts" -iname '*vangogh*' 2>/dev/null | head
echo "== existing KSU? =="
ls -d "$K/drivers/kernelsu" 2>/dev/null || echo "no drivers/kernelsu"
echo "== LOCALVERSION =="
grep -m2 LOCALVERSION "$K/arch/arm64/configs/vendor/"*vangogh* 2>/dev/null || true
echo "DONE"
