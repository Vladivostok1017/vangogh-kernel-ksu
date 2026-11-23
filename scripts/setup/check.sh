#!/usr/bin/env bash
# Environment / connectivity probe for vangogh kernel build
echo "===== host ====="
uname -a
nproc
free -g | head -2
echo
echo "===== mounts ====="
ls -d /mnt/* 2>/dev/null
echo
echo "===== build deps ====="
for t in gcc g++ make ld python3 bc bison flex cpio git curl unzip zstd lz4 openssl rsync libssl-dev; do
  if command -v "$t" >/dev/null 2>&1; then echo "OK    $t"; else echo "MISS  $t"; fi
done
echo
echo "===== network (curl each host, no proxy) ====="
for u in https://github.com https://raw.githubusercontent.com https://codeload.github.com https://objects.githubusercontent.com https://android.googlesource.com https://ghproxy.net https://cdn.jsdelivr.net https://mirrors.tuna.tsinghua.edu.cn; do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$u" 2>/dev/null)
  printf '%-42s %s\n' "$u" "$code"
done
echo
echo "===== proxy env ====="
env | grep -iE 'proxy' || echo "(none)"
