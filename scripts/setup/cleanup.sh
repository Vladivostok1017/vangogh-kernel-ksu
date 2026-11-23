#!/usr/bin/env bash
echo "=== 清理前 ==="
du -sh "$HOME/vanilla" "$HOME/pixelos" 2>/dev/null
df -h / | tail -1

echo
echo "=== 删除源码/编译产物/下载包（全部为可重新获取的中间产物）==="
rm -rf "$HOME/pixelos" \
       "$HOME/vanilla/src" \
       "$HOME/vanilla/dl" \
       "$HOME/vanilla/out-vanilla" \
       "$HOME/vanilla/out-stock" \
       "$HOME/vanilla/out-drift" \
       "$HOME/vanilla/out-pe13" \
       "$HOME/vanilla/pe13-vendor" \
       "$HOME/vanilla/pe13-work" \
       "$HOME/vanilla/pe13-ko" \
       "$HOME/vanilla/vendor-ko" \
       "$HOME/vanilla/ksu" \
       "$HOME/vanilla/tools" \
       "$HOME/vanilla/tc" \
       "$HOME/vanilla/logs"
rm -f "$HOME/vanilla/stock_config.gz" 2>/dev/null
rmdir "$HOME/vanilla" 2>/dev/null

echo "=== 清理后 ==="
du -sh "$HOME/vanilla" 2>/dev/null || echo "(~/vanilla 已删除)"
df -h / | tail -1
