#!/usr/bin/env bash
# Download AOSP clang 10.0.6 (r365631c) + aarch64 gcc 4.9 via local proxy
P="http://127.0.0.1:17890"
export http_proxy="$P" https_proxy="$P"
set -e
mkdir -p ~/vanilla/tc
cd ~/vanilla/tc

echo "== clang r365631c (10.0.6) =="
if [ ! -x clang-r365631c/bin/clang ]; then
  for br in master main; do
    echo "  trying branch $br ..."
    if curl -fL --retry 3 -o clang.tar.gz \
      "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/$br/clang-r365631c.tar.gz"; then
      break
    fi
  done
  ls -lh clang.tar.gz
  mkdir -p clang-r365631c
  tar -xzf clang.tar.gz -C clang-r365631c
fi

echo "== aarch64 gcc 4.9 =="
if [ ! -x gcc49/bin/aarch64-linux-android-gcc ]; then
  for br in master main; do
    echo "  trying branch $br ..."
    if curl -fL --retry 3 -o gcc49.tar.gz \
      "https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/refs/heads/$br.tar.gz"; then
      break
    fi
  done
  ls -lh gcc49.tar.gz
  mkdir -p gcc49
  tar -xzf gcc49.tar.gz -C gcc49
fi

echo "== verify =="
clang-r365631c/bin/clang --version | head -2
gcc49/bin/aarch64-linux-android-gcc --version | head -1
du -sh ~/vanilla/tc
echo TOOLCHAIN_OK
