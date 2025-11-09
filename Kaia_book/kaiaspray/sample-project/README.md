# Kaiaspray Sample Project

这是一个最小化的 Hardhat 示例，用于验证 Kaiaspray 本地网络的部署与合约交互流程。示例包含一个 `SimpleStorage` 合约以及对应的部署脚本。

## 前提条件

- 已启动 Kaiaspray 本地网络，并确认 RPC 端口与链 ID（默认 `http://127.0.0.1:8551` / `949494`）
- Node.js 18+（建议使用 `nvm` 或 `fnm` 管理版本）

## 快速开始

1. 复制环境变量样例并填写测试账户私钥

   ```bash
   cp env.sample .env
   # 编辑 .env，填入从 Kaiaspray 节点目录中导出的测试账户私钥
   ```

   如果 `scripts/0_kaia_setup.sh` 已执行，可在 `cn1/conf/kcn1.accountlist.json` 等文件中找到默认生成的测试账户与私钥。

2. 安装依赖并编译合约

   ```bash
   npm install
   npm run compile
   ```

3. 部署合约到 Kaiaspray 网络

   ```bash
   npm run deploy:kaiaspray
   ```

   终端将输出部署账号、余额、合约地址及合约当前存储值。

## 自定义配置

- 修改 `.env` 中的 `KAIASPRAY_RPC` / `KAIASPRAY_CHAIN_ID` 以适配不同的 Kaiaspray 配置
- 根据需要扩展 `scripts/` 或添加更多合约文件

## 常见问题

- **报错 `No account is available`**：确认 `.env` 已填写私钥，并以 `0x` 开头
- **连接超时或 `ECONNREFUSED`**：确认 Kaiaspray 网络已启动，RPC 端口与配置一致
- **Gas 相关报错**：使用默认配置时，Gas 参数会自动估算；如需自定义，可在 `hardhat.config.js` 的 `networks.kaiaspray` 中添加 `gasPrice`、`gas` 等字段

