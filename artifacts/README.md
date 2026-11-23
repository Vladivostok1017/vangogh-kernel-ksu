# artifacts/ — 可刷入产物与安装包

本目录随仓库提供**真实跑过的**产物，不是在别处另发的 Release 链接。所有 `.img`
都是 `boot` 槽镜像（header v2，128 MiB 槽位），已按 `xz -6` 压缩；解压方法与校验值
见下方表格与 `SHA256SUMS`。

```bash
# 解压（Linux / WSL / Termux）
xz -dk artifacts/boot/out-c6-working-ksu-0.9.5.img.xz      # 得到同名 .img
# 校验（压缩包与解压后两种摘要都记在 SHA256SUMS 里）
sha256sum -c artifacts/SHA256SUMS                          # 会因 “.img 不存在” 报两类条目
sha256sum artifacts/boot/out-c6-working-ksu-0.9.5.img      # 对比带 (decompressed) 的那一行
```

Windows 下可用 7-Zip 解 `.xz`，或 `wsl xz -dk <file>`。

## boot/ — 内核镜像

| 文件（解压后） | 压缩包 | 大小(raw) | sha256 (raw) | 说明 |
|---|---|---|---|---|
| `out-c6-working-ksu-0.9.5.img` | 12.47 MiB | 128 MiB | `ea0f1d17eea387d2c2e049a3aa324cb9dcd559589992a362fe92a67de694f038` | **可用版本**。Driftwood 4.19.157 + MIUI 私有驱动 + `QCA_CLD_WLAN` 内建 + KernelSU v0.9.5(kprobe)。实机验证：开机、Wi-Fi 5GHz 866Mbps、`su` 可用、Magisk 模块自动迁移。**无音频**。 |
| `out-c-experimental.img` | 12.45 MiB | 128 MiB | `58ce432892e620abbbb2606e919f50311d7d7505ba64733f8fa223b7a8d3e815` | 早期路线 C 中间产物（KSU 打通、Wi-Fi 未定型的阶段）。归档用于对比。 |
| `out-c2-experimental.img` | 12.48 MiB | 128 MiB | `8ca9b602cd553adafee4ee3273ef1b959262d44c000de10f3803fac7da259089` | 音频全部 `=y` 内建的实验镜像，**已知启动 panic**（q6/adsp 早于 ADSP 固件探测）。仅存档反面证据。 |
| `out-c3-experimental.img` | 12.46 MiB | 128 MiB | `0c56f44f8dae56044d19ac4bef81887c565283c60b5c511ae62a74b9f8eb9eff` | 音频部分内建的过渡版本。 |

刷入 / 回滚（设备需已解锁 BL，`fastboot` 在 Windows 侧执行）：

```powershell
# 临时启动，不写分区，重启即恢复原状 —— 先验证能不能开机
fastboot boot out-c6-working-ksu-0.9.5.img
# 确认可用后再落盘
fastboot flash boot out-c6-working-ksu-0.9.5.img
# 回滚（任一）
fastboot flash boot ..\backup\boot\magisk-patched-boot.img     # 回到原厂+Magisk
fastboot flash boot ..\backup\boot\stock-v13.0.7.0.img         # 回到纯净原厂
```

> ⚠️ 先把 `backup/` 里的分区备份落到自己机器上再动手；`fastboot flash boot` 之前
> 务必用 `fastboot boot` 验证过同一份镜像。

## apk/ — 管理器

| 文件 | sha256 | 用途 |
|---|---|---|
| `KernelSU_v0.9.5.apk` | `8384b08fb8c4cf1314fa87aff80839faf284d22eeff41a8319e8eaa1336f1e7b` | 唯一匹配内核内 KSU 版本的管理器。**必须装这个版本**，新版管理器（v1.0+）只认 GKI 内核，会显示"未安装"。安装前先 `adb uninstall me.weishu.kernelsu`（设备上若已有更高版本会 `INSTALL_FAILED_VERSION_DOWNGRADE`）。 |
| `SukiSU_Nova_v3.0.0.apk` | `1202adb835a64d8b3df703da7884a2966f8728c131cffb29fb5f48d31d81ac85` | 移植 SukiSU 时试装的管理器，仅供对照，与当前内核不配套。 |

## config/

`stock_config.gz` —— 原厂 `boot` 镜像里抽出的 `/proc/config.gz`（V13.0.7.0.SJVCNXM）。
`scripts/` 里的对比脚本都以它为基线；`docs/HANDOFF.md` 里那张"MIUI 模块 CRC 表"也是
拿它和自编内核逐符号对出来的。

## pack-manifest.json

`scripts/release-artifacts.py` 的产物清单：每个文件的原始路径、原始大小/`mtime`、
压缩前后 sha256。删掉它不会影响仓库可用性，但下次重跑脚本时无法命中缓存。
