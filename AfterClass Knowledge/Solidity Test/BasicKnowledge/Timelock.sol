// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title TimeLockController
 * @notice 实现了交易时间锁机制，只有在最小延迟和最大延迟之间才能执行交易。
 */
contract TimeLockController { // 规范化合约名
    // ===============================================
    // 事件 (Events)
    // ===============================================
    event Queue(bytes32 indexed operationId, uint256 eta);
    event Execute(bytes32 indexed operationId, uint256 eta);

    // ===============================================
    // 常量与状态变量
    // ===============================================
    // 操作 ID => 是否在队列中
    mapping (bytes32 => bool) public queuedTransactions;
    
    // 合约管理员地址，使用 immutable 节省 Gas
    address private immutable contractAdmin; 
    
    // 常量：时间延迟，使用 SCREAMING_SNAKE_CASE
    uint256 public constant MIN_DELAY = 10; // 最小延迟时间（秒）
    uint256 public constant MAX_DELAY = 60 * 60 * 24 * 30; // 最大延迟时间（秒），约 30 天

    // ===============================================
    // 构造函数和访问控制
    // ===============================================
    
    /**
     * @notice 构造函数，设置合约管理员。
     */
    constructor() {
        contractAdmin = msg.sender;
    }

    /**
     * @notice 限制只有合约管理员才能调用。
     */
    modifier onlyOwner() {
        require(msg.sender == contractAdmin, "TimeLockController: Not admin");
        _;
    }

    // ===============================================
    // 核心功能 (Core Functions)
    // ===============================================

    /**
     * @notice 根据交易参数计算操作的唯一 ID (哈希)。
     * @dev 使用 abi.encode 确保哈希的唯一性和防碰撞。
     */
    function getOperationId( // 规范化函数名
        address _target,
        uint256 _value,
        string calldata _signature, // 交易签名/函数标识
        bytes calldata _data,
        uint256 _eta
    ) 
        public 
        pure 
        returns (bytes32) 
    {
        return keccak256(abi.encode(_target, _value, _signature, _data, _eta));
    }

    /**
     * @notice 将一笔交易放入时间锁队列。
     * @param _eta 预期的执行时间戳。
     */
    function queueTransaction( // 规范化函数名
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _data,
        uint256 _eta
    ) 
        external 
        onlyOwner 
    {
        bytes32 operationId = getOperationId(_target, _value, _signature, _data, _eta);
        
        require(!queuedTransactions[operationId], "TimeLockController: already queued");
        
        // 检查执行时间是否在 [当前时间 + 最小延迟, 当前时间 + 最大延迟] 范围内
        require(
            _eta > block.timestamp + MIN_DELAY && _eta < block.timestamp + MAX_DELAY, 
            "TimeLockController: invalid ETA (must be in [MIN_DELAY, MAX_DELAY])"
        );
        
        queuedTransactions[operationId] = true;
        emit Queue(operationId, _eta);
    }

    /**
     * @notice 执行一笔已在队列中且时间已到的交易。
     */
    function executeTransaction( // 规范化函数名
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _data,
        uint256 _eta
    ) 
        external 
        onlyOwner 
        returns (bytes memory result) 
    {
        bytes32 operationId = getOperationId(_target, _value, _signature, _data, _eta);
        
        require(queuedTransactions[operationId], "TimeLockController: not queued");
        // 检查当前时间是否已到达预定时间
        require(block.timestamp >= _eta, "TimeLockController: execution time not reached");

        queuedTransactions[operationId] = false;
        
        // 执行交易，将 ETH 和 calldata 转发给目标地址
        (bool success, bytes memory res) = _target.call{value: _value}(_data);
        require(success, "TimeLockController: transaction execution failed");
        
        emit Execute(operationId, _eta);
        return res;
    }

    /**
     * @notice 从队列中取消一笔交易。
     * @param _operationId 要取消的交易的操作 ID。
     */
    function cancelTransaction(bytes32 _operationId) external onlyOwner { // 规范化函数名
        require(queuedTransactions[_operationId], "TimeLockController: not queued");
        queuedTransactions[_operationId] = false;
    }
}