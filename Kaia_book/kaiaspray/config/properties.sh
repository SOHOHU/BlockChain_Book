#!/bin/bash

# 本脚本用于配置 Kaiaspray 本地网络部署。可以通过环境变量覆盖默认值。

# ---- 基础路径配置 -----------------------------------------------------------

# 配置目录
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 项目根目录（config 上一级）
PROJECT_ROOT="$(cd "$CONFIG_DIR/.." && pwd)"

# 若已在环境变量 KAIA_SOURCE_DIR 中指定 kaia 源码路径，将优先使用
KAIA_SOURCE_DIR="${KAIA_SOURCE_DIR:-}"

if [ -n "$KAIA_SOURCE_DIR" ]; then
  KAIACODE="$KAIA_SOURCE_DIR"
else
  # 默认假设 kaia 源码与本仓库同级，即 ../../kaia
  DEFAULT_KAIA_DIR="$(cd "$PROJECT_ROOT/.." 2>/dev/null && pwd)/kaia"
  if [ -d "$DEFAULT_KAIA_DIR" ]; then
    KAIACODE="$DEFAULT_KAIA_DIR"
  else
    echo "[properties.sh] 未找到 kaia 源码目录。"
    echo "  请先克隆 https://github.com/kaiachain/kaia 至任意路径，"
    echo "  然后设置环境变量 KAIA_SOURCE_DIR 指向该路径，再次运行脚本。"
    return 1 2>/dev/null || exit 1
  fi
fi

# HOMEDIR 为本地部署目录，保持为当前仓库根目录
HOMEDIR="$PROJECT_ROOT"

# ---- 网络基础参数 -----------------------------------------------------------

NETWORK_ID="${NETWORK_ID:-949494}"         # 可修改为任意未被占用的链 ID
NUMOFCN="${NUMOFCN:-1}"                    # CN 节点数量
NUMOFPN="${NUMOFPN:-1}"                    # PN 节点数量
NUMOFEN="${NUMOFEN:-1}"                    # EN 节点数量
NUMOFTESTACCSPERNODE="${NUMOFTESTACCSPERNODE:-1}"

# ---- Remix / CORS 配置 ------------------------------------------------------

REMIX="${REMIX:-true}"                     # 如需关闭 Remix 支持设为 false
ENFORREMIX="${ENFORREMIX:-$REMIX}"

# ---- Homi 相关可选项 --------------------------------------------------------

HOMI_CNKEYS="${HOMI_CNKEYS:-false}"
HOMI_PNKEYS="${HOMI_PNKEYS:-false}"
HOMI_ENKEYS="${HOMI_ENKEYS:-false}"

HOMI_PATCH_ADDRESSBOOK="${HOMI_PATCH_ADDRESSBOOK:-false}"
HOMI_REGISTRY_MOCK="${HOMI_REGISTRY_MOCK:-false}"
HOMI_NUMOF_INITIAL_CN_NUM="${HOMI_NUMOF_INITIAL_CN_NUM:-0}"
HOMI_BAOBAB_TEST="${HOMI_BAOBAB_TEST:-false}"
HOMI_ADDITIONAL_OPTIONS="${HOMI_ADDITIONAL_OPTIONS:-}"

# ---- 可选的 ADDITIONAL 配置覆盖示例 -----------------------------------------
# 如需为某个节点追加启动参数，可在运行前导出变量，例如：
#   export OVERRIDE_CONF_ADDITIONAL_CN_1="--mine --miner.threads=1"
#   export OVERRIDE_CONF_ADDITIONAL_EN_1="--http.corsdomain=*"


