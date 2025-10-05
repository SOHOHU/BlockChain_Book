// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// 被委托调用的合约（目标合约）
contract TestDelegateCall {
    // 状态变量的顺序和类型必须与调用合约 DelegateCall 完全一致，这是 delegatecall 正确工作的关键。
    uint256 public num;
    address public sender;
    uint256 public value;

    /**
     * @notice 设置状态变量 num、sender 和 value。
     * @param _num 用于计算新 num 值的输入。
     */
    function setValue(uint256 _num) external payable { // 函数名使用小驼峰命名法
        num = 2 * _num;
        sender = msg.sender;
        value = msg.value;
    }
}

// 调用合约（代理合约）
contract DelegateCall {
    // 状态变量必须与 TestDelegateCall 保持完全一致的顺序和类型！
    uint256 public num;    // Slot 0
    address public sender; // Slot 1
    uint256 public value;  // Slot 2

    /**
     * @notice 使用 delegatecall 调用目标合约 TestDelegateCall 中的 setValue 函数。
     * 所有状态变量的修改将发生在 DelegateCall 合约的存储中。
     * @param _test 目标合约 (TestDelegateCall) 的地址。
     * @param _num 传递给目标函数的参数。
     */
    function setValue(address _test, uint256 _num) external payable {
        // 使用 abi.encodeWithSelector 是比 abi.encodeWithSignature 更推荐和更节约 gas 的方式
        // 委托调用：代码在 _test 运行，但存储（状态变量）在 DelegateCall 合约中修改。
        (bool success, ) = _test.delegatecall(
            abi.encodeWithSelector(TestDelegateCall.setValue.selector, _num)
        );
        // 确保调用成功
        require(success, "Delegate call failed");
    }
}