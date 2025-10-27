
## 接下来我将详细解释移出流动性这个步骤在合约中的生命线（不理解添加流动性的同学可以参考）

约定：依然使用UniswapV3讲解
---

### **1、 NFT 头寸管理合约**

* **合约**：`NonfungiblePositionManager`（V3）

  * V4 对应 NFT LP 的管理合约，可能命名为 `UniswapV4PositionsNFT`
* **函数**：

  ```solidity
  function decreaseLiquidity(DecreaseLiquidityParams calldata params) external returns (uint256 amount0, uint256 amount1);
  ```

  * 参数 `params` 包含：

    * tokenId: NFT ID (#18165)
    * liquidity: 要移出的流动性数量
    * tickLower / tickUpper: 原本头寸的价格区间
  * 功能：销毁头寸中的流动性份额，并计算返还的 token0/token1 数量

---

### 2、 收取手续费**

* **函数**：

  ```solidity
  function collect(CollectParams calldata params) external returns (uint256 amount0, uint256 amount1);
  ```

  * 参数 `params` 包含：

    * tokenId: NFT ID
    * recipient: 资产返还地址
  * 功能：

    * 收取 NFT 头寸内累计的交易手续费
    * 同时返回用户账户

> 在 V4 中，这一步可能在 **decreaseLiquidity()** 内部直接完成，自动把手续费一起返还给用户。

---

### 3、 池子合约（UniswapV3Pool）**

* **函数**：

  ```solidity
  function burn(uint128 liquidity) external returns (uint256 amount0, uint256 amount1);
  ```

  * 用于减少池子中的流动性
  * 内部会更新：

    * `liquidity`
    * `tickCumulative`
    * `feeGrowthGlobalX128`
* **资金流向**：

  * NFT 头寸内的 token0/token1 按比例从池子返回用户钱包

---

### **4、 ERC20/ERC721 事件**

* ERC20 WBTC 转账事件：

  ```solidity
  Transfer(address indexed from, address indexed to, uint256 value)
  ```

  * 从池子（Uniswap V4） → 用户钱包

* ERC721 NFT burning：

  ```solidity
  _burn(uint256 tokenId)
  ```

  * NFT 被销毁，表示头寸完全移除

* ETH 是原生币，返回方式通过 **call / value**：

  ```solidity
  (bool success, ) = recipient.call{value: amount0}("");
  ```

