#!/usr/bin/env bash
# Install remaining build deps through the local proxy (no apt source changes)
P="http://127.0.0.1:17890"
set -x
sudo apt-get -o Acquire::http::Proxy="$P" -o Acquire::https::Proxy="$P" update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::http::Proxy="$P" -o Acquire::https::Proxy="$P" \
     install -y -qq unzip zstd lz4 libssl-dev libelf-dev kmod bc bison flex cpio rsync
echo "=== result ==="
for t in unzip zstd lz4 openssl bc bison flex cpio kmod; do printf '%-8s -> ' "$t"; command -v "$t" || echo MISSING; done
