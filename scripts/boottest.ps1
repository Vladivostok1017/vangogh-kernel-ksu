#!/usr/bin/env pwsh
# SPDX-License-Identifier: GPL-2.0-only
# boottest.ps1 - 用 fastboot 临时启动指定内核镜像并回报结果
# 用法: .\boottest.ps1 -Image F:\vanilla-build\out\boot-xxx.img [-Wait 60]
param(
  [Parameter(Mandatory=$true)][string]$Image,
  [int]$Wait = 60
)
if (-not (Test-Path $Image)) { Write-Host "镜像不存在: $Image"; exit 2 }

Write-Host "=== [1] 进入 bootloader ==="
$adb = Get-Process adb -ErrorAction SilentlyContinue
if ($adb) { adb reboot bootloader 2>&1 | Out-Null }
Start-Sleep -Seconds 12

Write-Host "=== [2] fastboot 状态 ==="
$fb = fastboot devices
$fb

Write-Host "=== [3] 临时启动镜像 ==="
fastboot boot $Image 2>&1 | Select-Object -First 3

Write-Host "=== [4] 等待 $Wait 秒后探测 ==="
Start-Sleep -Seconds $Wait
$dev = adb devices | Select-String "device$"
if ($dev) {
  Write-Host "--- 已启动，读取内核版本 ---"
  adb shell "uname -a"
  adb shell "cat /proc/version"
  adb shell "cat /proc/uptime"
} else {
  Write-Host "!!! 未检测到 adb 设备（内核可能崩溃或仍在启动）"
  fastboot devices
}
