// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title ICounter
 * @notice 计数器合约的标准接口。
 */
interface ICounter { // 规范化接口名 ICounter
    function count() external view returns (uint256); // 明确类型 uint256
    function inc() external;
}

/**
 * @title InterfaceCaller
 * @notice 演示如何通过接口实例化来调用外部合约函数。
 */
contract InterfaceCaller { // 规范化合约名 InterfaceCaller
    uint256 public counterValue; // 明确类型 uint256

    /**
     * @notice 通过接口调用外部计数器合约的函数。
     * @param _counterAddress 计数器合约的地址。
     */
    function callExternalCounter(address _counterAddress) external { // 规范化函数名
        // 接口实例化：通过地址强制类型转换来创建一个接口实例。
        ICounter counterContract = ICounter(_counterAddress);
        
        // 调用外部合约的函数
        counterContract.inc();
        counterValue = counterContract.count(); // 获取最新值
    }
}