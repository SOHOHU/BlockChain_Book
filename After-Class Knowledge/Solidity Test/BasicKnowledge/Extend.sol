// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// 基类 A
contract ContractA { // 契约名使用大驼峰命名法
    // public 状态变量可以被继承合约访问
    uint256 public publicName;
    // private 状态变量不能被继承合约直接访问，即使是内部函数也不行
    uint256 private privateClock;

    /**
     * @notice 构造函数，初始化状态变量。
     * @param _name 初始化的公共变量值。
     */
    constructor (uint256 _name) { // 明确类型 uint256
        publicName = _name;
        privateClock = 123;
    }

    /**
     * @notice 一个可被子合约重写的函数，使用 public 确保外部和继承合约都能访问。
     * 必须使用 virtual 关键字标记为可重写。
     * @return 计算结果。
     */
    function calculateData() public view virtual returns (uint256) { // 函数名使用小驼峰命名法
        // external 函数无法直接被本合约内部的其他函数调用，改为 public
        uint256 a = publicName + privateClock;
        return a;
    }

    /**
     * @notice 内部函数，只能在合约内部或继承合约中调用。
     * @return 一个常量值。
     */
    function getConstantValue() internal pure returns (uint256) {
        return 789;
    }
}

// 子类 B 继承 A
contract ContractB is ContractA {
    /**
     * @notice 子类构造函数，调用父类构造函数。
     * @param _name 传递给父类 ContractA 的参数。
     */
    constructor(uint256 _name) ContractA(_name) {} // 调用父类构造函数

    /**
     * @notice 重写父类 ContractA.calculateData 函数。
     * 必须使用 override 关键字，且函数签名（名称、参数、返回类型）必须一致。
     */
    function calculateData() public pure virtual override returns (uint256) {
        uint256 a = 456;
        return a;
    }
}

// 子类 C 继承 A 和 B (多重继承)
// 注意：继承顺序很重要，状态变量的存储槽位由继承顺序决定（从右到左）
contract ContractC is ContractA, ContractB {
    uint256 public extraValue;

    /**
     * @notice 子类构造函数，遵循 C3 线性化规则，从右到左调用直接父类。
     * 此处只需调用 B 的构造函数，B 会负责调用 A 的构造函数。
     */
    constructor(uint256 _name, uint256 _extra) ContractB(_name) {
        extraValue = _extra;
    }

    /**
     * @notice 重写继承链中的函数。
     * 由于 ContractA 和 ContractB 都实现了 calculateData，因此必须显式声明 override(ContractA, ContractB)。
     */
    function calculateData() public pure override(ContractA, ContractB) returns (uint256) {
        // 可以通过 super 关键字调用继承链上层的函数实现
        // super.getConstantValue(); // 示例调用父类内部函数
        uint256 a = getConstantValue() + 10101; // 内部函数可以直接调用
        return a;
    }
}