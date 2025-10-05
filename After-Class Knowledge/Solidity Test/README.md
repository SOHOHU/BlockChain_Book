
## Solidity 的基础练习

---

## BasicKnowledge：基本的语法知识


1.  **`Hello world.sol`** → **`Boolean.sol`** → **`Math1.sol`**:
    > 合约基础结构、状态变量、**`view`** / **`pure`** 函数、布尔类型、整数类型、**全局变量**（`msg.sender`, `block.timestamp`）。
2.  **`Immutable.sol`**:
    > **`constant`** 和 **`immutable`** 常量、**`receive()`** 和 **`fallback()`** 接收函数。
3.  **`Counter.sol`**:
    > 状态修改、基本的 **循环** (`for`) 和条件判断。
4.  **`Error.sol`**:
    > 错误处理机制：**`require`**, **`revert`**, **`assert`** 和 **自定义错误** 的使用。
5.  **`Arraytest.sol`**:
    > **数组**（动态/静态）、数组操作、**`memory`** 和 **`storage`** 的概念。
6.  **`mappping.sol`** → **`emus.sol`**:
    > **映射** (`mapping`)、如何实现**可迭代映射**；**枚举类型** (`enum`)。
7.  **`structs.sol`**:
    > **结构体** (`struct`)；深入理解 **`storage` 引用** 与 **`memory` 拷贝** 的核心区别。
8.  **`FunctionModifer.sol`**:
    > **自定义函数修饰符** (`modifier`) 的编写和应用，实现前置检查。
9.  **`Ownable.sol`**:
    > 最基础的 **所有权模式**，使用 `modifier` 实现 **`OnlyOwner`** 访问控制。
10. **`Extend.sol`**:
    > **合约继承**、**`virtual`** 和 **`override`** 关键字。
11. **`MyInterface.sol`** → **`liberary.sol`**:
    > **接口** (`interface`) 的实例化和使用；**库** (`library`) 和 **`using for`** 扩展功能。
12. **`Accesscontrol.sol`**:
    > 进阶访问控制：**基于角色的访问控制**（RBAC）模式。
13. **`IERC20.sol`**:
    > 学习 **ERC-20 代币标准接口** 和其实现，代币的基础交互。
14. **`Callotherfunction.sol`**:
    > **标准合约调用**，通过接口或地址调用外部合约函数。
15. **`Send.sol`**:
    > **发送 ETH 的三种方式**：**`transfer`** / **`send`** / **`call`** 及其 Gas 限制。
16. **`Multicall.sol`**:
    > **多重调用** 模式，使用 **`staticcall`** 批量读取数据。
17. **`Delegatecall.sol`**:
    > **委托调用** (`delegatecall`) 的原理，理解其在**可升级合约**中的作用和存储槽风险。
18. **`New.sol`** → **`Proxy.sol`** → **`create2fac.sol`**:
    > **合约工厂**（`new` 关键字）→ **EVM 汇编部署**（`create`）→ **确定性地址部署**（`create2`）。
19. **`Hash.sol`**:
    > 哈希函数 **`keccak256`** 的安全使用，区分 **`abi.encode`** 和 **`abi.encodePacked`** 的哈希碰撞风险。
20. **`sig.sol`**:
    > **链下签名验证** (EIP-191)，使用 **`ecrecover`** 恢复签名者地址。
21. **`selfdestruct.sol`**:
    > 合约 **自毁** (`selfdestruct`) 功能及其后果。
22. **`Timelock.sol`**:
    > **时间锁模式** (Timelock)，实现关键操作的延迟执行。
23. **`Multisigwallet.sol`**:
    > **多重签名钱包** (MultiSig)，结合多种技术实现安全资金管理（**综合练习**）。
24. **`Dutch.sol`**:
    > **荷兰拍** 模式，结合时间戳和代币标准(`IERC721`)的综合应用。