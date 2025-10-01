首先来拆解一下注入流动性的交易过程。还是按照我们已经讲解过的UniswapV3版本为准

1、钱包发起交易
我的钱包地址向uniswap的合约发起转账操作，调用合约NonfungiblePositionManager的mint()函数
本例中：
token0: ETH
token1: WBTC
amount0Desired: 0.00009996 ETH
amount1Desired: 0.00001484 WBTC
price range: （自定义Tick区间）
调用这个函数之后继续完成以下步骤的调用


2、流动池处理流动性

首先调用 UniswapV3Pool的函数`mint()`，相继完成如下流程

  * 计算当前池子价格和 tick 区间
  * 根据投入的 token0/token1 数量，计算可提供的流动性份额
  * 更新池子状态：`liquidity`, `tickCumulative`, `feeGrowth` 等
  * ETH + WBTC 被锁定在池子合约中
  * 手续费累积在池子内部（按 LP 的份额分配）

3、铸造 LP NFT
随后回到NonfungiblePositionManager.mint()函数，完成NFT 头寸创建，即position（代码详解中详细解释了）

4、交易完成，Gas 支付
这部分执行safeTransferFrom即可，gas的计算方法与swap中解释的相同

补充：
1、为什么我在ERC20转账中没看到我转出的ETH？
很简单，因为ETH不满足ERC20标准。它没有没掉，只是不显示了。ERC721 代币转账同理，它只显示LP Token（NFT）
2、L2 gas费为什么会出现那么多种类？
因为注入流动性的操作比较复杂，调用了多个合约来进行，所以gas消耗很大。这种情况下告诉用户最大的小费，让用户知道最大情况下的费用。至于为什么Swap和Transfer没有这些，因为他们消耗的gas很小，这个附加可以忽略不计了。

