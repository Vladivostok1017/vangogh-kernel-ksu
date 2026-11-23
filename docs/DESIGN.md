# 技术设计说明

本文记录本项目的方案取舍与支撑数据。结论性描述见根目录 [`README.md`](../README.md)，
完整过程记录（含每次实验的命令与输出）见 [`HANDOFF.md`](HANDOFF.md)。

---

## 1. 约束

### 1.1 非 GKI 内核

设备出厂内核为 Linux 4.19.113，属 GKI 之前的版本。

- KernelSU 自 v1.0 起只支持 GKI 2.0（5.10+），4.19 上的最后一个官方版本为 **v0.9.5**（上游 issue #1705）。
- 非 GKI 内核无法以模块形式加载 KSU，必须编译进内核。
- v0.9.5 不支持 SUSFS 与 KPM。

### 1.2 上游源码缺失

`MiCode/Xiaomi_Kernel_OpenSource` 中与 SM7250 相关的分支：

| 分支 | 版本 | 与设备关系 |
|---|---|---|
| `vangogh-q-oss` | 4.19.81 / Android 10 | 设备为 4.19.113 / Android 12，且不含 MIUI S 代私有驱动 |
| `picasso-r-oss` | 4.19 / Android 11 | 同平台兄弟机型（Redmi K30 5G），含 MIUI 私有驱动 |

结论：不能直接用官方 `vangogh` 源码，需以继承自 `picasso-r-oss` 的第三方树为基座。

### 1.3 vendor 模块 ABI 不兼容

设备启用 `CONFIG_MODVERSIONS=y`，模块与内核通过逐符号 CRC 校验。`same_magic()` 在模块携带
CRC 时忽略版本号字符串，因此真正决定能否加载的是每个符号的 CRC 与 `module_layout`。

实测（内核取自本项目构建产物，模块取自设备的 `/vendor/lib/modules`）：

| 模块 | 一致符号 | 不一致符号 | 一致率 |
|---|---|---|---|
| `qca_cld3_wlan.ko` | 186 | 232 | 44% |
| `exfat.ko` | 40 | 84 | 32% |
| `audio_machine_lito.ko` | 21 | 46 | 31% |
| `audio_apr.ko` | 30 | 19 | 61% |

`module_layout` 亦不一致：模块期望 `0x2e17d2b3`，本项目内核为 `0x1ddb62a5`。

放宽校验的两次实验：

| 实验 | 结果 |
|---|---|
| 仅放宽 `module_layout` | 模块仍被逐符号 CRC 拒绝，加载失败 |
| 放宽全部符号 CRC | 模块可载入，但触发内核 panic（`struct module` 等结构布局与 MIUI 内核不同） |

结论：MIUI 的 `.ko` 无法用于任何第三方内核，这不是校验参数问题，而是 ABI 差异。

---

## 2. 方案

### 2.1 驱动编入内核

既然 vendor 模块不可用，就避免依赖它们：把需要的驱动以 `=y` 编入内核。

已采用：`CONFIG_QCA_CLD_WLAN=y`（Wi-Fi）。

需要注意该驱动的构建依赖 `techpack` 的编译环境；`KERNEL_BUILD` 变量不得全局传递，否则
qcacld 找不到 `a_debug.h` / `qdf_status.h`。

### 2.2 KernelSU 接入

- 版本固定 `v0.9.5`（tag `b766b985`），克隆到内核树的**父目录**：`drivers/kernelsu` 是指向
  `../../KernelSU/kernel` 的相对软链，位置错误会报 `drivers/Kconfig: can't open file`。
- 采用 **kprobe** 模式，不修改内核源码；需 `CONFIG_KPROBES` / `CONFIG_KPROBE_EVENTS` / `CONFIG_KRETPROBES`。
- 授权按 **uid** 进行：`adb shell`（uid 2000）不在默认授权列表内。

### 2.3 基座与必需配置

基座：`WeeAris/Driftwood_kernel_xiaomi_sm7250`，分支 `android-4.19-standalone`，
提交 `3f1ef13491d16039a3eca412237cb5f8ddf5800b`（Linux 4.19.157）。

该树保留了 MIUI 私有驱动，但默认配置不含下列项。早期使用 PixelExperience 内核树 + 原厂配置时
缺少其中 11 项，编出的内核在 MIUI 上 panic：

```
CONFIG_MIHW  CONFIG_MIGT  CONFIG_MILLET  CONFIG_MIGT_ENERGY_MODEL
CONFIG_MI_MEMORY_SYSFS  CONFIG_MI_RECLAIM  CONFIG_MIUI_ZRAM_MEMORY_TRACKING
CONFIG_SF_BINDER  CONFIG_PERF_CRITICAL_RT_TASK  CONFIG_FTS_FOD_AREA_REPORT
CONFIG_PACKAGE_RUNTIME_INFO
```

`config/vangogh_ksu.fragment` 固化了当前可用的子集。注意：`olddefconfig` 只读取 `.config`，
修改 defconfig 后必须重新执行 `make vendor/vangogh_user_defconfig`。

---

## 3. 源码补丁

`patches/0001-core-build-fixes.patch` 的内容：

| 文件 | 问题 | 修法 |
|---|---|---|
| `kernel/sched/tune.c` | `boost_write_wrapper` / `prefer_idle_write_wrapper` 定义在 `#ifdef CONFIG_STUNE_ASSIST` 内，却被无条件引用 | 补 `#ifdef` 守卫 |
| `drivers/power/supply/qcom/smb5-lib.h` | 成员 `use_bq_pump` 位于 `#ifdef CONFIG_BQ2597X_CHARGE_PUMP` 内，`qpnp-smb5.c` 无条件读取 | 将成员声明移出条件块 |
| `drivers/soc/qcom/msm_bus/msm_bus_core.h` | `#if 0` 关闭了真实声明，强制走 `static inline` 桩，与 `.c` 中的定义冲突 | 改为 `#ifdef CONFIG_DEBUG_FS` |
| `techpack/**/Kbuild` | `-Werror` 叠加 clang-14 警告导致编译中断 | 改为 `-Wno-error` |

---

## 4. 构建环境注意事项

以下问题均在 4.19 + clang-14 组合下出现过，`build.sh` 已处理，手工构建时需注意。

| 现象 | 原因 | 处理 |
|---|---|---|
| `as: unrecognized option '-EL'` | kbuild 自动追加 `--prefix=/usr/bin/`，使系统 `as` 参数解析错误 | 覆盖 `CLANG_FLAGS="--target=aarch64-linux-gnu --gcc-toolchain=/usr -no-integrated-as"` |
| `make: unrecognized option '--target=…'` | 赋值参数被 make 当作自身选项 | 用数组逐个传递，每个赋值作为单个 argv |
| `scripts/gcc-wrapper.py` 语法错误 | 该脚本为 Python 2 语法，Makefile 第 394 行默认经由它包装 `CC` | 命令行显式传 `CC=clang` 覆盖 |
| `.bss.rtic` 段 `relocation truncated to fit: R_AARCH64_ADR_PREL_PG_HI21` | 默认链接器处理远距离重定位失败 | 使用 `LD=ld.lld-14` |
| `techpack/*/Kbuild: recipe commences before first target` | 删除 `-Werror` 时连同行尾续行符 `\` 一起删掉 | 用 `s/-Werror/-Wno-error/g`，保留续行 |
| `redefinition of 'snd_event_notify'` | 手工生成的 `config/*autoconf.h` 把整份 `.config` 都 `#define`，与内核 `autoconf.h` 冲突 | 清空这些生成文件 |
| `'a_debug.h' / 'qdf_status.h' not found` | 全局传入了 `KERNEL_BUILD=0` | 该变量不得全局传递 |

---

## 5. 音频

### 5.1 两种构建模式

`techpack/audio` 由 `KERNEL_BUILD` 变量切换：

```makefile
ifeq ($(KERNEL_BUILD), 1)   # 内置：obj-y 编入 vmlinux
ifeq ($(KERNEL_BUILD), 0)   # 外置：每个子系统产出 *_dlkm.ko
```

### 5.2 内置模式失败

音频代码全部 `=y` 时，内核在启动阶段 panic。原因是 `q6adm` / `q6asm` 等驱动在内核初始化
早期即探测 ADSP 通道，而 ADSP 固件此时尚未由用户空间加载。

外置模式需要 `AUDIO_ROOT` 指向 `techpack/audio`，并生成 `config/litoauto.conf`，否则报
`defconfig 失败: /config/litoauto.conf`。

### 5.3 当前状态与下一步

- `KERNEL_BUILD=0` 路线可编译出 `Image`（音频代码不进内核）。
- `make modules` 仍失败于重复符号与重复定义：`msm_qti_pp_send_chmix_cfg_cmd`、
  `snd_event_*`、`audio_ssr_*`。原因是批量改写 Kbuild 时 `*_OBJS` 列表被两个分支重复追加。
- 下一步：
  1. 逐个 dlkm 组核对 `*_OBJS` 唯一性（约 40 个 Kbuild）
  2. 从设备 `/vendor/lib/modules/modules.load` 与 `modules.dep` 取真实加载顺序（需 root）
  3. 打包为 KernelSU 模块，用 `service.sh` 在开机后按序 `insmod`
  4. `setprop ctl.restart audioserver` 使 HAL 使用新声卡

### 5.4 相关标定数据

扬声器功放（`cs35l41`）的单元级标定位于 `persist/audio/`（`cs35l41_cal.txt`、`cs35l41_cal.bin`、
`us_cal_v2`）。该分区未纳入本仓库，见 [`../backup/README.md`](../backup/README.md)。

---

## 6. 已验证不可行的路线

记录于此以避免重复投入：

1. 使用官方 `vangogh-q-oss`（4.19.81 / Android 10）编译：版本与私有驱动均不匹配
2. 使用 PixelExperience 的 `kernel_xiaomi_vangogh` + 原厂配置：缺少 11 项 MIUI 私有驱动，MIUI 上 panic
3. 让 MIUI 的 `.ko` 加载进自编内核：CRC / ABI 不兼容，放宽校验后 panic（见 1.3）
4. 将音频全部编入内核：ADSP 初始化顺序导致 panic（见 5.2）
5. 移植 SukiSU Nova 至 4.19：受阻于 `file_operations`（`iopoll` / `remap_file_range`）、
   `security_inode_init_security_anon`、fsnotify `handle_inode_event`、`SECCOMP_ARCH_NATIVE_NR`、
   SELinux `avtab` / `flex_array` / `filename_trans_key` 等 4.19 不存在的接口与内部结构

补充：`MODULE_IMPORT_NS` 为 5.4+ 引入；`strncpy_from_user_nofault` 系列与 `untagged_addr`
在 4.19 中不存在，需 compat 头。这几项已通过版本守卫与 shim 绕过，但上述 5 条的阻塞点不在此列。

---

## 7. 测量方法

CRC 比对（`scripts/setup/crc-compare.py`）：

1. 用构建产物 `out/.config` 与 `Module.symvers` 得到内核侧各导出符号的 CRC
2. 用 `readelf -x __versions <module>.ko` 读取模块期望的 CRC
3. 逐符号求交并统计一致率

`module_layout` 的期望值同样来自 `__versions` 段。

---

## 8. 参考

- Driftwood Kernel `android-4.19-standalone` @ `3f1ef13`
- KernelSU v0.9.5（`b766b985`），issue #1705（非 GKI 支持终止说明）
- PixelExperience `kernel_xiaomi_vangogh`
- MiCode `Xiaomi_Kernel_OpenSource` → `picasso-r-oss`
- Linux 4.19 文档：`Documentation/kbuild/`、`Documentation/modules.rst`
