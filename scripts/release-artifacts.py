#!/usr/bin/env python3
"""Bundle every build/backup artifact into the repository as xz-compressed blobs.

Why this exists
---------------
The project ships real, byte-exact device artifacts: the boot images that were
actually booted on hardware, the APKs that were installed, the stock config that
was diffed against, and the *irreplaceable* partition/firmware backups taken
before anything was flashed.  A public git host rejects single blobs above
100 MiB, and raw partition dumps are mostly padding, so every large artifact is
stored as ``<name>.xz`` (xz -6 via Python lzma).  Boot images shrink ~10:1.

Usage
-----
    python3 scripts/release-artifacts.py [--src /mnt/f/vanilla-build] [--jobs 8]

Writes:
    artifacts/boot/*.img.xz, artifacts/apk/*, artifacts/config/*
    backup/partitions/*.xz, backup/firmware/*.xz, backup/ko/*
    artifacts/SHA256SUMS   backup/SHA256SUMS   (raw + packed digests)

The script is idempotent: an existing ``.xz`` whose source size + mtime match
the recorded manifest entry is skipped unless ``--force`` is given.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import lzma
import os
import sys
import time
from concurrent.futures import ProcessPoolExecutor

# (source path relative to --src, destination path relative to repo root)
# compress=False copies bytes verbatim (already-compressed payloads).
JOBS: list[tuple[str, str, bool]] = [
    # --- working / experimental boot images (header v2, 128 MiB slots) ---
    ("out-c6.img", "artifacts/boot/out-c6-working-ksu-0.9.5.img.xz", True),
    ("out-c.img", "artifacts/boot/out-c-experimental.img.xz", True),
    ("out-c2.img", "artifacts/boot/out-c2-experimental.img.xz", True),
    ("out-c3.img", "artifacts/boot/out-c3-experimental.img.xz", True),
    # --- installer payloads ---
    ("KernelSU_v0.9.5.apk", "artifacts/apk/KernelSU_v0.9.5.apk", False),
    ("SukiSU_Nova_v3.0.0.apk", "artifacts/apk/SukiSU_Nova_v3.0.0.apk", False),
    # --- reference config ---
    ("stock_config.gz", "artifacts/config/stock_config.gz", False),
    # --- stock / magisk boot backups ---
    ("backup/boot-stock-v13.0.7.0.img", "backup/boot/stock-v13.0.7.0.img.xz", True),
    ("backup/partitions/bk-partitions/boot.img", "backup/boot/magisk-patched-boot.img.xz", True),
    # --- partition table backups ---
    ("backup/partitions/bk-partitions/devcfg.img", "backup/partitions/devcfg.img.xz", True),
    ("backup/partitions/bk-partitions/devinfo.img", "backup/partitions/devinfo.img.xz", True),
    ("backup/partitions/bk-partitions/dtbo.img", "backup/partitions/dtbo.img.xz", True),
    ("backup/partitions/bk-partitions/misc.img", "backup/partitions/misc.img.xz", True),
    ("backup/partitions/bk-partitions/sec.img", "backup/partitions/sec.img.xz", True),
    ("backup/partitions/bk-partitions/vbmeta.img", "backup/partitions/vbmeta.img.xz", True),
    # --- firmware backups ---
    ("backup/bk-firmware/abl.img", "backup/firmware/abl.img.xz", True),
    ("backup/bk-firmware/aop.img", "backup/firmware/aop.img.xz", True),
    ("backup/bk-firmware/bluetooth.img", "backup/firmware/bluetooth.img.xz", True),
    ("backup/bk-firmware/devcfg.img", "backup/firmware/devcfg.img.xz", True),
    ("backup/bk-firmware/dsp.img", "backup/firmware/dsp.img.xz", True),
    ("backup/bk-firmware/featenabler.img", "backup/firmware/featenabler.img.xz", True),
    ("backup/bk-firmware/hyp.img", "backup/firmware/hyp.img.xz", True),
    ("backup/bk-firmware/imagefv.img", "backup/firmware/imagefv.img.xz", True),
    ("backup/bk-firmware/keymaster.img", "backup/firmware/keymaster.img.xz", True),
    ("backup/bk-firmware/logo.img", "backup/firmware/logo.img.xz", True),
    ("backup/bk-firmware/modem.img", "backup/firmware/modem.img.xz", True),
    ("backup/bk-firmware/qupfw.img", "backup/firmware/qupfw.img.xz", True),
    ("backup/bk-firmware/storsec.img", "backup/firmware/storsec.img.xz", True),
    ("backup/bk-firmware/tz.img", "backup/firmware/tz.img.xz", True),
    ("backup/bk-firmware/uefisecapp.img", "backup/firmware/uefisecapp.img.xz", True),
    ("backup/bk-firmware/vbmeta_system.img", "backup/firmware/vbmeta_system.img.xz", True),
    ("backup/bk-firmware/xbl.img", "backup/firmware/xbl.img.xz", True),
    ("backup/bk-firmware/xbl_config.img", "backup/firmware/xbl_config.img.xz", True),
    # --- vendor modules kept for CRC analysis (small, stored as-is) ---
    ("backup/ko/audio_apr.ko", "backup/ko/audio_apr.ko", False),
    ("backup/ko/audio_machine_lito.ko", "backup/ko/audio_machine_lito.ko", False),
    ("backup/ko/exfat.ko", "backup/ko/exfat.ko", False),
    ("backup/ko/lcd.ko", "backup/ko/lcd.ko", False),
    ("backup/ko/qca_cld3_wlan.ko", "backup/ko/qca_cld3_wlan.ko", False),
    ("backup/ko/rmnet_perf.ko", "backup/ko/rmnet_perf.ko", False),
]

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(REPO, "artifacts", "pack-manifest.json")

# 故意**不**入仓的四个分区：内容是本机的身份数据，不进公开历史
#   persist.img    Wi-Fi MAC / 指纹与传感器标定 / MI 账号 ID 与 FIDO·MiPay·Widevine 密钥
#   modemst1.img   EFS2 的 IMEI、射频校准、SIM 锁
#   modemst2.img   同上（第二份）
#   fsg.img        出厂 golden copy，可把上面两个恢复回出厂态
# 需要时用 --include-identity 在本机导出（默认不导出）。
IDENTITY_EXCLUDED = [
    ("backup/partitions/bk-partitions/persist.img", "backup/partitions/persist.img.xz"),
    ("backup/partitions/bk-partitions/modemst1.img", "backup/partitions/modemst1.img.xz"),
    ("backup/partitions/bk-partitions/modemst2.img", "backup/partitions/modemst2.img.xz"),
    ("backup/partitions/bk-partitions/fsg.img", "backup/partitions/fsg.img.xz"),
]



def sha256_file(path: str, chunk: int = 1 << 20) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for block in iter(lambda: fh.read(chunk), b""):
            h.update(block)
    return h.hexdigest()


def pack(job):
    src_rel, dst_rel, compress = job
    src = os.path.join(SRC_ROOT, src_rel)
    dst = os.path.join(REPO, dst_rel)
    if not os.path.isfile(src):
        return {"dst": dst_rel, "status": "missing-source", "src": src_rel}

    st = os.stat(src)
    key = f"{src_rel}|{dst_rel}"
    if not FORCE and os.path.isfile(dst):
        prev = MANIFEST_CACHE.get(key)
        if (
            prev
            and prev.get("src_size") == st.st_size
            and prev.get("src_mtime") == int(st.st_mtime)
            and os.path.getsize(dst) == prev.get("dst_size")
        ):
            return {"dst": dst_rel, "status": "cached", **prev}

    os.makedirs(os.path.dirname(dst), exist_ok=True)
    t0 = time.time()
    if compress:
        with open(src, "rb") as fin, lzma.open(dst, "wb", format=lzma.FORMAT_XZ, preset=PRESET) as fout:
            while True:
                block = fin.read(4 << 20)
                if not block:
                    break
                fout.write(block)
    else:
        with open(src, "rb") as fin, open(dst, "wb") as fout:
            while True:
                block = fin.read(4 << 20)
                if not block:
                    break
                fout.write(block)

    entry = {
        "src": src_rel,
        "dst": dst_rel,
        "src_size": st.st_size,
        "src_mtime": int(st.st_mtime),
        "dst_size": os.path.getsize(dst),
        "src_sha256": sha256_file(src),
        "dst_sha256": sha256_file(dst),
        "compressed": compress,
        "elapsed_s": round(time.time() - t0, 1),
    }
    return {"dst": dst_rel, "status": "packed", **entry}


def main() -> int:
    global SRC_ROOT, FORCE, PRESET, MANIFEST_CACHE
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=os.environ.get("VANGOGH_ARTIFACT_SRC", "/mnt/f/vanilla-build"))
    ap.add_argument("--jobs", type=int, default=min(8, os.cpu_count() or 4))
    ap.add_argument("--preset", type=int, default=6)
    ap.add_argument("--force", action="store_true")
    ap.add_argument(
        "--include-identity",
        action="store_true",
        help="同时导出 persist/modemst1/modemst2/fsg（含 IMEI、MAC、支付密钥，只在本机留档用）",
    )
    args = ap.parse_args()

    jobs = list(JOBS)
    if args.include_identity:
        jobs += [(s, d, True) for s, d in IDENTITY_EXCLUDED]

    SRC_ROOT, FORCE, PRESET = args.src, args.force, args.preset
    MANIFEST_CACHE = {}
    MANIFEST_CACHE = {}
    if os.path.isfile(MANIFEST):
        try:
            with open(MANIFEST, encoding="utf-8") as fh:
                MANIFEST_CACHE = {f"{e['src']}|{e['dst']}": e for e in json.load(fh)}
        except Exception:
            MANIFEST_CACHE = {}

    if not os.path.isdir(SRC_ROOT):
        print(f"source root not found: {SRC_ROOT}", file=sys.stderr)
        return 2

    print(f"src={SRC_ROOT}  jobs={args.jobs}  preset={args.preset}  entries={len(jobs)}")
    if not args.include_identity:
        print(f"身份数据不入仓（{len(IDENTITY_EXCLUDED)} 个分区跳过）："
              + ", ".join(os.path.basename(s) for s, _ in IDENTITY_EXCLUDED))
    results = []
    with ProcessPoolExecutor(max_workers=args.jobs) as pool:
        for res in pool.map(pack, jobs):
            results.append(res)
            if res["status"] == "packed":
                print(
                    f"  packed  {res['src_size']/2**20:8.1f} MiB -> {res['dst_size']/2**20:7.2f} MiB"
                    f"  {res['dst']}  ({res['elapsed_s']}s)"
                )
            elif res["status"] == "cached":
                print(f"  cached  {res['dst']}")
            else:
                print(f"  MISSING {res['src']}", file=sys.stderr)

    os.makedirs(os.path.dirname(MANIFEST), exist_ok=True)
    merged = {f"{e['src']}|{e['dst']}": e for e in results if e["status"] in ("packed", "cached")}
    merged.update({k: v for k, v in MANIFEST_CACHE.items()
                   if k not in merged and k.split("|", 1)[1] in {d for _, d, _ in jobs}})
    with open(MANIFEST, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(sorted(merged.values(), key=lambda e: e["dst"]), fh, indent=2)
        fh.write("\n")

    # per-tree checksum files (raw digest lets people verify a re-flashed image)
    for tree in ("artifacts", "backup"):
        lines = []
        for e in sorted(merged.values(), key=lambda e: e["dst"]):
            if not e["dst"].startswith(tree + "/"):
                continue
            if not os.path.isfile(os.path.join(REPO, e["dst"])):
                continue
            lines.append(f"{e['dst_sha256']}  {e['dst']}")
            if e["src_sha256"] != e["dst_sha256"]:
                lines.append(f"{e['src_sha256']}  {e['dst'][:-3]}  (decompressed)")
        out = os.path.join(REPO, tree, "SHA256SUMS")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        with open(out, "w", encoding="utf-8", newline="\n") as fh:
            fh.write("\n".join(lines) + "\n")
        print(f"wrote {tree}/SHA256SUMS ({len(lines)} lines)")

    total = sum(e["dst_size"] for e in merged.values() if os.path.isfile(os.path.join(REPO, e["dst"])))
    print(f"repository payload total: {total/2**20:.1f} MiB")
    missing = [r for r in results if r["status"] == "missing-source"]
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
