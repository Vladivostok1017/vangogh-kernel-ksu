#!/usr/bin/env bash
P="http://127.0.0.1:17890"
export https_proxy="$P" http_proxy="$P"
echo "=== [1] 拉取固件备份 ==="
adb pull /sdcard/bk-firmware /mnt/f/vanilla-build/backup/ 2>&1 | tail -1
ls -lh /mnt/f/vanilla-build/backup/bk-firmware/ 2>/dev/null | head -22

echo
echo "=== [2] 下载指定提交的内核源码（6b5f9dd7a）==="
mkdir -p "$HOME/vanilla/dl" && cd "$HOME/vanilla/dl"
if [ ! -f pe-kernel-6b5f9dd7a.tar.gz ]; then
  curl -L --retry 3 -o pe-kernel-6b5f9dd7a.tar.gz \
    "https://codeload.github.com/PixelExperience-Devices/kernel_xiaomi_vangogh/tar.gz/6b5f9dd7a"
fi
ls -lh pe-kernel-6b5f9dd7a.tar.gz
rm -rf "$HOME/vanilla/src/pe13-kernel-6b5f"
mkdir -p "$HOME/vanilla/src/pe13-kernel-6b5f"
tar -xzf pe-kernel-6b5f9dd7a.tar.gz -C "$HOME/vanilla/src/pe13-kernel-6b5f" --strip-components=1 2>/dev/null && \
  echo "解压完成" && head -4 "$HOME/vanilla/src/pe13-kernel-6b5f/Makefile"

echo
echo "=== [3] 提取 PE13 vendor 模块 ==="
sudo DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::http::Proxy="$P" install -y -qq brotli >/dev/null 2>&1
echo "brotli: $(command -v brotli || echo MISSING)"
