// @ts-ignore: Hardhat 运行时会确保 ethers 存在
import * as hre from "hardhat"; 
// 或者您可以尝试直接使用 require
// const hre = require("hardhat");

async function main() {
    // 1. 获取合约工厂
    // 我们使用 hre.ethers，并添加 @ts-ignore 来暂时忽略 TypeScript 的静态检查
    // 因为在 Hardhat 运行时，这个属性是存在的。
    const BuyMeACoffee = await (hre as any).ethers.getContractFactory("BuyMeACoffee");

    // 2. 部署合约
    console.log("Deploying BuyMeACoffee...");
    const buyMeACoffee = await BuyMeACoffee.deploy();

    // 3. 等待部署完成
    await buyMeACoffee.waitForDeployment();

    // 4. 打印部署信息
    const contractAddress = await buyMeACoffee.getAddress();
    console.log(`BuyMeACoffee deployed to: ${contractAddress}`);
    // 请记录下这个地址！
}

// 确保在主函数发生错误时能捕获到
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});