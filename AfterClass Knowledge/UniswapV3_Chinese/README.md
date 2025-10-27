

# Uniswap V3 

在本项目中，我对UniswapV3的7个核心合约代码做了详细的中文注释，包含了我对一些功能的理解，必要的关键字解释和DEFI的原理。适合有编程基础（偶尔类比其他程序设计语言）并且对Uniswap已有了解的同学们一起讨论。
七个关键合约文件为（包含路径，避免找错）：

1.  v3-core/contracts/UniswapV3Factory.sol 

2.  v3-core/contracts/UniswapV3Pool.sol 

3.  v3-periphery/contracts/NonfungiblePositionManager.sol 

4.  v3-periphery/contracts/libraries/NonfungiblePositionDescriptor.sol 

5.  v3-periphery/contracts/SwapRouter.sol 

6.  v3-periphery/contracts/V3Migrator.sol 

7.  v3-core/contracts/libraries/UniswapV3PoolDeployer.sol 


－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－

为了帮助理解UniswapV3的原理，我选择了3个典型场景来帮助读者串起各个关键合约的功能，建议在阅读完合约理解后配合理解。（事例中的NFT其实是LP Token，为了保留源码特征，这里依然写成NFT）

## 致谢
Uniswap工作室提供的源码：https://github.com/Uniswap/v3-core.git
成都信息工程学院梁培利老师的区块链金融公开课： https://www.bilibili.com/video/BV1xs4y127xW
Jeiwan的UniswapV3 Book：https://github.com/Jeiwan/uniswapv3-book
---


> **示例背景（在没有特殊说明的情况下，使用如下的数值）**  
> - Token0（USDC，6 decimals，示例主网地址）：`0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48`  
> - Token1（WETH，18 decimals，示例主网地址）：`0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`  
> - fee tier = `3000` （即 0.3%）→ 对应 `tickSpacing = 60`（fee 与 tickSpacing 的常见映射，factory 可返回 tickSpacing）。:contentReference[oaicite:5]{index=5}  
> - 用户地址（示例）：`0xUserAAA...`（下文简称 `User`）  
> - 初始余额（示例、便于读数）：`User` 持有 `WETH = 2.0`（= `2 * 1e18`）与 `USDC = 5,000`（= `5000 * 1e6`）。  
> - 本示例将**add**：`1.0 WETH` 与 `2,000 USDC`，区间示例 `tickLower = -600`、`tickUpper = 600`（均为 `tickSpacing=60` 的整数倍）。

> **注意**：下面“链上变化”的 `poolAddress`、事件 id 等均为示例值（用来说明哪些 storage / balance 会变化）。在真实链上执行时，请替换为从 `createPool` / tx receipt 获取的真实地址与返回值。

---

## 场景 A — 创建池 → 添加流动性（mint）→ 移除（decreaseLiquidity）+ 收取（collect）


### 步骤 A1 — 在 Factory 创建池（`createPool`）

**调用（合约 & 签名 / 来源）**  
- 合约接口（来源：`v3-core/contracts/UniswapV3Factory.sol`）:  

```solidity
function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
event PoolCreated(address indexed token0, address indexed token1, uint24 indexed fee, address pool);
```

（源码见 Uniswap v3 core 仓库）。

**操作示例**

* 由任意 EOA（例如 `0xDeployerAAA`）发起：`factory.createPool(USDC, WETH, 3000)`。
* `Factory` 会通过 `PoolDeployer` 使用 `CREATE2` 部署一个新的 `UniswapV3Pool` 实例（地址由 create 返回 / `PoolCreated` event 可读）。([docs.uniswap.org][2])

**链上关键变化**

* 事件：`PoolCreated(token0=0xA0..., token1=0xC0..., fee=3000, pool=0xPool1234...)`（在 tx receipt 中）。
* Factory.storage: `getPool(USDC, WETH, 3000)` → `0xPool1234`（现在可从 Factory 读取到该池地址）。
* `UniswapV3Pool` 的 immutable 字段 `token0`, `token1`, `fee`, `tickSpacing` 在部署时写入合约初始化 storage 可读（pool 合约内部）。([GitHub][1])

---

### 步骤 A2 — （若池未初始化）初始化池：写入初始 `sqrtPriceX96`

> 我把“初始化”并入示例流程：如果 `createPool` 后池未初始化，下一步由你的脚本直接调用 `initialize(...)` 来把初始价格写入 `slot0`。

**函数 & 来源**

* `IUniswapV3Pool.initialize(uint160 sqrtPriceX96)` — pool 接口（`v3-core`）。([docs.uniswap.org][3])

**如何计算 `sqrtPriceX96`（Q64.96 表示）**

* 定义：`sqrtPriceX96 = floor( sqrt(P) * 2^96 )`，其中 `P` 是 `token1/token0` 的价格（注意 `token0` / `token1` 的排序由合约按地址排序决定）。`sqrtPriceX96` 存储为 Q64.96 固定点数。([docs.uniswap.org][4])

**数值例子（我们假设前端决定的初始价格）**

* 假设我们想设：`1 WETH = 2,000 USDC`。因为 `token0 = USDC`、`token1 = WETH`，所以 `P = token1/token0 = 1 / 2000 = 0.0005`。

  * `sqrt(P) = sqrt(0.0005) ≈ 0.022360679774997897`。
  * `2^96 = 79228162514264337593543950336`。
  * `sqrtPriceX96 = floor(0.022360679774997897 * 2^96) = 1771595571142957112070504448`（这是整数 Q64.96 表示）。（数值计算示例）([RareSkills][5])

**链上调用 / 变化**

* 调用：`IUniswapV3Pool(0xPool1234).initialize(1771595571142957112070504448)`。
* 结果：`pool.slot0()` 由未初始化 → `(sqrtPriceX96 = 1771595571142957112070504448, tick = computedTick, observationIndex = 0, ...)`，并发出 `Initialize` event。注意：若别人先初始化并设置不合理价格，可能造成首位 LP 被套利，故常推荐在已知市场价时一并初始化并尽快 add liquidity。([Trail of Bits][6])

---

### 步骤 A3 — `approve` → `NonfungiblePositionManager.mint`（添加范围流动性，铸造 NFT）

**需要的合约 / 签名 / 来源**

* ERC20: `approve(address spender, uint256 amount)`（标准 ERC20）。
* `NonfungiblePositionManager.mint(MintParams calldata params)` — periphery (来源：`v3-periphery` / docs)。简化签名：

```solidity
function mint(MintParams calldata params) external payable
  returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
```

（参见 `NonfungiblePositionManager` 文档 / 源码）。([docs.uniswap.org][7])

**本例参数（小数值）**

* `token0 = USDC`, `token1 = WETH`, `fee = 3000`
* `tickLower = -600`, `tickUpper = 600`（符合 tickSpacing = 60）([RareSkills][8])
* `amount0Desired = 2000 USDC`（`2000 * 1e6`）
* `amount1Desired = 1.0 WETH`（`1 * 1e18`）
* `recipient = 0xUserAAA`, `deadline = now + 1 hour`

**前置：approve（必须）**

* `USDC.approve(NonfungiblePositionManagerAddr, 2000 * 1e6)` → ERC20.allowance 写入。
* `WETH.approve(NonfungiblePositionManagerAddr, 1 * 1e18)` → ERC20.allowance 写入。

**mint 的内部要点（简述）**

* `mint` 会调用 `LiquidityAmounts.getLiquidityForAmounts(...)`（库）来计算在当前 `sqrtPriceX96` 与指定 `tickLower/tickUpper` 下，给定 `amount0` / `amount1` 可得到的最大 `liquidity`（`uint128`）。然后通过 pool 的 `mint` 回调（pool 会在回调里要求转入 tokens）把实际 `amount0`/`amount1` 扣走并增加 pool 的 `liquidity`。最后，PositionManager 在自身 storage 中为该新头寸铸造 ERC-721（`tokenId`），并记录 `positions(tokenId)`（包含 `liquidity`, `tickLower`, `tickUpper`, `tokensOwed0/1` 等）。

**核心公式：`LiquidityAmounts` 的概念性表示**（完整实现见官方库）

* 记 `√P`（当前 sqrt price），`√PA`（tickLower 对应的 sqrt），`√PB`（tickUpper 对应的 sqrt），则：
  * `getLiquidityForAmount0`（仅 token0 支持时）约为：

    $L_0 = \frac{amount0 \cdot \sqrt{PA} \cdot \sqrt{PB}}{\sqrt{PB} - \sqrt{PA}}$
  * `getLiquidityForAmount1`（仅 token1 支持时）约为：

    $L_1 = \frac{amount1}{\sqrt{PB} - \sqrt{PA}}$
  * `getLiquidityForAmounts` 会基于当前 `√P` 选择 $L = \min(L_0', L_1')$（详见官方 `LiquidityAmounts.sol`）。


。
（详见官方 `LiquidityAmounts.sol`）。注意：实际实现为定点 Q64.96 运算并有向下取整與 uint128 截断。([docs.uniswap.org][9])

**链上示例变化（成功 mint）**

* 假设 `mint` 返回：`tokenId = 1001`, `liquidity = L1001`, `amount0 = 2000 USDC`，`amount1 = 1 WETH`（两边完全消耗，仅为示例）。
* 账户变更：

  * `USDC.balanceOf(0xUserAAA)`：`5000` → `3000`（减少 `2000`）。
  * `WETH.balanceOf(0xUserAAA)`：`2.0` → `1.0`（减少 `1.0`）。
* Pool / storage 变更：

  * `pool.liquidity`（全局）由 `L_old` → `L_old + L1001`（写入 pool 的 `liquidity` storage）。
  * `ticks[tickLower].liquidityGross += L1001`，`ticks[tickUpper].liquidityGross += L1001`（tick 结构发生写入） — 这些都是 pool 的 storage 写操作。
  * `NonfungiblePositionManager.positions(1001)` 写入 `{ token0, token1, fee, tickLower, tickUpper, liquidity = L1001, tokensOwed0 = 0, tokensOwed1 = 0, ... }`（写入 PositionManager 的 storage）。([docs.uniswap.org][7])

**事件（可在 tx receipt 查看）**

* `Transfer`（ERC721 mint） → `tokenId = 1001`。
* `Mint` / `IncreaseLiquidity`（pool 层） → 记录 `amount0`, `amount1`, `liquidity`。

---

### 步骤 A4 — 减少流动性（`decreaseLiquidity`）并收取（`collect`）

**签名 / 来源（简化）**

```solidity
function decreaseLiquidity(DecreaseLiquidityParams calldata params) external returns (uint256 amount0, uint256 amount1);
function collect(CollectParams calldata params) external returns (uint256 amount0, uint256 amount1);
```

（详见 `NonfungiblePositionManager` 文档 / 源码）。([docs.uniswap.org][7])

**操作示例**

* `User` 决定退出一半流动性：读取 `positions(1001).liquidity == L1001`，调用：
  `decreaseLiquidity(tokenId=1001, liquidity = L1001 / 2, amount0Min = 0, amount1Min = 0, deadline)`。

**decreaseLiquidity 的效果（链上 storage 变化）**

* `NonfungiblePositionManager.positions(1001).liquidity` 从 `L1001` → `L1001 / 2`（写入 storage）。
* Pool 的全局 `liquidity` 也相应减少（并在对应 ticks 处更新 `liquidityNet` / `liquidityGross`），同时计算并记录该减少操作应释放回的基础代币 `amount0_delta` / `amount1_delta` —— 这些通常会先存为 `tokensOwed0/1`（或立即返回，依具体实现路径），但 `collect` 是把这些代币真正转给 `recipient`。([docs.uniswap.org][7])

**collect（把代币转给用户）**

* 调用：`collect(tokenId=1001, recipient=0xUserAAA, amount0Max=uint128_max, amount1Max=uint128_max)`。
* 结果（示例）：`USDC.balanceOf(0xUserAAA)` 从 `3000` → `3000 + amount0_returned`（例如 +1000 → 4000），`WETH.balanceOf(0xUserAAA)` 从 `1.0` → `1.0 + amount1_returned`（例如 +0.5 → 1.5）。
* `positions(1001).tokensOwed0` / `tokensOwed1` 相应被清零或减少。`positions(1001).liquidity` 已被 decrease 步骤修改。([docs.uniswap.org][7])

**关于手续费（fees）的分配**


* Swap 时收取的手续费累积在 pool 的 `feeGrowthGlobal0X128/feeGrowthGlobal1X128`。在 `collect` 时，PositionManager 会用 `feeGrowthInside - feeGrowthInsideLast` 的差值来计算该 position 在该时期应分配的手续费份额并把手续费（token0 / token1）一并转出给 `recipient`。详见 `UniswapV3Pool` 与 `NonfungiblePositionManager` 的实现注释。([docs.uniswap.org][9])


## 场景 B － 交易 （包括单跳和多跳交易）
- Token A = WETH `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`（18 decimals）  
- Token B = USDC `0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48`（6 decimals）  
- Token C = DAI `0x6B175474E89094C44Da98b954EedeAC495271d0F`（18 decimals）  
- fee tiers: 常用 `3000` 表示 0.3%（注意：fee 在合约中以“hundredths of a basis point”表示，即 `fee/1_000_000` 为分数）。:contentReference[oaicite:4]{index=4}

示例账户：  
- `0xTrader1`（做单跳）初始：WETH = `0.1`（= `0.1 * 1e18`），USDC = `0`。  
- `0xTrader2`（做多跳）初始：WETH = `0.06`，USDC = `0`，DAI = `0`。  

我们演示两种交易：  
- 单跳：`0xTrader1` 用 `0.05 WETH` 换 USDC（通过 SwapRouter.exactInputSingle）。  
- 多跳：`0xTrader2` 用 `0.05 WETH` 路由 `WETH -> USDC (3000) -> DAI (500)`（示例费率），使用 SwapRouter.exactInput（path 编码方式）。

---

## B1 单跳交换：`exactInputSingle`（高层步骤与关键变化）

### 1) 相关合约 / 函数签名（来源）  
- `ISwapRouter.exactInputSingle(ExactInputSingleParams calldata params)` — periphery SwapRouter 接口。:contentReference[oaicite:5]{index=5}  
  ```solidity
  function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
  ```

`ExactInputSingleParams` 包含：`tokenIn, tokenOut, fee, recipient, deadline, amountIn, amountOutMinimum, sqrtPriceLimitX96`。([docs.uniswap.org][1])

### 2) 前置（必须）

* `tokenIn.approve(SwapRouterAddress, amountIn)` 或使用 `permit`。（Router 需要从用户 pull tokenIn）
* 验证路由池存在（factory.getPool(tokenIn, tokenOut, fee) 返回非零地址），否则交易会 revert。([docs.uniswap.org][2])

### 3) 调用示例（参数示意）

* Trader = `0xTrader1`：

  ```js
  params = {
    tokenIn: WETH,
    tokenOut: USDC,
    fee: 3000,
    recipient: "0xTrader1",
    deadline: Math.floor(Date.now()/1000) + 60*60,
    amountIn: 0.05 * 1e18,
    amountOutMinimum: 95 * 1e6, // 最小回报（示例）
    sqrtPriceLimitX96: 0
  }
  router.exactInputSingle(params)
  ```

  官方 docs 有完整示例。([docs.uniswap.org][3])

### 4) Router 内部要点（行为简述）

* Router pull `amountIn`（会触发 ERC20 transferFrom）；然后 Router 调用目标池的 `swap()`；pool 会执行 swap 逻辑（计算 price 变动、consume liquidity、更新 `slot0.sqrtPriceX96` 与 `tick`，并更新 fee 累积变量），最后把 `tokenOut` 发给 `recipient`。Router 返回 `amountOut`（实际拿到的 tokenOut 数量）。([docs.uniswap.org][2])

### 5) fee 的计算（简明公式）

* 合约中 `fee` 参数的单位是 hundredths of basis points → fee fraction = `fee / 1_000_000`。
  例如 `fee = 3000` → fee fraction = `3000 / 1_000_000 = 0.003 = 0.3%`。([docs.uniswap.org][1])
* 手续费近似（不考虑价格影响）：`feeAmount ≈ amountIn * fee / 1_000_000`（注意实际 amountIn 发挥作用前 pool 内部会按复杂 math 计算滑点与费的精确分配，以下为直观说明）。

### 6) 链上示例变化（小数值示例，带“近似 / 说明”）

* 初始：`WETH.balanceOf(0xTrader1) = 0.1`, `USDC.balanceOf(0xTrader1) = 0`。池价格近似 `1 WETH = 2000 USDC`（示例）。
* Trader 执行 `exactInputSingle`：`amountIn = 0.05 WETH`。

  * 近似手续费 `fee ≈ 0.05 * 0.003 = 0.00015 WETH`（被计入池的 fee 机制，用于 LP 分配）。([docs.uniswap.org][1])
  * 假设滑点很小，理论 bruto amountOut ≈ `0.05 * 2000 = 100 USDC`，去除手续费后大致 `≈ 99.7 USDC`，但实际 amountOut 取决于池的 liquidity 与 price 曲线，所以 Router 返回 `amountOut` 为实际数值（示例取 `amountOut = 99 USDC`）。
* 链上最终变化（示例）：

  * `WETH.balanceOf(0xTrader1)`：`0.1` → `0.05`（减少 `0.05`）
  * `USDC.balanceOf(0xTrader1)`：`0` → `99`（示例）
  * `pool.slot0.sqrtPriceX96`：可能向更高/更低微幅移动（取决于相对池深）——这是 pool 的 storage 写入。([docs.uniswap.org][4])
  * `UniswapV3Pool` 会 emit `Swap(sender, recipient, amount0, amount1, sqrtPriceX96, liquidity, tick)` 事件（你可在 tx receipt 中查看）。([docs.uniswap.org][5])

---

## B2 多跳（multi-hop）交换：`exactInput`（路径 path 编码、逐跳执行）

### 1) 函数签名（来源）

* `ISwapRouter.exactInput(ExactInputParams calldata params)` — 支持 bytes `path`（多段编码）。([docs.uniswap.org][1])

  ```solidity
  function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
  ```

  `ExactInputParams` 包含 `bytes path`、`recipient`、`deadline`、`amountIn`、`amountOutMinimum`。([docs.uniswap.org][1])

### 2) path 的编码规则（示意）

* path 的二进制格式为：`(20 bytes tokenA) | (3 bytes fee) | (20 bytes tokenB) | (3 bytes fee) | (20 bytes tokenC) | ...`，也就是 `address + uint24 + address + ...` 的重复结构。官方文档与示例说明如何编码（前端常使用 `ethers.utils.solidityPack` 或 `abi.encodePacked`）。([docs.uniswap.org][6])

**JS（ethers）示例：构造 path（WETH -> USDC -> DAI）**

```js
// 假设 ethers 已导入，fee 单位为整数（例：3000）
const path = ethers.utils.solidityPack(
  ["address","uint24","address","uint24","address"],
  [WETH, 3000, USDC, 500, DAI]
);
```

> 上面生成的是 bytes，可以直接作为 `ExactInputParams.path` 传入 `exactInput`。示例思路参考社区/文档。([Medium][7])

### 3) 多跳内部流程（高层、逐跳）

* Router pull `amountIn`（tokenA），对 path 的第一段调用 poolA.swap（tokenA→tokenB），poolA 把 tokenB 转回 Router（或直接送往下一跳指定地址，Router 的实现会把中间所得作为下一跳输入），Router 用得到的 tokenB 继续对下一段 poolB.swap（tokenB→tokenC），如此迭代直到最后一跳，最后把 `tokenOut` 转给 `recipient`。每一跳都会独立更新对应 pool 的 `slot0`、`feeGrowth`、tick structures 等。([docs.uniswap.org][6])

### 4) 典型多跳示例（小数值）

* Trader = `0xTrader2`，`WETH.balance = 0.06`，想把 `0.05 WETH` 经过 `WETH->USDC (3000)` 再 `USDC->DAI (500)`，得到 DAI。
* 近似估算（市场假设）：1 WETH = 2000 USDC，1 USDC ≈ 1 DAI。

  * 第一跳（WETH→USDC）理论 bruto ≈ `0.05 * 2000 = 100 USDC`（扣手续费 0.3% → ≈ 99.7 USDC）
  * 第二跳（USDC→DAI）理论 bruto ≈ `99.7 DAI`（扣手续费 0.05% → ≈ 99.65 DAI）
* 最终 Router 返回 `amountOut ≈ 99.6 DAI`（示例，真实值取决于每个池 liquidity 与 price 跃迁）。链上变化（示例）：

  * `WETH.balanceOf(0xTrader2)` 从 `0.06` → `0.01`（减少 `0.05`）
  * `DAI.balanceOf(0xTrader2)` 从 `0` → `≈99.6`（示例）
  * 两个池的 `slot0` 与 `feeGrowth` 各自发生更新，且每跳都 emit 各自的 `Swap` 事件（可在 tx receipt 中依次看到两个 Swap event）。([docs.uniswap.org][6])

### 5) exactInput vs exactOutput（提示）

* `exactInput`：指定输入 `amountIn`，返回最大可能的 `amountOut`（适合你不想先估算输出）。
* `exactOutput`：指定想要得到的 `amountOut`，并为此提供 `amountInMaximum`（Router 会反向计算并从路径末端向前执行以确保得到指定输出）。**注意：exactOutput 的 path 编码在某些实现中需要反向编码（见 docs）**。详见多跳 docs。([docs.uniswap.org][6])

---

## B3 事件 / 可查点（tx receipt 中可直接验证的项）

* 每个池会发出 `Swap` event：

  ```solidity
  event Swap(
    address sender,
    address recipient,
    int256 amount0,
    int256 amount1,
    uint160 sqrtPriceX96,
    uint128 liquidity,
    int24 tick
  );
  ```


  你可以在交易回执里按顺序读取这些事件来核对每跳的 `amount0/amount1`、`sqrtPriceX96` 与 `tick`。([docs.uniswap.org][5])

* Router 或 pool 的其他可查字段（可通过链上读取）：

  * `pool.slot0()` → `(sqrtPriceX96, tick, observationIndex, observationCardinality, ... )`（用于核验 price/price change）。([docs.uniswap.org][4])
  * `pool.feeGrowthGlobal0X128` / `pool.feeGrowthGlobal1X128`（fee 累积，用于 LP 的 later collect）。([docs.uniswap.org][4])

---

# 场景 C — 迁移：从 Uniswap V2 迁移到 Uniswap V3

**目的**：用极小数值示例说明 `V3Migrator` 如何把 Uniswap V2 LP token 烧掉（取回 underlying），再在 V3 用这些 underlying 调用 `NonfungiblePositionManager.mint` 铸成 V3 range position（及后续的移除/collect 步骤）。文档给出关键函数签名/来源、必要公式与链上可查状态变化（余额 / storage）。

> 说明：示例数值极小，便于理解与手工核对。请在真实执行时替换为链上实际合约地址与 tx 返回值。

---

## 前置（假设与最小数值）
- V2 pair：`DAI / WETH`（示例代币地址省略）  
- V3 pool 目标：`DAI / WETH, fee = 3000`（需已存在或由脚本创建）  
- 用户（示例）`0xMigrateUser` 初始持有：  
  - `V2 LP token = 10`（代表在 V2 的 liquidity share）  
  - `DAI = 0`, `WETH = 0`  
- V2 pair reserves（示例）：`reserveDAI = 10_000`, `reserveWETH = 5`，`totalSupplyLP = 100`  
  - 所以 `LP 份额 = 10 / 100 = 0.10`（10%）

---

## 核心合约 / 关键函数（签名与来源路径说明）
- **Uniswap V2 Pair (core)**  
  ```solidity
  function transferFrom(address from, address to, uint value) external returns (bool);
  function burn(address to) external returns (uint amount0, uint amount1); // pair contract


（V2 pair 的 `burn` 会把 underlying 返还到指定地址）

* **V3Migrator (periphery)** — 高层行为（典型实现）

  ```solidity
  // (具体实现文件) v3-periphery/contracts/V3Migrator.sol
  // 伪签名/高层：migrate(address v2Pair, uint256 lpAmount, MintParams params) external;
  ```

  行为：`transferFrom` V2 LP token → 调用 V2 pair 的 `burn()` → 得到 `amount0/amount1` → 调用 `NonfungiblePositionManager.mint(...)` 用这些 underlying 铸造 V3 position，返回 `tokenId`。

* **NonfungiblePositionManager (periphery)**

  ```solidity
  function mint(MintParams calldata params) external payable
    returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
  ```

---

## 核心数学 / 公式（把 V2 LP → underlying 的映射）

从 V2 的 `burn` 角度，若用户提交 `lpAmount`，获得的 underlying 为：

$$
\text{amount0} = \frac{lpAmount}{totalSupplyLP} \times reserve0
\qquad
\text{amount1} = \frac{lpAmount}{totalSupplyLP} \times reserve1
$$

示例（按上面 reserves）：`lpAmount = 10` →

* `amountDAI = 10/100 * 10_000 = 1_000 DAI`
* `amountWETH = 10/100 * 5 = 0.5 WETH`

---

## 步骤 C1 — 授权 & 调用 `V3Migrator.migrate`（高层流程）

1. **Approve（前置）**：

   * `V2LPToken.approve(V3MigratorAddr, 10)` → 在 ERC20 上写入 `allowance(0xMigrateUser, V3Migrator) = 10`。

2. **调用 migrate（示意）**：

   * `V3Migrator.migrate(v2Pair = 0xV2Pair, lpAmount = 10, mintParams = {...})`
   * 内部行为（按顺序）：

     * `V2LP.transferFrom(0xMigrateUser, v2Pair, 10)`（或 to migrator, 依实现）
     * `v2Pair.burn(address(this) or migratorDestination)` → pair 返回 `(amount0 = 1000 DAI, amount1 = 0.5 WETH)` 给 migrator（或直接给 `NonfungiblePositionManager`，视实现）。
     * migrator 调用 `NonfungiblePositionManager.mint`（把 `amount0/amount1` 作为 `amount0Desired/amount1Desired`），并把铸好的 `tokenId` 归属给用户（或把 NFT 转给用户）。

**链上关键变化（示例）**

* `V2LP.balanceOf(0xMigrateUser)`：`10` → `0`（被 migrator 扣除）
* `v2Pair` reserves 会因 burn 而减少（在 `burn` 内部更新）
* migrator/manager 使用 `1000 DAI + 0.5 WETH` 调用 `mint` → 返回 `tokenId = 2001`，`positions(2001).liquidity = L_migrated`（写入 PositionManager storage），并最终将 NFT 转给 `0xMigrateUser`（`ERC721 Transfer` event）

---

## 步骤 C2 — 在 V3 的 mint（与之前 A 场景相同，简要）

* `NonfungiblePositionManager.mint` 参数示例：

  * `token0 = DAI`, `token1 = WETH`, `fee = 3000`, `tickLower/tickUpper`（由 migrator 或用户指定）
  * `amount0Desired = 1000 DAI`, `amount1Desired = 0.5 WETH`
* 结果示例（假设两边完全使用）：

  * 返回 `tokenId = 2001`, `liquidity = L2001`, `amount0 = 1000`, `amount1 = 0.5`
  * `positions(2001)` 写入 `{liquidity = L2001, tickLower, tickUpper, tokensOwed0 = 0, tokensOwed1 = 0}`

**链上变化小结**

* `DAI.balanceOf(0xMigrateUser)`、`WETH.balanceOf(0xMigrateUser)` 保持 0（因为 underlying 直接用于 mint）；用户收到的是 V3 NFT `tokenId=2001`。
* V3 pool 的 `liquidity`、对应 ticks、`feeGrowth` 等更新（如同典型 mint）。

---

## 步骤 C3 —（可选）移除流动性并收取（decrease + collect）

迁移完成后，持有 `tokenId=2001` 的用户可按场景 A 的步骤移除与收取（缩短说明）：

1. `decreaseLiquidity(tokenId=2001, liquidity = L2001)` → `positions(2001).liquidity` 变为 0（或减少），pool 全局 `liquidity` 相应减少；计算 `amount0_returned` / `amount1_returned` 并计入 `tokensOwed`。
2. `collect(tokenId=2001, recipient=0xMigrateUser, amount0Max, amount1Max)` → 实际 ERC20 transfer，把本金与手续费转回用户；`positions(2001).tokensOwed0/1` 清零或相应减少。

示例：若全额退出，用户最终可能收回接近 `1000 DAI` 与 `0.5 WETH`（视期间价格与手续费变化，手续费会改变最终数额）。

---

## 可查点（tx / storage / events）

* 在 V2：查看 `Transfer`（LP 转移）与 `Burn`（或 pair 的 `Burn` event）以确认 `amount0/amount1`。
* 在 periphery：`V3Migrator` 的 tx receipt（确认调用顺序、参数）。
* 在 V3：检查 `NonfungiblePositionManager` 的 `Mint` / `Transfer`（ERC721）事件，读 `positions(tokenId)`、pool 的 `liquidity` 与 `ticks`。

---



