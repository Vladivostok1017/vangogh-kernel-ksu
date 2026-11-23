#!/usr/bin/env bash
export https_proxy=http://127.0.0.1:17890 http_proxy=http://127.0.0.1:17890
BASE="https://raw.githubusercontent.com/oppo-source/android_kernel_oppo_sm8350"
for br in "oppo/sm8350_s_12.1_find_x3_pro" "oppo/sm8350_t_13.0.0_find_x3_pro" "oppo/sm8350_u_14.0.0_find_x3_pro"; do
  echo "===== $br ====="
  curl -s --max-time 40 "$BASE/$br/Makefile" | head -6
  echo "  --- 是否含 MIUI/OPPO 私有目录线索 ---"
  curl -s --max-time 40 "https://api.github.com/repos/oppo-source/android_kernel_oppo_sm8350/contents?ref=$br" \
    | grep -oE '"name": "[^"]+"' | sed 's/"name": //' | tr -d '"' | tr '\n' ' ' | head -c 600
  echo
  echo
done
