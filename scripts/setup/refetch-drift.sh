#!/usr/bin/env bash
set -o pipefail
P="http://127.0.0.1:17890"
export http_proxy="$P" https_proxy="$P"
mkdir -p "$HOME/work" && cd "$HOME/work"

if [ ! -d driftwood/.git ]; then
  echo "=== 克隆 Driftwood（含 KernelSU 子模块指向）==="
  git clone --depth=1 -b android-4.19-standalone \
    https://github.com/WeeAris/Driftwood_kernel_xiaomi_sm7250.git driftwood 2>&1 | tail -3
fi

K="$HOME/work/driftwood"
echo
echo "=== 检查关键驱动是 =m 还是 =y ==="
CFG="$K/arch/arm64/configs/vendor/vangogh_user_defconfig"
for opt in QCA_CLD_WLAN WLAN WCNSS WIFI QCOM_QMI_HELPERS SND_SOC_WCD937X \
           SND_SOC_WCD938X SND_SOC_BOLERO SND_SOC_MACHINE_LITO EXFAT_FS \
           RMNET_PERF RMNET_SHS MIHW MIGT MILLET; do
  hit=$(grep -m1 "^CONFIG_${opt}=" "$CFG" 2>/dev/null || grep -m1 "^# CONFIG_${opt} is not set" "$CFG" 2>/dev/null)
  printf '%-28s %s\n' "$opt" "${hit:-（未在 defconfig 中出现）}"
done

echo
echo "=== defconfig 中所有 =m 的项（前 40）==="
grep -c "=m$" "$CFG"
grep "=m$" "$CFG" | head -40
