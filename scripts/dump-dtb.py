#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
import struct, sys
src = open("/mnt/c/Users/Administrator/Downloads/boot.img", "rb").read()
ps = struct.unpack('<I', src[36:40])[0]
ks, rs = struct.unpack('<I', src[8:12])[0], struct.unpack('<I', src[16:20])[0]
hs = struct.unpack('<I', src[1644:1648])[0]
ds, da = struct.unpack('<IQ', src[1648:1660])
rnd = lambda n: (n + ps - 1)//ps*ps
off = ps + rnd(ks) + rnd(rs)
print(f"page={ps} kernel={ks} ramdisk={rs} header_size={hs} dtb_size={ds} dtb_addr=0x{da:x} offset=0x{off:x}", file=sys.stderr)
dtb = src[off:off+ds]
open("/tmp/stock.dtb","wb").write(dtb)
print(f"wrote /tmp/stock.dtb ({len(dtb)} bytes)")
