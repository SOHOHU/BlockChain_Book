const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  const balance = await hre.ethers.provider.getBalance(deployer.address);

  console.log("部署账号:", deployer.address);
  console.log("部署账号余额:", hre.ethers.formatEther(balance), "KAIA");

  const SimpleStorage = await hre.ethers.getContractFactory("SimpleStorage");
  const contract = await SimpleStorage.deploy(42);
  await contract.waitForDeployment();

  const address = await contract.getAddress();
  console.log("SimpleStorage 已部署到:", address);

  const currentValue = await contract.get();
  console.log("当前存储值:", currentValue.toString());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

