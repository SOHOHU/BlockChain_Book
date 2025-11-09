"use client";

import { useState, useEffect } from "react";
import { ethers } from "ethers";
import { CONTRACT_ABI, CONTRACT_ADDRESS, KAIROS_NETWORK } from "@/lib/contract";

interface Memo {
  from: string;
  timestamp: bigint;
  name: string;
  message: string;
}

export default function Home() {
  const [account, setAccount] = useState<string>("");
  const [contract, setContract] = useState<ethers.Contract | null>(null);
  const [memos, setMemos] = useState<Memo[]>([]);
  const [name, setName] = useState("");
  const [message, setMessage] = useState("");
  const [amount, setAmount] = useState("0.001");
  const [isLoading, setIsLoading] = useState(false);
  const [isOwner, setIsOwner] = useState(false);

  // 监听网络切换
  useEffect(() => {
    if (typeof window !== "undefined" && (window as any).ethereum) {
      const handleChainChanged = () => {
        window.location.reload();
      };

      const handleAccountsChanged = (accounts: string[]) => {
        if (accounts.length === 0) {
          setAccount("");
          setContract(null);
        } else if (accounts[0] !== account) {
          window.location.reload();
        }
      };

      (window as any).ethereum.on("chainChanged", handleChainChanged);
      (window as any).ethereum.on("accountsChanged", handleAccountsChanged);

      return () => {
        (window as any).ethereum.removeListener("chainChanged", handleChainChanged);
        (window as any).ethereum.removeListener("accountsChanged", handleAccountsChanged);
      };
    }
  }, [account]);

  // 检查是否安装了 MetaMask
  const checkMetaMask = () => {
    if (typeof window !== "undefined" && !(window as any).ethereum) {
      alert("请安装 MetaMask 钱包！");
      return false;
    }
    return true;
  };

  // 连接钱包
  const connectWallet = async () => {
    if (!checkMetaMask()) return;

    try {
      const ethereum = (window as any).ethereum;
      
      // 详细日志：查看当前网络
      const chainId = await ethereum.request({ method: 'eth_chainId' });
      console.log("🔍 当前网络 Chain ID:", chainId);
      console.log("🔍 Chain ID (十进制):", parseInt(chainId, 16));
      
      // 如果不是 Kaia Kairos，尝试切换
      if (chainId !== '0x3e9') { // 0x3e9 = 1001
        console.log("⚠️  不在 Kaia Kairos 网络，尝试切换...");
        try {
          await switchToKairos();
          console.log("✅ 网络切换成功");
        } catch (switchError) {
          console.error("❌ 网络切换失败:", switchError);
          alert("请手动切换 MetaMask 到 Kaia Kairos 测试网\n\n网络信息：\n名称: Kaia Kairos Testnet\nRPC: https://public-en.kairos.kaia.io\nChain ID: 1001");
          return;
        }
      } else {
        console.log("✅ 已在 Kaia Kairos 网络");
      }

      console.log("🔄 创建 Provider...");
      const provider = new ethers.BrowserProvider(ethereum);
      
      console.log("🔄 请求账户访问...");
      await provider.send("eth_requestAccounts", []);
      
      console.log("🔄 获取 Signer...");
      const signer = await provider.getSigner();
      
      console.log("🔄 获取地址...");
      const address = await signer.getAddress();
      console.log("✅ 钱包地址:", address);
      
      setAccount(address);

      // 连接合约
      console.log("🔄 连接合约:", CONTRACT_ADDRESS);
      const contractInstance = new ethers.Contract(
        CONTRACT_ADDRESS,
        CONTRACT_ABI,
        signer
      );
      setContract(contractInstance);

      // 检查是否是合约所有者
      try {
        const ownerAddress = await contractInstance.owner();
        setIsOwner(address.toLowerCase() === ownerAddress.toLowerCase());
        console.log("✅ 合约所有者检查完成");
      } catch (err) {
        console.log("⚠️  无法检查所有者状态:", err);
      }

      // 加载备忘录
      console.log("🔄 加载备忘录...");
      await loadMemos(contractInstance);
      console.log("✅ 备忘录加载完成");
      
      console.log("🎉 钱包连接成功！");
    } catch (error: any) {
      console.error("❌ 连接钱包失败 - 详细错误:", error);
      console.error("错误类型:", error.name);
      console.error("错误消息:", error.message);
      console.error("错误代码:", error.code);
      
      let errorMessage = "连接钱包失败！\n\n";
      
      if (error.code === 4001) {
        errorMessage += "原因：你拒绝了连接请求";
      } else if (error.code === -32002) {
        errorMessage += "原因：请先在 MetaMask 中处理待处理的请求";
      } else if (error.message.includes("network")) {
        errorMessage += "原因：网络问题\n\n请确保：\n1. MetaMask 连接到 Kaia Kairos 测试网\n2. Chain ID 是 1001\n3. RPC URL 是 https://public-en.kairos.kaia.io";
      } else {
        errorMessage += `原因：${error.message}`;
      }
      
      alert(errorMessage);
    }
  };

  // 切换到 Kaia Kairos 测试网
  const switchToKairos = async () => {
    try {
      await (window as any).ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: KAIROS_NETWORK.chainId }],
      });
    } catch (switchError: any) {
      // 网络不存在，添加网络
      if (switchError.code === 4902) {
        try {
          await (window as any).ethereum.request({
            method: "wallet_addEthereumChain",
            params: [KAIROS_NETWORK],
          });
        } catch (addError) {
          console.error("添加网络失败:", addError);
        }
      }
    }
  };

  // 加载所有备忘录
  const loadMemos = async (contractInstance: ethers.Contract) => {
    try {
      const memosList = await contractInstance.getMemos();
      setMemos(memosList);
    } catch (error) {
      console.error("加载备忘录失败:", error);
    }
  };

  // 购买咖啡
  const buyCoffee = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!contract) {
      alert("请先连接钱包！");
      return;
    }

    if (!name || !message) {
      alert("请填写姓名和留言！");
      return;
    }

    setIsLoading(true);

    try {
      const tx = await contract.buyCoffee(name, message, {
        value: ethers.parseEther(amount),
      });

      await tx.wait();
      
      alert("感谢您的咖啡！☕");
      
      // 清空表单
      setName("");
      setMessage("");
      
      // 重新加载备忘录
      await loadMemos(contract);
    } catch (error: any) {
      console.error("购买咖啡失败:", error);
      alert("交易失败：" + (error.message || "未知错误"));
    } finally {
      setIsLoading(false);
    }
  };

  // 提现
  const withdrawTips = async () => {
    if (!contract) return;

    setIsLoading(true);

    try {
      const tx = await contract.withdrawTips();
      await tx.wait();
      alert("提现成功！");
    } catch (error: any) {
      console.error("提现失败:", error);
      alert("提现失败：" + (error.message || "未知错误"));
    } finally {
      setIsLoading(false);
    }
  };

  // 格式化地址
  const formatAddress = (address: string) => {
    return `${address.substring(0, 6)}...${address.substring(address.length - 4)}`;
  };

  // 格式化时间
  const formatTimestamp = (timestamp: bigint) => {
    const date = new Date(Number(timestamp) * 1000);
    return date.toLocaleString("zh-CN");
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-amber-50 to-orange-100">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <header className="text-center mb-12">
          <h1 className="text-5xl font-bold text-amber-900 mb-4">
            ☕ Buy Me A Coffee
          </h1>
          <p className="text-xl text-amber-700 mb-6">
            用 KAIA 请我喝杯咖啡，支持我的创作！
          </p>
          
          {!account ? (
            <button
              onClick={connectWallet}
              className="bg-amber-600 hover:bg-amber-700 text-white font-bold py-3 px-8 rounded-full transition duration-300 shadow-lg"
            >
              连接钱包
            </button>
          ) : (
            <div className="inline-block bg-white px-6 py-3 rounded-full shadow-md">
              <p className="text-amber-900 font-semibold">
                已连接: {formatAddress(account)}
              </p>
            </div>
          )}
        </header>

        <div className="max-w-6xl mx-auto grid md:grid-cols-2 gap-8">
          {/* 购买咖啡表单 */}
          <div className="bg-white rounded-2xl shadow-xl p-8">
            <h2 className="text-2xl font-bold text-amber-900 mb-6">
              请我喝咖啡
            </h2>
            
            <form onSubmit={buyCoffee} className="space-y-4">
                <div>
                  <label className="block text-amber-900 font-semibold mb-2">
                    您的名字
                  </label>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className="w-full px-4 py-2 border-2 border-amber-200 rounded-lg focus:outline-none focus:border-amber-500"
                    placeholder="输入您的名字"
                    disabled={isLoading}
                  />
                </div>

                <div>
                  <label className="block text-amber-900 font-semibold mb-2">
                    留言
                  </label>
                  <textarea
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    className="w-full px-4 py-2 border-2 border-amber-200 rounded-lg focus:outline-none focus:border-amber-500 h-24"
                    placeholder="说点什么..."
                    disabled={isLoading}
                  />
                </div>

                <div>
                  <label className="block text-amber-900 font-semibold mb-2">
                    金额 (KAIA)
                  </label>
                  <input
                    type="number"
                    step="0.001"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    className="w-full px-4 py-2 border-2 border-amber-200 rounded-lg focus:outline-none focus:border-amber-500"
                    disabled={isLoading}
                  />
                </div>

                <button
                  type="submit"
                  disabled={isLoading || !account}
                  className="w-full bg-amber-600 hover:bg-amber-700 text-white font-bold py-3 rounded-lg transition duration-300 disabled:bg-gray-400"
                >
                  {isLoading ? "处理中..." : "送出咖啡 ☕"}
                </button>
              </form>

            {isOwner && (
              <div className="mt-6 pt-6 border-t border-amber-200">
                <button
                  onClick={withdrawTips}
                  disabled={isLoading}
                  className="w-full bg-green-600 hover:bg-green-700 text-white font-bold py-3 rounded-lg transition duration-300"
                >
                  提现小费
                </button>
              </div>
            )}
          </div>

          {/* 留言板 */}
          <div className="bg-white rounded-2xl shadow-xl p-8">
            <h2 className="text-2xl font-bold text-amber-900 mb-6">
              留言墙 ({memos.length})
            </h2>
            
            <div className="space-y-4 max-h-[600px] overflow-y-auto">
              {memos.length === 0 ? (
                <p className="text-gray-500 text-center py-8">
                  还没有留言，成为第一个吧！
                </p>
              ) : (
                [...memos].reverse().map((memo, index) => (
                  <div
                    key={index}
                    className="bg-amber-50 rounded-lg p-4 border-l-4 border-amber-500"
                  >
                    <div className="flex justify-between items-start mb-2">
                      <p className="font-bold text-amber-900">{memo.name}</p>
                      <p className="text-xs text-amber-600">
                        {formatTimestamp(memo.timestamp)}
                      </p>
                    </div>
                    <p className="text-gray-700 mb-2">{memo.message}</p>
                    <p className="text-xs text-amber-600">
                      来自: {formatAddress(memo.from)}
                    </p>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>

        {/* Footer */}
        <footer className="text-center mt-12 text-amber-700">
          <p>基于 Kaia Kairos 测试网构建</p>
          <p className="text-sm mt-2">
            <a
              href="https://docs.kaia.io"
            target="_blank"
            rel="noopener noreferrer"
              className="hover:text-amber-900 underline"
            >
              Kaia 文档
            </a>
            {" | "}
            <a
              href="https://www.kaia.io/faucet"
            target="_blank"
            rel="noopener noreferrer"
              className="hover:text-amber-900 underline"
          >
              获取测试 KAIA
          </a>
          </p>
        </footer>
        </div>
    </div>
  );
}
