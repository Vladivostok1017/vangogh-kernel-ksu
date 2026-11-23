#!/usr/bin/env bash
K="$HOME/work/driftwood"
cd "$K" || { echo "树不存在: $K"; exit 1; }
echo "driftwood branch: $(git rev-parse --abbrev-ref HEAD)"
echo "driftwood commit: $(git rev-parse HEAD)"
cd "$K/KernelSU" 2>/dev/null && echo "KernelSU: $(git describe --tags 2>/dev/null) / $(git rev-parse --short HEAD)"
