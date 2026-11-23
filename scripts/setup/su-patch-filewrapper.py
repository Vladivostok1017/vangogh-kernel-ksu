#!/usr/bin/env python3
"""Port SukiSU's file_wrapper.c to 4.19: guard 5.x-only file_operations members
and the anon-inode LSM hook."""
import re, sys

P = "/root/work/driftwood/SukiSU/kernel/infra/file_wrapper.c"
s = open(P).read()
orig = s

# 1) iopoll: only exists >= 5.0 ; 6.1 changed its signature
old_guard = "#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 1, 0)\nstatic int ksu_wrapper_iopoll("
new_guard = ("#if LINUX_VERSION_CODE < KERNEL_VERSION(5, 0, 0)\n"
             "/* struct file_operations::iopoll does not exist before 5.0 */\n"
             "#elif LINUX_VERSION_CODE >= KERNEL_VERSION(6, 1, 0)\n"
             "static int ksu_wrapper_iopoll(")
if "iopoll does not exist before 5.0" not in s:
    s = s.replace(old_guard, new_guard, 1)

# 2) fops assignment for iopoll
old = "    p->ops.iopoll = fp->f_op->iopoll ? ksu_wrapper_iopoll : NULL;"
new = ("#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 0, 0)\n"
       "    p->ops.iopoll = fp->f_op->iopoll ? ksu_wrapper_iopoll : NULL;\n"
       "#endif")
s = s.replace(old, new, 1)

# 3) remap_file_range: added in 5.0 (from dedupe_file_range)
old = ("static loff_t ksu_wrapper_remap_file_range(struct file *file_in, loff_t pos_in, "
       "struct file *file_out, loff_t pos_out,")
new = ("#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 0, 0)\n" + old)
s = s.replace(old, new, 1)
# close the guard right before the next function
old2 = "static int ksu_wrapper_fadvise(struct file *fp, loff_t off1, loff_t off2, int flags)"
new2 = "#endif /* >= 5.0: remap_file_range */\n\n" + old2
s = s.replace(old2, new2, 1)

# 4) fops assignment for remap_file_range
old = "    p->ops.remap_file_range = fp->f_op->remap_file_range ? ksu_wrapper_remap_file_range : NULL;"
new = ("#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 0, 0)\n"
       "    p->ops.remap_file_range = fp->f_op->remap_file_range ? ksu_wrapper_remap_file_range : NULL;\n"
       "#endif")
s = s.replace(old, new, 1)

# 5) security_inode_init_security_anon: added in 5.10
old = """    error = security_inode_init_security_anon(inode, &qname, context_inode);
    if (error) {
        iput(inode);
        return ERR_PTR(error);
    }"""
new = """#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 10, 0)
    error = security_inode_init_security_anon(inode, &qname, context_inode);
    if (error) {
        iput(inode);
        return ERR_PTR(error);
    }
#else
    /* 4.19: alloc_anon_inode() already set up security; nothing further */
    (void)qname;
    (void)context_inode;
#endif"""
if "4.19: alloc_anon_inode() already set up security" not in s:
    s = s.replace(old, new, 1)

if s != orig:
    open(P, "w").write(s)
    print("file_wrapper.c 已修补")
else:
    print("未修改（可能已打过补丁）")
