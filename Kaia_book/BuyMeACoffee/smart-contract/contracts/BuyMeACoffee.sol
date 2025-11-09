// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BuyMeACoffee {
    // 结构体用于存储“咖啡”的信息
    struct Memo {
        address payable from;
        uint256 timestamp;
        string name;
        string message;
    }

    // 存储所有购买记录的数组
    Memo[] memos;

    // 合约的部署者/所有者
    address payable owner;

    // 咖啡购买事件，用于方便前端查询
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    // 构造函数：在合约部署时运行一次
    constructor() {
        owner = payable(msg.sender);
    }

    // --- 核心功能 1: 购买咖啡 ---
    // 可支付函数 (payable)，允许用户发送 KAIA 代币 (msg.value)
    function buyCoffee(string memory _name, string memory _message) public payable {
        // 要求发送的金额不能为零
        require(msg.value > 0, "Can't buy coffee with 0 KAIA!");

        // 记录购买信息
        memos.push(
            Memo({
                from: payable(msg.sender),
                timestamp: block.timestamp,
                name: _name,
                message: _message
            })
        );

        // 发出事件
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    // --- 核心功能 2: 提现小费 ---
    // 限制只有合约所有者可以调用
    function withdrawTips() public {
        require(msg.sender == owner, "You are not the owner!");

        // 获取合约当前的余额
        uint256 balance = address(this).balance;

        // 要求余额大于零
        require(balance > 0, "No tips to withdraw!");

        // 将所有余额转账给所有者
        owner.transfer(balance);
    }

    // --- 辅助功能: 获取所有购买记录 ---
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }
}