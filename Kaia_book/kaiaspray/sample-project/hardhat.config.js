require("dotenv").config();
require("@nomicfoundation/hardhat-ethers");

const rpcUrl = process.env.KAIASPRAY_RPC || "http://127.0.0.1:8551";
const chainId = Number(process.env.KAIASPRAY_CHAIN_ID || 949494);
const privateKey = process.env.KAIASPRAY_PRIVATE_KEY
  ? process.env.KAIASPRAY_PRIVATE_KEY.startsWith("0x")
    ? process.env.KAIASPRAY_PRIVATE_KEY
    : `0x${process.env.KAIASPRAY_PRIVATE_KEY}`
  : undefined;

/** @type {import("hardhat/config").HardhatUserConfig} */
const config = {
  solidity: {
    version: "0.8.21",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    kaiaspray: {
      url: rpcUrl,
      chainId,
      accounts: privateKey ? [privateKey] : []
    }
  }
};

module.exports = config;

