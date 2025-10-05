// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// 被部署的合约
contract DeployTest { // 契约名使用大驼峰命名法
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }
}

// 使用 create2 部署合约的工厂合约
contract Create2Factory { // 契约名使用大驼峰命名法
    // 事件：记录成功部署的合约地址
    event Deploy(address addr);

    /**
     * @notice 使用 create2 部署 DeployTest 合约。
     * @param _salt 用于地址计算的盐值。
     */
    function deploy(uint256 _salt) external {
        // new 合约 {salt: bytes32(_salt)} 是使用 create2 的语法
        DeployTest test = new DeployTest{
            salt: bytes32(_salt) // 将 uint 转换为 bytes32 作为 salt
        }(msg.sender); // 构造函数参数：将调用者设为 owner
        
        emit Deploy(address(test));
    }

    /**
     * @notice 计算使用 create2 部署合约的预期地址。
     * @param bytecode 待部署合约的字节码（包括构造函数参数的编码）。
     * @param salt 用于计算地址的盐值。
     * @return addr 预期部署的合约地址。
     */
    function getAddress(bytes memory bytecode, uint256 salt) public view returns (address addr) {
        // create2 地址计算公式：
        // keccak256( 0xff + 部署者地址 + salt + keccak256(合约字节码) )
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),              // 固定的前缀 0xff
                address(this),             // 部署者地址（即本合约地址）
                bytes32(salt),             // salt（必须是 bytes32 类型）
                keccak256(bytecode)        // 待部署合约字节码的哈希
            )
        );
        // 取哈希值的低 20 字节作为地址
        addr = address(uint160(uint256(hash)));
    }

    /**
     * @notice 计算 DeployTest 合约的完整部署字节码（包括构造函数参数）。
     * @param _owner 构造函数参数。
     * @return bytecode 完整部署字节码。
     */
    function getBytecode(address _owner) public pure returns (bytes memory bytecode) {
        // type(ContractName).creationCode 是合约本身的创建字节码
        // abi.encode(_owner) 是构造函数参数的编码
        bytecode = abi.encodePacked(
            type(DeployTest).creationCode,
            abi.encode(_owner)
        );
        return bytecode;
    }
}