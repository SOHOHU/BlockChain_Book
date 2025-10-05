// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title MathLibrary
 * @notice 库合约，不能有状态变量，不能接收 ETH，其代码通过 delegatecall 注入调用合约。
 */
library MathLibrary { // 库名使用大驼峰命名法

    /**
     * @notice 计算两个数中的最大值。
     * 库函数通常是 internal pure/view，并通过 using for 挂载到类型上。
     * @param x 第一个数。
     * @param y 第二个数。
     * @return 两个数中的最大值。
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }
}

contract LibraryUsageTest { // 规范化合约名
    // 使用 MathLibrary 中的函数来扩展 uint256 类型
    using MathLibrary for uint256;

    /**
     * @notice 演示如何使用库函数 (max) 扩展 uint256 类型。
     * @param x 第一个输入。
     * @param y 第二个输入。
     * @return 最大值。
     */
    function testMax(uint256 x, uint256 y) public pure returns (uint256) {
        // 当使用 using for 之后，max 函数的第一个参数 (x) 会自动成为调用的对象
        return x.max(y); 
        // 相当于 MathLibrary.max(x, y);
    }
}