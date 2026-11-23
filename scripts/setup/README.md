# setup/ — 适配全过程的原始脚本（历史记录，非一键构建）

这里保留的是**这次适配从零到跑起来实际执行过的 138 个脚本**，按时间顺序编号。
它们不是给人直接跑的教程，而是证据链：每一个结论（哪条路线不通、为什么 panic、
哪个 CRC 对不上）都能在对应脚本里找到当时用的命令和参数。

想要"干净的一键构建"，用仓库根目录的 `build.sh` 和 `patches/`；这里的脚本是为了
**可追溯**而原样保留，路径里带 `$HOME/work/...`，换机器不一定能直接跑。

## 命名与实际产物的对应

| 脚本 | 对应产物 | 结果 |
|---|---|---|
| `build-image.sh` / `build-ksu.sh` / `build-vangogh.sh` | 早期 4.19.113 树尝试 | 配置缺 11 项 MIUI 私有开关，MIUI 上 panic |
| `build-driftwood*.sh` | 换到 Driftwood 树 | ✅ 能开机 |
| `build-route-c1.sh` … `build-route-c5.sh` | 路线 C（自带模块 + Magisk 覆盖） | 部分成功，改用内建驱动 |
| `build-c6.sh` | `artifacts/boot/out-c6-working-ksu-0.9.5.img` | ✅ **最终可用镜像** |
| `build-c2*.sh` / `build-c12*.sh` | 音频 dlkm 化实验 | ❌ 重复符号 / 启动 panic，见 `docs/HANDOFF.md` |
| `build-pe13-ksu.sh` / `dl-pe13.sh` / `sync-pixelos.sh` | PixelOS 方向 | 已放弃（非 GKI 与 GKI 内核不能混） |
| `crc-compare.py` / `run-crc-compare.sh` | 根目录 README 里的 MIUI 模块 CRC 表 | 结论来源 |
| `patch-modcrc.py` / `patch-modlayout.py` | 放宽模块 CRC 的实验 | 证明"放宽 CRC 不可行" |
| `parse_boot.py` / `dump_header.py` / `pack_boot.py` | boot header v2 解析与重打包 | 逐字节往返校验通过 |
| `audio-probe*.sh` / `drift-diag-wifi-audio.sh` | 设备侧音频链路取证 | 定位到 q6/adsp 加载顺序 |
| `diag*.sh` / `check*.sh` / `sweep.sh` / `status.sh` | 各种诊断与配置比对 | 排查工具 |
| `device-backup*.sh` / `backup-parts.sh` / `pull-and-prepare.sh` | `backup/` 里那些数据的采集脚本 | 只读拷贝，未写分区 |
| `toolchain.sh` / `install-clang.sh` / `link-lld.sh` / `tools-setup.sh` | WSL 工具链搭建 | clang-14 + ld.lld-14 |

## 容易踩的坑（都在这些脚本里踩过）

- `CLANG_FLAGS` 必须带 `--target=aarch64-linux-gnu --gcc-toolchain=/usr -no-integrated-as`，
  否则 kbuild 会自动加 `--prefix=/usr/bin/`，导致 `as: unrecognized option '-EL'`。
- `make` 会把 `--target=...` 当成自己的参数 → 用 bash 数组 `ARGS=( O=... "CC=..." )` 逐个传。
- `scripts/gcc-wrapper.py` 是 python2 语法 → 命令行传 `CC` 覆盖 Makefile 第 394 行。
- `.bss.rtic` 段 `relocation truncated to fit` → 必须 `LD=ld.lld-14`。
- `techpack/*/Kbuild` 改 `-Werror` 时必须保留行尾续行符 `\`，否则
  `recipe commences before first target`。
- `KERNEL_BUILD=0` **不能**全局传，会让 qcacld 找不到 `a_debug.h` / `qdf_status.h`。
- 改完 `vendor/vangogh_user_defconfig` 必须重跑该 defconfig（`olddefconfig` 只读 `.config`）。
- 生成的 `config/*autoconf.h` 不能包含整份 `.config`，否则与内核 `autoconf.h` 冲突
  （`redefinition of 'snd_event_notify'`）。

---

本目录下的全部脚本与 docs/、scripts/ 其余内容一样，以 GPL-2.0（GPL-2.0-only）发布，见仓库根目录 [`LICENSE`](../../LICENSE)。

