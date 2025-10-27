// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// ----------------------
// 目标合约实现
// ----------------------
contract ImplementationV1 { // 规范化合约名
    address public owner = msg.sender;

    function setOwner(address _newOwner) public { // 规范化函数名
        require(owner == msg.sender,"ImplementationV1: Only current owner");
        owner = _newOwner;
    }
}

contract ImplementationV2 { // 规范化合约名
    address public owner = msg.sender;
    uint256 public sentValue;
    uint256 public x;
    uint256 public y;

    constructor(uint256 _x,  uint256 _y) payable {
        x = _x;
        y = _y;
        sentValue = msg.value;
    }
}

// ----------------------
// 部署和执行合约的工厂
// ----------------------

contract ContractDeployer { // 规范化合约名
    event Deploy(address indexed newContractAddress);

    fallback() external payable{}
    receive() external payable {} 

    /**
     * @notice 使用 EVM 汇编 `create` 操作码部署合约。
     * @param _code 待部署合约的完整字节码（包含构造函数参数）。
     * @return addr 部署后的合约地址。
     */
    function deployContract(bytes memory _code) external payable returns (address addr) { 
        assembly {
            // create(value, offset, size)
            // callvalue()：本次交易携带的 ETH
            // add(_code, 0x20)：跳过 bytes 数据的长度槽位 (32 字节)
            // mload(_code)：获取 bytes 数据的实际长度
            addr := create(callvalue(), add(_code, 0x20), mload(_code))
        }

        require(addr != address(0), "ContractDeployer: deployment failed");
        emit Deploy(addr);
    }

    /**
     * @notice 对指定合约执行一个通用的低级 `call`。
     * @param _targetContract 目标合约地址。
     * @param _data 调用的 calldata。
     */
    function executeCall(address _targetContract, bytes memory _data) external payable { 
        // 将调用方发送的 ETH 一并转发
        (bool success, ) = _targetContract.call{value: msg.value}(_data);
        require(success, "ContractDeployer: call failed");
    }
}

// ----------------------
// 辅助工具
// ----------------------

contract BytecodeHelper { // 规范化合约名
    
    /**
     * @notice 获取 ImplementationV1 的创建字节码（无构造函数参数）。
     * @return 字节码。
     */
    function getBytecodeV1() external pure returns (bytes memory) {
        return type(ImplementationV1).creationCode;
    }

    /**
     * @notice 获取 ImplementationV2 的完整创建字节码（包含编码参数）。
     * @param _x 构造函数参数 x。
     * @param _y 构造函数参数 y。
     * @return 带有编码参数的完整字节码。
     */
    function getBytecodeV2(uint256 _x,  uint256 _y) external pure returns (bytes memory) {
        // 将参数的 ABI 编码附加到 creationCode 后面
        bytes memory bytecode = type(ImplementationV2).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_x, _y));
    }

    /**
     * @notice 生成调用 setOwner 函数的 calldata。
     * @param _newOwner 要设置的新所有者地址。
     * @return 调用的 calldata。
     */
    function getSetOwnerCallData(address _newOwner) external pure returns ( bytes memory) { // 规范化函数名
        // abi.encodeWithSignature("函数签名", 参数...)
        return abi.encodeWithSignature("setOwner(address)", _newOwner);
    }
}