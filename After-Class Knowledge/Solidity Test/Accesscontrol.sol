// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract AccessControl { // 契约名使用大驼峰命名法
    // 事件：记录角色授予和撤销的行为
    event RoleGranted(bytes32 indexed role, address indexed account); // 移除下划线，使用大驼峰
    event RoleRevoked(bytes32 indexed role, address indexed account);

    // 状态变量：角色 => 地址 => 是否拥有该角色
    mapping(bytes32 => mapping(address => bool)) public roles;

    // 常量：角色哈希值。使用 abi.encode 而非 abi.encodePacked 以避免哈希碰撞的潜在风险。
    bytes32 public constant ADMIN_ROLE = keccak256(abi.encode("ADMIN")); // 常量名使用全大写加下划线
    bytes32 public constant USER_ROLE = keccak256(abi.encode("USER"));

    /**
     * @notice 检查调用者是否拥有指定角色的修饰符。
     * @param _role 要检查的角色哈希。
     */
    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "AccessControl: Caller is missing role"); // 更好的错误信息
        _; // 运行被修饰函数体的代码
    }

    // 构造函数：部署合约时，将 ADMIN_ROLE 授予部署者
    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice 内部函数：授予指定地址指定角色。
     * @param _role 要授予的角色哈希。
     * @param _account 接收角色的地址。
     */
    function _grantRole(bytes32 _role, address _account) internal {
        // 避免重复设置，节省 gas
        if (!roles[_role][_account]) {
            roles[_role][_account] = true;
            emit RoleGranted(_role, _account);
        }
    }

    /**
     * @notice 外部函数：授予指定地址指定角色。只有 ADMIN 角色可以调用。
     * @param _role 要授予的角色哈希。
     * @param _account 接收角色的地址。
     */
    function grantRole(bytes32 _role, address _account) external onlyRole(ADMIN_ROLE) {
        _grantRole(_role, _account); // 委托给内部函数实现，避免重复代码和事件
    }

    /**
     * @notice 内部函数：撤销指定地址指定角色。
     * @param _role 要撤销的角色哈希。
     * @param _account 被撤销角色的地址。
     */
    function _revokeRole(bytes32 _role, address _account) internal {
        if (roles[_role][_account]) {
            roles[_role][_account] = false;
            emit RoleRevoked(_role, _account);
        }
    }

    /**
     * @notice 外部函数：撤销指定地址指定角色。只有 ADMIN 角色可以调用。
     * @param _role 要撤销的角色哈希。
     * @param _account 被撤销角色的地址。
     */
    function revokeRole(bytes32 _role, address _account) external onlyRole(ADMIN_ROLE) {
        _revokeRole(_role, _account); // 委托给内部函数实现
    }
}