#!/usr/bin/env bash
D="$HOME/vanilla/dl/pe13"
Z="$D/PixelExperience_vangogh-13.0-20231028-2241-OFFICIAL.zip"
W="$HOME/vanilla/pe13-work"

echo "=== 是否含 transfer.list / 其他镜像 ==="
unzip -l "$Z" | grep -E "transfer\.list|\.img|payload" | head -20

echo
echo "=== updater-script 全文 ==="
cd "$W" && unzip -o -j "$Z" "META-INF/com/google/android/updater-script" -d "$W" >/dev/null 2>&1 && cat updater-script
