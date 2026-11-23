# backup/ — 刷机前的设备备份（不可再生）

这些文件是在**动任何分区之前**从设备上只读拷出来的。`boot` 之外的每一项都无法从
官方 ROM 包里还原：`persist`、`modemst1/2`、`fsg`、`sec`、`devinfo`、`devcfg` 里
装着本机的射频校准、传感器标定、DRM/密钥类数据以及 BL 解锁状态。写坏其中任何一个，
轻则丢基带/掉指纹，重则变砖且官方售后也无法用刷机包修好。

> **本机数据提醒**：这部分内容是**这台设备**的原始数据（含射频校准等设备唯一信息）。
> 仓库照原样保留以便完整复现与救援；如果要 fork 后公开分发，建议先评估是否要保留
> `persist/`、`modemst*`、`fsg`、`sec`、`devinfo` 这几项，或改为私有 Release 附件。

所有 `.img` 以 `xz -6` 存放，校验见 `SHA256SUMS`（同时记录压缩包与解压后摘要）。

```bash
xz -dk backup/boot/stock-v13.0.7.0.img.xz
sha256sum backup/boot/stock-v13.0.7.0.img   # 对比 SHA256SUMS 中 (decompressed) 行
```

## boot/ — 引导镜像

| 文件 | raw 大小 | sha256 (raw) | 说明 |
|---|---|---|---|
| `stock-v13.0.7.0.img` | 128 MiB | `e6fd536426687d74320d768f22561302c53dc4d7577a9ef61d0ffdb894898141` | 原厂 boot，未打补丁。`fastboot flash boot` 即可回到纯净 MIUI。 |
| `magisk-patched-boot.img` | 128 MiB | `6846866f2ba48666d7ed0f5bf4b3820a989762f5f6fb2ef7ef8cf60c6a5d1c1e` | 刷本项目内核**之前**设备上正在用的 boot（原厂 + Magisk 30.7 修补）。回滚到"有 root 的原厂"用这个。 |

## partitions/ — 分区表相关镜像

| 文件 | raw 大小 | 说明 |
|---|---|---|
| `dtbo.img.xz` | 32 MiB | device tree overlay。改内核不动它，但换 ROM 会用上。 |
| `vbmeta.img.xz` | 128 KiB | 校验链。解锁 BL 后已被置为 disable-verity/verification 状态。 |
| `misc.img.xz` | 4 MiB | 启动模式标志位（recovery/bootloader 跳转）。 |
| `devinfo.img.xz` | 16 MiB | 含 BL 解锁状态。 |
| `devcfg.img.xz` | 256 KiB | 设备配置。 |
| `fsg.img.xz` | 8 MiB | 调制解调器文件系统（EFS 备份区）。 |
| `modemst1.img.xz` / `modemst2.img.xz` | 各 8 MiB | **IMEI / 射频校准**。丢了只能靠这两个文件救。 |
| `persist.img.xz` | 64 MiB | 指纹、传感器标定、Widevine 等。 |
| `sec.img.xz` | 32 KiB | 安全分区。 |

回写示例（**确认分区名后再执行**）：

```bash
fastboot flash dtbo    dtbo.img
fastboot flash modemst1 modemst1.img
fastboot flash modemst2 modemst2.img
fastboot flash persist persist.img
fastboot flash fsg     fsg.img
```

## firmware/ — bootloader 与固件分区

`abl`、`xbl`、`xbl_config`、`aop`、`tz`、`hyp`、`keymaster`、`qupfw`、`storsec`、
`uefisecapp`、`imagefv`、`featenabler`、`bluetooth`、`dsp`、`modem`、`logo`。

这些是**升级/降级链路上的高危分区**。正常只改内核时完全用不到；只有把 `xbl`/`abl`
写坏到进不了 fastboot 时才需要它们配合 EDL 模式救砖。`modem.img`（320 MiB，压缩后
65.6 MiB）是完整的调制解调器固件镜像。

> 刷这些分区属于"救砖"操作，与内核项目本身无关。仓库保留它们的原因只有一个：
> 万一哪天要在本机回滚，素材是齐的。

## ko/ — 原厂内核模块样本

从设备 `/vendor/lib/modules` 拷出来的 MIUI 模块，用来做 `CONFIG_MODVERSIONS` 的逐符号
CRC 对比（结论见根目录 `README.md` 与 `docs/HANDOFF.md`）：

| 文件 | 说明 |
|---|---|
| `qca_cld3_wlan.ko` | WLAN 驱动。因为它的 CRC 与自编内核只有 44% 对得上，才改成**编进内核**（`CONFIG_QCA_CLD_WLAN=y`）。 |
| `audio_apr.ko` / `audio_machine_lito.ko` | 音频链路模块，正是当前未解决的音频适配目标。 |
| `exfat.ko` / `lcd.ko` / `rmnet_perf.ko` | 其余抽样样本。 |

这些 `.ko` 保持原样（不压缩），方便直接用 `modinfo`、`readelf -x __versions` 检查。
