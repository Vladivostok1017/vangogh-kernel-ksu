#!/usr/bin/env bash
K="$HOME/work/driftwood"
echo "=== dsp/Kbuild: USF_OBJS 与 q6usm 出现处（含上下文） ==="
grep -n "USF_OBJS\|q6usm\|usf_dlkm\|obj-y" "$K/techpack/audio/dsp/Kbuild" | head -25
echo
echo "=== codecs/Kbuild 230-240 上下文 ==="
sed -n '225,240p' "$K/techpack/audio/asoc/codecs/Kbuild"
echo
echo "=== wsa883x/Kbuild 的 obj 行 ==="
grep -n "^obj-\|^ifeq\|^endif" "$K/techpack/audio/asoc/codecs/wsa883x/Kbuild" | head -12
