#!/usr/bin/env bash
# PixelOS sixteen (Android 16) source sync — long running, resumable
set -o pipefail
P="http://127.0.0.1:17890"
export http_proxy="$P" https_proxy="$P"
LOG="$HOME/vanilla/logs/repo-sync.log"
mkdir -p "$HOME/vanilla/logs" "$HOME/bin" "$HOME/pixelos"

echo "=== [1/4] 安装 repo 工具 ===" | tee "$LOG"
if [ ! -x "$HOME/bin/repo" ]; then
  curl -fsSL --retry 3 https://storage.googleapis.com/git-repo-downloads/repo -o "$HOME/bin/repo" || {
      echo "storage.googleapis.com 失败，尝试镜像"; 
      curl -fsSL --retry 3 https://raw.githubusercontent.com/GerritCodeReview/git-repo/main/repo -o "$HOME/bin/repo"
  }
  chmod a+x "$HOME/bin/repo"
fi
export PATH="$HOME/bin:$PATH"
repo --version 2>&1 | head -2 | tee -a "$LOG"

echo "=== [2/4] git 身份配置 ===" | tee -a "$LOG"
git config --global user.name "vanilla-builder"
git config --global user.email "builder@localhost"
git config --global http.proxy "$P"

echo "=== [3/4] repo init (PixelOS sixteen, depth=1) ===" | tee -a "$LOG"
cd "$HOME/pixelos" || exit 1
if [ ! -d .repo ]; then
  repo init -u https://github.com/PixelOS-AOSP/manifest -b sixteen --depth=1 --no-clone-bundle 2>&1 | tail -15 | tee -a "$LOG"
fi

echo "=== [4/4] repo sync -c -j8 (耗时最长) ===" | tee -a "$LOG"
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags --optimized-fetch 2>&1 | tail -40 | tee -a "$LOG"
echo "=== sync exit=$? ===" | tee -a "$LOG"
du -sh "$HOME/pixelos" 2>/dev/null | tee -a "$LOG"
