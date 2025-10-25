# 网络结构与智能合约

## 1、区块链网络结构

区块链网络是一个去中心化的点对点(P2P)网络。理解网络结构对于把握区块链系统的整体架构至关重要。

---

### 1.1、P2P网络基础

#### 1.1.1、什么是P2P网络？

P2P(Peer-to-Peer)网络是一种分布式网络架构，其中每个节点既是客户端也是服务器。

**传统客户端-服务器模型 vs P2P网络:**

```
传统模型:
客户端1 ──┐
客户端2 ──┼──→ 中心服务器
客户端3 ──┘

P2P网络:
节点1 ←─→ 节点2
  ↕         ↕
节点4 ←─→ 节点3
```

**P2P网络的优势:**

| 特性 | 传统网络 | P2P网络 |
|------|---------|---------|
| **单点故障** | 存在 | 不存在 |
| **可扩展性** | 受限于中心服务器 | 节点越多越强大 |
| **抗审查性** | 弱 | 强 |
| **成本** | 需要维护中心服务器 | 由网络共同承担 |

#### 1.1.2、区块链网络层次

区块链网络可以分为四层：

```
┌─────────────────────────┐
│   应用层                 │ ← DApp、钱包、区块链浏览器
├─────────────────────────┤
│   共识层                 │ ← PoW、PoS等共识机制
├─────────────────────────┤
│   网络层                 │ ← P2P通信、节点发现、消息传播
├─────────────────────────┤
│   数据层                 │ ← 区块、交易、Merkle树
└─────────────────────────┘
```

**各层功能:**

1. **数据层**: 存储区块链的实际数据
2. **网络层**: 负责节点间的通信
3. **共识层**: 确保所有节点对数据达成一致
4. **应用层**: 面向用户的应用程序

---

### 1.2、网络节点类型

在区块链网络中，不是所有节点都一样。根据功能不同，节点可以分为几种类型。

#### 1.2.1、全节点 (Full Node)

全节点是区块链网络的"完整参与者"，它保存完整的区块链数据并验证所有交易。

**全节点的职责:**

```
1. 存储完整区块链
   - 比特币: 约500GB (2024年)
   - 以太坊: 约1TB

2. 验证所有交易
   - 检查签名是否有效
   - 验证是否有足够余额
   - 确保没有双花

3. 验证所有区块
   - 验证PoW/PoS证明
   - 检查Merkle根
   - 确保区块符合协议规则

4. 转发信息
   - 将新交易传播给其他节点
   - 转发新区块
```

**运行全节点的要求:**

| 资源 | 比特币 | 以太坊 |
|------|--------|--------|
| **存储** | 500GB+ | 1TB+ |
| **内存** | 2GB+ | 8GB+ |
| **网络** | 需要稳定连接 | 需要稳定连接 |
| **同步时间** | 数天 | 数天到一周 |

**为什么要运行全节点？**

- **安全性**: 不需要信任其他人，自己验证一切
- **隐私性**: 不会向第三方泄露你的交易信息
- **支持网络**: 为网络提供基础设施
- **投票权**: 在某些升级决策中有发言权

#### 1.2.2、轻节点 (Light Node / SPV Node)

轻节点只下载区块头，不下载完整区块，适合资源受限的设备（如手机）。

**SPV (Simplified Payment Verification) 原理:**

轻节点通过Merkle证明验证交易，而不需要完整区块。

```
步骤1: 轻节点只下载区块头
区块头 (80字节) vs 完整区块 (可能几MB)

步骤2: 当需要验证交易时
1. 向全节点请求Merkle证明
2. 全节点返回:
   - 目标交易
   - Merkle路径 (log(n)个哈希)
   
步骤3: 轻节点验证
1. 使用Merkle证明计算根哈希
2. 与区块头中的Merkle根对比
3. 如果匹配，交易确实在区块中
```

**轻节点 vs 全节点:**

| 特性 | 全节点 | 轻节点 |
|------|--------|--------|
| **存储需求** | 500GB+ | 几百MB |
| **验证能力** | 验证一切 | 只验证与自己相关的交易 |
| **安全性** | 最高 | 较高（信任算力最多的链） |
| **启动时间** | 数天 | 几分钟 |
| **适用场景** | 服务器、桌面 | 移动设备 |

#### 1.2.3、矿工节点 (Mining Node)

矿工节点专门负责创建新区块（在PoW系统中）。

**矿工节点的工作流程:**

```
1. 收集交易
   - 从网络接收待确认交易
   - 放入内存池(Mempool)
   - 优先选择手续费高的交易

2. 构建区块
   - 创建Coinbase交易（给自己的奖励）
   - 选择交易打包进区块
   - 构建Merkle树

3. 挖矿
   While True:
       尝试不同的nonce
       计算区块哈希
       if 哈希 < 目标难度:
           找到了！广播区块
           break

4. 获得奖励
   - 区块奖励 (如比特币目前6.25 BTC)
   - 交易手续费
```

**挖矿池 (Mining Pool):**

单个矿工很难挖到区块，所以矿工会组成矿池：

```
矿池运作方式:

矿池服务器
    │
    ├─→ 矿工1 (10 TH/s)
    ├─→ 矿工2 (15 TH/s)
    ├─→ 矿工3 (20 TH/s)
    └─→ ...

1. 矿池分配任务给各个矿工
2. 矿工提交工作证明(shares)
3. 任意矿工找到有效区块时，奖励归矿池
4. 矿池按贡献分配奖励给各矿工
```

**常见的挖矿池分配方式:**

- **PPS (Pay Per Share)**: 每提交一个share就支付，风险由矿池承担
- **PPLNS (Pay Per Last N Shares)**: 根据最近N个share分配，运气好坏影响收益
- **FPPS (Full Pay Per Share)**: PPS + 交易费分配

---

### 1.3、节点发现与网络拓扑

新节点如何加入区块链网络？其他节点如何找到彼此？

#### 1.3.1、节点发现机制

**引导节点 (Bootstrap Nodes):**

每个区块链客户端都硬编码了一些"引导节点"的地址：

```
比特币核心客户端中的引导节点:
seed.bitcoin.sipa.be
dnsseed.bluematt.me
dnsseed.bitcoin.dashjr.org
...

新节点启动流程:
1. 连接到引导节点
2. 请求: "给我一些其他节点的地址"
3. 引导节点返回: [节点1, 节点2, ..., 节点N]
4. 新节点连接到这些节点
5. 重复请求，建立连接网络
```

**地址传播 (Address Propagation):**

节点之间会互相分享已知的节点地址：

```
节点A连接到节点B后:
1. A发送: "我知道这些节点: [节点C, 节点D, ...]"
2. B回应: "我知道这些节点: [节点E, 节点F, ...]"
3. 双方更新各自的节点列表
4. 定期重复这个过程
```

#### 1.3.2、网络拓扑

比特币网络是一个随机图(Random Graph)，每个节点通常连接8-125个其他节点。

```
典型的网络拓扑:

节点1 ←→ 节点2 ←→ 节点5
 ↕         ↕         ↕
节点3 ←→ 节点4 ←→ 节点6
 ↕         ↕         ↕
节点7 ←→ 节点8 ←→ 节点9

每个节点连接若干邻居
消息通过邻居传播到整个网络
```

**连接策略:**

```
比特币节点的连接策略:
- 出站连接: 8个（主动连接其他节点）
- 入站连接: 最多125个（接受其他节点连接）
- 为什么限制连接数？
  · 防止资源耗尽
  · 保持网络去中心化
  · 提高传播效率
```

---

### 1.4、消息传播机制

当一笔新交易或新区块产生时，如何快速传播到整个网络？

#### 1.4.1、交易传播

```
交易传播的"洪泛算法"(Flooding):

1. 用户创建交易，发送给节点A
2. 节点A验证交易有效性
3. 如果有效，A将交易转发给所有邻居（除了发送者）
4. 邻居节点B, C, D收到交易
5. B, C, D各自验证，然后转发给它们的邻居
6. 重复这个过程，直到覆盖全网络

优化:
- 不重复转发（记录已见过的交易）
- 批量转发（Inv消息）
```

**Inv/GetData机制:**

为了节省带宽，节点不直接发送完整交易，而是：

```
节点A → 节点B: "我有这些新交易 [Hash1, Hash2, ...]" (Inv消息)
节点B检查: "Hash1我已经有了，Hash2我需要"
节点B → 节点A: "给我Hash2的完整数据" (GetData消息)
节点A → 节点B: 发送完整交易数据
```

#### 1.4.2、区块传播

区块传播类似，但更关键（因为关系到共识）：

```
区块传播优化技术:

1. Compact Blocks (紧凑区块)
   传统方式:
   - 发送完整区块 (1-2 MB)
   
   Compact Blocks:
   - 假设接收方已经有大部分交易（在mempool中）
   - 只发送: 区块头 + 交易索引
   - 接收方从mempool重构区块
   - 节省90%以上带宽

2. FIBRE (Fast Internet Bitcoin Relay Engine)
   - 专门为矿工优化的中继网络
   - 使用专用连接和UDP协议
   - 可在100ms内传播到全球主要矿池

3. 区块只传播一次
   - 验证后立即转发（Pipeline）
   - 不等待完全下载
```

---

### 1.5、分叉处理

当两个矿工同时挖出区块时会发生什么？

#### 1.5.1、临时分叉

```
初始状态:
...→ Block 100

两个矿工同时挖出Block 101:
         → Block 101A (矿工A挖出)
       /
Block 100
       \
         → Block 101B (矿工B挖出)

网络分裂:
- 靠近矿工A的节点看到Block 101A
- 靠近矿工B的节点看到Block 101B
- 都是有效区块！

解决: 最长链规则
假设矿工C基于Block 101A挖出Block 102:

...→ Block 100 → Block 101A → Block 102  ← 更长，胜出
               \
                → Block 101B (被放弃)

所有节点切换到更长的链
Block 101B中的交易回到mempool
```

**为什么这个机制有效？**

```
概率分析:
- 诚实节点有更多算力（假设>50%）
- 诚实节点都在最长链上工作
- 因此最长链会越来越长
- 攻击者的短链会被超越

确认深度:
- 1个确认: 有可能被回滚
- 3个确认: 较安全
- 6个确认: 非常安全（比特币标准）
- 区块越深，回滚越难
```

---

## 2、智能合约

智能合约是区块链技术的重大突破。如果说比特币实现了"可编程的货币"，那么智能合约实现了"可编程的法律"。

---

### 2.1、智能合约概述

#### 2.1.1、什么是智能合约？

智能合约是运行在区块链上的程序，它可以自动执行、控制或记录法律相关的事件和行动。

**通俗理解:**

```
传统合约:
"如果A发生，那么执行B"
- 需要人工判断A是否发生
- 需要人工执行B
- 可能有争议

智能合约:
if (A发生) {
    自动执行B
}
- 代码自动判断
- 代码自动执行
- 无需信任第三方
```

**自动售货机类比:**

尼克·萨博(Nick Szabo)在1994年提出了智能合约的概念，他用自动售货机来类比：

```
自动售货机:
1. 投入1美元
2. 选择商品
3. 如果金额足够 → 自动出货
4. 如果金额不足 → 退回硬币

智能合约:
1. 发送交易（包含金额和参数）
2. 合约检查条件
3. 如果条件满足 → 自动执行
4. 如果条件不满足 → 回滚交易
```

#### 2.1.2、智能合约的特性

**1. 自动执行 (Automatic Execution)**

```
传统流程:
买家 → 付款 → 等待卖家确认 → 卖家发货

智能合约流程:
买家 → 调用合约并付款 → 合约自动验证 → 自动执行

无需等待，无需信任对方
```

**2. 去中心化 (Decentralization)**

```
合约部署后:
- 运行在成千上万个节点上
- 没有人可以单独关闭它
- 没有中心服务器
- 抗审查
```

**3. 不可篡改 (Immutability)**

```
合约部署后:
- 代码不能修改（除非设计了升级机制）
- 历史执行记录永久保存
- 任何人都无法删除或修改

优点: 可信、可审计
缺点: 如果有bug，很难修复
```

**4. 透明性 (Transparency)**

```
合约代码公开:
- 任何人都可以查看源代码
- 可以审计逻辑是否正确
- "代码即法律"

但也可以实现隐私:
- 数据可以加密
- 使用零知识证明
```

---

### 2.2、以太坊虚拟机 (EVM)

以太坊虚拟机是智能合约的运行环境。

#### 2.2.1、EVM基础

**什么是EVM？**

```
EVM = 以太坊虚拟机 (Ethereum Virtual Machine)

类比:
- Java程序运行在JVM上
- JavaScript运行在浏览器的JS引擎上
- 智能合约运行在EVM上

EVM是一个:
- 图灵完备的虚拟机
- 沙盒环境（隔离，不能访问外部资源）
- 确定性的（相同输入总是产生相同输出）
```

**EVM的设计特点:**

| 特性 | 说明 |
|------|------|
| **栈式虚拟机** | 基于栈的指令集，不是寄存器 |
| **256位字长** | 所有操作基于256位整数（匹配哈希和密钥长度） |
| **确定性** | 相同输入产生相同输出（对共识至关重要） |
| **隔离性** | 智能合约无法访问网络、文件系统等外部资源 |
| **Gas计量** | 每个操作消耗Gas，防止无限循环 |

#### 2.2.2、EVM的工作原理

```
智能合约执行流程:

1. Solidity源代码
   contract SimpleStorage {
       uint256 value;
       function set(uint256 x) public {
           value = x;
       }
   }

2. 编译为字节码
   0x608060405234801561001057600080fd5b50...
   
3. 部署到区块链
   - 创建交易，data字段包含字节码
   - 交易被打包进区块
   - 合约被分配地址

4. 调用合约
   - 创建交易，to字段为合约地址
   - data字段包含函数调用编码
   - EVM执行字节码
   - 状态改变被记录
```

**EVM的内存模型:**

```
EVM有三个存储数据的地方:

1. Storage (永久存储)
   - 存储在区块链上
   - 永久保存
   - 读写最贵 (20,000 Gas写入)
   
   uint256 value;  // 存储在Storage

2. Memory (临时内存)
   - 函数执行时使用
   - 函数结束后清空
   - 相对便宜
   
   function f() public {
       uint256[] memory temp;  // 临时数组
   }

3. Stack (栈)
   - 最多1024个元素
   - EVM指令操作栈
   - 最便宜
```

---

### 2.3、Gas机制

Gas是以太坊最重要的机制之一，它防止了资源滥用。

#### 2.3.1、为什么需要Gas？

**问题: 停机问题**

```
如果允许无限循环:

contract Evil {
    function dos() public {
        while(true) {  // 无限循环
            // 节点会永远执行，无法响应其他请求
        }
    }
}

网络会被攻击者瘫痪！
```

**解决方案: Gas**

```
每个操作都消耗Gas:
- 加法: 3 Gas
- 乘法: 5 Gas
- 存储写入: 20,000 Gas
- ...

用户设置Gas Limit:
- 这笔交易最多消耗多少Gas

如果Gas用完:
- 执行中止
- 状态回滚
- Gas费不退还（已消耗的计算资源）
```

#### 2.3.2、Gas的计算

```
Gas费用 = Gas Used × Gas Price

示例:
一笔转账交易:
- Gas Used = 21,000 Gas
- Gas Price = 50 Gwei (用户设定)
- 总费用 = 21,000 × 50 Gwei = 1,050,000 Gwei = 0.00105 ETH

如果ETH价格是$2000:
- 实际费用 = 0.00105 × $2000 = $2.1
```

**不同操作的Gas消耗:**

| 操作 | Gas消耗 | 说明 |
|------|---------|------|
| 基础交易 | 21,000 | 最简单的ETH转账 |
| 数据存储(零→非零) | 20,000 | 写入新数据 |
| 数据存储(非零→非零) | 5,000 | 修改现有数据 |
| 数据存储(非零→零) | -15,000 | 删除数据有退款 |
| 加法/减法 | 3 | 算术运算 |
| 乘法/除法 | 5 | 稍贵的运算 |
| SHA3 | 30 + 数据 | 哈希计算 |
| SLOAD | 800 | 读取存储 |

#### 2.3.3、Gas优化技巧

**1. 使用合适的数据类型**

```solidity
// 不好: 浪费空间
contract Bad {
    uint8 a;   // 使用一个存储槽，但只用了8位
    uint256 b; // 新的存储槽
    uint8 c;   // 又一个新存储槽
}
// 总共使用3个存储槽

// 好: 打包存储
contract Good {
    uint8 a;    // 
    uint8 c;    // 这三个打包在一个存储槽中
    uint256 b;  // 单独一个存储槽
}
// 总共使用2个存储槽，节省5,000 Gas!
```

**2. 使用memory代替storage**

```solidity
// 不好: 每次都读取storage
function sumArray(uint256[] storage arr) internal view returns (uint256) {
    uint256 sum = 0;
    for(uint i = 0; i < arr.length; i++) {
        sum += arr[i];  // 每次循环读取storage，800 Gas
    }
    return sum;
}

// 好: 先复制到memory
function sumArray(uint256[] storage arr) internal view returns (uint256) {
    uint256[] memory tempArr = arr;  // 复制到memory
    uint256 sum = 0;
    for(uint i = 0; i < tempArr.length; i++) {
        sum += tempArr[i];  // 读取memory，3 Gas
    }
    return sum;
}
```

**3. 使用事件(Events)代替存储**

```solidity
// 不好: 存储历史记录
contract Bad {
    struct Record {
        uint256 value;
        uint256 timestamp;
    }
    Record[] public history;  // 存储在链上，很贵!
    
    function addRecord(uint256 value) public {
        history.push(Record(value, block.timestamp));
    }
}

// 好: 使用事件
contract Good {
    event RecordAdded(uint256 value, uint256 timestamp);
    
    function addRecord(uint256 value) public {
        emit RecordAdded(value, block.timestamp);
        // 事件存储在日志中，Gas消耗低很多
        // 可以通过链下查询获取历史
    }
}
```

---

### 2.4、Solidity编程基础

Solidity是以太坊智能合约的主要编程语言。

#### 2.4.1、基本语法

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyFirstContract {
    // 状态变量（存储在区块链上）
    uint256 public value;
    address public owner;
    
    // 构造函数（部署时执行一次）
    constructor() {
        owner = msg.sender;  // msg.sender = 调用者地址
    }
    
    // 修饰器（可重用的权限检查）
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;  // 继续执行函数
    }
    
    // public函数（任何人都可以调用）
    function setValue(uint256 _value) public onlyOwner {
        value = _value;
    }
    
    // view函数（只读，不修改状态，不消耗Gas）
    function getValue() public view returns (uint256) {
        return value;
    }
}
```

#### 2.4.2、数据类型

```solidity
contract DataTypes {
    // 值类型
    bool public flag = true;
    uint256 public number = 100;  // 无符号整数
    int256 public signedNumber = -50;  // 有符号整数
    address public addr = 0x1234...;  // 地址
    bytes32 public data;  // 固定长度字节
    
    // 引用类型
    uint256[] public dynamicArray;  // 动态数组
    uint256[5] public fixedArray;  // 固定数组
    mapping(address => uint256) public balances;  // 映射
    
    struct Person {
        string name;
        uint256 age;
    }
    Person public person;
    
    enum State { Created, Locked, Inactive }
    State public state;
}
```

#### 2.4.3、一个完整的例子: 简单代币

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleToken {
    // 状态变量
    string public name = "MyToken";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // 事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // 构造函数: 铸造初始供应
    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }
    
    // 转账功能
    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(to != address(0), "Invalid address");
        
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    // 授权功能
    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    // 代理转账
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balanceOf[from], "Insufficient balance");
        require(value <= allowance[from][msg.sender], "Allowance exceeded");
        require(to != address(0), "Invalid address");
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        
        emit Transfer(from, to, value);
        return true;
    }
}
```

---

### 2.5、智能合约安全

智能合约一旦部署就无法修改，因此安全性至关重要。

#### 2.5.1、常见安全漏洞

**1. 重入攻击 (Reentrancy Attack)**

这是最著名的智能合约漏洞，导致了2016年的DAO攻击（损失6000万美元）。

```solidity
// 易受攻击的合约
contract Vulnerable {
    mapping(address => uint256) public balances;
    
    function withdraw() public {
        uint256 amount = balances[msg.sender];
        
        // 危险！先转账再更新余额
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
        
        balances[msg.sender] = 0;
    }
}

// 攻击合约
contract Attacker {
    Vulnerable public victim;
    
    constructor(address _victim) {
        victim = Vulnerable(_victim);
    }
    
    function attack() public payable {
        victim.withdraw();
    }
    
    receive() external payable {
        // 重入！在余额清零前再次调用withdraw
        if (address(victim).balance >= 1 ether) {
            victim.withdraw();
        }
    }
}

执行流程:
1. 攻击者调用withdraw()
2. victim转账给攻击者
3. 触发攻击者的receive()
4. receive()再次调用withdraw()  ← 重入!
5. 此时balances[攻击者]还没清零
6. 攻击者可以反复提款
```

**修复方法: Checks-Effects-Interactions模式**

```solidity
contract Secure {
    mapping(address => uint256) public balances;
    
    function withdraw() public {
        uint256 amount = balances[msg.sender];
        
        // 先更新状态
        balances[msg.sender] = 0;
        
        // 再转账
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
    }
}

或者使用ReentrancyGuard:
```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Secure is ReentrancyGuard {
    mapping(address => uint256) public balances;
    
    function withdraw() public nonReentrant {  // 添加nonReentrant修饰器
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
    }
}
```

**2. 整数溢出/下溢**

在Solidity 0.8之前，整数溢出不会报错：

```solidity
// Solidity < 0.8.0
uint8 a = 255;
a += 1;  // a = 0 (溢出)

uint8 b = 0;
b -= 1;  // b = 255 (下溢)

// 可能被利用的例子
contract Vulnerable {
    mapping(address => uint256) public balances;
    
    function transfer(address to, uint256 value) public {
        // 如果value很大，可能导致溢出
        require(balances[msg.sender] - value >= 0);  // 总是true!
        balances[msg.sender] -= value;
        balances[to] += value;
    }
}
```

**修复:**

```solidity
// 方法1: 使用Solidity 0.8+ (自动检查溢出)
pragma solidity ^0.8.0;

// 方法2: 使用SafeMath库 (0.8之前)
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Secure {
    using SafeMath for uint256;
    
    function transfer(address to, uint256 value) public {
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
    }
}
```

#### 2.5.2、安全最佳实践

```
1. 使用established库
   - OpenZeppelin Contracts
   - 经过审计和实战检验
   
2. 遵循Checks-Effects-Interactions模式
   - 先检查条件
   - 再修改状态
   - 最后与外部交互

3. 使用修饰器进行权限控制
   modifier onlyOwner() {
       require(msg.sender == owner);
       _;
   }

4. 设置紧急暂停机制
   bool public paused = false;
   
   modifier whenNotPaused() {
       require(!paused);
       _;
   }

5. 代码审计
   - 正式上线前请专业团队审计
   - 使用自动化工具(Slither, Mythril)

6. 测试覆盖
   - 单元测试
   - 集成测试
   - 边界情况测试
```

---

*本章节详细介绍了区块链的网络结构和智能合约。P2P网络让区块链实现了去中心化，智能合约让区块链拥有了可编程性。理解这两者对于掌握区块链技术至关重要。*
