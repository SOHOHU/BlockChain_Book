在这段Swap示例中，我们发现ETH不是直接从流动池兑换而来的
它经历了五步：
0、精准输入（输入我要的0.001ETH，告诉我多少WBTC）
1、EOA -> Uniswap V4 0.001WETH （用户向合约交付0.001ETH）
2、LP(WETH/WBTC) → Uniswap V4：0.00000372WBTC  （LP 提供 WBTC 供交换）
3、Uniswap V4 → V3 LP(WETH/WBTC) 0.0001WETH   （V4 收取用户 WETH 并转入 LP）
4、Uniswap V4 → 0x3d83…8fb290 0WETH	（占位或回退金额，可能用于多路径调用）
5、Uniswap V4 → 0x77ed…d10f53bb	0.00000372WBTC	（最终用户收到兑换后的 WBTC）

这5步符合ERC20的准则，也符合之前讲过的代码的函数顺序（假设在UniswapV3进行）
这是单跳swap
1、Step 0 & 1：用户调用交易
在合约：SwapRouter（V3）调用函数：

function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut)

2、Step 2 & 3：与流动性池交互

在合约：UniswapV3Pool 调用函数：

function swap(
    address recipient,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96,
    bytes calldata data
) external returns (int256 amount0, int256 amount1)
其中：
zeroForOne = true  （token0 → token1，ETH贬值） 
amountSpecified = exact amount in or out (精准输入，amountSpecified > 0)
recipient = Router （最终用户地址）

4、Step 4：中间地址（占位）

调用接口函数：

IUniswapV3SwapCallback(unusedAddress).uniswapV3SwapCallback(amount0Delta, amount1Delta, data);

调用 callback，可能触发内部代币计算（因为手续费给流动池增加的Token0和Token1价值），不转实际资金

5、Step 5：最终用户收到 WBTC

合约：Router 调用函数（没有讲过，UniswapV2的Router有一样的函数）：

TransferHelper.safeTransfer(tokenOut, recipient, amountOut);

