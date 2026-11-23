#!/usr/bin/env python3
"""Controlled experiment: relax ONLY the module_layout check, keep all other
symbol CRC checks strict. Distinguishes "struct module compatible" from not."""
K = "/root/vanilla/src/driftwood"

# 1) revert the global CRC relax (restore upstream behaviour)
p = f"{K}/kernel/module.c"
s = open(p).read()
if "MIUI compat" in s:
    s = s.replace(
        """bad_version:
	pr_warn("%s: CRC mismatch for symbol %s (loading anyway, MIUI compat)\\n",
	       info->name, symname);
	return 1;""",
        """bad_version:
	pr_warn("%s: disagrees about version of symbol %s\\n",
	       info->name, symname);
	return 0;""")
    open(p, "w").write(s)
    print("已还原全局 CRC 放宽")
else:
    print("全局放宽不存在，跳过还原")

# 2) relax only module_layout
s = open(p).read()
old = """	preempt_enable();
	return check_version(info, "module_layout", mod, crc);
}"""
new = """	preempt_enable();
	/* EXPERIMENT: ignore module_layout mismatch only, keep others strict */
	(void)check_version(info, "module_layout", mod, crc);
	pr_warn("%s: module_layout CRC relaxed (experiment)\\n", info->name);
	return 1;
}"""
if "module_layout CRC relaxed" in s:
    print("module_layout 已放宽，跳过")
elif old in s:
    open(p, "w").write(s.replace(old, new, 1))
    print("已打补丁：只放宽 module_layout")
else:
    print("未匹配 check_modstruct_version，需人工检查")
