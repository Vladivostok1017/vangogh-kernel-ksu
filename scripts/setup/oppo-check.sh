#!/usr/bin/env bash
export https_proxy=http://127.0.0.1:17890 http_proxy=http://127.0.0.1:17890
echo "=== oppo-source 仓库总览（分页拉取）==="
for p in 1 2 3; do
  curl -s --max-time 40 "https://api.github.com/orgs/oppo-source/repos?per_page=100&page=$p" \
    | grep -oE '"full_name": "[^"]+"' | sed 's/"full_name": //'
done > /tmp/oppo_repos.txt
wc -l < /tmp/oppo_repos.txt

echo
echo "=== 含 peacock / sm8350 / findx3 的仓库 ==="
grep -iE "peacock|sm8350|findx3|find_x3" /tmp/oppo_repos.txt || echo "(未找到)"

echo
echo "=== 全部仓库名（前 60）==="
head -60 /tmp/oppo_repos.txt
