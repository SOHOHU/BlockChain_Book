// 简单的独立部署脚本（不依赖 Hardhat 编译）
const { ethers } = require("ethers");
require("dotenv").config();

// BuyMeACoffee 合约的字节码和 ABI
const CONTRACT_BYTECODE = ""; // 需要从编译后的文件中获取

const CONTRACT_ABI = [
  {
    "inputs": [],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "from",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "timestamp",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "string",
        "name": "name",
        "type": "string"
      },
      {
        "indexed": false,
        "internalType": "string",
        "name": "message",
        "type": "string"
      }
    ],
    "name": "NewMemo",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "_name",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "_message",
        "type": "string"
      }
    ],
    "name": "buyCoffee",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getMemos",
    "outputs": [
      {
        "components": [
          {
            "internalType": "address payable",
            "name": "from",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "timestamp",
            "type": "uint256"
          },
          {
            "internalType": "string",
            "name": "name",
            "type": "string"
          },
          {
            "internalType": "string",
            "name": "message",
            "type": "string"
          }
        ],
        "internalType": "struct BuyMeACoffee.Memo[]",
        "name": "",
        "type": "tuple[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "withdrawTips",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

async function main() {
  // 连接到 Kaia Kairos 测试网
  const provider = new ethers.JsonRpcProvider(
    "https://public-node-api.kairos.kaia.io/v1/a29e46a75f8541c888d36329e49ad420"
  );

  // 使用私钥创建钱包
  const privateKey = process.env.KAIROS_PRIVATE_KEY;
  if (!privateKey) {
    console.error("错误：未找到 KAIROS_PRIVATE_KEY 环境变量");
    process.exit(1);
  }

  const wallet = new ethers.Wallet(privateKey, provider);
  console.log("部署账户:", wallet.address);

  // 检查余额
  const balance = await provider.getBalance(wallet.address);
  console.log("账户余额:", ethers.formatEther(balance), "KAIA");

  if (balance === 0n) {
    console.error("错误：账户余额为 0，请先从水龙头获取测试 KAIA");
    console.log("水龙头地址: https://www.kaia.io/faucet");
    process.exit(1);
  }

  // 注意：由于编译问题，这个脚本需要字节码
  // 请使用在线 Solidity 编译器（如 Remix）编译合约并获取字节码
  if (!CONTRACT_BYTECODE) {
    console.log("\n=== 部署说明 ===");
    console.log("1. 访问 Remix IDE: https://remix.ethereum.org");
    console.log("2. 创建新文件并粘贴 BuyMeACoffee.sol 的内容");
    console.log("3. 编译合约（Solidity 0.8.0）");
    console.log("4. 在 Remix 中使用 'Injected Provider - MetaMask' 部署");
    console.log("5. 确保 MetaMask 连接到 Kaia Kairos 测试网");
    console.log("6. 部署后复制合约地址到 frontend/lib/contract.ts");
    return;
  }

  // 如果有字节码，则部署合约
  console.log("\n开始部署合约...");
  const factory = new ethers.ContractFactory(CONTRACT_ABI, CONTRACT_BYTECODE, wallet);
  const contract = await factory.deploy();
  await contract.waitForDeployment();

  const address = await contract.getAddress();
  console.log("\n✅ 合约部署成功！");
  console.log("合约地址:", address);
  console.log("\n请将此地址更新到 frontend/lib/contract.ts 中的 CONTRACT_ADDRESS");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });



