// 完整的编译和部署脚本 (ES Module)
import solc from "solc";
import fs from "fs";
import path from "path";
import { ethers } from "ethers";
import dotenv from "dotenv";
import { fileURLToPath } from "url";

// 获取当前文件目录
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 加载环境变量
dotenv.config();

// 颜色输出
const colors = {
  green: "\x1b[32m",
  red: "\x1b[31m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  reset: "\x1b[0m"
};

function log(message, color = "reset") {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// 编译合约
function compileContract() {
  log("\n📦 开始编译合约...", "blue");

  // 读取合约源代码
  const contractPath = path.resolve(__dirname, "../contracts/BuyMeACoffee.sol");
  const source = fs.readFileSync(contractPath, "utf8");

  // 编译输入
  const input = {
    language: "Solidity",
    sources: {
      "BuyMeACoffee.sol": {
        content: source,
      },
    },
    settings: {
      outputSelection: {
        "*": {
          "*": ["abi", "evm.bytecode"],
        },
      },
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  };

  // 编译
  const output = JSON.parse(solc.compile(JSON.stringify(input)));

  // 检查错误
  if (output.errors) {
    let hasError = false;
    output.errors.forEach((error) => {
      if (error.severity === "error") {
        log(`❌ 编译错误: ${error.message}`, "red");
        hasError = true;
      } else {
        log(`⚠️  警告: ${error.message}`, "yellow");
      }
    });
    if (hasError) {
      process.exit(1);
    }
  }

  // 获取编译结果
  const contract = output.contracts["BuyMeACoffee.sol"]["BuyMeACoffee"];
  
  log("✅ 编译成功！", "green");

  return {
    abi: contract.abi,
    bytecode: contract.evm.bytecode.object,
  };
}

// 部署合约
async function deployContract(abi, bytecode) {
  log("\n🚀 开始部署合约到 Kaia Kairos 测试网...", "blue");

  // 连接到 Kaia Kairos 测试网
  // 尝试多个 RPC 端点以提高成功率
  const rpcUrls = [
    "https://public-en.kairos.kaia.io",
    "https://kaia-kairos.blockpi.network/v1/rpc/public",
    "https://public-node-api.kairos.kaia.io/v1/a29e46a75f8541c888d36329e49ad420"
  ];
  
  let provider;
  for (const url of rpcUrls) {
    try {
      log(`尝试连接 RPC: ${url.substring(0, 40)}...`, "blue");
      provider = new ethers.JsonRpcProvider(url, undefined, {
        staticNetwork: ethers.Network.from({
          name: "kairos",
          chainId: 1001
        })
      });
      // 测试连接
      await provider.getBlockNumber();
      log("✅ 连接成功！", "green");
      break;
    } catch (error) {
      log(`⚠️  连接失败，尝试下一个...`, "yellow");
      continue;
    }
  }
  
  if (!provider) {
    log("❌ 所有 RPC 节点都无法连接", "red");
    process.exit(1);
  }

  // 获取私钥
  const privateKey = process.env.KAIROS_PRIVATE_KEY;
  if (!privateKey) {
    log("❌ 错误：未找到 KAIROS_PRIVATE_KEY 环境变量", "red");
    log("请确保 .env 文件中包含 KAIROS_PRIVATE_KEY", "yellow");
    process.exit(1);
  }

  // 格式化私钥
  const formattedKey = privateKey.startsWith('0x') ? privateKey : `0x${privateKey}`;

  // 创建钱包
  const wallet = new ethers.Wallet(formattedKey, provider);
  log(`📍 部署账户: ${wallet.address}`, "blue");

  // 检查余额
  const balance = await provider.getBalance(wallet.address);
  log(`💰 账户余额: ${ethers.formatEther(balance)} KAIA`, "blue");

  if (balance === 0n) {
    log("❌ 错误：账户余额为 0", "red");
    log("请先从水龙头获取测试 KAIA: https://www.kaia.io/faucet", "yellow");
    process.exit(1);
  }

  // 创建合约工厂
  const factory = new ethers.ContractFactory(abi, bytecode, wallet);

  // 部署合约
  log("\n⏳ 正在部署合约，请稍候...", "yellow");
  const contract = await factory.deploy();
  
  log(`📝 交易哈希: ${contract.deploymentTransaction().hash}`, "blue");
  
  // 等待部署完成
  await contract.waitForDeployment();
  
  const contractAddress = await contract.getAddress();

  log("\n🎉 合约部署成功！", "green");
  log(`📍 合约地址: ${contractAddress}`, "green");
  log(`🔍 区块浏览器: https://kairos.kaiascope.com/address/${contractAddress}`, "blue");

  return contractAddress;
}

// 更新前端配置
function updateFrontendConfig(contractAddress) {
  log("\n📝 更新前端配置...", "blue");

  const configPath = path.resolve(__dirname, "../../frontend/lib/contract.ts");
  
  // 检查文件是否存在
  if (!fs.existsSync(configPath)) {
    log("⚠️  警告：前端配置文件不存在，跳过更新", "yellow");
    return;
  }

  // 读取配置文件
  let content = fs.readFileSync(configPath, "utf8");

  // 替换合约地址
  content = content.replace(
    /export const CONTRACT_ADDRESS = ".*";/,
    `export const CONTRACT_ADDRESS = "${contractAddress}";`
  );

  // 写入文件
  fs.writeFileSync(configPath, content, "utf8");

  log("✅ 前端配置已自动更新！", "green");
}

// 保存部署信息
function saveDeploymentInfo(contractAddress, abi) {
  log("\n💾 保存部署信息...", "blue");

  const deploymentDir = path.resolve(__dirname, "../deployments");
  if (!fs.existsSync(deploymentDir)) {
    fs.mkdirSync(deploymentDir);
  }

  const deploymentInfo = {
    network: "kairos",
    contractAddress: contractAddress,
    deploymentTime: new Date().toISOString(),
    blockExplorer: `https://kairos.kaiascope.com/address/${contractAddress}`,
    abi: abi,
  };

  const filePath = path.join(deploymentDir, "BuyMeACoffee-kairos.json");
  fs.writeFileSync(filePath, JSON.stringify(deploymentInfo, null, 2), "utf8");

  log(`✅ 部署信息已保存到: deployments/BuyMeACoffee-kairos.json`, "green");
}

// 主函数
async function main() {
  try {
    log("\n" + "=".repeat(60), "blue");
    log("  Buy Me A Coffee - 自动编译和部署工具", "blue");
    log("=".repeat(60), "blue");

    // 1. 编译合约
    const { abi, bytecode } = compileContract();

    // 2. 部署合约
    const contractAddress = await deployContract(abi, bytecode);

    // 3. 更新前端配置
    updateFrontendConfig(contractAddress);

    // 4. 保存部署信息
    saveDeploymentInfo(contractAddress, abi);

    // 5. 显示下一步
    log("\n" + "=".repeat(60), "green");
    log("  🎉 部署完成！接下来的步骤：", "green");
    log("=".repeat(60), "green");
    log("\n1. 测试前端应用:", "blue");
    log("   cd frontend", "yellow");
    log("   npm install", "yellow");
    log("   npm run dev", "yellow");
    log("\n2. 部署到 Vercel:", "blue");
    log("   cd frontend", "yellow");
    log("   vercel --prod", "yellow");
    log("\n3. 提交任务:", "blue");
    log("   发送邮件到 dev@kaia.io", "yellow");
    log("   包含 Vercel 链接和合约地址", "yellow");
    log("\n");

  } catch (error) {
    log(`\n❌ 部署失败: ${error.message}`, "red");
    console.error(error);
    process.exit(1);
  }
}

// 运行主函数
main()
  .then(() => {
    log("✨ 所有操作完成！\n", "green");
    process.exit(0);
  })
  .catch((error) => {
    log(`\n❌ 发生错误: ${error.message}`, "red");
    console.error(error);
    process.exit(1);
  });

