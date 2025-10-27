// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract EnumTest { // 契约名使用大驼峰命名法
    // 枚举 (Enum)：定义一组命名常量，默认从 0 开始。
    enum Status {
        None, // 0
        Ship, // 1
        Go,   // 2
        Back  // 3
    }

    Status public currentStatus; // 枚举类型的状态变量

    // 结构体 (Struct)：定义自定义的复杂数据类型。
    struct Order { // 结构体名使用大驼峰命名法
        address owner;
        Status status;
    }

    Order public myOrder; // 结构体类型的状态变量

    /**
     * @notice 获取当前订单的状态。
     * @return 订单的 Status 枚举值。
     */
    function getStatus() external view returns (Status) { // 函数名使用小驼峰命名法
        return myOrder.status;
    }

    /**
     * @notice 设置订单的状态。
     * @param _status 传入的 Status 枚举值。
     */
    function setStatus(Status _status) external {
        myOrder.status = _status;
    }

    /**
     * @notice 将订单状态设置为 Status.Ship。
     */
    function shipOrder() external { // 使用更具描述性的函数名
        myOrder.status = Status.Ship;
    }

    /**
     * @notice 删除订单的状态（将恢复为枚举的第一个值，即 Status.None/0）。
     */
    function resetStatus() external { // 使用更具描述性的函数名
        delete myOrder.status;
    }
}