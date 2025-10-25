# 区块链学习笔记 📚

> 这是一个专注于区块链技术深度学习的个人笔记项目，通过逐行代码解析的方式深入理解各种DeFi协议的核心机制。

## 🎯 项目简介

本项目整合了我的区块链学习历程，采用**代码逐行深度解析**的学习方式，深入理解各种DeFi协议的设计思想和实现细节。通过系统性的学习笔记，记录从基础概念到高级应用的完整学习路径。

## 📅 学习进展记录

| 日期范围 | 学习主题 | 学习内容概述 |
| :---: | :--- | :--- |
| **9.10 - 9.20** | **UniswapV2_Chinese** | **UniswapV2** 核心合约代码逐行深度解析。 |
| **9.20 - 9.23** | **UniswapV3_Chinese** | **UniswapV3** 核心合约代码逐行深度解析。 |
| **9.23 - 9.24** | **Uniswap_Explain_Examples** | **Uniswap** 平台实际操作记录与交易解析。 |
| **9.25 - 9.26** | **ZKP** | **零知识证明** 初步理解。 |
| **9.26 - 9.27** | **Cross-chain-bridge / ZKP / Token Economy** | **跨链桥** 初步理解。<br>**ZKP** 补充基础知识：**承诺函数**。<br>**Token Economy** 作业 1：实现区块链浏览器的数据读取与分析。 |
| **9.29 - 9.30** | **Defi lending system / ZKP (KZG)** | **Defi 借贷体系** 初步理解与原理分析。<br>**ZKP** 进阶知识学习：**KZG 承诺**。 |
| **9.30 - 10.1** | **Oracle / ZKP** | **预言机** 初步理解与原理分析。<br>**ZKP** 知识补充：**PLONK算术化和证明过程详细解释**。 |
| **10.1 - 10.2** | **ZKP / Traditional Finance / Stablecoin** | **ZKP** ZK-Lookup深度理解。<br>**传统金融(复习)** 。**稳定币(复习)** |
| **10.2 - 10.3** | **Token Economy** | <br>**Token Economy** : 课程知识全部总结 |
| **10.3 - 10.4** | **ZKP** | <br>**ZKP** : ZK-Lookup：Logup |
| **10.4 - 10.5** | **Solidity** | <br>**Solidity Test/BasicKnowledge** : 做一些Solidity的基本练习 |
| **10.5 - 10.6** | **ZKP / Decentralized Identity** | <br>**ZKP** : 进阶知识学习：**ZKVM基本原理理解**。<br>**Decentralized Identity**: 初步理解与原理分析 |
| **10.6 - 10.7** | **ZKP / DDEX** | <br>**ZKP** : 进阶知识学习：**用ZK实现去中心化加密计算**。<br>**DDEX**: 初步理解与原理分析 + Hyperliquid原理理解 |
| **10.7 - 10.11** | **Go Test** | <br>**Go Test** : 基本语法学习 + 基于Web3的实战。 |
| **10.10 - 10.11** | **ZKP** | <br>**ZKP** : ZK-Rollup复习，笔记更新 + ZK-Swap基本理解 |
| **10.11 - 10.13** | **ZKP / Cryptography** | <br>**ZKP** : Nova 基本理解。<br>**Cryptography** : 课程知识全部总结 |
| **10.13 - 10.14** | **ZKP** | <br>**ZKP** : Halo2 基本理解 |
| **10.14 - 10.16** | **Distributed System** | <br>***Distributed System** : 课程知识全部总结 + 课程大作业 |
| **10.17 - 10.18** | **Cryptography/Project** | <br>**Project** : 课程大作业：攻击DLP |
| **10.18 - 10.19** | **Introduction of Blockchain** | <br>**Introduction of Blockchain** : 课程知识全部总结 |
| **10.20 - 10.21** | **1inch_Chinese** | <br>**1inch_Chinese** : 核心合约代码逐行深度解析。|

## 🌟 里程碑

  * **10.07 - 今天：** ：**加入 Fracted 项目组**，开始实际项目开发与协作。

## 📁 项目结构

```
BlockChain_Book/
├── After-Class Knowledge/          # 课后知识学习
│   ├── 1inch_chinese/            # 1inch协议学习笔记
│   │   ├── contracts/           # 核心智能合约
│   │   │   ├── OneSplit.sol     # 主聚合合约
│   │   │   ├── OneSplitBase.sol # 基础功能合约
│   │   │   ├── IOneSplit.sol    # 接口定义
│   │   │   ├── UniversalERC20.sol # ERC20工具库
│   │   │   └── interface/       # 各种DEX接口
│   │   ├── img/                 # 学习图表
│   │   └── README.md           # 1inch学习文档
│   └── [其他学习模块...]
├── Classroom knowledge/          # 课堂知识
│   └── Introduction of Blockchain/ # 区块链入门课程
└── README.md                    # 项目总览
```

## 🔍 当前学习重点：1inch协议

### 什么是1inch？

1inch是一个**DEX聚合器协议**，通过智能路由算法为用户找到最优的交易路径，实现最佳价格执行。它整合了多个去中心化交易所，包括：

- **Uniswap V1/V2**
- **Kyber Network**
- **Bancor**
- **Curve**
- **Balancer**
- **Mooniswap**
- 等多个DEX

### 核心学习文件

经过筛选，以下文件对学习1inch协议最为重要：

#### 🎯 核心合约
- **`OneSplit.sol`** - 主聚合合约，实现核心交换逻辑
- **`OneSplitBase.sol`** - 基础功能合约，包含所有DEX集成
- **`IOneSplit.sol`** - 接口定义，理解协议规范

#### 🛠️ 工具合约
- **`UniversalERC20.sol`** - ERC20代币统一处理库
- **`BalancerLib.sol`** - Balancer协议集成库

#### 🔌 接口文件
- **`interface/`** 目录下的各种DEX接口文件，理解各协议集成方式

### 学习方式

采用**逐行代码解析**的方式：
1. 从接口定义开始，理解协议规范
2. 深入核心合约，分析算法逻辑
3. 研究各DEX集成，理解聚合机制
4. 通过实际案例，验证理论理解

## ⏳ 后续学习计划展望 (2025.10 - 2026.11)

  * **[2025.10]**：合约开发基本程序设计语言：Solidity/Rust

## 📝 学习笔记特色

- **深度解析**：每行代码都有详细注释和原理解释
- **实践导向**：结合理论学习和实际应用
- **系统化**：从基础到高级的完整学习路径
- **持续更新**：跟随技术发展不断补充新内容

---

*这个项目记录了我从区块链初学者到深度研究者的完整学习历程，希望能为同样热爱区块链技术的朋友提供参考。*