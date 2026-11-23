#!/usr/bin/env bash
P="http://127.0.0.1:17890"
export http_proxy="$P" https_proxy="$P"
set -e
mkdir -p ~/vanilla/dl/pe13
cd ~/vanilla/dl/pe13
URL="https://dl.pixelexperience.org/fzE80xlRmATVLyMWzMn4xRiIZn1tdCeYij48BufHZAHqhoITzdkGTtZLE6TwrJVagdCrEz6I0rgI4qxDc1Hrc6t6CmQnCW5S2gDsYhW1mXM=/PixelExperience_vangogh-13.0-20231028-2241-OFFICIAL.zip"
FN=PixelExperience_vangogh-13.0-20231028-2241-OFFICIAL.zip
if [ ! -f "$FN" ]; then
  curl -L --retry 3 --retry-delay 3 -C - -o "$FN" "$URL"
fi
ls -lh "$FN"
echo "=== 内容 ==="
unzip -l "$FN" | head -25
