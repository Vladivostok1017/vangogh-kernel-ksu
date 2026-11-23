#!/usr/bin/env bash
P="http://127.0.0.1:17890"
export https_proxy="$P" http_proxy="$P"
echo "=== 现有工具 ==="
for t in simg2img debugfs unzip python3; do
  printf '%-10s ' "$t"; command -v "$t" || echo MISSING
done
echo
echo "=== 安装 android-sdk-libsparse-utils / e2fsprogs ==="
sudo DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::http::Proxy="$P" -o Acquire::https::Proxy="$P" \
     install -y -qq android-sdk-libsparse-utils e2fsprogs 2>&1 | tail -5
echo "simg2img: $(command -v simg2img || echo MISSING)"
echo "debugfs : $(command -v debugfs || echo MISSING)"
echo
echo "=== PE 树内核构建产物 ==="
ls -l "$HOME/vanilla/out-vanilla/Module.symvers" "$HOME/vanilla/out-vanilla/arch/arm64/boot/Image" 2>/dev/null || echo "(缺失)"
echo
echo "=== PE13 下载进度 ==="
ls -lh "$HOME/vanilla/dl/pe13/" 2>/dev/null
