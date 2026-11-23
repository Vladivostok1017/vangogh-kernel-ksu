#!/usr/bin/env bash
export https_proxy=http://127.0.0.1:17890 http_proxy=http://127.0.0.1:17890
for repo in android_kernel_oppo_sm8350 android_kernel_modules_and_devicetree_oppo_sm8350; do
  echo "========== $repo =========="
  curl -s --max-time 40 "https://api.github.com/repos/oppo-source/$repo/branches?per_page=100" \
    | grep -oE '"name": "[^"]+"' | sed 's/"name": //' | tr -d '"' | tr '\n' ' '
  echo
  echo "--- 默认分支/描述 ---"
  curl -s --max-time 40 "https://api.github.com/repos/oppo-source/$repo" \
    | grep -oE '"(default_branch|description|size)": [^,]+' | head -3
  echo
done
