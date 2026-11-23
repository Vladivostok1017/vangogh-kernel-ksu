#!/usr/bin/env python3
"""Relax module CRC check so MIUI's /vendor modules (built against 4.19.113)
can load into this 4.19.157 tree. Mismatch is logged but not fatal."""
K = "/root/vanilla/src/driftwood"
p = f"{K}/kernel/module.c"
s = open(p).read()

old = """bad_version:
	pr_warn("%s: disagrees about version of symbol %s\\n",
	       info->name, symname);
	return 0;"""
new = """bad_version:
	pr_warn("%s: CRC mismatch for symbol %s (loading anyway, MIUI compat)\\n",
	       info->name, symname);
	return 1;"""

if "MIUI compat" in s:
    print("已打过补丁，跳过")
elif old in s:
    open(p, "w").write(s.replace(old, new, 1))
    print("kernel/module.c 已修补: CRC 不符改为警告并放行")
else:
    print("未匹配到目标，需人工检查")
