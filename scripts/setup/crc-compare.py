#!/usr/bin/env python3
"""Compare MIUI vendor module CRC expectations against our kernel's Module.symvers.

struct modversion_info { unsigned long crc; char name[MODULE_NAME_LEN]; }
4.19: MODULE_NAME_LEN = 56  ->  8 + 56 = 64 bytes per entry (arm64, 64-bit crc)
"""
import struct, sys, os

MODULE_NAME_LEN = 56

def parse_symvers(path):
    table = {}
    for line in open(path, encoding='utf-8', errors='replace'):
        parts = line.split('\t')
        if len(parts) < 2:
            continue
        try:
            crc = int(parts[0], 16)
        except ValueError:
            continue
        table[parts[1]] = crc
    return table

def elf_section(data, name):
    if data[:4] != b'\x7fELF':
        return None
    is64 = data[4] == 2
    if not is64:
        return None
    e_shoff = struct.unpack_from('<Q', data, 0x28)[0]
    e_shentsize = struct.unpack_from('<H', data, 0x3A)[0]
    e_shnum = struct.unpack_from('<H', data, 0x3C)[0]
    e_shstrndx = struct.unpack_from('<H', data, 0x3E)[0]
    sh_str_off = struct.unpack_from('<Q', data, e_shoff + e_shstrndx*e_shentsize + 0x18)[0]
    for i in range(e_shnum):
        base = e_shoff + i*e_shentsize
        sh_name, sh_type = struct.unpack_from('<II', data, base)
        sh_offset, sh_size = struct.unpack_from('<QQ', data, base + 0x18)
        end = data.index(b'\x00', sh_str_off + sh_name)
        nm = data[sh_str_off + sh_name:end].decode(errors='replace')
        if nm == name:
            return sh_offset, sh_size
    return None

def parse_versions(ko):
    data = open(ko, 'rb').read()
    sec = elf_section(data, '__versions')
    if not sec:
        return None
    off, size = sec
    n = size // 64
    out = {}
    for i in range(n):
        base = off + i*64
        crc = struct.unpack_from('<Q', data, base)[0]
        raw = data[base+8: base+8+MODULE_NAME_LEN]
        nm = raw.split(b'\x00')[0].decode(errors='replace')
        if nm:
            out[nm] = crc & 0xffffffff
    return out

def main():
    symvers = parse_symvers(sys.argv[1])
    print(f"我们的内核符号表: {len(symvers)} 个导出符号\n")
    for ko in sys.argv[2:]:
        vers = parse_versions(ko)
        name = os.path.basename(ko)
        if vers is None:
            print(f"[{name}] 无法解析 __versions（可能未启用 MODVERSIONS）")
            continue
        matched = mismatched = missing = 0
        bad = []
        for sym, crc in vers.items():
            if sym not in symvers:
                missing += 1
                continue
            if symvers[sym] == crc:
                matched += 1
            else:
                mismatched += 1
                if len(bad) < 6:
                    bad.append(f"{sym}: 模块期望 0x{crc:08x} / 我们 0x{symvers[sym]:08x}")
        total = len(vers)
        pct = (matched / total * 100) if total else 0
        print(f"[{name}] 依赖符号 {total} 个 → 一致 {matched} ({pct:.1f}%) / 不一致 {mismatched} / 我们没导出 {missing}")
        for b in bad:
            print(f"    {b}")
        # module_layout 专项
        if 'module_layout' in vers:
            exp = vers['module_layout']
            got = symvers.get('module_layout')
            print(f"    module_layout: 模块期望 0x{exp:08x} / 我们 0x{got:08x} → {'一致' if exp==got else '不一致'}")
        print()

if __name__ == '__main__':
    main()
