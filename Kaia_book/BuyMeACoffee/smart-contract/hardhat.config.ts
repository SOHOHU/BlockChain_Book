import hardhatToolboxMochaEthersPlugin from "@nomicfoundation/hardhat-toolbox-mocha-ethers";
import { configVariable, defineConfig } from "hardhat/config";
import * as dotenv from "dotenv";

// 加载 .env 文件
dotenv.config();

// --- 1. 获取 KAIROS PRIVATE KEY ---
// 确保您已经设置了 KAIROS_PRIVATE_KEY 环境变量 (例如在 .env 文件中)
const KAIROS_PRIVATE_KEY = process.env.KAIROS_PRIVATE_KEY || "";
const formattedKey = KAIROS_PRIVATE_KEY.startsWith('0x') ? KAIROS_PRIVATE_KEY : `0x${KAIROS_PRIVATE_KEY}`;

export default defineConfig({
    plugins: [hardhatToolboxMochaEthersPlugin],
    solidity: {
        profiles: {
            default: {
                version: "0.8.28",
            },
            production: {
                version: "0.8.28",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        },
    },
    networks: {
        // --- Kaia Kairos Testnet 配置 ---
        kairos: {
            type: "http",
            // 这是一个公共节点，您可以替换为 Kaia 官方推荐的最新 RPC
            url: "https://public-node-api.kairos.kaia.io/v1/a29e46a75f8541c888d36329e49ad420", 
            chainId: 1001, // Kaia Kairos 的 ChainID
            accounts: [formattedKey],
        },
        
        // --- 默认配置 (可选保留或删除) ---
        hardhatMainnet: {
            type: "edr-simulated",
            chainType: "l1",
        },
        hardhatOp: {
            type: "edr-simulated",
            chainType: "op",
        },
        sepolia: {
            type: "http",
            chainType: "l1",
            url: configVariable("SEPOLIA_RPC_URL"),
            accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
        },
    },
});