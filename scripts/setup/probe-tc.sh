#!/usr/bin/env bash
export https_proxy=http://127.0.0.1:17890 http_proxy=http://127.0.0.1:17890
B="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads"
for ref in main-kernel master; do
  for ver in clang-r450784d clang-r416183b clang-r365631c; do
    code=$(curl -sI --max-time 20 -o /dev/null -w '%{http_code}' "$B/$ref/$ver.tar.gz")
    printf '%-12s %-18s %s\n' "$ref" "$ver" "$code"
  done
done
echo "--- gcc 4.9 ---"
G="https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/refs/heads"
for ref in main-kernel master; do
  code=$(curl -sI --max-time 20 -o /dev/null -w '%{http_code}' "$G/$ref.tar.gz")
  printf '%-12s %s\n' "$ref" "$code"
done
