// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// 被调用的目标合约
contract TargetContract { // 规范化合约名

    /**
     * @notice 返回 ID 1 和当前区块时间戳。
     * @return id 1。
     * @return timestamp 当前区块时间戳。
     */
    function f1() external view returns(uint256 id, uint256 timestamp) { // 明确类型
        return (1, block.timestamp);
    }

    /**
     * @notice 返回 ID 2 和当前区块时间戳。
     * @return id 2。
     * @return timestamp 当前区块时间戳。
     */
    function f2() external view returns(uint256 id, uint256 timestamp) {
        return (2, block.timestamp);
    }

    /**
     * @notice 编码 f1() 的函数签名 calldata。
     * @return 编码后的 calldata。
     */
    function getF1Calldata() external pure returns (bytes memory) {
        // abi.encodeWithSignature 是 abi.encodeWithSelector 的一个语法糖
        return abi.encodeWithSignature("f1()"); 
    }
}

// -----------------------------------------------------------
// 模式 1: Multicall (多重 Call) - 调用多个外部合约的 view/pure 函数
// -----------------------------------------------------------

contract MultiCall { // 规范化合约名

    /**
     * @notice 一次性调用多个外部合约的函数。
     * 使用 staticcall (只读调用) 确保不会修改状态，且 gas 消耗低。
     * 每次调用的 msg.sender 都是 MultiCall 合约地址。
     * @param _targets 目标合约的地址数组。
     * @param _calldata 要调用的函数 calldata 数组。
     * @return 每次调用的返回值 (bytes 数组)。
     */
    function multicall(
        address[] calldata _targets, 
        bytes[] calldata _calldata
    ) 
        external 
        view 
        returns(bytes[] memory) 
    {
        require(_targets.length == _calldata.length, "MultiCall: Length mismatch"); 

        bytes[] memory results = new bytes[](_targets.length); // 存储每个函数的返回值

        for(uint256 i = 0; i < _targets.length; i++) {
            // 使用 staticcall 进行只读调用 (防止状态修改)
            (bool success, bytes memory res) = _targets[i].staticcall(_calldata[i]); 
            require(success, "MultiCall: call failed"); 
            results[i] = res;
        }
        return results;
    }
}


// -----------------------------------------------------------
// 模式 2: MultiDelegateCall (多重委托调用)
// -----------------------------------------------------------

contract MultiDelegateCall { // 规范化合约名
    // 状态变量，用于演示 delegatecall 的效果
    uint256 public testValue = 0; 

    /**
     * @notice 演示多重委托调用。
     * 每次调用的代码在目标合约(_targets)中运行，但状态修改发生在 **本合约** 的存储中。
     * 每次调用的 msg.sender 都是 **外部发起者** 的地址。
     * @param _targets 目标合约的地址数组。
     * @param _calldata 要调用的函数 calldata 数组。
     * @return 每次调用的返回值 (bytes 数组)。
     */
    function multiDelegateCall(
        address[] calldata _targets, 
        bytes[] calldata _calldata
    ) 
        external 
        returns(bytes[] memory) 
    {
        require(_targets.length == _calldata.length, "MultiDelegateCall: Length mismatch"); 

        bytes[] memory results = new bytes[](_targets.length);

        for(uint256 i = 0; i < _targets.length; i++) {
            // 使用 delegatecall，所有状态修改都发生在当前合约
            (bool success, bytes memory res) = _targets[i].delegatecall(_calldata[i]); 
            require(success, "MultiDelegateCall: call failed"); 
            results[i] = res;
        }
        return results;
    }
    
    // 为了演示，添加一个目标函数，用于通过 delegatecall 修改 testValue
    function setValue(uint256 _newValue) external {
        testValue = _newValue;
    }
}