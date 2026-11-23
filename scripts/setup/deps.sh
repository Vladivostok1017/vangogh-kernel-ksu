#!/usr/bin/env bash
set -x
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  unzip zstd lz4 libssl-dev build-essential libelf-dev kmod python3-pip rsync bc bison flex cpio
echo "=== result ==="
for t in unzip zstd lz4 openssl kmod; do printf '%s -> ' "$t"; command -v "$t" || echo MISSING; done
dpkg -l libssl-dev | tail -2
