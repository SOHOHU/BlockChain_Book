// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

contract SimpleMathTest { // 规范化合约名
    // 状态变量
    int256 public signedNumber = 100; // 明确类型 int256
    uint256 public unsignedNumber = 200; // 明确类型 uint256
    uint8 public smallUnsigned = 255;

    /**
     * @notice 计算两个无符号整数的和，并返回带符号整数。
     * @param _a 第一个无符号整数。
     * @param _b 第二个无符号整数。
     * @return 两个数之和的带符号整数结果。
     */
    function add(uint256 _a, uint256 _b) public pure returns(int256){ // 明确类型
        // Solidity 0.8+ 默认进行安全检查，防止溢出。
        return int256(_a + _b); // 强制类型转换
    }

    /**
     * @notice 计算状态变量 unsignedNumber 和 smallUnsigned 的和。
     * @return 两个状态变量之和的带符号整数结果。
     */
    function addStateVariables() public view returns(int256){ // 规范化函数名
        return int256(unsignedNumber + smallUnsigned);
    }

    /**
     * @notice 返回几个常用的全局区块链变量。
     * @return sender 当前交易的发送者地址 (msg.sender)。
     * @return timestamp 当前区块的时间戳 (block.timestamp)。
     * @return blockNum 当前区块的编号 (block.number)。
     */
    function getGlobalVariables() external view returns (address sender, uint256 timestamp, uint256 blockNum) { // 规范化函数名和返回类型
        // 全局变量
        sender = msg.sender;
        timestamp = block.timestamp;
        blockNum = block.number;
        return (sender, timestamp, blockNum);
    }
}