# Solana 铸造代币快速上手（CLI）

基于你当前的环境（solana-cli 1.18.21），按以下步骤完成本地生成钥匙、配置 RPC、创建 SPL Token，并初始化元数据。

## 1) 准备环境

为什么：CLI 版本和网络决定了后续命令的兼容性与费用来源（Devnet 免费、Localnet 离线、Mainnet 真实资产）。

- 安装 CLI（已完成）：`solana --version`
- 确认网络：本例使用 Devnet，也可换本地 validator。

## 2) 生成并配置钱包

为什么：Mint 和后续铸币都需要签名者；配置默认 keypair 和 RPC，命令才知道用谁签、往哪发。

```bash
# 生成带前缀的 keypair（示例前缀 bos）
solana-keygen grind --starts-with bos:1
# 将生成的 bos*.json 作为默认 keypair
solana config set --keypair bosg5sFrZ3kRZ8T2fbNoXdsxNSnH3H329Cg37FtDToC.json

# 切换到 Devnet（或 localnet）
solana config set --url devnet

# 查看余额，确认有足够 SOL 付费
solana balance
```

> 如果余额不足，可到 Devnet 水龙头申请，或在本地 validator 使用内置空投。

## 3) 再生成一个专用于 Mint 的地址（可选）

为什么：出于品牌或管理分离，让 Mint 地址有特定前缀，且可与支付费的默认钱包区分。

为了让 Mint 有特定前缀，可以再 grind 一个：

```bash
solana-keygen grind --starts-with mnt:1
```

假设生成文件 `mntjcBjoxaLNp2FVVbZ2fQ6AsPMTvYQXmfUsaBuRBcS.json`，地址即为 `mntjcBjoxaLNp2FVVbZ2fQ6AsPMTvYQXmfUsaBuRBcS`。

## 4) 创建 SPL Token

为什么：真正创建链上的 Mint 账户（包含 decimals、mint authority 等），`--enable-metadata` 让后续可以向 mint 附加内置元数据 PDA。

使用新版 Token-2022 程序 ID：`TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb`。

```bash
spl-token create-token \
  --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb \
  --enable-metadata \
  mntjcBjoxaLNp2FVVbZ2fQ6AsPMTvYQXmfUsaBuRBcS.json
```

输出会包含：
- Address: 你的 Mint 地址（本例 mntjcBjoxaLNp2FVVbZ2fQ6AsPMTvYQXmfUsaBuRBcS）
- Decimals: 默认 9
- Signature: 交易签名

> `--enable-metadata` 会在 mint 里创建可扩展的元数据 PDA，但不会自动填充内容。

## 5) 初始化元数据

为什么：链上展示名称/符号/URI 需先写入元数据账户（符合 Metaplex 标准）；未初始化时，钱包可能只显示地址。

用同一条命令填入名称/符号/URI（需签名人是 mint authority，默认为 keypair）：

```bash
spl-token initialize-metadata \
  mntjcBjoxaLNp2FVVbZ2fQ6AsPMTvYQXmfUsaBuRBcS \
  "Your Token Name" \
  "YTN" \
  "https://your.domain/metadata.json"
```

`metadata.json` 通常是符合 Metaplex 标准的 JSON，需自行托管。

## 6) 创建关联账户并铸币

为什么：SPL 代币要存到钱包的 ATA（Associated Token Account）；没有 ATA 无法持有；mint 操作把代币供应记到账上。

```bash
# 创建你的钱包的 ATA
spl-token create-account mntjcBjoxaLNp2FVVbZ2fQ6AsPMTvYQXmfUsaBuRBcS

# 铸造 100 单位（按 decimals=9，实际为 100 * 10^9 base units）
spl-token mint mntjcBjoxaLNp2FVVbZ2fQ6AsPMTvYQXmfUsaBuRBcS 100
```

## 7) 查询与验证

```bash
# 查询 mint 信息
spl-token account-info mntjcBjoxaLNp2FVVbZ2fQ6AsPMTvYQXmfUsaBuRBcS

# 查看你钱包的代币余额
spl-token balance mntjcBjoxaLNp2FVVbZ2fQ6AsPMTvYQXmfUsaBuRBcS
```

## 常见问题

- **为什么要切换 RPC**：不同网络有不同状态，避免把测试代币发到主网或反之。
- **为什么需要 mint authority**：只有 mint authority 能增发或设置元数据；遗失私钥等于无法再铸币/改元数据。
- **为什么要 airdrop/余额检查**：每次创建账户、铸币都要消耗少量 SOL 作为租金/手续费。

- **报错网络不通**：确认 `solana config get` 的 RPC URL 与期望网络一致（devnet/localnet）。
- **权限错误**：mint/metadata 操作需 mint authority；默认是创建 mint 的 keypair。
- **余额不足**：Devnet 领取 SOL；localnet 运行 validator 后用 `solana airdrop 10`。

按上面步骤，你即可在 Solana 上完成 Token 创建、元数据初始化与铸造。模板中的 keypair 和地址请替换为你自己生成的文件与地址。***
