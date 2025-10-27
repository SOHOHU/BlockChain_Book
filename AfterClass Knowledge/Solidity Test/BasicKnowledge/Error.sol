// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ErrorTest { // 契约名使用大驼峰命名法

    /**
     * @notice 检查输入是否大于 10。用于处理用户输入或外部条件错误。
     * @param a 待检查的数字。
     */
    function forRequire(uint256 a) external pure { // 函数名使用小驼峰命名法，明确类型
        // require：用于检查输入或外部条件。失败时退回剩余 gas 并可提供错误信息。
        require(a > 10, "Input must be greater than 10");
    }

    // 自定义错误（Solidity 0.8.4+ 推荐）：更节约 gas
    error MyError(address me, uint256 i);

    /**
     * @notice 演示使用 revert 关键字。
     * @param a 待检查的数字。
     */
    function forRevert(uint256 a) external view {
        if (a == 10) {
            // revert：可以直接触发回滚，并可提供错误信息。
            revert("a == 10");
        }

        if (a > 20) {
            // 使用自定义错误来 revert
            revert MyError(msg.sender, block.number);
        }
    }

    uint256 public num = 123;

    /**
     * @notice 演示 assert 的典型用法（通常用于检查不应发生的情况/内部错误）。
     * 当 assert 失败时，会消耗所有剩余 gas 并回滚。
     */
    function forAssert() external {
        // assert：用于检查不应发生的内部错误或状态。如果失败，表示代码中有 bug。
        assert(num == 123);
        num++; // 假设 num++ 是一个内部状态修改
    }

    /**
     * @notice 演示 assert 在 view 函数中的用法。
     */
    function forAssert2() external view {
        // 仅在 view 函数中，assert 失败的行为与 require/revert 相似，不会消耗所有 gas。
        assert(num == 123);
    }
}