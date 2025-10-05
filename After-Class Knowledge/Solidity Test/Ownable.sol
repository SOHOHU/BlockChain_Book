// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title Ownable
 * @notice 提供基本的合约所有权管理功能。
 */
contract Ownable { // 规范化合约名为 Ownable
    // 存储合约的拥有者地址
    address private _owner; // 使用 private 变量，通过 getter 函数暴露

    /**
     * @notice 构造函数，将部署者设置为合约的初始拥有者。
     */
    constructor () {
        _owner = msg.sender;
    }

    /**
     * @notice 返回当前合约的拥有者地址。
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice 限制只有合约拥有者才能调用该函数。
     */
    modifier onlyOwner() { // 规范化修饰符名 onlyOwner
        require(_owner == msg.sender, "Ownable: Only owner can call this function");
        _;
    }

    /**
     * @notice 转移合约的所有权给新的地址。
     * 只有当前所有者可以调用。
     * @param _newOwner 新的拥有者地址。
     */
    function transferOwnership(address _newOwner) external onlyOwner { // 规范化函数名
        require(_newOwner != address(0), "Ownable: New owner address cannot be zero address");
        _owner = _newOwner;
    } 

    /**
     * @notice 只有拥有者可以调用的视图函数。
     * @param _input 任意输入值。
     * @return signal 返回输入的信号值。
     */
    function ownerCanCall(uint256 _input) external view onlyOwner returns(uint256 signal) { // 规范化函数名和类型
        signal = _input;
    }

    /**
     * @notice 任何人都可以调用的纯函数。
     * @return 恒定的返回值 0。
     */
    function anyoneCanCall() external pure returns(uint256) { // 规范化函数名
        return 0;
    }
}