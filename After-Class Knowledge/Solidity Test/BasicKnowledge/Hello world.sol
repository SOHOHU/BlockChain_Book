// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract HelloWorld { // 规范化合约名
    // 状态变量：合约存储空间中的变量
    string public myName = "SOHO HU"; // 规范化变量名，增加 public 方便外部读取

    /**
     * @notice 获取当前存储的名称。
     * view 承诺不会修改合约的任何状态变量（不改变存储）。
     * @return 存储的名称。
     */
    function getName() public view returns(string memory) {
        return myName;
    }

    /**
     * @notice 修改存储的名称。
     * 这是一个状态修改函数（State-modifying function）。
     * @param _newName 新的名称。
     */
    function changeName(string memory _newName) public {
        myName = _newName;
    }

    /**
     * @notice 纯函数示例，不读取也不修改任何状态变量。
     * pure 承诺既不会读取 (如 myName)，也不会修改 (如 myName = ...)。
     * @param _inputName 传入的名称。
     * @return 传入的名称。
     */
    function pureTest(string memory _inputName) public pure returns(string memory) {
        return _inputName;
    }
}