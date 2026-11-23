#!/usr/bin/env python3
"""Minimal fixes for driftwood tree when built with vangogh_user_defconfig
(STUNE_ASSIST=n, BQ2597X_CHARGE_PUMP=n)."""
import re, sys

K = "/root/vanilla/src/driftwood"

def patch_tune():
    p = f"{K}/kernel/sched/tune.c"
    s = open(p).read()
    if "CONFIG_STUNE_ASSIST\n\t\t.write_s64" in s:
        print("tune.c 已打过补丁，跳过")
        return
    s2 = s.replace(
        "\t\t.write_s64 = boost_write_wrapper,",
        "#ifdef CONFIG_STUNE_ASSIST\n\t\t.write_s64 = boost_write_wrapper,\n#endif", 1)
    s2 = s2.replace(
        "\t\t.write_u64 = prefer_idle_write_wrapper,",
        "#ifdef CONFIG_STUNE_ASSIST\n\t\t.write_u64 = prefer_idle_write_wrapper,\n#endif", 1)
    if s2 != s:
        open(p, "w").write(s2)
        print("tune.c 已修补 (2 处 write wrapper 加 #ifdef)")
    else:
        print("tune.c 未匹配到目标，需人工检查")

def patch_smb5():
    p = f"{K}/drivers/power/supply/qcom/smb5-lib.h"
    s = open(p).read()
    old = """#ifdef CONFIG_BQ2597X_CHARGE_PUMP
	/* used for bq charge pump solution */
	struct usbpd		*pd;
	bool			use_bq_pump;
#endif
"""
    new = """#ifdef CONFIG_BQ2597X_CHARGE_PUMP
	/* used for bq charge pump solution */
	struct usbpd		*pd;
#endif
	/* declared unconditionally: read in code paths not wrapped by the
	 * CONFIG_BQ2597X_CHARGE_PUMP guard (vangogh has no bq pump) */
	bool			use_bq_pump;
"""
    if "declared unconditionally" in s:
        print("smb5-lib.h 已打过补丁，跳过")
        return
    if old in s:
        open(p, "w").write(s.replace(old, new, 1))
        print("smb5-lib.h 已修补 (use_bq_pump 移出 #ifdef)")
    else:
        print("smb5-lib.h 未匹配，需人工检查")

patch_tune()
patch_smb5()
