#!/usr/bin/env python3
"""msm_bus_core.h: '#if 0' around the debugfs prototypes makes every TU use
static-inline stubs while msm_bus_dbg_rpmh.c still defines the real functions.
Turn it into the CONFIG_DEBUG_FS guard it was meant to be."""
K = "/root/vanilla/src/driftwood"
p = f"{K}/drivers/soc/qcom/msm_bus/msm_bus_core.h"
s = open(p).read()

old = "#if 0\nvoid msm_bus_dbg_client_data("
new = "#ifdef CONFIG_DEBUG_FS\nvoid msm_bus_dbg_client_data("
if new in s:
    print("已打过补丁，跳过")
elif old in s:
    open(p, "w").write(s.replace(old, new, 1))
    print("msm_bus_core.h 已修补: #if 0 -> #ifdef CONFIG_DEBUG_FS")
else:
    print("未匹配到目标模式")
    import re
    for m in re.finditer(r"#if 0", s):
        line = s[:m.start()].count("\n") + 1
        print(f"  发现 #if 0 在行 {line}")
