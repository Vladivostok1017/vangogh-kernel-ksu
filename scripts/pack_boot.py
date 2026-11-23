#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
"""
Pack an Android boot image (header v0-v2) by reusing the stock image's header
verbatim and swapping the kernel payload.

Usage:
  pack_boot.py --src stock_boot.img --kernel Image --out new_boot.img [--pad 134217728]

Only kernel_size in the header is updated; every other byte of the header is
preserved, so cmdline/os_version/tags_addr/dtb region stay exactly as stock.
"""
import argparse, os, struct, sys

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', required=True, help='stock boot.img (header donor)')
    ap.add_argument('--kernel', required=True, help='new kernel Image (raw)')
    ap.add_argument('--out', required=True)
    ap.add_argument('--pad', type=int, default=0, help='pad output to this size')
    ap.add_argument('--zero_tail', action='store_true',
                    help='zero the trailing stock region (drops the stale AVB footer)')
    ap.add_argument('--ramdisk', default=None, help='override ramdisk (default: from src)')
    ap.add_argument('--dtb', default=None, help='override dtb (default: from src)')
    a = ap.parse_args()

    src = open(a.src, 'rb').read()
    magic, = struct.unpack('<8s', src[:8])
    if magic != b'ANDROID!':
        sys.exit('not a boot image')
    (kernel_size, kernel_addr, ramdisk_size, ramdisk_addr, second_size,
     second_addr, tags_addr, page_size, header_version, os_version) = struct.unpack('<10I', src[8:48])
    if header_version > 2:
        sys.exit(f'header v{header_version} not supported by this packer')

    def rnd(n):
        return (n + page_size - 1) // page_size * page_size

    # locate regions in source
    off = page_size
    s_kernel = src[off:off + kernel_size]; off += rnd(kernel_size)
    s_ramdisk = src[off:off + ramdisk_size]; off += rnd(ramdisk_size)
    s_second = src[off:off + second_size]; off += rnd(second_size)
    s_dtb = b''
    dtb_size = 0
    if header_version >= 2:
        # v2 header: recovery_dtbo_size@1632, recovery_dtbo_offset@1636,
        # header_size@1644, dtb_size@1648, dtb_addr@1652
        hs, = struct.unpack('<I', src[1644:1648])
        if hs >= 1660:
            dtb_size, _dtb_addr = struct.unpack('<IQ', src[1648:1660])
        s_dtb = src[off:off + dtb_size]; off += rnd(dtb_size)

    kernel = open(a.kernel, 'rb').read()
    ramdisk = open(a.ramdisk, 'rb').read() if a.ramdisk else s_ramdisk
    dtb = open(a.dtb, 'rb').read() if a.dtb else s_dtb

    header = bytearray(src[:1660]) if header_version >= 2 else bytearray(src[:page_size])
    struct.pack_into('<I', header, 8, len(kernel))
    struct.pack_into('<I', header, 16, len(ramdisk))
    if header_version >= 2 and dtb:
        struct.pack_into('<I', header, 1648, len(dtb))

    out = bytearray()
    out += header
    out += b'\x00' * (page_size - len(header))
    out += kernel + b'\x00' * (rnd(len(kernel)) - len(kernel))
    out += ramdisk + b'\x00' * (rnd(len(ramdisk)) - len(ramdisk))
    if second_size:
        out += s_second + b'\x00' * (rnd(len(s_second)) - len(s_second))
    if dtb:
        out += dtb + b'\x00' * (rnd(len(dtb)) - len(dtb))

    if a.pad and len(out) < a.pad:
        out += b'\x00' * (a.pad - len(out))

    # preserve whatever trails the used regions in the stock image (AVB footer
    # / vbmeta blob lives at the end of the partition)
    if not a.zero_tail and len(src) > len(out):
        tail = src[len(out):]
        out += tail
    if a.zero_tail:
        out += b'\x00' * (len(src) - len(out)) if len(src) > len(out) else b''

    open(a.out, 'wb').write(out)
    print(f'kernel   {len(kernel)} (was {kernel_size})')
    print(f'ramdisk  {len(ramdisk)}')
    print(f'dtb      {len(dtb)}')
    print(f'total    {len(out)} -> {a.out}')

if __name__ == '__main__':
    main()
