// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/**
 * @title MultiSigWallet
 * @notice 一个多重签名钱包，需要达到 minimumRequired 个所有者批准才能执行交易。
 */
contract MultiSigWallet { // 规范化合约名
    // ===============================================
    // 事件 (Events)
    // ===============================================
    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId);
    event Approve(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);


    // ===============================================
    // 结构体 (Structs)
    // ===============================================
    /**
     * @notice 存储交易详情的结构体。
     */
    struct Transaction { // 规范化结构体名
        address to;        // 目标地址
        uint256 value;     // 随交易发送的 ETH 数量 (Wei)
        bytes data;        // 要执行的函数调用数据 (calldata)
        bool executed;     // 交易是否已执行
    }


    // ===============================================
    // 状态变量 (State Variables)
    // ===============================================
    uint256 public requiredConfirmations; // 批准交易所需的最低所有者数量
    address[] public owners;              // 所有者地址列表
    Transaction[] public transactions;    // 所有待处理和已处理的交易列表
    // 交易ID => 所有者地址 => 是否已批准
    mapping(uint256 => mapping(address => bool)) public isApproved;
    // 所有者地址 => 是否为所有者 (快速查找，使用 private 保护)
    mapping(address => bool) private isOwner; 


    // ===============================================
    // 修饰符 (Modifiers)
    // ===============================================

    /**
     * @notice 限制只有钱包所有者才能调用。
     */
    modifier onlyOwner() {
        require(isOwner[msg.sender], "MultiSigWallet: Not an owner");
        _;
    }

    /**
     * @notice 检查交易 ID 是否存在。
     */
    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "MultiSigWallet: Transaction does not exist");
        _;
    }

    /**
     * @notice 检查交易是否尚未执行。
     */
    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "MultiSigWallet: Transaction already executed");
        _;
    }

    // ===============================================
    // 构造函数 (Constructor)
    // ===============================================

    /**
     * @notice 构造函数，初始化钱包所有者和所需批准数量。
     * @param _owners 初始所有者地址数组。
     * @param _required 所需的最小批准数量。
     */
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "MultiSigWallet: Owners required");
        require(_owners.length >= _required && _required > 0, "MultiSigWallet: Invalid required count");

        for(uint256 i = 0; i < _owners.length; i++)
        {
            address _owner = _owners[i];
            require(_owner != address(0), "MultiSigWallet: Invalid owner address");
            require(!isOwner[_owner], "MultiSigWallet: Duplicate owner");

            isOwner[_owner] = true;
            owners.push(_owner);
        }

        requiredConfirmations = _required;
    }

    // ===============================================
    // 核心功能 (Core Functions)
    // ===============================================

    /**
     * @notice 允许任何人向多签钱包存入 ETH。
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice 提交一个新的交易到队列。
     * @param _to 交易的目标地址。
     * @param _value 随交易发送的 ETH 数量 (Wei)。
     * @param _data 要调用的函数 calldata。
     */
    function submitTransaction(address _to, uint256 _value, bytes calldata _data) 
        external 
        onlyOwner 
    {
        // 明确使用 Transaction 结构体名称
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        emit Submit(transactions.length - 1);
    }

    /**
     * @notice 批准一个待执行的交易。
     * @param _txId 交易的唯一 ID。
     */
    function approveTransaction(uint256 _txId) 
        external 
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId) 
    {
        require(!isApproved[_txId][msg.sender], "MultiSigWallet: Already approved"); // 检查是否已批准

        isApproved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    /**
     * @notice 计算当前交易的批准数量。
     */
    function _getApprovalCount(uint256 _txId) internal view returns (uint256 count) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (isApproved[_txId][owners[i]]) {
                count++ ;
            }
        }
    }

    /**
     * @notice 执行一个已达到所需批准数量的交易。
     * 任何人都可以调用执行函数。
     * @param _txId 交易的唯一 ID。
     */
    function executeTransaction(uint256 _txId) 
        external 
        txExists(_txId) 
        notExecuted(_txId) 
    {
        // 检查批准数量是否足够
        require(_getApprovalCount(_txId) >= requiredConfirmations, "MultiSigWallet: Not enough approvals");
        
        // 使用 storage 引用，节省 Gas
        Transaction storage transactionToExecute = transactions[_txId];

        transactionToExecute.executed = true;
        
        // 低级 call 执行，将 ETH 和 calldata 转发给目标地址
        (bool success, ) = transactionToExecute.to.call{value: transactionToExecute.value}(transactionToExecute.data); 
        require(success, "MultiSigWallet: Transaction execution failed");
        
        emit Execute(_txId);
    }
}