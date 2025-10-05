// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Counter {
    uint256 public count; // 明确类型为 uint256

    /**
     * @notice 计数器加 1。
     */
    function increment() external { // 使用更具描述性的函数名
        count++;
    }

    /**
     * @notice 计数器减 1。
     */
    function decrement() external { // 使用更具描述性的函数名
        count--;
    }

    /**
     * @notice 循环加 10 次，并在第 5 次时将 count 重置为 100。
     */
    function incrementTenWithReset() external {
        // i 应从 0 开始
        for (uint256 i = 0; i < 10; i++) {
            count++;
            if (i == 4) { // 当 i=4 时（即第 5 次循环）
                count = 100;
            }
        }
    }
}