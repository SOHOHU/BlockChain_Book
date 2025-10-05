// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ImmutableTest { // 规范化合约名
    // constant (常量): 编译时已知，直接嵌入字节码，不占用存储空间，最省 Gas。
    uint256 public constant FIXED_VALUE = 456; // 常量名使用全大写加下划线

    // immutable (不可变变量): 构造函数运行时设置，之后不能修改，不占用存储空间，比 constant 灵活。
    uint256 public immutable initializedValue; // 规范化变量名

    // 普通状态变量 (存储在 Storage)
    uint256 public stateCount; // 规范化变量名

    /**
     * @notice 构造函数，用于设置 immutable 变量。
     */
    constructor () {
        initializedValue = 123; // 只能在构造函数中设置
        stateCount = 0;
    }

    // =======================
    // ETH 接收函数和 Fallback 函数
    // =======================

    // receive 函数：用于接收不带 calldata 的纯 ETH 转账
    receive() external payable {
        stateCount--; // 仅在接收纯 ETH 时减少计数
    }

    // fallback 函数：当调用不存在的函数签名时，或接收带 calldata 的 ETH 转账时调用
    fallback() external payable {
        stateCount++; // 在任何未匹配的调用时增加计数
    }

    /**
     * @notice 用于接收 ETH 的函数，可用于任何外部调用。
     */
    function deposit() external payable {
        // 无需额外代码，仅用于接收 ETH
    }

    /**
     * @notice 获取合约的余额和状态计数。
     * @return contractBalance 合约当前的 ETH 余额。
     * @return currentStateCount 状态计数器的值。
     */
    function getBalanceAndCount() external view returns (uint256 contractBalance, uint256 currentStateCount) {
        // address(this).balance 是一个全局变量，表示合约地址上的 ETH 余额
        return (address(this).balance, stateCount); 
    }
}