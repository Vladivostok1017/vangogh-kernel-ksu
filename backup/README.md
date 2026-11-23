# backup/ — 刷机前的设备备份

这些文件是在**动任何分区之前**从设备上只读拷出来的。除了 `boot/` 里的原厂镜像能
从官方 ROM 包里再拿到，其余都是当时现场取的。

所有 `.img` 以 `xz -6` 存放，校验见 `SHA256SUMS`（同时记录压缩包与解压后摘要）。

```bash
xz -dk backup/boot/stock-v13.0.7.0.img.xz
sha256sum backup/boot/stock-v13.0.7.0.img   # 对比 SHA256SUMS 中 (decompressed) 行
```

---

## ⚠️ 有四个分区**故意不在**这个仓库里

| 分区 | 里面的内容 | 为什么不公开 |
|---|---|---|
| `persist.img` | Wi-Fi MAC；汇顶指纹标定；加速度计/陀螺/马达/功放标定；面板色彩标定与批次号；`data/` 下 MI 账号 ID、FIDO 凭据、MiPay 密钥、Widevine 供给与授权 | 本机身份 + 账号标识 + 密钥材料 |
| `modemst1.img` | EFS2 NV 库：IMEI / MEID、射频校准、SIM 锁 | IMEI 是设备永久身份 |
| `modemst2.img` | 同上（第二份镜像） | 同上 |
| `fsg.img` | 出厂 golden copy，可把上面两个恢复回出厂态 | 同上 |

它们仍然完整保存在**本机** `F:\vanilla-build\backup\partitions\bk-partitions\`。
需要重新导出到仓库（仅限本地留档）时：

```bash
python3 scripts/release-artifacts.py --include-identity
```

> 顺带一句：这几个文件对别人基本没用 —— `persist/data/` 里的密钥是 TEE 硬件绑定的，
> 换机解不开；标定数据只对同一颗传感器有意义；射频校准拷贝到别的机器上只会让信号
> 更差。不让它们进公开历史的理由只有一条：IMEI 和 MI 账号 ID 一旦被爬到就是永久
> 留痕，删不干净。

---

## boot/ — 引导镜像

| 文件 | raw 大小 | sha256 (raw) | 说明 |
|---|---|---|---|
| `stock-v13.0.7.0.img` | 128 MiB | `e6fd536426687d74320d768f22561302c53dc4d7577a9ef61d0ffdb894898141` | 原厂 boot，未打补丁。`fastboot flash boot` 即可回到纯净 MIUI。 |
| `magisk-patched-boot.img` | 128 MiB | `6846866f2ba48666d7ed0f5bf4b3820a989762f5f6fb2ef7ef8cf60c6a5d1c1e` | 刷本项目内核**之前**设备上正在用的 boot（原厂 + Magisk 30.7 修补）。回滚到"有 root 的原厂"用这个。 |

这两个镜像里没有任何身份数据（内核 + ramdisk + dtb + AVB 尾部），可以放心公开。

## partitions/ — 分区镜像（已逐字节核过内容）

| 文件 | raw 大小 | 实测内容 |
|---|---|---|
| `dtbo.img.xz` | 32 MiB | 官方 FDT overlay，通用，非本机独有 |
| `vbmeta.img.xz` | 128 KiB | AVB0 校验链，解锁后已置 disable-verity/verification |
| `misc.img.xz` | 4 MiB | 只有 31 个非零字节：残留启动命令 `bootonce-bootloader` + `boot-system0`，无身份信息 |
| `devinfo.img.xz` | 16 MiB | 只有 15 个非零字节：`ANDROID-BOOT!` 魔数 + `0x90`、`0x8a0` 两个 `01` 标志位（BL 解锁状态）。改它等于改锁状态，不是身份数据 |
| `devcfg.img.xz` | 256 KiB | 官方签名的设备配置 ELF，通用 |
| `sec.img.xz` | 32 KiB | **全 0**（32768 字节里非零字节 0 个），这台设备上没有任何内容 |

回写示例（**确认分区名后再执行**）：

```bash
fastboot flash dtbo  dtbo.img
fastboot flash misc  misc.img
fastboot flash devinfo devinfo.img   # ⚠️ 会覆盖 BL 解锁标志，一般不要动
```

## firmware/ — bootloader 与固件分区

`abl`、`xbl`、`xbl_config`、`aop`、`tz`、`hyp`、`keymaster`、`qupfw`、`storsec`、
`uefisecapp`、`imagefv`、`featenabler`、`bluetooth`、`dsp`、`modem`、`logo`。

都是官方固件镜像（EL2 签名的 BL、TEE、DSP、modem 等），内容不随设备变化。
正常只改内核时完全用不到；只有把 `xbl`/`abl` 写坏到进不了 fastboot 时，才需要它们
配合 EDL 模式救砖。`modem.img`（320 MiB，压缩后 65.6 MiB）是完整的调制解调器固件。

> 刷这些分区属于"救砖"操作，与内核项目本身无关。保留它们的原因只有一个：
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
