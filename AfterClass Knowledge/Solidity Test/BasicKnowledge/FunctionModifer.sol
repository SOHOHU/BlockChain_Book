// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract FunctionModifierTest { // 契约名使用大驼峰命名法
    // 状态变量
    bool public isPaused; // 规范化变量名
    uint256 public counter; // 明确类型 uint256

    /**
     * @notice 构造函数，初始化合约状态。
     * @param _isPaused 初始的暂停状态。
     * @param _initialCount 初始计数。
     */
    constructor(bool _isPaused, uint256 _initialCount) {
        isPaused = _isPaused;
        counter = _initialCount;
    }

    /**
     * @notice 修饰符：要求合约未暂停。
     */
    modifier whenNotPaused() { // 修饰符使用小驼峰命名法
        require (!isPaused, "FunctionModifierTest: Contract is paused"); // 规范化错误信息
        _; // _ 代表被修饰函数的代码
    }

    /**
     * @notice 修饰符：检查输入值是否为特定值，并在函数体执行后修改状态。
     * @param _input 待检查的输入参数。
     */
    modifier onlyValidInput(uint256 _input) { // 修饰符使用小驼峰命名法
        require (_input == 100, "FunctionModifierTest: Invalid input value");
        _;
        counter = 1024; // 在函数体执行后执行的逻辑
    }

    /**
     * @notice 设置暂停状态。
     * @param _newPauseState 新的暂停状态。
     */
    function setPause(bool _newPauseState) external {
        isPaused = _newPauseState;
    }

    /**
     * @notice 获取当前计数器的值。
     * @return 当前计数器的值。
     */
    function getCounter() external view returns(uint256){
        return counter;
    }

    /**
     * @notice 增加计数器，受到两个修饰符的限制。
     * @param _a 传递给 onlyValidInput 修饰符的参数。
     */
    function incrementWithChecks(uint256 _a) external whenNotPaused onlyValidInput(_a) {
        counter++;
    }

    /**
     * @notice 减少计数器，受到暂停修饰符的限制。
     */
    function decrement() external whenNotPaused {
        counter--;
    }
}