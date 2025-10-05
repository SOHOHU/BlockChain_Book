// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract HashFunctionTest { // 契约名使用大驼峰命名法

    /**
     * @notice 计算三个输入的 keccak256 哈希值。
     * 推荐使用 abi.encode 以避免由于类型截断/连接导致的哈希碰撞。
     * @param _text 字符串输入。
     * @param _num 整数输入。
     * @param _addr 地址输入。
     * @return 计算出的 bytes32 哈希值。
     */
    function calculateHash(string memory _text, uint256 _num, address _addr) external pure returns (bytes32) {
        // **安全提示：** 避免使用 abi.encodePacked，因为它可能导致哈希碰撞。
        // abi.encode 会对每个参数进行 32 字节填充，确保输入边界清晰。
        return keccak256(abi.encode(_text, _num, _addr));
    }

    /**
     * @notice 示例：使用 abi.encodePacked 的危险性（不规范，仅作演示）。
     * @param _a 第一个 uint8。
     * @param _b 第二个 uint8。
     * @return 使用 abi.encodePacked 计算的哈希值。
     */
    function unsafeHashPacked(uint8 _a, uint8 _b) external pure returns (bytes32) {
        // 警告：keccak256(abi.encodePacked(uint8(1), uint8(2)))
        // 和 keccak256(abi.encodePacked(uint16(258))) 可能会产生相同的哈希值。
        return keccak256(abi.encodePacked(_a, _b));
    }
}