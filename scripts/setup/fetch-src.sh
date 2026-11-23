#!/usr/bin/env bash
# Download kernel source trees as tarballs through the local proxy
P="http://127.0.0.1:17890"
export http_proxy="$P" https_proxy="$P"
set -e
mkdir -p ~/vanilla/dl ~/vanilla/src
cd ~/vanilla/dl

echo "== [1/2] PixelExperience kernel_xiaomi_sm7250 @ twelve =="
curl -L --retry 3 --retry-delay 2 -o pe-twelve.tar.gz \
  https://codeload.github.com/PixelExperience-Devices/kernel_xiaomi_sm7250/tar.gz/refs/heads/twelve
ls -lh pe-twelve.tar.gz

echo "== [2/2] MiCode Xiaomi_Kernel_OpenSource @ vangogh-q-oss =="
curl -L --retry 3 --retry-delay 2 -o micode-vangogh-q.tar.gz \
  https://codeload.github.com/MiCode/Xiaomi_Kernel_OpenSource/tar.gz/refs/heads/vangogh-q-oss
ls -lh micode-vangogh-q.tar.gz

echo "== extract =="
rm -rf ~/vanilla/src/pe ~/vanilla/src/micode
mkdir -p ~/vanilla/src/pe ~/vanilla/src/micode
tar -xzf pe-twelve.tar.gz -C ~/vanilla/src/pe --strip-components=1
tar -xzf micode-vangogh-q.tar.gz -C ~/vanilla/src/micode --strip-components=1
echo "== sizes =="
du -sh ~/vanilla/src/pe ~/vanilla/src/micode
echo "== makefile versions =="
head -5 ~/vanilla/src/pe/Makefile
head -5 ~/vanilla/src/micode/Makefile
echo "== defconfigs =="
ls ~/vanilla/src/pe/arch/arm64/configs/vendor/ 2>/dev/null | grep -iE 'lito|vangogh' || ls ~/vanilla/src/pe/arch/arm64/configs | grep -iE 'lito|vangogh'
echo "--- micode ---"
ls ~/vanilla/src/micode/arch/arm64/configs/vendor/ 2>/dev/null | grep -iE 'lito|vangogh' || ls ~/vanilla/src/micode/arch/arm64/configs | grep -iE 'lito|vangogh'
echo "DONE"
