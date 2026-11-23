#!/usr/bin/env bash
export https_proxy=http://127.0.0.1:17890 http_proxy=http://127.0.0.1:17890
echo "=== PE vangogh 页面中的下载链接 ==="
curl -sL --max-time 30 "https://get.pixelexperience.org/vangogh" \
  | grep -oE 'https?://[^"[:space:]]+' | grep -iE 'download|\.zip|sourceforge' | head -10
echo
echo "=== PE 官方 API（若有） ==="
for u in "https://api.pixelexperience.org/devices/vangogh" "https://get.pixelexperience.org/api/vangogh"; do
  printf '%-52s ' "$u"
  code=$(curl -s -o /tmp/pe_api.json -w '%{http_code}' --max-time 25 "$u")
  echo "http=$code"
  [ "$code" = "200" ] && head -c 300 /tmp/pe_api.json && echo
done
