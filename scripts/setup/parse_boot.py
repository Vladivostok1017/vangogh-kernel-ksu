#!/usr/bin/env python3
import struct, sys, hashlib, gzip, io, os

path = sys.argv[1]
data = open(path, 'rb').read()
print(f"file      : {path}")
print(f"size      : {len(data)} bytes ({len(data)/1048576:.1f} MiB)")
print(f"sha256    : {hashlib.sha256(data).hexdigest()}")
assert data[:8] == b'ANDROID!', "not an android boot image"

f = struct.unpack('<8s10I', data[:48])
magic = f[0]
kernel_size, kernel_addr, ramdisk_size, ramdisk_addr, second_size, second_addr, tags_addr, page_size, header_version, os_version = f[1:]
print(f"kernel    : size={kernel_size} addr=0x{kernel_addr:x}")
print(f"ramdisk   : size={ramdisk_size} addr=0x{ramdisk_addr:x}")
print(f"second    : size={second_size}")
print(f"tags_addr : 0x{tags_addr:x}")
print(f"page_size : {page_size}")
print(f"hdr ver   : {header_version}")
print(f"os_version: 0x{os_version:08x}")

if header_version >= 1:
    name = data[48:48+16].split(b'\x00')[0].decode(errors='replace')
    cmdline = data[64:64+512].split(b'\x00')[0].decode(errors='replace')
    idv = data[576:576+8]
    extra = data[608:608+1024].split(b'\x00')[0].decode(errors='replace')
    print(f"board     : {name!r}")
    print(f"cmdline   : {cmdline!r}")
    print(f"id        : {idv.hex()}")
    print(f"extra_cmd : {extra!r}")

pages = lambda n: (n + page_size - 1) // page_size if n else 0
off = page_size
kern = data[off:off+kernel_size]; off += pages(kernel_size)*page_size
rd   = data[off:off+ramdisk_size]; off += pages(ramdisk_size)*page_size
print(f"kernel sha: {hashlib.sha256(kern).hexdigest()}")
print(f"ramdisk sh: {hashlib.sha256(rd).hexdigest()}")
print(f"kernel magic: {kern[:4].hex()} ({kern[:2]!r})")

# detect payload compression of kernel
def kind(b):
    if b[:2] == b'\x1f\x8b': return 'gzip'
    if b[:4] == b'\x04\x22\x4d\x18': return 'lz4'
    if b[:4] == b'\x28\xb5\x2f\xfd': return 'zstd'
    if b[:3] == b'\x5d\x00\x00': return 'lzma'
    if b[:4] == b'\x02\x21\x4c\x18': return 'lz4-legacy'
    return 'raw/unknown'
print(f"kernel compression: {kind(kern)}")
print(f"ramdisk first bytes: {rd[:6].hex()}  compression={kind(rd)}")

outdir = sys.argv[2] if len(sys.argv) > 2 else 'out'
os.makedirs(outdir, exist_ok=True)
open(os.path.join(outdir,'kernel.bin'),'wb').write(kern)
open(os.path.join(outdir,'ramdisk.bin'),'wb').write(rd)
print(f"written to {outdir}/kernel.bin ramdisk.bin")
