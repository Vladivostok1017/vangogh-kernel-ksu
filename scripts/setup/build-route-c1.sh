#!/usr/bin/env bash
# Route C step 1: Driftwood tree + MIUI boot options + WIFI BUILT-IN
set -o pipefail
K="$HOME/work/driftwood"
OUT="$HOME/work/out-c"
LOG="$HOME/work/build-c.log"
export PATH="$HOME/bin:$PATH"
mkdir -p "$HOME/bin"

echo "=== [1] 编译补丁（与上次成功启动时相同）===" | tee "$LOG"
python3 - <<'PY'
import re
K="/root/work/driftwood"
# tune.c: guard the two wrappers that are defined under CONFIG_STUNE_ASSIST
p=f"{K}/kernel/sched/tune.c"; s=open(p).read()
if "CONFIG_STUNE_ASSIST\n\t\t.write_s64" not in s:
    s=s.replace("\t\t.write_s64 = boost_write_wrapper,","#ifdef CONFIG_STUNE_ASSIST\n\t\t.write_s64 = boost_write_wrapper,\n#endif",1)
    s=s.replace("\t\t.write_u64 = prefer_idle_write_wrapper,","#ifdef CONFIG_STUNE_ASSIST\n\t\t.write_u64 = prefer_idle_write_wrapper,\n#endif",1)
    open(p,"w").write(s); print("tune.c patched")
else: print("tune.c already")
# smb5-lib.h: use_bq_pump must exist even without CONFIG_BQ2597X_CHARGE_PUMP
p=f"{K}/drivers/power/supply/qcom/smb5-lib.h"; s=open(p).read()
if "declared unconditionally" not in s:
    old="""#ifdef CONFIG_BQ2597X_CHARGE_PUMP
	/* used for bq charge pump solution */
	struct usbpd		*pd;
	bool			use_bq_pump;
#endif
"""
    new="""#ifdef CONFIG_BQ2597X_CHARGE_PUMP
	/* used for bq charge pump solution */
	struct usbpd		*pd;
#endif
	/* declared unconditionally: read outside the BQ guard */
	bool			use_bq_pump;
"""
    if old in s: open(p,"w").write(s.replace(old,new,1)); print("smb5-lib.h patched")
    else: print("smb5-lib.h NOT matched")
else: print("smb5-lib.h already")
# msm_bus_core.h: '#if 0' -> CONFIG_DEBUG_FS so .c definitions don't clash with stubs
p=f"{K}/drivers/soc/qcom/msm_bus/msm_bus_core.h"; s=open(p).read()
if "#ifdef CONFIG_DEBUG_FS\nvoid msm_bus_dbg_client_data(" not in s:
    s=s.replace("#if 0\nvoid msm_bus_dbg_client_data(","#ifdef CONFIG_DEBUG_FS\nvoid msm_bus_dbg_client_data(",1)
    open(p,"w").write(s); print("msm_bus_core.h patched")
else: print("msm_bus_core.h already")
PY

echo "=== [2] techpack 去掉 -Werror ===" | tee -a "$LOG"
grep -rl -- "-Werror" "$K/techpack" --include=Kbuild --include=Makefile 2>/dev/null | while read -r f; do
  sed -i 's/-Werror/-Wno-error/g' "$f"
done
echo "done" | tee -a "$LOG"

echo "=== [3] defconfig 追加选项 ===" | tee -a "$LOG"
CFG="$K/arch/arm64/configs/vendor/vangogh_user_defconfig"
add(){ grep -q "^CONFIG_$1=y" "$CFG" || echo "CONFIG_$1=y" >> "$CFG"; }
# MIUI 私有驱动（上次靠它们才启动成功）
for o in MIHW MIGT MILLET MIGT_ENERGY_MODEL SF_BINDER PERF_CRITICAL_RT_TASK; do add "$o"; done
# 本次关键：wifi 驱动编进内核
add QCA_CLD_WLAN
# KSU 用到的 kprobe（先加上，KSU 之后接）
for o in KPROBES KPROBE_EVENTS KRETPROBES; do add "$o"; done
grep -E "^(CONFIG_(MIHW|MIGT|MILLET|QCA_CLD_WLAN|KPROBES|KRETPROBES))=" "$CFG" | tee -a "$LOG"

echo "=== [4] 生成配置 ===" | tee -a "$LOG"
cd "$K" || exit 1
rm -rf "$OUT"
MAKE=( O="$OUT" ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j8 "${MAKE[@]}" vendor/vangogh_user_defconfig >> "$LOG" 2>&1 || { echo "defconfig failed"; tail -5 "$LOG"; exit 1; }
make -j8 "${MAKE[@]}" olddefconfig >> "$LOG" 2>&1
echo "--- 生效情况 ---" | tee -a "$LOG"
grep -E "^CONFIG_(QCA_CLD_WLAN|MIHW|MIGT|MILLET|KPROBES|KRETPROBES)=" "$OUT/.config" | tee -a "$LOG"

echo "=== [5] 编译 ===" | tee -a "$LOG"
make -j16 "${MAKE[@]}" Image >> "$LOG" 2>&1
echo "make exit=$?" | tee -a "$LOG"
grep -nE " error:|Error [12]\b|undefined symbol" "$LOG" | head -8
IMG="$OUT/arch/arm64/boot/Image"
if [ -f "$IMG" ]; then
  ls -l "$IMG"; strings -n 10 "$IMG" | grep -m1 "^Linux version 4.19"
  python3 /mnt/f/vanilla-build/setup/pack_boot.py \
    --src "/mnt/c/Users/Administrator/Downloads/boot.img" \
    --kernel "$IMG" --out /mnt/f/vanilla-build/out-c.img --pad 134217728 && echo PACKED
else
  echo IMAGE_MISSING
fi
