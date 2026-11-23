#!/usr/bin/env bash
P="http://127.0.0.1:17890"
echo "== direct (no proxy) =="
curl -sL -o /dev/null --max-time 15 -w 'codeload direct: http=%{http_code} speed=%{speed_download} B/s\n' \
  https://codeload.github.com/PixelExperience-Devices/kernel_xiaomi_sm7250/tar.gz/refs/heads/twelve
echo "== via clash proxy 127.0.0.1:17890 =="
curl -sL -x "$P" -o /dev/null --max-time 15 -w 'codeload proxy : http=%{http_code} speed=%{speed_download} B/s\n' \
  https://codeload.github.com/PixelExperience-Devices/kernel_xiaomi_sm7250/tar.gz/refs/heads/twelve
curl -sL -x "$P" -o /dev/null --max-time 15 -w 'github.com    : http=%{http_code} speed=%{speed_download} B/s\n' \
  https://github.com/
curl -sL -x "$P" -o /dev/null --max-time 15 -w 'googlesource  : http=%{http_code} speed=%{speed_download} B/s\n' \
  https://android.googlesource.com/
curl -sL -x "$P" -o /dev/null --max-time 15 -w 'raw.githubuser: http=%{http_code} speed=%{speed_download} B/s\n' \
  https://raw.githubusercontent.com/tiann/KernelSU/main/README.md
