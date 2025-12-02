# Solana 铸造 NFT 快速上手（CLI + Metaplex）

与 fungible token 不同，NFT 需满足：1) 供应量为 1；2) 有独立的元数据（JSON）和媒体资源；3) 常用 Metaplex 标准。下述用 Devnet 为例，演示完整流程。

## 1) 准备环境

为什么：Metaplex CLI 需要 Node/npm 环境，Solana CLI 负责签名与账户操作。确保：

- `solana --version` 正常；`solana config set --url devnet` 指向 Devnet（或本地）。
- 安装 Metaplex CLI（token-metadata 标准工具）：  
  ```bash
  npm install -g @metaplex-foundation/cli
  ```
  （如已安装可跳过，或使用新版 `sugar` CLI 也可。）

## 2) 生成/配置钱包

为什么：NFT 铸造和元数据更新需签名者，配置默认 keypair 与网络：

```bash
solana-keygen new -o nft-keypair.json   # 如需特定前缀可用 grind
solana config set --keypair nft-keypair.json
solana config set --url devnet
solana balance                          # 确认有 SOL 付费
```

## 3) 准备元数据 JSON 与媒体资源

为什么：NFT 的显示依赖元数据 + 指向的媒体（如图片）。先将资源上传到可访问的存储（如 Arweave/Pinata/IPFS 网关）。示例 `metadata.json` 结构：

```json
{
  "name": "My NFT",
  "symbol": "MYNFT",
  "description": "My first Solana NFT",
  "seller_fee_basis_points": 500,
  "image": "https://your.domain/media.png",
  "attributes": [{ "trait_type": "rarity", "value": "common" }],
  "properties": {
    "files": [{ "uri": "https://your.domain/media.png", "type": "image/png" }],
    "category": "image",
    "creators": [{ "address": "<YOUR_WALLET_ADDRESS>", "share": 100 }]
  }
}
```

上传后得到 metadata URI（如 `https://your.domain/metadata.json`）。

## 4) 创建 NFT（Metaplex “create”）

为什么：Metaplex CLI 会帮你创建 Mint（供应量 1）、Metadata、Master Edition，并将你设为 update authority。

```bash
metaplex create \
  nft \
  --name "My NFT" \
  --symbol "MYNFT" \
  --uri "https://your.domain/metadata.json" \
  --seller-fee-basis-points 500 \
  --keypair nft-keypair.json \
  --require-ownership false
```

输出将包含：
- Mint 地址（NFT 的唯一地址）
- Metadata PDA / Master Edition PDA
- 交易签名

> `--require-ownership false` 允许创建时不强制上传文件到 bundlr，前提是 URI 可访问。

## 5) 可选：手动用 SPL-Token 创建 1 供应的 Mint

如果不用 Metaplex `create`，也可手动流程：

```bash
# 创建 0 decimals 的 Mint（供应可为 1）
spl-token create-token --decimals 0
# 创建 ATA
spl-token create-account <MINT>
# 铸造 1
spl-token mint <MINT> 1
```

然后用 Metaplex CLI 将 Metadata/Edition 绑定到该 Mint：

```bash
metaplex mint nft \
  --mint <MINT> \
  --uri "https://your.domain/metadata.json" \
  --name "My NFT" \
  --symbol "MYNFT"
```

## 6) 验证与查看

```bash
# 查看 NFT 元数据
metaplex show nft --mint <MINT>

# 或用 solana explorer 打开 Mint 地址（选择 Devnet）
```

## 7) 常见问题

- **为什么要 0 decimals**：NFT 需不可分割，通常 decimals=0，供应=1。
- **为什么要 Metadata/Edition**：仅有 Mint 无法被钱包识别为 NFT；Metaplex Metadata 标准提供展示信息，Edition 确认唯一性/限量。
- **URI 需可访问**：钱包会拉取 URI 指向的 JSON/媒体，不可访问会导致显示错误。
- **权限**：update authority 才能修改元数据；mint authority（若未永久冻结）可再次铸造，需谨慎。

按以上步骤，你即可在 Devnet 创建并验证一枚合规的 Solana NFT。***
