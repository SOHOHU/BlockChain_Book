// BuyMeACoffee 合约配置

// 合约 ABI（从 BuyMeACoffee.sol 提取）
export const CONTRACT_ABI = [
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

// 合约地址 - 部署后需要更新此地址
export const CONTRACT_ADDRESS = "0x068B3b3907C778945e24F6f921Cc8EAd10E55dFE";

// Kaia Kairos 测试网配置
export const KAIROS_CHAIN_ID = "0x3e9"; // 1001 in hex
export const KAIROS_RPC_URL = "https://public-en.kairos.kaia.io";

export const KAIROS_NETWORK = {
  chainId: KAIROS_CHAIN_ID,
  chainName: "Kaia Kairos Testnet",
  nativeCurrency: {
    name: "KAIA",
    symbol: "KAIA",
    decimals: 18,
  },
  rpcUrls: [KAIROS_RPC_URL],
  blockExplorerUrls: ["https://kairos.kaiascope.com"],
};

