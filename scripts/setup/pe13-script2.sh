#!/usr/bin/env bash
W="$HOME/vanilla/pe13-work"
cd "$W" || exit 1
echo "=== updater-script 后半段（从 dynamic_partitions 之后）==="
awk 'f{print} /update_dynamic_partitions/{f=1}' updater-script | sed -n '1,120p'
