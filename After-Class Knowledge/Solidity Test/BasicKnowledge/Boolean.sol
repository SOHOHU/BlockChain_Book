// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

contract BooleanTest { // 契约名使用大驼峰命名法
    bool public a; // 状态变量添加 public 访问修饰符，通常会给变量起一个更具描述性的名字，例如：isTrue
    int256 public num1 = 100; // 明确指定 int 类型为 int256（Solidity 默认）并添加 public

    /**
     * @notice 根据输入的数字与 num1 的比较结果，返回布尔值 a 或其反值。
     * @param num2 待比较的整数。
     * @return 比较结果的布尔值。
     */
    function getBool(int256 num2) public view returns (bool) { // 函数名使用小驼峰命名法，明确类型
        if (num2 > num1) {
            return !a; // 如果 num2 > num1，返回 a 的反值
        } else {
            return a; // 否则返回 a
        }
    }
}