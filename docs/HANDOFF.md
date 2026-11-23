# 小米10青春版 (vangogh) KernelSU 内核移植 — 交接文档

生成时间：本轮会话结束时
设备：M2002J9E / vangogh / SM7250 lito / MIUI 13 (V13.0.7.0.SJVCNXM) / Android 12 / 内核 4.19.113 非GKI

---

## 一、已达成（可用的成果）

| 项目 | 状态 | 证据 |
|---|---|---|
| 自编内核在 MIUI 13 上启动 | ✅ | `uname -r` = 4.19.157-perf-g3f1ef13491d1-dirty，`sys.boot_completed=1` |
| WiFi 正常（驱动内置，不依赖小米模块） | ✅ | `wlan0` 已连 5GHz，`cmd wifi status` 显示 COMPLETED、866Mbps、已获 IP |
| KernelSU root | ✅ | 管理器识别，Termux 授权后 `su -c id` = uid=0 |
| Magisk 模块自动迁移到 KSU | ✅ | /data/adb/modules 被 KSU 识别 |

**产物**：`F:\vanilla-build\out-c6.img`（128MB boot 镜像，内核 43.1MB）
- 内含：Driftwood 4.19.157 + MIUI 私有驱动(MIHW/MIGT/MILLET/SF_BINDER/PERF_CRITICAL) + QCA_CLD_WLAN(内置) + KernelSU 0.9.5(kprobe)
- **无音频**

**验证方式（不写分区）**：
```
fastboot boot F:\vanilla-build\out-c6.img
```

**持久化**（确认后）：
```
fastboot flash boot F:\vanilla-build\out-c6.img
```

**回滚**：
```
fastboot flash boot F:\vanilla-build\backup\bk-partitions\boot.img    # 当前 Magisk 版
fastboot flash boot F:\vanilla-build\backup\boot-stock-v13.0.7.0.img  # 纯原厂
```

---

## 二、已验证行不通的路线（不要重复走）

1. **官方 MiCode `vangogh-q-oss` 源码**：4.19.81/A10，与设备运行的 4.19.113/A12 不匹配，且不含 MIUI S 代私有驱动 → 起不来。
2. **PE 树 + 原厂配置**：缺 MIHW/MILLET 等 11 个 MIUI 私有驱动 → 起不来。
3. **依赖 MIUI 的 vendor 模块**（`/vendor/lib/modules/*.ko`）：逐符号 CRC 比对一致率仅 31~61%（wlan 44%、exfat 32%），`module_layout` 也不符；
   - 只放宽 `module_layout` → 仍 0 模块加载；
   - 全部放宽 → 模块能载入但内核 panic（`struct module` 等 ABI 不一致）。
   → **结论：MIUI 的 .ko 在第三方内核下不可用；必须自带驱动。**
4. **音频编进内核（c2）**：起不来。原因是音频驱动（q6/adsp 依赖）在内核早期探测时 ADSP 尚未就绪。
5. **SukiSU Nova 移植到 4.19**：卡在 `file_operations`(iopoll/remap_file_range)、`security_inode_init_security_anon`、fsnotify `handle_inode_event`、seccomp `SECCOMP_ARCH_NATIVE_NR`、**SELinux `avtab`/`flex_array`/`filename_trans_key` 内部结构**。需重写策略层，非 shim 可解。

---

## 三、音频的剩余工作（下一步从这里开始）

### 关键机制（已查明）
`techpack/audio` 支持两种构建模式，由变量 `KERNEL_BUILD` 切换：
```makefile
ifeq ($(KERNEL_BUILD), 1)   # 内置：obj-y，编进 vmlinux
ifeq ($(KERNEL_BUILD), 0)   # 外置：每个子系统一个 *_dlkm.ko
```
MIUI 自身用的是 **外置模式**（`audio_*.ko`，在 ADSP 起来后按序加载）。

### 已完成的改造
- `techpack/audio/**/Kbuild` 中 `ifeq ($(KERNEL_BUILD), 1)` → 改为 `1_DISABLED`（禁用内置列表）
- 同上 `ifeq ($(KERNEL_BUILD), 0)` → 改为 `ifeq (0, 0)`（恒真，启用模块定义）
- `asoc/codecs/Kbuild` 末尾追加 `obj-m += wcd938x/ bolero/ wsa883x/ ...` 以进入子目录
- 生成 `techpack/audio/config/litoauto.conf`（来自 .config），`*autoconf.h` 必须**留空**（否则与内核 autoconf.h 重复定义）
- 注释掉全部 `KBUILD_EXTRA_SYMBOLS`（小米 OUT 路径）
- 编译需传 `AUDIO_ROOT=<树>/techpack/audio`；**不要**全局传 `KERNEL_BUILD=0`（会破坏 qcacld/wifi 的头文件路径）

### 当前阻塞点
`make modules` 报**重复符号/重复定义**：`snd_event_*`、`audio_ssr_*`、`msm_qti_pp_send_chmix_cfg_cmd`。
原因：粗略补丁使部分 `*_OBJS` 变量被两个分支重复追加，同一 `.o` 被编进同一模块两次。

### 正确的下一步
不要继续用 sed 批量改。应当：
1. 逐个 dlkm 组（`q6_dlkm` / `adsp_loader_dlkm` / `audio_machine_lito_dlkm` / `audio_wcd938x_dlkm` / `audio_bolero_cdc_dlkm` / `audio_swr_dlkm` / `snd_event_dlkm` …）核对 `*_OBJS` 的唯一性；
2. 按 MIUI 的 `modules.load`/`modules.dep`（可从 `/vendor/lib/modules/` 取得，需 root）确定加载顺序；
3. 打包为 KernelSU 模块，用 `service.sh` 在开机后 `insmod`（KSU 模块目录 `/data/adb/modules/<id>/`，脚本中可用 `$MODDIR`）；
4. `audioserver` 需重启才会使用新声卡：`setprop ctl.restart audioserver`。

---

## 四、工程环境（重建方法）

- WSL Ubuntu 24.04，工具链：`clang-14` + `ld.lld-14`（`~/bin` 内建 clang/ld.lld/llvm-* 软链）
- 内核树：`~/work/driftwood`（`WeeAris/Driftwood_kernel_xiaomi_sm7250` 的 `android-4.19-standalone` 分支）
- 构建命令（无音频版）：
```bash
export PATH=$HOME/bin:$PATH
cd ~/work/driftwood
MAKE=( O=$HOME/work/out-c5 ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
       CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 \
       "KCFLAGS=-Wno-unused-but-set-variable -Wno-unused-variable" )
make -j8 "${MAKE[@]}" vendor/vangogh_user_defconfig
make -j8 "${MAKE[@]}" olddefconfig
make -j16 "${MAKE[@]}" Image
```
- 打包：`python3 F:\vanilla-build\setup\pack_boot.py --src <原厂boot.img> --kernel <Image> --out <out> --pad 134217728`
  （该打包器已通过逐字节往返校验，复用原厂 header + dtb + AVB 尾部）

### 必要的源码补丁（让该树能在 4.19 且用 vangogh 配置编译）
1. `kernel/sched/tune.c`：两个 `*_write_wrapper` 加 `#ifdef CONFIG_STUNE_ASSIST`
2. `drivers/power/supply/qcom/smb5-lib.h`：`use_bq_pump` 移出 `#ifdef CONFIG_BQ2597X_CHARGE_PUMP`
3. `drivers/soc/qcom/msm_bus/msm_bus_core.h`：`#if 0` → `#ifdef CONFIG_DEBUG_FS`
4. `techpack/**/Kbuild`：`-Werror` → `-Wno-error`
5. defconfig 追加：`MIHW/MIGT/MILLET/MIGT_ENERGY_MODEL/SF_BINDER/PERF_CRITICAL_RT_TASK/QCA_CLD_WLAN/KPROBES/KPROBE_EVENTS/KRETPROBES/KSU`

---

## 五、备份清单（`F:\vanilla-build\backup\`）

- `bk-partitions/`：boot(Magisk版)、dtbo、vbmeta、vbmeta_system、misc、devinfo、devcfg、modemst1、modemst2、fsg、persist、sec
- `bk-firmware/`：abl、xbl、xbl_config、aop、tz、hyp、keymaster、qupfw、storsec、uefisecapp、imagefv、featenabler、bluetooth、dsp、modem、logo
- `boot-stock-v13.0.7.0.img`：纯原厂 boot（packer 的 header 来源）

---

## 六、已知限制

- KernelSU 0.9.5 是最后一个支持非 GKI 的官方版本（1.0 起移除）；无 SUSFS、无 KPM，抗检测弱
- KSU 管理器不提供模块「执行(action.sh)」按钮，需手动：`su -c 'cd /data/adb/modules/<id> && sh action.sh'`
- Zygisk 类模块在 KSU 下不生效（需 ZygiskNext）
- `adb shell su` 需把 shell(uid 2000) 加入白名单；否则用 Termux 的 `su -c`
- 该内核未启用 ramoops/pstore（原厂 DT 无 ramoops 节点），崩溃无法留日志
