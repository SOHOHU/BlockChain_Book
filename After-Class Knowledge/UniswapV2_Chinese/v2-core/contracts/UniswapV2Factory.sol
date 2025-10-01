// 指定这段代码只允许 0.5.16 版本编译。
pragma solidity = 0.5.16;

// 引入一个名为 IUniswapV2Factory 的接口合约
// 引入 UniswapV2Pair 合约，这个合约是用来创建交易对的
import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

// Factory三大作用：创建交易对，管理交易对，设置手续费
// 声明合约，调用接口IUniswapV2Factory
contract UniswapV2Factory is IUniswapV2Factory {
/*----------------------------------------------------------------基本变量声明----------------------------------------------------------------------------------------------------------------*/
    // 收取手续费的地址，
    // 关键字解析：
    // 1、public：由于Solidity默认变量是私有的，想要外部访问变量需要将合约声明为public（本质上是编写了一个getter函数）
    // 2、address：类型，即地址
    address public feeTo;
    // 设置feeTo的权限者地址
    // 功能解析：这是常用的地址管理手段，只有特定权限的人可以修改手续费地址（public是可以看，没有修改权限）
    address public feeToSetter;
    // 两种token对应的交易对地址
    // 关键字解析：mapping，同java中的hashmap。语法为mapping(KeyType => ValueType)
    /* 功能解析：从左到右的三个address分别理解为：tokenA的地址，tokenB的地址，tokenA和tokenB交易对的地址
                即：mapping(tokenA的地址 => mapping(tokenB的地址 => tokenA和tokenB交易对的地址))
                这是Solidity特有的语法，必须同时输入tokenA的地址和tokenB地址才可以索引到tokenA和tokenB交易对的地址
                同时忽略了顺序，无论传入的参数是 (tokenA, tokenB) 还是 (tokenB, tokenA)，代码都会先进行排序，然后查找到或存储到同一个位置
    */ 
    mapping(address => mapping(address => address)) public getPair;
    // 所有的交易对地址
    address[] public allPairs;
    // 定义交易对创建事件,返回参数tokenA地址,tokenB地址,pair地址,allPairs长度(第几个交易对)
    // 关键字解析：
    // 1、event：先对操作保存到日志，再于广播通。事件可以被外部应用接受，外部应用可通过监听该事件执行相应操作，事件名为PairCreated。
    // 2、indexed：用于声明事件中的变量，方便外部应用对事件操作时进行索引。
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

/*----------------------------------------------------------------函数声明----------------------------------------------------------------------------------------------------------------*/
    // 设置feeTo的权限者地址
    // 关键字解析：
    // constructor：构造函数在声明后只会在合约部署时自动执行一次，和C++构造函数同理
    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    // 所有交易对的数量
    // 关键字解析：
    // 1、external：表示这个函数只能被外部合约或账户调用，不能被本合约内部的其他函数调用
    // 2、表示这个函数不修改任何状态变量，只是读取数据。调用 view 函数是免费的，不需要消耗 Gas
    // 功能解析：
    // 外部合约随时可以调用函数allPairsLength，获得变量allPairs.length
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    /**
     * @dev: 创建tokenA和tokenB的交易对并获得pair地址
     * @param {address} tokenA:tokenA地址
     * @param {address} tokenB:tokenB地址
     * @return {address} 返回对应的pair地址
     */
    // 关键字解析：
    // 1、 require：用于验证外部输入或合约状态。当条件不满足时，它会回滚交易并退还剩余的 Gas。基本语法为require(bool condition, string memory reason)
    // 如果 condition 为 true，代码会继续执行。如果 condition 为 false，交易会立即回滚，并返回 reason 中的字符串。
    // 2、（）元组的利用：(address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA)，非常类似python中三元判断的写法，利用了元组，其拆解后如下
    /*
        address token0;
        address token1;

        if (tokenA < tokenB) {
            token0 = tokenA;
            token1 = tokenB;
        } else {
            token0 = tokenB;
            token1 = tokenA;
        }
    */
    //3、
    // 
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        // 判断两个token是否一样
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        // tokenA和tokenB中的谁的地址小，谁是token0，大的是token1
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        // 判断任一token是非0地址
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        // 判断是否已经有这两种token的交易对，确保交易对是非0地址
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS');
        // type(x).creationCode 获得包含x的合约的bytecode,是bytes类型(不能在合同本身或继承的合约中使用,因为会引起循环引用)
        // 关键字解析：
        // 1、bytes：字节数据类型，存放类似于c++的字节数组
        // 2、memory：声明变量为临时存储，变量在函数调用期间存在，并在函数执行结束后被销毁
        // 3. type(X)：系统调用，获得合约X的完整字节码
        // 4、creationCode：合约的创建字节码
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        // 两个地址是确定值，salt可以通过链下计算
        // 关键字解析：
        // 1、abi.encodePacked()：系统调用，将token0, token1按字节序列拼接
        // 2、keccak256()：SHA-3哈希加密函数，生成256为哈希值，因此32字节
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            // 内联汇编块，它允许开发者直接使用EVM的底层操作码（类似汇编语言），因为在 Solidity 0.5.16 版本中，create2 操作码还没有被作为内置函数提供
            // 关键字解析：
            // 1、create2：系统调用，用于生成新的交易对
            // 2、add(bytecode, 32): 汇编函数，将 bytecode 的起始地址偏移 32 字节。这是因为 Solidity 的 bytes 变量的第一个 32 字节存储的是数据的长度
            // 3、mload(bytecode): 汇编函数，从 bytecode 的起始地址加载数据，即获取 bytecode 的长度。
            // 4、:=运算符：汇编赋值语句
            // 功能解析：
            // 已知，create2(value, offset, size, salt)为交易对创建函数，接下来按照入EVM栈的顺序介绍变量
            // 1、salt：前面求出来的字面量，入栈
            // 2、size：mload(bytecode)自动执行，完成后将size推入栈中（栈底）
            // 3、offset：字节码的内存起始地址，由add(bytecode, 32)自动执行，完成后将offset推入栈中size：字节码的长度。由
            // 4、value：在这里写好的字面量，即0，入栈
            // 执行时与C语言执行函数类似，从栈中弹出前四个参数，可以保证顺序与声明一致
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        // 设置pair地址交易对的两种token
        // 功能解析：有非常巧妙的设计
        // 1、pair被强制转换为IUniswapV2Pair接口类型，并且调用接口initialize实现初始化
        // 2、由于接口无法使用构造函数（构造函数是在合约部署时自动执行的，你无法在部署之后再调用它），因此使用了initialize传递必要参数
        IUniswapV2Pair(pair).initialize(token0, token1);
        // 将token0和token1的交易对地址设置到mapping中(0和1的双向交易对)
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        // 推入交易对地址数组
        allPairs.push(pair);
        // 发送事件
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    // 设置收取手续费的地址
    // 关键字解析：msg.sender，是一个全局变量，表示当前调用此函数的账户地址
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    // 更改设置feeTo的权限者地址
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
