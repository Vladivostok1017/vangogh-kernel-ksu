#!/usr/bin/env bash
# Extract /lib/modules/*.ko from PE13's vendor.new.dat.br for CRC verification
set -o pipefail
P="http://127.0.0.1:17890"
export https_proxy="$P" http_proxy="$P"
D="$HOME/vanilla/dl/pe13"
Z="$D/PixelExperience_vangogh-13.0-20231028-2241-OFFICIAL.zip"
W="$HOME/vanilla/pe13-vendor"
mkdir -p "$W"
cd "$W" || exit 1

echo "=== [1] 取出 vendor 数据 ==="
unzip -o -j "$Z" "vendor.new.dat.br" "vendor.transfer.list" -d "$W" >/dev/null 2>&1
ls -lh vendor.new.dat.br vendor.transfer.list

echo "=== [2] brotli 解压 ==="
[ -f vendor.new.dat ] || brotli -d -o vendor.new.dat vendor.new.dat.br
ls -lh vendor.new.dat

echo "=== [3] 取 sdat2img ==="
[ -f sdat2img.py ] || curl -fsSL -o sdat2img.py "https://raw.githubusercontent.com/xpirt/sdat2img/master/sdat2img.py"
head -3 sdat2img.py

echo "=== [4] new.dat -> vendor.img ==="
[ -f vendor.img ] || python3 sdat2img.py vendor.transfer.list vendor.new.dat vendor.img
ls -lh vendor.img

echo "=== [5] 用 debugfs 列出 /lib/modules ==="
debugfs -R "ls -l /lib/modules" vendor.img 2>/dev/null | head -30
