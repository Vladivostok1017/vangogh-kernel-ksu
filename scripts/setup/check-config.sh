#!/usr/bin/env bash
gzip -dc /mnt/f/vanilla-build/stock_config.gz > /tmp/stock.config
echo "config lines = $(wc -l < /tmp/stock.config)"
check() {
  local c="$1"
  local hit
  hit=$(grep -m1 "^CONFIG_${c}=" /tmp/stock.config)
  [ -z "$hit" ] && hit=$(grep -m1 "^# CONFIG_${c} is not set" /tmp/stock.config)
  [ -z "$hit" ] && hit="MISSING"
  printf '%-28s %s\n' "CONFIG_${c}" "$hit"
}
for c in KPROBES KRETPROBES UPROBES HAVE_SYSCALL_TRACEPOINTS EXT4_FS KALLSYMS KALLSYMS_ALL \
         SECCOMP SECURITY_SELINUX MODULES OVERLAY_FS CC_IS_CLANG LTO_NONE FTRACE DYNAMIC_FTRACE \
         ARM64 ARM64_PTR_AUTH STATIC_USERMODEHELPER; do
  check "$c"
done
echo
echo "--- toolchain ---"
for t in clang-14 ld.lld-14 llvm-ar-14 aarch64-linux-gnu-gcc aarch64-linux-gnu-ld; do
  printf '%-26s ' "$t"; command -v "$t" || echo MISSING
done
clang-14 --version 2>/dev/null | head -1
