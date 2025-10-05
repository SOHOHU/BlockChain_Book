// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// 被调用的目标合约
contract Test {
    uint256 public x;
    uint256 public value = 123;

    /**
     * @notice 设置 x 的值。
     * @param _x 新的 x 值。
     */
    function setX(uint256 _x) external {
        x = _x;
    }

    /**
     * @notice 获取 x 的值。
     * @return x 的当前值。
     */
    function getX() external view returns (uint256) {
        return x;
    }

    /**
     * @notice 设置 x 的值并接收以太币。
     * @param _x 新的 x 值。
     */
    function setXReceiveEther(uint256 _x) external payable { // 函数名使用小驼峰命名法
        x = _x;
        value = msg.value; // 记录接收到的以太币数量
    }

    /**
     * @notice 获取 x 和 value 的值。
     * @return x 的值和 value 的值。
     */
    function getXAndValue() external view returns (uint256, uint256) {
        return (x, value);
    }
}

// 高级调用合约
contract CallTestContract {
    // 事件：用于记录 fallback 函数被调用的情况
    event Log(string message);

    // 回退函数 (fallback)：在调用不存在的函数时（或未带数据的原生转账）被调用
    fallback() external payable {
        emit Log("Fallback function executed"); // 更清晰的事件消息
    }

    // 接收函数 (receive)：仅在不带数据的原生以太币转账时被调用
    receive() external payable {}

    /**
     * @notice 使用高级调用方式调用 Test.setX。
     * @param _test 目标 Test 合约地址。
     * @param _x 传递的参数。
     */
    function callSetX(Test _test, uint256 _x) external {
        // 高级调用：类型安全，编译器会检查函数签名
        _test.setX(_x);
    }

    /**
     * @notice 使用高级调用方式调用 Test.getX。
     * @param _test 目标 Test 合约地址。
     * @return x 从目标合约获取的 x 值。
     */
    function callGetX(address _test) external view returns (uint256 x) {
        // 通过类型转换 Test(_test) 实例化合约接口
        x = Test(_test).getX();
        return x;
    }

    /**
     * @notice 使用高级调用方式调用 Test.setXReceiveEther 并发送 ETH。
     * @param _test 目标 Test 合约地址。
     * @param _x 传递的参数。
     */
    function callSetXAndSendEther(address _test, uint256 _x) external payable { // 函数名使用小驼峰命名法
        // 使用 {value: msg.value} 语法发送 ETH 给目标合约
        Test(_test).setXReceiveEther{value: msg.value}(_x);
        // 将当前交易带入的 ETH 全部转发给 Test 合约
    }

    /**
     * @notice 使用高级调用方式调用 Test.getXAndValue。
     * @param _test 目标 Test 合约地址。
     * @return x 从目标合约获取的 x 值。
     * @return value 从目标合约获取的 value 值。
     */
    function callGetXAndValue(address _test) external view returns (uint256 x, uint256 value) {
        (x, value) = Test(_test).getXAndValue();
        return (x, value);
    }
}

// 低级调用合约
contract LowLevelCall { // 契约名使用大驼峰命名法
    bytes public data; // 用于存储调用返回的数据

    /**
     * @notice 演示低级 call 的用法。
     * @param _test 目标合约地址。
     */
    function callGetX(address _test) external payable { // 函数名使用小驼峰命名法
        // 低级调用：_test.call{value: ETH_AMOUNT}(calldata)
        // abi.encodeWithSignature("getX()")：编码函数签名和参数
        (bool success, bytes memory _data) = _test.call{value: 123}(
            abi.encodeWithSignature("getX()") // 修正：应该是 getX()，不是 getX(address)
        );
        require(success, "Call failed");
        data = _data; // 存储返回的原始字节数据
    }

    /**
     * @notice 演示调用不存在的函数。低级 call 调用不存在的函数时，如果目标合约有 fallback 函数，会成功并执行 fallback。
     * @param _test 目标合约地址。
     */
    function callNotExist(address _test) external {
        // 低级调用默认会成功，除非目标合约 revert 或没有足够的 gas
        // 成功并不代表函数执行正确，仅代表 EVM 层面的调用成功
        (bool success, ) = _test.call(abi.encodeWithSignature("doesNotExist()"));
        // 如果目标合约有 fallback，这里 success 可能是 true，并执行 fallback
        require(success, "Call to non-existent function failed");
    }
}