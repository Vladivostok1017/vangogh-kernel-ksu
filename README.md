# vangogh-kernel-ksu

面向 Xiaomi Mi 10 Lite Zoom（`vangogh`，M2002J9E）的自编译 ARM64 内核，内置 KernelSU。

| 项 | 值 |
|---|---|
| 设备 | Xiaomi Mi 10 Lite Zoom / `vangogh` / M2002J9E |
| SoC | Qualcomm SM7250 (lito)，ARM64 |
| 适用系统 | MIUI 13 `V13.0.7.0.SJVCNXM`（Android 12） |
| 内核基座 | Linux 4.19.157，`WeeAris/Driftwood_kernel_xiaomi_sm7250` @ `3f1ef13`（`android-4.19-standalone`） |
| KernelSU | v0.9.5，kprobe 模式，编译进内核 |
| 产物 | `Image`（ARM64 内核镜像）/ `boot.img`（boot header v2） |
| 前置条件 | Bootloader 已解锁；具备 `fastboot` 环境 |

当前发布版本见 [Releases](../../releases)，仓库内也随附同一批产物（[`artifacts/`](artifacts/README.md)）。

---

## 支持状态

| 项目 | 状态 | 说明 |
|---|---|---|
| 启动 MIUI 13 | 支持 | 实机验证 |
| Wi-Fi | 支持 | `CONFIG_QCA_CLD_WLAN=y`，驱动编入内核；5 GHz / 866 Mbps 实测连通并获取 IP |
| KernelSU root | 支持 | 内核内置 KSU v0.9.5，管理器授权后 `su` 可用 |
| Magisk 模块 | 支持 | KSU 可直接识别并迁移已有模块 |
| 音频 | **不支持** | 内核不含音频驱动，播放与通话均无声，见 [音频](#音频) |
| 相机 / 指纹 / 蓝牙 / 传感器 | 未验证 | 未做回归测试 |
| 其它 MIUI 版本 | 不支持 | boot header 中的 dtb 复用自 `V13.0.7.0.SJVCNXM` |

---

## 安装

### 1. 前置条件

- Bootloader 已解锁（未解锁时 `fastboot` 会拒绝写入）
- 已备份关键分区；采集脚本见 [`scripts/device-backup-partitions.sh`](scripts/device-backup-partitions.sh) 与 [`scripts/device-backup-firmware.sh`](scripts/device-backup-firmware.sh)
- 设备系统版本为 `V13.0.7.0.SJVCNXM`

### 2. 使用预编译镜像

从 [Releases](../../releases) 下载，或使用仓库内文件：

```bash
xz -dk artifacts/boot/out-c6-working-ksu-0.9.5.img.xz
sha256sum boot-vangogh-ksu-0.9.5.img        # 与 SHA256SUMS 中解压后的摘要比对
```

写入：

```bash
fastboot boot  boot-vangogh-ksu-0.9.5.img   # 临时启动，不写分区；重启即恢复原状
fastboot flash boot boot-vangogh-ksu-0.9.5.img   # 验证通过后再持久化
```

安装管理器（版本必须与内核内 KSU 一致，否则报 `INSTALL_FAILED_VERSION_DOWNGRADE`）：

```bash
adb uninstall me.weishu.kernelsu            # 仅当设备上已装有其它版本
adb install artifacts/apk/KernelSU_v0.9.5.apk
```

### 3. 从源码构建

见 [构建](#构建)。构建产物需按 [打包](#打包) 重新封装为 `boot.img` 后才能刷入。

### 4. 验证

```bash
adb shell uname -r                          # 期望 4.19.157-perf-g3f1ef13491d1-…
adb shell getprop sys.boot_completed        # 期望 1
adb shell "ip addr show wlan0 | grep inet"  # 期望有 IPv4 地址
```

KernelSU 管理器应显示「已安装 / 工作中」。

### 5. 回滚

```bash
fastboot flash boot stock-boot-V13.0.7.0.SJVCNXM.img   # 回到纯净原厂
fastboot flash boot magisk-boot-backup.img             # 回到原厂 + Magisk
```

两个镜像均由本机在刷写前导出，位于 Release 资产与 [`backup/boot/`](backup/README.md)。

---

## 构建

### 依赖

Linux 或 WSL2，Ubuntu 22.04 及以上：

```bash
sudo apt install clang-14 lld-14 llvm-14 gcc-aarch64-linux-gnu \
                 bc bison flex cpio rsync libssl-dev libelf-dev
```

磁盘需求 ≥ 20 GB（内核树约 1.4 GB）。

Debian/Ubuntu 只提供带版本号的二进制（`clang-14`、`ld.lld-14`、`llvm-ar-14`），而 kbuild 在 `LLVM=1`
下调用不带版本号的名字，`build.sh` 会在 `work/toolbin/` 内自动建立软链，无需手工配置。

### 命令

```bash
./build.sh                            # 拉源码 → 打补丁 → 编译 → out/arch/arm64/boot/Image
./build.sh --pack <原厂boot.img>      # 额外封装成可 fastboot 的 boot.img
./build.sh --clean                    # 清空 work/ 与 out/ 后重建
./build.sh --audio-wip                # 附带应用音频 dlkm 实验补丁（WIP，不保证可用）
```

| 环境变量 | 默认 | 说明 |
|---|---|---|
| `JOBS` | `nproc` | 并行编译任务数 |
| `WORK` | `./work` | 源码与工具链软链目录 |
| `OUT` | `./out` | 输出目录（`.config`、`Image`） |

固定版本：Driftwood `3f1ef13491d16039a3eca412237cb5f8ddf5800b`、KernelSU tag `v0.9.5`。

### 输出

```
out/arch/arm64/boot/Image     内核镜像
out/.config                   最终配置
```

### 配置

`config/vangogh_ksu.fragment` 会被追加进 `vendor/vangogh_user_defconfig`，关键项：

```ini
CONFIG_MIHW=y                    # 小米硬件抽象层，缺失时 MIUI 无法启动
CONFIG_MIGT=y
CONFIG_MILLET=y
CONFIG_MIGT_ENERGY_MODEL=y
CONFIG_SF_BINDER=y
CONFIG_PERF_CRITICAL_RT_TASK=y
CONFIG_QCA_CLD_WLAN=y            # Wi-Fi 驱动编入内核
CONFIG_KPROBES=y
CONFIG_KPROBE_EVENTS=y
CONFIG_KRETPROBES=y
CONFIG_KSU=y                     # KernelSU
```

修改 defconfig 后必须重新执行 `make vendor/vangogh_user_defconfig`（`olddefconfig` 只读 `.config`），
否则 `CONFIG_*` 不会生效。

### 打包

内核镜像不能单独刷入，需复用原厂 `boot.img` 的 header、dtb 与 AVB 尾部重新封装：

```bash
python3 scripts/pack_boot.py --src 原厂boot.img \
        --kernel out/arch/arm64/boot/Image \
        --out boot-ksu.img --pad 134217728
```

`pack_boot.py` 已通过逐字节往返校验：以原厂 kernel 重新打包，产物 sha256 与原文件一致。

---

## 设计说明

本节只列结论；实测数据、失败实验与完整推理见 [`docs/DESIGN.md`](docs/DESIGN.md)。

**驱动编入内核。** 设备为非 GKI 内核（4.19），MIUI 的 vendor 内核模块与任何第三方内核的
`CONFIG_MODVERSIONS` 符号 CRC 无法对齐（`qca_cld3_wlan.ko` 420 个依赖符号中仅 186 个一致），
放宽校验会导致加载后 panic。因此 Wi-Fi 等驱动以 `=y` 编入内核，不加载小米的 `.ko`。

**KernelSU 编译进内核。** KSU v1.0 起仅支持 GKI 2.0（5.10+），4.19 上只能用 v0.9.5，且必须内置，
不能以模块形式加载。采用 kprobe 模式，不修改内核源码。

**基座选择。** 官方 `MiCode` 仓库只有 `vangogh-q-oss`（Android 10 / 4.19.81），与设备 4.19.113 不匹配
且不含 MIUI S 代私有驱动。Driftwood 树继承自同平台机型 `picasso` 的 Android 11 公开源码，保留了
`MIHW` / `MIGT` / `MILLET` / `SF_BINDER` / `PERF_CRITICAL_RT_TASK`，是 MIUI 13 能正常启动的前提。

### 音频

内核**不包含**音频驱动。`techpack/audio` 内置（`KERNEL_BUILD=1`）会在启动阶段 panic：`q6adm`/`q6asm`
等驱动在 ADSP 固件就绪前即探测通道。MIUI 自身采用外置模式（`/vendor/lib/modules/audio_*.ko`，开机后
按序加载）。当前 `KERNEL_BUILD=0` 路线可以编译出 `Image`，但 `make modules` 仍存在重复符号
（`snd_event_*`、`msm_qti_pp_send_chmix_cfg_cmd`），尚未产出可加载的 `audio_*.ko`。

---

## 仓库结构

```
build.sh                              一键构建
patches/
  0001-core-build-fixes.patch         4.19 + clang 编译所需的 3 处源码修正与新头文件
  0002-techpack-audio-dlkm-wip.patch  techpack -Wno-error 与音频 dlkm 化实验（WIP）
  0003-vangogh-defconfig.patch        defconfig 改动
config/vangogh_ksu.fragment           追加到 defconfig 的关键配置
scripts/
  pack_boot.py                        boot.img 重打包（header v2，含 dtb）
  dump-dtb.py                         从 boot.img 提取 dtb
  read-pstore.sh                      读取崩溃日志（需 root）
  device-backup-partitions.sh         备份 EFS / 关键分区（需 root）
  device-backup-firmware.sh           备份引导链 / 固件分区（需 root）
  boottest.ps1                        Windows 侧一键 boot 测试
  release-artifacts.py                产物归档与校验清单生成
  setup/                              适配过程中使用的全部构建/诊断脚本及索引
artifacts/                            实机产物：boot 镜像、管理器 APK、原厂 config
backup/                               分区 / 固件 / 模块备份
docs/
  DESIGN.md                           技术设计与实测数据
  HANDOFF.md                          完整技术记录：结论、证据、卡点、下一步
  PUBLISH.md                          发布流程与仓库元数据
  releases/                           各版本发布说明存档
```

### 未随仓库发布的备份

`persist`、`modemst1`、`modemst2`、`fsg` 四个分区含本机身份数据（Wi-Fi MAC、指纹与传感器标定、
MI 账号标识、FIDO/MiPay/Widevine 密钥材料、IMEI），不进入本仓库及其历史。需要时在本机执行：

```bash
python3 scripts/release-artifacts.py --include-identity
```

逐项说明见 [`backup/README.md`](backup/README.md)。

---

## 已知限制

- KernelSU 停留在 **v0.9.5**：无 SUSFS、无 KPM，抗检测能力有限
- 管理器不提供模块 `action.sh` 执行入口，需手动：`su -c 'cd /data/adb/modules/<id> && sh action.sh'`
- Zygisk 类模块需要配合 ZygiskNext
- `adb shell`（uid 2000）不在 KSU 授权列表内，需先授权或用 Termux 执行 `su -c`
- 本内核不含音频驱动
- 仅适配 `V13.0.7.0.SJVCNXM`，其它版本未验证

---

## 故障排查

| 现象 | 原因 | 处理 |
|---|---|---|
| 管理器显示「未安装」 | 管理器版本与内核内 KSU 不一致（新版只认 GKI） | 卸载后安装 v0.9.5 |
| `INSTALL_FAILED_VERSION_DOWNGRADE` | 设备上已装更高版本管理器 | `adb uninstall me.weishu.kernelsu` 后重装 |
| `fastboot boot` 后重启回到原系统 | 预期行为，`boot` 不写分区 | 需持久化时用 `flash boot` |
| 开机卡在 Logo / 反复重启 | 内核与系统版本不匹配 | 刷回原厂 `boot.img` |
| `adb shell su` 提示未找到 | uid 2000 未授权 | 在管理器内授权，或改用 Termux |
| Wi-Fi 不可用 | 未启用 `CONFIG_QCA_CLD_WLAN=y` 或加载了原厂 `wlan.ko` | 检查 `out/.config`，勿加载 vendor 模块 |
| 编译报 `as: unrecognized option '-EL'` | kbuild 自动追加 `--prefix`，与系统 `as` 冲突 | 见 `docs/DESIGN.md` 的 `CLANG_FLAGS` 说明 |
| `drivers/Kconfig: can't open drivers/kernelsu/Kconfig` | KernelSU 未放在内核树的父目录 | 将 KernelSU 克隆到 `work/` 同级 |
| `配置项未生效: CONFIG_*` | 改了 defconfig 但未重新生成 `.config` | 重新执行 `make vendor/vangogh_user_defconfig` |

---

## 版本记录

| 版本 | 日期 | 内容 |
|---|---|---|
| v1.0.0 | 2026-11-23 | 首个可用构建：内核启动、Wi-Fi、KernelSU root、Magisk 模块迁移；不含音频。说明见 [`docs/releases/v1.0.0.md`](docs/releases/v1.0.0.md) |

---

## 文档索引

| 文档 | 内容 |
|---|---|
| [`docs/DESIGN.md`](docs/DESIGN.md) | 方案取舍、CRC 实测数据、已验证不可行的路线、音频机制 |
| [`docs/HANDOFF.md`](docs/HANDOFF.md) | 完整技术交接：环境重建、补丁清单、卡点与下一步 |
| [`docs/PUBLISH.md`](docs/PUBLISH.md) | 发布流程、仓库元数据、大仓库推送处理 |
| [`artifacts/README.md`](artifacts/README.md) | 产物清单与校验值 |
| [`backup/README.md`](backup/README.md) | 备份分区逐项说明与回写方式 |
| [`scripts/setup/README.md`](scripts/setup/README.md) | 历史脚本索引 |

---

## 许可证

- 仓库内脚本与文档：MIT（见 [`LICENSE`](LICENSE)）
- 内核补丁：遵循被修改源码的许可，GPL-2.0
- 内核源码版权归各自所有者（Xiaomi、Qualcomm、Linux 基金会等）

## 致谢

- [Driftwood Kernel](https://github.com/WeeAris/Driftwood_kernel_xiaomi_sm7250)（`android-4.19-standalone`）：内核基座与 MIUI 私有驱动
- [KernelSU](https://github.com/tiann/KernelSU) v0.9.5
- [PixelExperience `kernel_xiaomi_vangogh`](https://github.com/PixelExperience-Devices/kernel_xiaomi_vangogh)：设备树与 defconfig 参考
- MiCode `Xiaomi_Kernel_OpenSource` 的 `picasso-r-oss`：MIUI 驱动公开来源
- 上游 Linux 内核贡献者
