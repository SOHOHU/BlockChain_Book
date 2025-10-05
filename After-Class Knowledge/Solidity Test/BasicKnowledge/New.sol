// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title WalletAccount
 * @notice 被工厂合约创建的钱包账户合约。
 */
contract WalletAccount { // 规范化合约名
    address public factory; // 创建本合约的工厂地址
    address public owner;   // 钱包的实际所有者

    /**
     * @notice 构造函数。
     * @param _owner 钱包的拥有者地址。
     */
    constructor(address _owner) payable {
        // msg.sender 此时是工厂合约的地址
        factory = msg.sender;
        owner = _owner;
    }

    // 允许通过 receive 接收 ETH
    receive() external payable {}
}

/**
 * @title WalletFactory
 * @notice 负责部署新的 WalletAccount 合约的工厂。
 */
contract WalletFactory { // 规范化合约名
    // 存储所有已创建的账户地址
    WalletAccount[] public accounts; 

    /**
     * @notice 创建一个新的 WalletAccount 合约，并发送 100 Wei。
     * @param _owner 新账户的拥有者地址。
     */
    function createAccount(address _owner) external { // 规范化函数名
        // 使用 new 关键字创建新合约，并通过 {value: ...} 发送 ETH
        WalletAccount account = new WalletAccount{value: 100 wei}(_owner); 
        
        accounts.push(account);
    }
}