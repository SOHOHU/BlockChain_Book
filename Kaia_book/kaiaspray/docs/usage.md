# Kaiaspray 本地网络使用说明

本指南介绍如何使用本仓库根目录下的 `kaiaspray/` 脚本在本地快速启动一条 Kaia 私有网络，实现对多类节点（CN/PN/EN）的自动化部署与运维，并演示如何通过示例项目部署测试合约。

## 前置条件

- 已安装 Git、Docker、Docker Compose
- 推荐在 Linux 环境或 WSL 中执行脚本（Windows PowerShell 无法直接运行 `.sh`）
- 已克隆并编译官方 `kaia` 源码（用于提供 `homi` 与节点二进制）
  ```bash
  git clone https://github.com/kaiachain/kaia.git
  cd kaia
  make
  ```
- 可选：如 `kaia` 源码不在默认路径，可通过环境变量 `KAIA_SOURCE_DIR` 指定位置

## 目录结构

```
kaiaspray/
├── config/                 # 配置文件（properties.sh、示例等）
├── docs/                   # 文档（含本使用说明）
├── monitoring/             # Prometheus / Grafana 相关资源
├── sample-project/         # Hardhat 示例项目，用于部署测试合约
├── scripts/                # Kaiaspray 官方脚本集合
└── README.md
```

> 提示：请始终在 `kaiaspray/` 根目录执行脚本，或通过 `./scripts/<script>.sh` 方式调用。脚本内部会自动定位到正确的工作目录。

## 快速启动

1. **配置 Kaia 源码路径（如必要）**
   ```bash
   export KAIA_SOURCE_DIR=/absolute/path/to/kaia
   ```
   若 `kaia` 源码与本仓库同级（即 `../kaia`），可跳过此步骤。

2. **准备配置**
   ```bash
   cd kaiaspray
   cp config/sample_properties.sh config/properties.sh   # 如需自定义，可编辑该文件
   ```
   在 `properties.sh` 中可调整链 ID、节点数量、Remix、Prometheus 等开关设置。

3. **生成节点目录与配置**
   ```bash
   ./scripts/0_kaia_setup.sh
   ```

4. **（可选）重新初始化节点数据**
   ```bash
   ./scripts/2_initialize_nodes.sh
   ```

5. **启动网络**
   ```bash
   ./scripts/3_ccstart.sh          # 启动全部节点
   ./scripts/3_ccstart.sh en 1     # 仅启动指定节点
   ```

6. **附着控制台 / 查看日志**
   ```bash
   ./scripts/5_attach.sh en 1      # 连接 EN1 控制台（IPC）
   ./scripts/5_attach.sh en 1 rpc  # 通过 HTTP RPC 连接 EN1
   ./scripts/6_logs.sh cn 1        # 跟踪 CN1 日志
   ```

7. **停止网络**
   ```bash
   ./scripts/4_ccstop.sh           # 停止所有节点
   ```

## 监控与可视化

1. 首次运行前，如需使用 Grafana 模板，可从官方仓库复制文件：
   ```
   kaiachain/kaiaspray/local-deploy/roles/monitor-init/files/grafana/dashboards/
   ```
   到本地 `kaiaspray/monitoring/grafana/provisioning/dashboards/`（目录如不存在需自行创建）。

2. 启动监控：
   ```bash
   ./scripts/7_monitoring.sh start
   ```
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3000 （默认账号/密码 `admin/admin`）

3. 停止监控：
   ```bash
   ./scripts/7_monitoring.sh stop
   ```

亦可直接执行：
```bash
docker compose -f monitoring/docker-compose.yml up -d
docker compose -f monitoring/docker-compose.yml down
```

## 示例项目：部署测试合约

`sample-project/` 为在 Kaiaspray 网络上部署智能合约的最小化示例，基于 Hardhat 与 ethers.js。运行前准备：

1. 在 Kaiaspray 网络启动后，查看 `cn1/conf/kcn1.accountlist.json` 或其它节点的账户清单，复制其中的测试账户私钥。
2. 创建环境变量文件：
   ```bash
   cd kaiaspray/sample-project
   cp env.sample .env
   # 编辑 .env，填入刚才复制的私钥（不带 0x 前缀也可以）
   ```
3. 安装依赖并执行部署：
   ```bash
   npm install
   npm run compile
   npm run deploy:kaiaspray
   ```

部署脚本会输出：

- 部署使用的账户地址及剩余余额
- `SimpleStorage` 合约地址
- 初始存储值（默认 42）

您可在 Hardhat 控制台或其它脚本中与该合约交互，验证 Kaiaspray 网络是否工作正常。

## 常用脚本速览

| 脚本 | 说明 |
| ---- | ---- |
| `scripts/1_copy_binary.sh [type] [index]` | 将编译好的二进制复制到节点目录 |
| `scripts/2_initialize_nodes.sh [type] [index]` | 删除并重新初始化节点数据 |
| `scripts/8_explorer.sh start en 1 [host]` | 启动以 EN1 为数据源的区块浏览器 |
| `scripts/9_rolling_update.sh [type] [index]` | 对节点执行滚动更新 |
| `scripts/10_jsexec.sh <target> <index> "<js>" [rpc/ws]` | 在节点控制台执行 JS 指令 |

## 故障排查

- **提示未找到 `kaia` 目录**  
  确认已编译官方仓库，并设置 `KAIA_SOURCE_DIR` 环境变量。

- **脚本无法执行**  
  在 Linux / WSL 中运行 `chmod +x scripts/*.sh` 后重新执行。

- **监控报错找不到模板文件**  
  按“监控与可视化”章节复制官方 Grafana 模板，再重新启动。

- **端口冲突**  
  修改 `config/properties.sh` 中的 `NETWORK_ID`、节点数量或 Prometheus 端口偏移，重新执行 `./scripts/0_kaia_setup.sh`。

- **部署脚本报错：缺少私钥或 RPC**  
  复制 `env.sample` 至 `.env` 并填入私钥；确认网络已启动且 RPC 端口与 `hardhat.config.js` 中的设置一致。

---

完成上述步骤后，即可在本地快速体验 Kaiaspray 区块链网络及多节点管理流程，并通过示例项目验证部署与交互链路。*** End Patch

