# 1inch协议

在本项目中，我对1inch协议的5个核心合约代码做了详细的中文注释，包含了我对DEX聚合器原理的理解，必要的关键字解释和DeFi聚合协议的设计思想。适合有编程基础并且对DeFi已有了解的同学们一起讨论。

五个关键合约文件为（包含路径，避免找错）：

1. `contracts/IOneSplit.sol` - 协议接口定义
2. `contracts/OneSplitBase.sol` - 核心算法实现  
3. `contracts/OneSplitAudit.sol` - 主审计合约
4. `contracts/UniversalERC20.sol` - 通用代币处理库
5. `contracts/OneSplit.sol` - 协议集成合约

－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－

为了帮助理解1inch协议的原理，我选择了3个典型场景来帮助读者串起各个关键合约的功能，建议在阅读完合约理解后配合理解。

## 致谢
1inch团队提供的源码：https://github.com/1inch/1inchProtocol
成都信息工程学院梁培利老师的区块链金融公开课：https://www.bilibili.com/video/BV1xs4y127xW
1inch官方文档：https://docs.1inch.exchange/

---

## 1inch协议概述

1inch是一个去中心化交易所聚合器，通过智能合约自动寻找最优的交易路径，为用户提供最佳的交易价格。协议的核心思想是：

1. **DEX聚合 - 连接多个DEX**
2. **路径优化 - 使用动态规划算法找到最优分配**
3. **Gas优化 - 通过CHI代币燃烧节省交易费用**
4. **安全第一 - 多重安全检查和事件记录**

## 核心架构

```
用户调用
    ↓
OneSplitAudit (代理合约)
    ↓
OneSplitBase (实现合约)
    ↓
各种DEX协议 (Uniswap, Curve, Kyber等)
```

## 核心功能流程

### 1. 查询阶段
```solidity
// 用户调用查询函数
getExpectedReturn(fromToken, destToken, amount, parts, flags)
    ↓
// 内部调用核心算法
getExpectedReturnWithGas(fromToken, destToken, amount, parts, flags, gasPrice)
    ↓
// 使用动态规划找到最优分配
_findBestDistribution(parts, matrix)
```

### 2. 执行阶段
```solidity
// 用户执行交换
swap(fromToken, destToken, amount, minReturn, distribution, flags)
    ↓
// 安全检查和处理
OneSplitAudit.swap()
    ↓
// 调用实现合约
OneSplitBase.swap()
    ↓
// 执行实际交换
各种DEX协议交换
```

## 关键设计模式

### 1. 代理模式
- `OneSplitAudit`作为代理合约，负责安全检查和事件记录
- `OneSplitBase`作为实现合约，包含核心业务逻辑
- 支持合约升级，提高协议的可维护性

### 2. 模块化设计
- 每个DEX都有独立的集成模块
- 通过多重继承实现功能组合
- 易于添加新的DEX协议

### 3. 动态规划算法
- 使用背包问题的变种算法
- 通过路径回溯构建最优分配方案
- 考虑Gas费用对最终收益的影响

## 支持的DEX协议

### Split类型（直接交换）
- Uniswap V1/V2
- Kyber Network
- Bancor
- Curve
- Mooniswap
- Balancer
- DForce Swap
- Shell
- mStable

### Wrap类型（包装交换）
- CHAI
- bDai
- Aave
- Fulcrum
- Compound
- iEarn
- Idle
- WETH

## 安全特性

### 1. 多重安全检查
- 代币授权检查
- 最小返回金额保护
- 重入攻击防护

### 2. Gas优化
- CHI代币燃烧（节省高达43%的Gas费用）
- 推荐Gas赞助
- 精确计算标志

### 3. 事件记录
- 完整的交换事件记录
- 便于监控和分析
- 支持推荐系统

## 使用示例

### 基本交换
```solidity
// 1. 查询最优路径
(uint256 returnAmount, uint256[] memory distribution) = 
    oneSplit.getExpectedReturn(DAI, WETH, 1000e18, 10, 0);

// 2. 执行交换
uint256 received = oneSplit.swap(
    DAI,           // 源代币
    WETH,          // 目标代币
    1000e18,       // 交换数量
    950e18,        // 最小返回金额
    distribution,  // 分配方案
    0              // 标志位
);
```

### 带推荐的交换
```solidity
uint256 received = oneSplit.swapWithReferral(
    DAI,           // 源代币
    WETH,          // 目标代币
    1000e18,       // 交换数量
    950e18,        // 最小返回金额
    distribution,  // 分配方案
    0,             // 标志位
    referral,      // 推荐人地址
    10000000000000000  // 1%手续费
);
```

## 标志位系统

### 禁用特定DEX
```solidity
uint256 flags = FLAG_DISABLE_UNISWAP | FLAG_DISABLE_KYBER;
```

### 启用Gas优化
```solidity
uint256 flags = FLAG_ENABLE_CHI_BURN;
```

### 启用推荐Gas赞助
```solidity
uint256 flags = FLAG_ENABLE_REFERRAL_GAS_SPONSORSHIP;
```