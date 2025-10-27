
# ZK-Swap 

---

## 1、ZK-Swap 概述

ZK-Swap 是一种**基于 ZK-Rollup 技术的去中心化交易协议（Layer 2 DEX）**。

其核心创新在于：它将 **自动做市商（AMM）** 的交易逻辑和状态管理从拥堵且昂贵的 Layer 1（以太坊主网）迁移至 **Layer 2** 侧链环境。（后面我们会举出具体的例子说明）

**核心技术：ZK-Rollup**
它通过 **零知识证明（Zero-Knowledge Proofs）** 机制，在保持所有交易的 **链上安全性** 与 **状态一致性** 的前提下，实现了 **链下批量交易** 与 **即时结算**。

* 将数千笔链下交易（Swap, Add/Remove Liquidity）的数据和状态变化**压缩打包**成一个**批次 (Batch)**。
* 利用 ZK-SNARK 证明这个批次中的所有交易都是**有效且正确**的。
* 仅将最终的**状态变化摘要（Merkle Root）**和**零知识证明**提交给 Layer 1 的智能合约进行验证。

(与An Applied Example-ZK-Rollup ＆ Zk-Sync这一节我们讲述的一致)

$$
\text{ZK-Swap} = \text{ZK-Rollup} + \text{AMM（自动做市机制）}
$$

因此理论上来说它将具有ZK-Rollup和DEX（如我们在Uniswap_Explain_Examples讲述的一样）共有的优点

ZK-Swap 作为一个创新的 Layer 2 协议，每一次重大版本更新都旨在解决现有版本遗留的限制或提升用户体验。

| 版本 | 关键变化 | 特点说明 |
| :--- | :--- | :--- |
| **v1.0** | 基于 ZK-Rollup + AMM 的基础实现。 | **核心功能确立：** 成功将 AMM 交易逻辑转移到 Layer 2，实现了低 Gas 费和高吞吐量。它确立了 ZK-Swap 的基本架构（Operator, Prover, Rollup 合约）。**限制：** 为了简化电路设计和确保数据可用性，所有的 Layer 2 交易数据（发送方、接收方、金额）在提交到 L1 时是**公开**的，缺乏隐私性。 |
| **v2.0** | 引入隐私保护电路。 | **隐私增强：** 借鉴了 Zcash 或 Tornado Cash 的零知识证明设计思想。在电路中增加了额外的约束来**隐藏交易金额和地址**。用户可以在保持 ZK-Rollup 高效率的同时，选择进行隐私交易。**实现路径：** 这通常是通过证明用户只花费了其私密承诺（Commitment）内的资产，而无需透露具体交易细节。 |
| **v3.0 (或后续)** | 通用资产支持及更灵活的流动性机制。 | **通用性与效率提升：** 目标是支持**任意 ERC-20** 代币的 $\text{Swap}$，并可能引入更复杂的 $\text{AMM}$ 模型（例如，类似 Uniswap V3 的**集中流动性 (Concentrated Liquidity)** 机制）。**挑战：** 集中流动性机制的复杂数学运算会极大地增加 ZK 电路的复杂度和证明时间，需要更先进的 SNARK 算法（如 PLONK、Halo2 等）和更优化的电路设计来支撑。 |

通过版本演进，ZK-Swap 不仅稳固了其作为高性能 DEX 的地位，也展现了 ZK-Rollup 技术作为下一代区块链基础设施的巨大潜力。

---

## 2、传统DEX的问题

ZK-Swap 主要解决了传统基于 Layer 1 且采用 AMM 机制的去中心化交易所（典型如 Uniswap 在高流量时的表现）所面临的 **高成本、低速度和可扩展性瓶颈**。

| 问题 | 传统 DEX (如 Uniswap L1) 的痛点 | ZK-Swap 的改进方案 |
| :--- | :--- | :--- |
| **Gas 成本** | 每次 **Swap、添加/移除流动性** 等操作都需要在 Layer 1 上作为独立交易执行。在网络拥堵时，Gas 费用可能远超交易金额。 | **批量交易链下执行。** 仅需为整个批次（Batch）的 **ZK 证明验证** 支付一次 Gas 费用。这笔费用被批次内的数千笔交易平均分摊，使得单笔交易的 Gas 成本几乎可以忽略不计。 |
| **速度** | 受限于 Layer 1 区块的确认时间（以太坊约 13 秒），用户必须等待区块打包才能确认交易。高峰期甚至需要等待数分钟。 | **Layer 2 实时结算。** 交易在 Layer 2 上由 Operator 实时处理和结算，用户体验到**即时**的交易确认，无需等待 Layer 1 出块。|
| **状态同步** | 每次状态更新（如余额变化）都**完全在链上执行**，占用宝贵的区块空间和计算资源。 | **状态在 Layer 2 中维护，ZK 证明同步。** Layer 1 仅存储最新的**状态根 (State Root)**。ZK-SNARK 证明了从旧状态根到新状态根转换的**有效性**，极大地压缩了链上所需的数据量和验证计算量。 |
| **安全性** | 依赖于以太坊的共识机制来保证交易的有效性和状态的不可篡改性。 | **状态证明由 ZK-SNARK 保证。** 除了依赖以太坊共识外，ZK-SNARK 提供了**密码学级别的正确性证明**。Layer 1 合约无需重新执行交易，只需验证数学证明，确保了交易执行的正确性。 |
| **隐私性 (潜在)** | 全部交易数据（发送方、接收方、金额）都**公开记录**在 Layer 1 上，缺乏隐私保护。 | **可通过扩展实现隐私交易。** 尽管 ZK-Swap V1 最初与传统 DEX 一样公开交易，但其技术基础（ZK-SNARK）天然支持隐私扩展。例如 **ZK-Swap V2** 即可通过在电路中引入额外的约束来隐藏交易金额和地址，实现更高层次的隐私保护。 |

这些优点本质上也是结合了ZK-Rollup的特点

---

## 3、ZK-Swap交易流程

### 3.1 总体系统架构

ZK-Swap 系统可分为 **四个核心组件**：

```
 ┌────────────────────────────┐
 │        Layer 1 (Ethereum)  │
 │  ┌───────────────────────┐ │
 │  │  Rollup 合约 (Verifier)│←──ZK Proof
 │  └───────────────────────┘ │
 └─────────────▲──────────────┘
               │
               │ ZK-SNARK 验证
               │
 ┌─────────────┴──────────────────┐
 │         Layer 2 (ZK-Rollup)    │
 │                                │
 │  ┌───────────┐   ┌──────────┐ │
 │  │  Operator │→→│ State DB │ │
 │  └───────────┘   └──────────┘ │
 │                                │
 │  ┌──────────────┐              │
 │  │  Swap Engine │──AMM逻辑──▶ │
 │  └──────────────┘              │
 │                                │
 │  ┌──────────────┐              │
 │  │  Prover Node │──生成证明──▶ │
 │  └──────────────┘              │
 └────────────────────────────────┘
```

**Rollup 合约（Verifier / Verifying Contract）**
这是 ZK-Swap 在以太坊主网上部署的核心智能合约。它是整个 Layer 2 系统的 **最终安全锚点**。
* **功能：**
    * **资金托管：** 负责托管所有用户从 Layer 1 存入的资金。
    * **状态根存储：** 存储 Layer 2 状态的最新 **Merkle Root**（即状态的哈希摘要）。
    * **ZK-SNARK 验证：** 接收来自 Layer 2 的 **ZK 证明 ($\Pi$)**。它执行 SNARK 验证算法。
    * **状态更新：** **只有** 在 ZK 证明验证通过后，合约才会更新其存储的状态根。这保证了任何状态变更都是由有效的、被证明正确的交易批次引起的。

**Operator（操作员）**
* **作用：** 相当于 Layer 2 的**交易排序器和打包者**。
* **功能：**
    * **交易收集：** 接收用户的链下交易请求（Swap、Add Liquidity 等）。
    * **交易执行：** 按照 **AMM 逻辑** 和 **Swap Engine** 的指令执行交易，并更新本地的 **State DB**。
    * **批次打包 (Batch Generation)：** 将一系列交易打包成一个**批次 (Batch)**，准备提交给 Prover。
    * **数据可用性 (Data Availability)：** 将压缩后的交易数据发布到 Layer 1（通常是以太坊的 `calldata`）。

**State DB（状态数据库）**
* **作用：** 存储 Layer 2 的**完整、当前状态**。
* **内容：** 包含 **账户树 (Account Tree)** 和 **流动性树 (Liquidity Tree)** 的详细信息，如每个用户的余额、Nonce、以及每个流动性池的资产数量等。
* **关系：** 它的根哈希（State Root）需要与 Layer 1 Rollup 合约中存储的根哈希保持一致（在成功验证后）。

**Swap Engine（交易引擎）**
* **作用：** 负责执行交易的具体**业务逻辑**。
* **功能：** 根据 **AMM (Constant Product Market Maker) 算法**，计算用户 Swap 交易的输入和输出数量，确保交易满足 $\text{x} \cdot \text{y} = \text{k}$ 等数学约束，并指示 Operator 更新 State DB。

**Prover Node（证明生成节点）**
* **作用：** 整个 ZK-Rollup 架构中 **密码学核心**。
* **功能：**
    * 接收 Operator 打包的交易批次（Batch）。
    * 将批次中的所有状态转换（如余额变化、AMM 运算）**算术化**，转换为一个巨大的**算术电路**。
    * 对该电路执行 ZK-SNARK 证明生成算法，输出一个简洁、不可伪造的 **零知识证明 ($\Pi$)**。
    * 将证明 $\Pi$ 提交给 Layer 1 的 **Rollup 合约** 进行验证。

---

### 3.2、系统工作流程

ZK-Swap 的完整交易流程是 Layer 1 与 Layer 2 协作的体现，确保了资金的安全性并实现了高效的交易。这个流程主要包括 **5 个阶段**：

#### Deposit (充值)

用户从其 Layer 1 钱包（如 MetaMask）发起一笔交易，将资金（如 ETH、ERC-20 代币）发送到 ZK-Swap 在 Layer 1 上部署的 **Rollup 智能合约** 中。（这一步实际上是ERC20标准，合约无法直接读取用户金额，我们在UniswapV2_Chinese中说过）

* **L1 合约响应：** 合约接收资金并锁定。
* **L2 状态同步：** Layer 2 的 **Operator** 持续监控 Layer 1 上的存款事件。一旦检测到新的存款，Operator 就会在 Layer 2 的 **State DB** 中为该用户增加相应的余额记录。

#### Off-Chain Swap (链下交易)

用户通过 ZK-Swap 界面（Layer 2 客户端）发起交易请求，包括 $\text{Swap}$（交易）、$\text{Add Liquidity}$（增加流动性）或 $\text{Remove Liquidity}$（移除流动性）等操作。

Operator 接收这些链下请求，并通过 **Swap Engine** 验证交易的合法性（例如，余额是否充足，是否满足 AMM 恒等式）。
如果交易合法，Operator 立即更新其本地的 **State DB**。对于用户而言，交易**即时完成**，无需等待 Layer 1 确认。

#### Batch Generation (批次打包)

Operator 在积累了足够数量的链下交易（通常是数千笔）或者达到一定时间间隔后，将这些交易聚合为一个 **批次 (Batch)**。
每个批次都包含：
* $\text{State Root}_{\text{old}}$：批次执行前的 Layer 2 状态根。
* $\text{State Root}_{\text{new}}$：批次执行后的 Layer 2 状态根。
* 所有交易的**压缩数据**（用于在 L1 保证数据可用性）。（与我们在Achieving Decentralized Private Computation说的一致）

#### Proof Generation (生成零知识证明)

**Prover Node** 接收 Operator 提供的交易批次、旧状态根和新状态根，以及所有交易细节作为**私密见证 ($\omega$)**。
* **构造与证明：**
    * Prover 将批次中的**所有状态转换（包括余额更新、AMM 运算和 Merkle 路径更新）**转化为一个巨大的**算术电路**。
    * 它执行 ZK-SNARK 算法，证明：“从 $\text{State Root}_{\text{old}}$ 到 $\text{State Root}_{\text{new}}$ 的状态转换是**合法且正确**地遵循了电路规则（即 AMM 逻辑和账户规则）。”

生成一个简洁的、密码学级别的证明 $\Pi$。

#### On-Chain Verification (链上验证)

Operator 将**证明 $\Pi$**、**$\text{State Root}_{\text{new}}$** 和**压缩后的交易数据**提交给 Layer 1 的 **Rollup 合约 (Verifier)**。
* **Verifier 验证：** Rollup 合约执行 ZK-SNARK 的验证算法 $V(\text{State Root}_{\text{old}}, \text{State Root}_{\text{new}}, \Pi)$。
    * **如果验证失败：** 证明被拒绝，状态根不更新。
    * **如果验证成功：** 合约接受证明，并**将存储的状态根从 $\text{State Root}_{\text{old}}$ 更新为 $\text{State Root}_{\text{new}}$**。

一旦 Layer 1 的状态根更新成功，就代表 Layer 2 批次中的所有交易都已得到以太坊主网的 **最终确认 (Finality)** 和安全保障。

---

### 3.3、补充：证明生成细节

在 ZK-Swap 中，所有 Layer 2 交易的正确性证明都依赖于一个基本前提：**证明系统状态从一个有效根 ($\text{Root}_{\text{old}}$) 转换到了另一个有效根 ($\text{Root}_{\text{new}}$) 的过程是合乎规则的**。为了实现这一点，系统状态必须被组织成易于证明的数据结构。

#### 3.3.1. 状态树结构（State Tree）

ZK-Swap 使用 **Merkle 树**（或其变体，如稀疏 Merkle 树）来表示整个 Layer 2 的状态。

ZK-Swap 主要使用两棵 Merkle 树来管理核心资产和交易对信息：

| 树类型 | 作用 | 节点内容 (Leaf Data) |
| :--- | :--- | :--- |
| **Account Tree (账户树)** | 存储每个用户的账户状态和余额信息。 | $\text{Leaf} = H(\text{User Address}, \text{Asset Balances}[N], \text{Nonce}, \text{Public Key})$ |
| **Liquidity Tree (流动性树)** | 存储每个交易对（Pool）的流动性信息。 | $\text{Leaf} = H(\text{Token A}, \text{Token B}, \text{Amount } \mathbf{x}, \text{Amount } \mathbf{y}, \text{LP Total Supply})$ |

* **状态根 (State Root)：** 这两棵树的根哈希通常会被聚合成一个**总状态根 Root**。这个 $\text{Root}$ 代表了整个 ZK-Swap 系统的**唯一有效状态**。
* **证明逻辑：** Prover 的核心任务就是证明：在给定的旧状态根下，执行一批交易后，得到的新状态根是正确的。只要能证明「旧状态 → 新状态」的转变是电路正确计算的结果，就相当于证明了批次中的所有交易都有效。

---

#### 3.3.2. 电路算术化

我们在ZK-STARKs已经详细阐述了算术化的基本原理，它在ZK-Swap的本质也是一样的，我们将需要验证的关键运算（也就是几个函数）分解为以下几种 **子电路 (Sub-circuit)**：

| 电路类型 | 验证内容 | 关键约束 (转化为代数表达式) |
| :--- | :--- | :--- |
| **账户更新电路** | 验证用户 $\text{Deposit} / \text{Withdraw}$ 或交易后导致的余额变化。 | 确保 $\text{Balance}_{\text{new}} = \text{Balance}_{\text{old}} \pm \text{Amount} \pm \text{Fee}$ 成立，且余额非负。 |
| **Swap 电路** | 验证交易是否符合自动做市商（AMM）的恒等式。 | 核心约束：$\mathbf{x}_{\text{new}} \cdot \mathbf{y}_{\text{new}} = \mathbf{x}_{\text{old}} \cdot \mathbf{y}_{\text{old}}$ (忽略手续费的简化形式，实际需考虑手续费) |
| **流动性电路** | 验证 $\text{Add} / \text{Remove Liquidity}$ 导致的 LP Token 发行/销毁以及池子余额的更新。 | 确保新铸造的 LP Token 数量与存入的 $\mathbf{x}, \mathbf{y}$ 资产成比例。 |
| **Merkle 路径电路** | 验证状态树更新（即叶子节点更新）前后的路径哈希正确性。 | 确保每个哈希运算 $H(L, R) \to \text{Parent}$ 在电路中正确执行，从而连接 $\text{Leaf}_{\text{old}}$ 到 $\text{Root}_{\text{old}}$ 以及 $\text{Leaf}_{\text{new}}$ 到 $\text{Root}_{\text{new}}$。 |

每笔链下交易（$T_i$）都对应于一系列**账户更新**和**池子状态变化**，也即对应一个**小电路** ($C_i$)。Operator 将一批 $N$ 笔交易打包时，Prover 需要将这些小电路**串联或聚合**，形成一个统一的**大电路 ($C_{\text{batch}}$)**：

$$
C_{\text{batch}} = \sum_{i=1}^N C_i
$$

在算术化过程中：

通过这种方式，ZK-Swap 将批量交易的正确性证明问题，成功转化为了一个**代数多项式验证问题**。

---

#### 4、实例：一次 Swap 的算术验证流程

ZK-Swap 的证明构建大体遵循 ZK-SNARK 的五步逻辑，我们不再加以赘述，但是我希望重新设计一个具体的例子来帮大家理解ZK-Swap是怎么实现的

以 Alice 将 10 USDT 换成 ETH 为例：

* **初始状态根：** $\mathbf{R}_{\text{old}}$
* **Alice 初始余额：** $B_{\text{Alice}}^{\text{old}} (\text{USDT})$, $B_{\text{Alice}}^{\text{old}} (\text{ETH})$
* **流动性池初始状态：** $\mathbf{x}_{\text{old}}$ (USDT 数量), $\mathbf{y}_{\text{old}}$ (ETH 数量)


| 步骤 | 电路逻辑（Prover 需验证的内容） | 涉及的状态变化 | 核心代数约束形式 |
| :--- | :--- | :--- | :--- |
| **① 验证账户余额充足** | 验证 Alice 在交易前拥有足够的 USDT，足以支付交易金额（10 USDT）和潜在的手续费。 | 无状态变化，仅验证私密见证 | $\mathbf{B}_{\text{Alice}}^{\text{old}} (\text{USDT}) \ge 10 + \text{fee}$ |
| **② 计算新池状态 (AMM 恒等式)** | 验证交易执行后，流动性池的 USDT (x) 和 ETH (y) 余额变化符合 AMM 的核心不变量约束。 | 仅涉及池状态 | $(\mathbf{x}_{\text{old}} + 10 \cdot (1 - \gamma)) \cdot (\mathbf{y}_{\text{old}} - \Delta y) = \mathbf{x}_{\text{old}} \cdot \mathbf{y}_{\text{old}}$ (其中 $\gamma$ 是手续费率，$\Delta y$ 是 Alice 获得的 ETH 数量) |
| **③ 更新 Alice 的 USDT 余额** | 验证 Alice 的 USDT 余额被正确扣除 (10 USDT + 手续费)。 | 账户状态变化 | $\mathbf{B}_{\text{Alice}}^{\text{new}} (\text{USDT}) = \mathbf{B}_{\text{Alice}}^{\text{old}} (\text{USDT}) - 10 - \text{fee}$ |
| **④ 更新 Alice 的 ETH 余额** | 验证 Alice 的 ETH 余额被正确增加 ($\Delta y$)。 | 账户状态变化 | $\mathbf{B}_{\text{Alice}}^{\text{new}} (\text{ETH}) = \mathbf{B}_{\text{Alice}}^{\text{old}} (\text{ETH}) + \Delta y$ |
| **⑤ 更新流动性池余额** | 验证池子中的 USDT 和 ETH 余额被正确更新。 | 流动性池状态变化 | $\mathbf{x}_{\text{new}} = \mathbf{x}_{\text{old}} + 10$  (USDT 增加)<br> $\mathbf{y}_{\text{new}} = \mathbf{y}_{\text{old}} - \Delta y$ (ETH 减少) |
| **⑥ 验证 Merkle 路径** | 验证更新后的 **Alice 账户叶子节点** 和 **USDT/ETH 流动性池叶子节点**，通过正确的哈希运算路径，连接到新的状态根 $\mathbf{R}_{\text{new}}$。 | **核心状态根变化** | $\mathbf{R}_{\text{new}} = \text{MerkleUpdate}(\mathbf{R}_{\text{old}}, \text{Leaf}_{\text{Alice}}^{\text{old}} \to \text{Leaf}_{\text{Alice}}^{\text{new}}, \text{Leaf}_{\text{Pool}}^{\text{old}} \to \text{Leaf}_{\text{Pool}}^{\text{new}})$ |


---




