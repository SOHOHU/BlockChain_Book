// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IERC20
 * @notice 必需由任何 ERC-20 代币合约实现的标准接口。
 * 使用接口名 IERC20 (Interface + 契约名) 是行业标准。
 */
interface IERC20 {
    // ==================
    // 事件
    // ==================
    /**
     * @notice 当代币发生转移时必须触发。
     * @param from 资金来源地址。
     * @param to 资金目标地址。
     * @param value 转移的代币数量。
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice 当 allowance 被设置时必须触发。
     * @param owner 授权人地址。
     * @param spender 被授权花费的地址。
     * @param value 新的授权额度。
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);


    // ==================
    // 状态查询函数 (View Functions)
    // ==================
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);


    // ==================
    // 状态修改函数 (State-Modifying Functions)
    // ==================
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract MyERC20Token is IERC20 { // 规范化合约名
    // 状态变量
    uint256 public override totalSupply; // 必须使用 override 关键字
    // address => balance
    mapping (address => uint256) public override balanceOf;
    // owner => spender => allowance
    mapping (address => mapping (address => uint256)) public override allowance;

    string public name = "HSQ Coin";
    string public symbol = "HC";
    uint8 public decimals = 18;

    // 构造函数：铸造初始代币给部署者
    constructor (uint256 initialSupply) {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    // 实现接口函数
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        // 检查：确保发送者有足够的余额
        require(balanceOf[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");

        // 状态更新
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }


    function approve(address spender, uint256 amount) external override returns (bool) {
        // 推荐：避免 0 检查，因为 ERC-20 标准没有要求
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount
    ) 
        external 
        override 
        returns (bool) 
    {
        // 检查：确保授权额度足够
        uint256 currentAllowance = allowance[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        // 检查：确保发送者有足够的余额
        require(balanceOf[sender] >= amount, "ERC20: transfer amount exceeds balance");

        // 状态更新
        // 0.8+ 版本默认防溢出/下溢，但最好知道发生了什么：
        // 扣除授权额度（对于一次性授权，推荐将 allowance 设置为 0）
        allowance[sender][msg.sender] = currentAllowance - amount; 
        // 扣除发送者余额
        balanceOf[sender] -= amount;
        // 增加接收者余额
        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }
}