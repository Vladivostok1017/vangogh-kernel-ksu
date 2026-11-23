# vangogh-kernel-ksu

在**小米10青春版（Mi 10 Lite Zoom / Youth Edition，代号 `vangogh`）**的 MIUI 13 上运行 **KernelSU** 的自编译内核项目。

> 设备：M2002J9E · SM7250 (lito) · MIUI 13 `V13.0.7.0.SJVCNXM` · Android 12 · 内核 4.19.113 · **非 GKI**

---

## 状态

| 功能 | 状态 | 说明 |
|---|---|---|
| 内核启动 MIUI 13 | ✅ | Linux 4.19.157 |
| WiFi | ✅ | 驱动内置（不依赖小米的 `wlan.ko`） |
| **KernelSU root** | ✅ | KernelSU v0.9.5（非 GKI 最后支持版本） |
| Magisk 模块迁移 | ✅ | KSU 直接识别 `action.sh` 之外的模块 |
| 音频 | ❌ | 见 [Roadmap](#roadmap) |
| 相机 / 指纹 | ⚠️ 未测 | 依赖 vendor 模块的部分可能受影响 |

---

## 为什么这个项目存在

这台设备的特殊性在于：

1. **它是非 GKI 内核（4.19）** → KernelSU 从 v1.0 起只支持 GKI 2.0（5.10+），所以只能用 **v0.9.5**，且必须**把 KSU 编进内核**（不能像 GKI 那样做成 `.ko` 加载）。
2. **小米没有公开 MIUI 13 对应的内核源码** → 官方 `MiCode/Xiaomi_Kernel_OpenSource` 只有 `vangogh-q-oss`（Android 10 / 4.19.81），而设备跑的是 4.19.113。
3. **MIUI 的 vendor 内核模块无法加载到第三方内核** →
   实测逐符号 CRC 比对（`qca_cld3_wlan.ko` 420 个依赖符号）：

   | 模块 | 一致 | 不一致 | 一致率 |
   |---|---|---|---|
   | `qca_cld3_wlan.ko` | 186 | 232 | **44%** |
   | `exfat.ko` | 40 | 84 | 32% |
   | `audio_machine_lito.ko` | 21 | 46 | 31% |
   | `audio_apr.ko` | 30 | 19 | 61% |

   `module_layout` 也不一致（模块期望 `0x2e17d2b3`，官方内核 `0x1ddb62a5`）。
   放宽 CRC 校验解决不了：只放宽 `module_layout` → 模块仍被逐符号拒绝；全部放宽 → 模块能载入但内核 panic。

**本项目的核心思路**：既然小米的模块用不了，那就**不用小米的模块**——把驱动（WiFi 等）编进内核，绕开 ABI 问题。

内核源码基座选的是社区维护的 **Driftwood**（`WeeAris/Driftwood_kernel_xiaomi_sm7250`），它从同平台兄弟机型（`picasso`，Redmi K30 5G）的 Android 11 公开源码继承而来，**保留了 MIUI 私有驱动**（`MIHW` / `MIGT` / `MILLET` / `SF_BINDER` / `PERF_CRITICAL_RT_TASK`）——这正是让 MIUI 13 能正常启动的关键。

---

## 快速开始

### 环境

- Linux / WSL2 Ubuntu 22.04+
- `clang-14`、`lld-14`、`llvm-14`、`gcc-aarch64-linux-gnu`、`bc bison flex cpio rsync libssl-dev libelf-dev`
- 磁盘 ≥ 20 GB（内核树约 1.4 GB）

```bash
sudo apt install clang-14 lld-14 llvm-14 gcc-aarch64-linux-gnu \
                 bc bison flex cpio rsync libssl-dev libelf-dev
```

### 构建

```bash
./build.sh                 # 全自动：拉源码 → 打补丁 → 编译 → 产出 Image
./build.sh --pack <原厂boot.img>   # 额外打包成可 fastboot 的 boot.img
```

产物：`out/arch/arm64/boot/Image`

### 打包 & 刷入

```bash
python3 scripts/pack_boot.py --src 原厂boot.img --kernel out/arch/arm64/boot/Image \
        --out boot-ksu.img --pad 134217728

fastboot boot   boot-ksu.img   # 先临时验证（不写分区，重启即恢复）
fastboot flash boot boot-ksu.img   # 确认无误后持久化
```

> `pack_boot.py` 复用原厂 boot 镜像的 header / dtb / AVB 尾部，只替换 kernel 载荷；
> 已通过**逐字节往返校验**（用原厂 kernel 重新打包，sha256 与原文件完全一致）。

### 回滚

```bash
fastboot flash boot 原厂boot.img
```

---

## 仓库结构

```
patches/
  0001-core-build-fixes.patch            # 让该树能用 vangogh 配置在 4.19 编译（3 处）
  0002-techpack-audio-dlkm-wip.patch     # techpack: -Wno-error + 音频 dlkm 化（WIP）
  0003-vangogh-defconfig.patch           # defconfig 改动
config/
  vangogh_ksu.fragment                   # 需要追加到 defconfig 的关键配置项
scripts/
  pack_boot.py                           # boot.img 重打包（header v2，含 dtb）
  dump-dtb.py                            # 从 boot.img 提取 dtb
  read-pstore.sh                         # 读取崩溃日志（需 root）
  device-backup-partitions.sh            # 备份 EFS/关键分区（需 root）
  device-backup-firmware.sh              # 备份引导链/固件分区（需 root）
  boottest.ps1                           # Windows 侧一键 boot 测试
docs/
  HANDOFF.md                             # 完整技术交接：结论、证据、卡点、下一步
build.sh
```

---

## 必须的源码补丁（`patches/0001`）

| 文件 | 问题 | 修法 |
|---|---|---|
| `kernel/sched/tune.c` | `boost_write_wrapper` / `prefer_idle_write_wrapper` 定义在 `#ifdef CONFIG_STUNE_ASSIST` 内，却被无条件引用 | 补 `#ifdef` 守卫 |
| `drivers/power/supply/qcom/smb5-lib.h` | `use_bq_pump` 成员在 `#ifdef CONFIG_BQ2597X_CHARGE_PUMP` 内，`qpnp-smb5.c` 无条件读取 | 成员声明提出条件块 |
| `drivers/soc/qcom/msm_bus/msm_bus_core.h` | `#if 0` 关掉了真实声明，强制走 `static inline` 桩，与 `.c` 定义冲突 | 改为 `#ifdef CONFIG_DEBUG_FS` |
| `techpack/**/Kbuild` | `-Werror` + clang-14 警告 → 编译失败 | 改 `-Wno-error` |

`config/vangogh_ksu.fragment` 中的关键项：

```ini
CONFIG_MIHW=y          # 小米硬件抽象层（缺了 MIUI 起不来）
CONFIG_MIGT=y
CONFIG_MILLET=y
CONFIG_MIGT_ENERGY_MODEL=y
CONFIG_SF_BINDER=y
CONFIG_PERF_CRITICAL_RT_TASK=y
CONFIG_QCA_CLD_WLAN=y  # WiFi 驱动内置（关键：绕开小米模块）
CONFIG_KPROBES=y
CONFIG_KPROBE_EVENTS=y
CONFIG_KRETPROBES=y
CONFIG_KSU=y           # KernelSU，走 kprobe，无需改内核源码
```

---

## Roadmap

### 音频（当前主要缺口）

`techpack/audio` 支持两种构建模式（`KERNEL_BUILD` 变量）：

```makefile
ifeq ($(KERNEL_BUILD), 1)   # 内置 → obj-y 编进 vmlinux
ifeq ($(KERNEL_BUILD), 0)   # 外置 → 每个子系统一个 *_dlkm.ko
```

- **内置模式实测会导致启动崩溃**：`q6adm/q6asm` 等驱动在内核早期就探测 ADSP 通道，此时 ADSP 固件尚未加载。
- MIUI 自身用的是**外置模式**（`/vendor/lib/modules/audio_*.ko`，开机后按序加载）。

当前进度：`KERNEL_BUILD=0` 路线已能让 **Image 编译通过**（音频代码不进内核），但 `make modules` 仍有**重复符号**问题（`snd_event_*`、`msm_qti_pp_send_chmix_cfg_cmd`），源于批量改写 Kbuild 时 `*_OBJS` 列表被重复追加。

下一步（正确做法）：
1. 逐个 dlkm 组核对 `*_OBJS` 唯一性（约 40 个 Kbuild）
2. 从设备的 `/vendor/lib/modules/modules.load|modules.dep` 取真实加载顺序（需 root）
3. 打包成 KernelSU 模块，用 `service.sh` 在开机后 `insmod`
4. `setprop ctl.restart audioserver` 让 HAL 使用新声卡

### 其它

- [ ] 验证相机 / 指纹 / 蓝牙 / 传感器
- [ ] 补 ramoops 节点以便捕获 panic（原厂 DT 无 ramoops，当前崩溃无日志）
- [ ] 评估 SukiSU / 新版 KSU 移植（受限于 4.19 的 SELinux 内部结构差异，见 docs）

---

## 已验证**行不通**的路线（避免重复踩坑）

1. 用官方 `vangogh-q-oss`（4.19.81/A10）编译 → 与设备 4.19.113 不匹配，且无 MIUI S 代驱动
2. 用 PixelExperience 的 vangogh 内核树 + 原厂配置 → 缺 11 个 MIUI 私有驱动
3. 让 MIUI 的 `.ko` 加载到自编内核 → CRC/ABI 不兼容（见上文数据）
4. 把音频全部编进内核 → ADSP 初始化顺序导致 panic
5. SukiSU Nova 移植到 4.19 → 卡在 `file_operations`(iopoll/remap_file_range)、`security_inode_init_security_anon`、fsnotify `handle_inode_event`、`SECCOMP_ARCH_NATIVE_NR`、SELinux `avtab`/`flex_array`/`filename_trans_key`

详细证据与命令见 [`docs/HANDOFF.md`](docs/HANDOFF.md)。

---

## 已知限制

- KernelSU **v0.9.5** 是最后一个支持非 GKI 的官方版本：无 SUSFS、无 KPM，**抗检测能力弱**
- KSU 管理器不提供模块「执行」按钮，需手动：`su -c 'cd /data/adb/modules/<id> && sh action.sh'`
- Zygisk 类模块需要 **ZygiskNext** 才能在 KSU 下工作
- `adb shell su` 需要把 shell（uid 2000）加入白名单；否则请用 Termux 执行 `su -c`
- 本项目产出的内核**不含音频驱动**

---

## 风险提示

刷写自定义内核存在变砖风险。请务必：

1. **先备份**（`scripts/device-backup-partitions.sh` + `device-backup-firmware.sh`），尤其是 `modemst1/modemst2`（IMEI/EFS）、`persist`
2. **先用 `fastboot boot` 临时验证**，确认能启动再 `flash`
3. 保留原厂 `boot.img` 以便随时回滚

---

## 致谢 / Credits

- [Driftwood Kernel](https://github.com/WeeAris/Driftwood_kernel_xiaomi_sm7250)（`android-4.19-standalone`）—— 内核基座与 MIUI 私有驱动
- [KernelSU](https://github.com/tiann/KernelSU) v0.9.5 —— 非 GKI 最后支持版本
- [PixelExperience](https://github.com/PixelExperience-Devices/kernel_xiaomi_vangogh)（`thirteen`）—— 设备树 / defconfig 参考
- MiCode `Xiaomi_Kernel_OpenSource` 的 `picasso-r-oss` —— MIUI 驱动的原始公开来源
- 所有上游 Linux 内核贡献者

## 许可

- 本项目中的**脚本与文档**：MIT
- **内核补丁**：遵循被修改内核的许可（GPL-2.0）
- 内核源码本身版权归各自所有者（Xiaomi / Qualcomm / Linux 基金会等）
