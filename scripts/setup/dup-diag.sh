#!/usr/bin/env bash
K="$HOME/work/driftwood/techpack/audio"
echo "=== 谁把 snd_event.c 编进模块 ==="
grep -rn "snd_event\.o\|snd_event_dlkm" "$K" --include=Kbuild 2>/dev/null | head -10
echo
echo "=== msm_qti_pp_send_chmix_cfg_cmd 定义处 ==="
grep -rn "msm_qti_pp_send_chmix_cfg_cmd" "$K" 2>/dev/null | grep -E "EXPORT_SYMBOL|^[^:]*\.c:" | head -8
echo
echo "=== msm-cirrus-playback 归属 ==="
grep -rn "msm-cirrus-playback" "$K" --include=Kbuild 2>/dev/null | head -5
