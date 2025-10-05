// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract IndexedMapping { // 规范化合约名
    // 映射：地址 => 余额
    mapping (address => uint256) public balances; // 规范化变量名，明确类型
    // 映射：地址 => 是否已插入索引数组
    mapping (address => bool) public isInserted; // 规范化变量名
    // 数组：存储所有已插入的地址（用于遍历）
    address[] public keyIndex;

    /**
     * @notice 构造函数：初始化一些数据。
     */
    constructor () {
        // 使用实际的地址而非示例地址，以保持代码的可运行性
        address addr1 = 0x742d35Cc6634C0532925a3b844Bc454e4438f44e; 
        address addr2 = 0x682570081d431c9D58E885e33636B6C7741870C0; 

        balances[addr1] = 10;
        balances[addr2] = 20;
        isInserted[addr1] = true;
        isInserted[addr2] = true;
        keyIndex.push(addr1);
        keyIndex.push(addr2);
    }

    /**
     * @notice 插入新的地址和余额，并维护索引数组。
     * 这种模式允许遍历映射中的所有键（Solidity 无法直接遍历映射）。
     * @param _newKey 要插入的地址。
     * @param _value 对应的余额值。
     */
    function insertKey(address _newKey, uint256 _value) external { // 规范化函数名
        if (!isInserted[_newKey]) {
            isInserted[_newKey] = true;
            keyIndex.push(_newKey);
        }
        balances[_newKey] = _value;
    }

    /**
     * @notice 删除一个地址，并维护索引数组和映射。
     * @param _key 要删除的地址。
     */
    function deleteKey(address _key) external { // 规范化函数名
        if (isInserted[_key]) {
            // 1. 删除索引数组中的元素（通过将最后一个元素移到被删除的位置，然后 pop）
            for (uint256 i = 0; i < keyIndex.length; i++) {
                if (keyIndex[i] == _key) {
                    // 将最后一个元素移到当前位置
                    keyIndex[i] = keyIndex[keyIndex.length - 1];
                    // 移除最后一个元素
                    keyIndex.pop();
                    break;
                }
            }

            // 2. 清理映射
            delete balances[_key];
            delete isInserted[_key];
        }
    }

    /**
     * @notice 获取所有地址的列表（映射的键）。
     * @return 所有地址的数组。
     */
    function getKeys() external view returns (address[] memory) {
        return keyIndex;
    }
}