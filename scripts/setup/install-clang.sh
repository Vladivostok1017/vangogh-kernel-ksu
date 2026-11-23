#!/usr/bin/env bash
P="http://127.0.0.1:17890"
LOG=/tmp/clang_install.log
exec > >(tee -a "$LOG") 2>&1
echo "=== start $(date) ==="
sudo fuser -k /var/lib/dpkg/lock-frontend 2>/dev/null
sudo -n rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock 2>/dev/null
sudo DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::http::Proxy="$P" -o Acquire::https::Proxy="$P" \
    install -y --no-install-recommends clang-14 lld-14 llvm-14 2>&1 | tail -25
echo "=== dpkg status ==="
dpkg -l clang-14 lld-14 2>/dev/null | tail -3
echo "=== binaries ==="
clang-14 --version 2>/dev/null | head -1 || echo "clang-14 MISSING"
ld.lld-14 --version 2>/dev/null | head -1 || echo "lld MISSING"
echo "=== done $(date) ==="
