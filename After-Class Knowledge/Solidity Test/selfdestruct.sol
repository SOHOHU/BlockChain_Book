// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title SelfDestructExample
 * @notice 演示合约自毁功能 (selfdestruct)。
 * @dev 警告：一旦销毁，合约代码将从链上移除，无法恢复，且所有剩余 ETH 会被转移。
 */
contract SelfDestructExample { // 规范化合约名
    address public owner;

    /**
     * @notice 构造函数，允许在部署时接收 ETH。
     */
    constructor() payable {
        owner = msg.sender;
    }

    /**
     * @notice 销毁合约并将剩余的 ETH 发送到指定地址。
     * 最佳实践：应限制只有合约拥有者才能调用此函数。
     */
    function destroyContract(address payable _recipient) external { // 规范化函数名
        // 限制只有部署者才能销毁
        require(msg.sender == owner, "SelfDestructExample: Only owner can kill");
        
        // 将合约内所有 ETH 转移给 _recipient，并销毁合约代码。
        selfdestruct(_recipient); 
    }

    /**
     * @notice 纯视图函数，用于测试合约被销毁前是否正常工作。
     * @return 恒定的返回值。
     */
    function testViewCall() external pure returns (uint256) { // 规范化函数名和类型
        return 123;
    }
}