// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title EtherReceiver
 * @notice 用于接收 ETH 的目标合约，并记录接收到的信息。
 */
contract EtherReceiver { // 规范化合约名
    event Log(uint256 amount, uint256 gasRemaining);

    /**
     * @notice 接收纯 ETH (不带 calldata) 时调用。
     */
    receive() external payable {
        // msg.value: 本次交易携带的 ETH 数量
        // gasleft(): 当前交易剩余的 Gas 数量
        emit Log(msg.value, gasleft()); 
    }
}

/**
 * @title EtherSender
 * @notice 演示 Solidity 中三种发送 ETH 的方法：transfer, send, call。
 */
contract EtherSender { // 规范化合约名

    /**
     * @notice 构造函数，允许在部署时接收 ETH。
     */
    constructor() payable {} 
    
    /**
     * @notice 获取合约当前余额。
     * @return 余额 (Wei)。
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice 使用 .transfer() 方法发送 ETH。
     * @dev 限制：只发送 2300 Gas。在 EIP-150 后通常不推荐使用。
     * @param _to 接收方地址。
     */
    function transferEth(address payable _to) external payable { // 规范化函数名
        _to.transfer(123 wei); // 明确单位 wei
    }

    /**
     * @notice 使用 .send() 方法发送 ETH。
     * @dev 限制：只发送 2300 Gas，需要手动检查成功状态。
     * @param _to 接收方地址。
     */
    function sendEth(address payable _to) external payable { // 规范化函数名
        bool success = _to.send(123 wei);
        require(success, "EtherSender: send failed");
    }
    
    /**
     * @notice 使用低级 .call() 方法发送 ETH。
     * @dev 推荐：默认转发所有剩余 Gas，最灵活和安全。
     * @param _to 接收方地址。
     */
    function callEth(address payable _to) external payable { // 规范化函数名
        // call{value: 123 wei}("") 发送 123 wei，且 calldata 为空
        (bool success, ) = _to.call{value: 123 wei}(""); 
        require(success, "EtherSender: call failed");
    }
}