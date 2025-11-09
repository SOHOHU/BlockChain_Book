# Kaiaspray 本地网络脚本集

一个独立的 Kaiaspray 本地网络项目，提供脚本化的一键部署流程、运维工具以及最小化的合约示例，方便在 Kaia 私有链上进行开发与测试。

## 目录结构

```
kaiaspray/
├── config/                 # properties.sh 与示例配置
├── docs/                   # 使用说明与补充文档
├── monitoring/             # Prometheus / Grafana 资源（含 docker-compose.yml）
├── sample-project/         # Hardhat 示例项目
├── scripts/                # Kaiaspray 官方脚本集合
└── README.md
```

## 快速开始

1. **准备依赖**
   - Git、Docker、Docker Compose
   - 已编译的 `kaia` 官方源码（提供 `homi` 与节点程序）
   - 在 Linux 或 WSL 环境执行脚本（Windows PowerShell 无法直接运行 `.sh` 文件）

2. **配置 Kaia 源码路径（如必要）**
   ```bash
   export KAIA_SOURCE_DIR=/absolute/path/to/kaia   # 若 kaia 源码不在 ../kaia
   ```

3. **初始化配置**
   ```bash
   cd kaiaspray
   cp config/sample_properties.sh config/properties.sh
   # 根据需要编辑 config/properties.sh，调整链 ID、节点数量、端口等
   ```

4. **生成节点目录与初始配置**
   ```bash
   ./scripts/0_kaia_setup.sh
   ```

5. **（可选）重建节点数据**
   ```bash
   ./scripts/2_initialize_nodes.sh
   ```

6. **启动本地区块链网络**
   ```bash
   ./scripts/3_ccstart.sh          # 启动全部节点
   ./scripts/3_ccstart.sh en 1     # 仅启动 EN1 等指定节点
   ```

7. **附着控制台 / 查看日志**
   ```bash
   ./scripts/5_attach.sh en 1 rpc  # 通过 HTTP RPC 连接 EN1
   ./scripts/6_logs.sh cn 1        # 实时查看 CN1 日志
   ```

8. **停止网络**
   ```bash
   ./scripts/4_ccstop.sh
   ```

更多细节请阅读 `docs/usage.md`。

## 监控与可视化（可选）

首次使用监控功能前，可将官方模板拷贝至 `monitoring/` 目录（结构与 Kaiaspray 官方仓库保持一致）。随后执行：

```bash
./scripts/7_monitoring.sh start                     # 启动 Prometheus / Grafana
docker compose -f monitoring/docker-compose.yml up -d   # 或直接使用 docker-compose
```

默认端口：Prometheus `9090`、Grafana `3000`（账号/密码 `admin/admin`）。

## 示例项目：`sample-project`

`sample-project/` 提供一个最小化的 Hardhat + ethers.js 示例，演示如何在 Kaiaspray 本地网络上部署并交互。主要文件：

- `contracts/SimpleStorage.sol`：简单的存储合约
- `scripts/deploy.js`：部署脚本，会输出部署地址与初始值
- `hardhat.config.js`：配置本地 kaiaspray 网络（默认 RPC `http://127.0.0.1:8551`，链 ID `949494`）
- `env.sample`：环境变量示例（用于填入部署私钥）

### 运行示例项目

```bash
cd kaiaspray/sample-project
cp env.sample .env                     # 填入本地测试账户私钥
npm install
npm run compile
npm run deploy:kaiaspray
```

> 提示：`0_kaia_setup.sh` 会在每个节点下生成测试账户，可在 `cn1/conf/kcn1.accountlist.json` 等文件中查看私钥信息。

部署完成后，脚本会打印合约地址和返回的初始存储值，可用于后续前端或脚本调试。

## 支持与参考

- Kaiaspray 官方仓库：https://github.com/kaiachain/kaiaspray
- Kaia 文档：https://docs.kaia.io
- Kairos 测试网水龙头：https://www.kaia.io/faucet

如需进一步的环境说明或脚本细节，请继续阅读 `docs/` 目录中的文档。欢迎在实践中根据自身需求扩展或定制脚本。*** End Patch

