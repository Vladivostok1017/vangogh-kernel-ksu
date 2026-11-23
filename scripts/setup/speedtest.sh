#!/usr/bin/env bash
# Measure download speed of candidate sources for the kernel tree
test_url() {
  local name="$1" url="$2"
  local r
  r=$(curl -sL -o /dev/null --max-time 20 -w '%{http_code} %{speed_download} %{size_download}' "$url" 2>/dev/null)
  set -- $r
  local code="$1" spd="$2" size="$3"
  local mbps
  mbps=$(awk -v s="${spd:-0}" 'BEGIN{printf "%.2f", s/1048576}')
  printf '%-28s http=%s  %8s MB/s  (%s bytes in ~20s)\n' "$name" "$code" "$mbps" "${size:-0}"
}

echo "== PE twelve =="
test_url "ghproxy PE"   "https://ghproxy.net/https://github.com/PixelExperience-Devices/kernel_xiaomi_sm7250/archive/refs/heads/twelve.tar.gz"
test_url "codeload PE"  "https://codeload.github.com/PixelExperience-Devices/kernel_xiaomi_sm7250/tar.gz/refs/heads/twelve"

echo "== MiCode vangogh-q-oss =="
test_url "ghproxy MiCode"  "https://ghproxy.net/https://github.com/MiCode/Xiaomi_Kernel_OpenSource/archive/refs/heads/vangogh-q-oss.tar.gz"
test_url "codeload MiCode" "https://codeload.github.com/MiCode/Xiaomi_Kernel_OpenSource/tar.gz/refs/heads/vangogh-q-oss"
