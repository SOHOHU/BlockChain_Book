// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ArrayTest { // 契约名使用大驼峰命名法
    // 动态数组（存储在 storage）
    uint256[] public dynamicArr = [1, 2, 3];
    // 静态数组（存储在 storage）
    uint256[10] public staticArr;

    /**
     * @notice 演示动态数组的基本操作（push, 索引修改, pop）和 memory 数组的创建。
     * @return len 动态数组 dynamicArr 的当前长度。
     */
    function arrayOperations() internal returns (uint256 len) { // 函数名使用小驼峰命名法，明确类型
        dynamicArr.push(4);  // 尾部添加元素
        dynamicArr[1] = 0;   // 索引修改元素
        dynamicArr.pop();    // 尾部删除元素

        // memory 数组：只能是局部变量，必须指定长度（定长），仅在函数执行期间存在。
        uint256[] memory a = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            a[i] = i;
        }

        len = dynamicArr.length;
    }

    /**
     * @notice 返回动态数组 dynamicArr 的副本和长度。
     * @return arrMemory dynamicArr 的 memory 副本。
     * @return length dynamicArr 的长度。
     */
    function returnArray() external returns (uint256[] memory arrMemory, uint256 length) {
        // 存储 (Storage) 变量赋值给 memory 变量时，会创建一个副本（类型转换）
        arrMemory = dynamicArr;
        length = arrayOperations();
    }
}