#!/usr/bin/env python3
"""Dump the full boot image header (v2) field by field, and the region layout."""
import struct, sys, hashlib

path = sys.argv[1]
d = open(path, 'rb').read()
h = struct.unpack('<8s10I', d[:48])
magic = h[0]
(kernel_size, kernel_addr, ramdisk_size, ramdisk_addr, second_size,
 second_addr, tags_addr, page_size, header_version, os_version) = h[1:]
print(f"magic          {magic!r}")
print(f"kernel_size    {kernel_size}")
print(f"kernel_addr    0x{kernel_addr:x}")
print(f"ramdisk_size   {ramdisk_size}")
print(f"ramdisk_addr   0x{ramdisk_addr:x}")
print(f"second_size    {second_size}")
print(f"second_addr    0x{second_addr:x}")
print(f"tags_addr      0x{tags_addr:x}")
print(f"page_size      {page_size}")
print(f"header_version {header_version}")
print(f"os_version     0x{os_version:08x}")
name = d[48:64].split(b'\x00')[0]
cmdline = d[64:576].split(b'\x00')[0].decode(errors='replace')
imgid = d[576:608]
extra = d[608:1632].split(b'\x00')[0]
print(f"name           {name!r}")
print(f"cmdline[{len(cmdline)}]  {cmdline!r}")
print(f"id             {imgid.hex()}")
print(f"extra_cmdline  {extra!r}")
# v2 fields
hs = 1632
header_size, = struct.unpack('<I', d[hs:hs+4])
print(f"header_size    {header_size}  (0x{header_size:x})")
reserved = struct.unpack('<4I', d[hs+4:hs+20])
print(f"reserved       {reserved}")
dtb_size, dtb_addr = struct.unpack('<IQ', d[hs+20:hs+32])
print(f"dtb_size       {dtb_size}")
print(f"dtb_addr       0x{dtb_addr:x}")

pages = lambda n: (n + page_size - 1) // page_size if n else 0
off = page_size
print(f"\n--- layout (page_size={page_size}) ---")
print(f"header occupies {page_size} bytes, now at 0x{off:x}")
k = d[off:off+kernel_size]; print(f"kernel  @0x{off:x} len={kernel_size} first4={k[:4].hex()}")
off += pages(kernel_size)*page_size
r = d[off:off+ramdisk_size]; print(f"ramdisk @0x{off:x} len={ramdisk_size} first4={r[:4].hex()}")
off += pages(ramdisk_size)*page_size
print(f"after ramdisk  0x{off:x}  (rest zero? {all(b==0 for b in d[off:off+64])})")
print(f"image total    {len(d)} (0x{len(d):x})")
