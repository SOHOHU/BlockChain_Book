这串数据看似很长，其实主要内容就是 函数+参数 的ABI 编码
从前四个字节：0x99e1d016可以对应出选择的函数是 function swap(SwapParams memory params) external payable returns (uint256 amountOut);（UniswapV4）

基于这个函数的函数结构和提供的交易细节，可以推出：
swap({
    path: [WETH, WBTC],
    recipient: 0x77ed…53bb,
    amountIn: 0.0001 ether,
    amountOutMinimum: ~0.00000372 WBTC,
    deadline: <2025-09-23 14:41:37>,
    pool: Uniswap V3 LP(WETH/WBTC),
    callback: 0x3d83…8fb290 (内部占位)
})
