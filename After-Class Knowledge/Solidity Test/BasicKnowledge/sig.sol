// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/**
 * @title SignatureVerifier
 * @notice 用于验证外部账户签名（非合约 EIP-191）的工具合约。
 */
contract SignatureVerifier { // 规范化合约名

    // ===============================================
    // 核心验证函数
    // ===============================================
    
    /**
     * @notice 验证给定的签名是否由指定地址生成。
     * @param _signer 预期的签名者地址。
     * @param _message 原始消息字符串。
     * @param _sig 完整的 ECDSA 签名 (r, s, v)。
     * @return 验证结果 (true/false)。
     */
    function verifySignature(address _signer, string memory _message, bytes memory _sig) 
        external 
        pure 
        returns (bool) 
    { // 规范化函数名
        // 1. 计算原始消息的哈希
        bytes32 messageHash = getMessageHash(_message);
        
        // 2. 计算以太坊标准签名哈希 (包含前缀)
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        // 3. 恢复签名者地址并进行比较
        return recoverSigner(ethSignedMessageHash, _sig) == _signer;
    }

    // ===============================================
    // 辅助哈希函数
    // ===============================================

    /**
     * @notice 计算消息内容的 keccak256 哈希。
     * @dev 这里的 abi.encodePacked 是为了匹配签名工具（如 MetaMask）的原始哈希步骤。
     * @param _message 原始消息字符串。
     * @return 消息哈希。
     */
    function getMessageHash(string memory _message) public pure returns (bytes32){ // 规范化函数名
        return keccak256(abi.encodePacked(_message));
    }

    /**
     * @notice 计算以太坊标准签名哈希（用于 ecrecover）。
     * @param _messageHash 消息哈希。
     * @return 标准签名哈希。
     */
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) { // 规范化函数名
        // 拼接前缀："\x19Ethereum Signed Message:\n32" + 消息哈希
        return keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            _messageHash
        ));
    }

    // ===============================================
    // 恢复函数 (Recovery)
    // ===============================================

    /**
     * @notice 从标准签名哈希和签名中恢复签名者地址。
     * @param _ethSignedMessageHash 以太坊标准签名哈希。
     * @param _sig 完整的 ECDSA 签名。
     * @return 恢复出的签名者地址。
     */
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _sig) public pure returns (address) { // 规范化函数名
        (bytes32 r, bytes32 s ,uint8 v) = splitSignature(_sig);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /**
     * @notice 将 65 字节的签名分割成 r (32), s (32), v (1) 三部分。
     * @param _sig 完整的签名。
     * @return r ECDSA 的 r 值。
     * @return s ECDSA 的 s 值。
     * @return v ECDSA 的 v 值。
     */
    function splitSignature(bytes memory _sig) public pure returns (bytes32 r, bytes32 s, uint8 v) { // 规范化函数名
        require(_sig.length == 65, "SignatureVerifier: Invalid signature length");
        
        assembly {
            // 从内存中加载 r (偏移 0x20), s (偏移 0x40), v (偏移 0x60)
            r := mload(add(_sig, 0x20))
            s := mload(add(_sig, 0x40))
            v := byte(0, mload(add(_sig, 0x60))) // v 是最后一个字节
        }
        
        // 确保 v 是 27 或 28 (以太坊签名标准)
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "SignatureVerifier: Invalid v value");
    }
}