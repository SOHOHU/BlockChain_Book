// 指定Solidity编译器版本为0.5.0或更高版本
// ^0.5.0 表示兼容0.5.0到0.6.0（不包括0.6.0）的所有版本
pragma solidity ^0.5.0;

// 导入OpenZeppelin的ERC20标准接口
// IERC20是ERC20代币的标准接口，定义了transfer、approve等基本函数
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//
// 1inch协议架构图 - 展示合约调用关系
// 这个ASCII图展示了1inch协议的核心架构设计
//  [ msg.sender ]                    // 用户调用者
//       | |
//       | |
//       \_/
// +---------------+ ________________________________
// | OneSplitAudit | _______________________________  \    // 主审计合约，处理实际交换
// +---------------+                                 \ \
//       | |                      ______________      | | (staticcall)  // 静态调用，不修改状态
//       | |                    /  ____________  \    | |
//       | | (call)            / /              \ \   | |               // 普通调用，可修改状态
//       | |                  / /               | |   | |
//       \_/                  | |               \_/   \_/
// +--------------+           | |           +----------------------+
// | OneSplitWrap |           | |           |   OneSplitViewWrap   |  // 包装合约，提供统一接口
// +--------------+           | |           +----------------------+
//       | |                  | |                     | |
//       | | (delegatecall)   | | (staticcall)        | | (staticcall)  // 委托调用，在调用者上下文中执行
//       \_/                  | |                     \_/
// +--------------+           | |             +------------------+
// |   OneSplit   |           | |             |   OneSplitView   |  // 核心实现合约
// +--------------+           | |             +------------------+
//       | |                  / /
//        \ \________________/ /
//         \__________________/
//


// 1inch协议常量定义合约
// 这个合约定义了所有用于控制DEX选择的标志位常量
// 使用位运算来组合多个标志，实现灵活的DEX选择控制
contract IOneSplitConsts {
    // 标志位组合示例：flags = FLAG_DISABLE_UNISWAP + FLAG_DISABLE_BANCOR + ...
    // 通过位运算OR操作来组合多个标志位
    
    // === 基础DEX禁用标志 ===
    // 禁用Uniswap V1 - 0x01 = 1 (二进制: 00000001)
    // 这是最基础的DEX，通常作为默认选择
    uint256 internal constant FLAG_DISABLE_UNISWAP = 0x01;
    
    // 已废弃的Kyber禁用标志 - 0x02 = 2 (二进制: 00000010)
    // Kyber协议已被弃用，此标志保留用于向后兼容
    uint256 internal constant DEPRECATED_FLAG_DISABLE_KYBER = 0x02; // Deprecated
    
    // 禁用Bancor协议 - 0x04 = 4 (二进制: 00000100)
    // Bancor是早期AMM协议，使用Bancor公式进行定价
    uint256 internal constant FLAG_DISABLE_BANCOR = 0x04;
    
    // 禁用Oasis协议 - 0x08 = 8 (二进制: 00001000)
    // Oasis是MakerDAO的DEX，主要用于DAI交易
    uint256 internal constant FLAG_DISABLE_OASIS = 0x08;
    
    // 禁用Compound协议 - 0x10 = 16 (二进制: 00010000)
    // Compound是借贷协议，其cToken可以用于交易
    uint256 internal constant FLAG_DISABLE_COMPOUND = 0x10;
    
    // 禁用Fulcrum协议 - 0x20 = 32 (二进制: 00100000)
    // Fulcrum是杠杆交易协议，其iToken可以用于交易
    uint256 internal constant FLAG_DISABLE_FULCRUM = 0x20;
    
    // 禁用Chai协议 - 0x40 = 64 (二进制: 01000000)
    // Chai是DAI的收益代币，通过质押DAI获得收益
    uint256 internal constant FLAG_DISABLE_CHAI = 0x40;
    
    // 禁用Aave协议 - 0x80 = 128 (二进制: 10000000)
    // Aave是借贷协议，其aToken可以用于交易
    uint256 internal constant FLAG_DISABLE_AAVE = 0x80;
    
    // 禁用SmartToken协议 - 0x100 = 256 (二进制: 100000000)
    // SmartToken是Bancor的智能代币系统
    uint256 internal constant FLAG_DISABLE_SMART_TOKEN = 0x100;
    
    // 已废弃的多路径ETH标志 - 0x200 = 512
    // 此功能已被弃用，默认关闭
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_ETH = 0x200; // Deprecated, Turned off by default
    
    // 禁用BDAI协议 - 0x400 = 1024
    // BDAI是Bancor的DAI代币
    uint256 internal constant FLAG_DISABLE_BDAI = 0x400;
    
    // 禁用iEarn协议 - 0x800 = 2048
    // iEarn是收益聚合协议
    uint256 internal constant FLAG_DISABLE_IEARN = 0x800;
    
    // === Curve协议相关标志 ===
    // 禁用Curve Compound池 - 0x1000 = 4096
    // Curve是稳定币交换协议，专门用于稳定币交易
    uint256 internal constant FLAG_DISABLE_CURVE_COMPOUND = 0x1000;
    
    // 禁用Curve USDT池 - 0x2000 = 8192
    uint256 internal constant FLAG_DISABLE_CURVE_USDT = 0x2000;
    
    // 禁用Curve Y池 - 0x4000 = 16384
    // Y池是Yearn Finance的稳定币池
    uint256 internal constant FLAG_DISABLE_CURVE_Y = 0x4000;
    
    // 禁用Curve Binance池 - 0x8000 = 32768
    // Binance池是币安的稳定币池
    uint256 internal constant FLAG_DISABLE_CURVE_BINANCE = 0x8000;
    // 已废弃的多路径DAI标志 - 0x10000 = 65536
    // 此功能已被弃用，默认关闭
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_DAI = 0x10000; // Deprecated, Turned off by default
    
    // 已废弃的多路径USDC标志 - 0x20000 = 131072
    // 此功能已被弃用，默认关闭
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_USDC = 0x20000; // Deprecated, Turned off by default
    
    // 禁用Curve Synthetix池 - 0x40000 = 262144
    // Synthetix是合成资产协议，其sToken可以用于交易
    uint256 internal constant FLAG_DISABLE_CURVE_SYNTHETIX = 0x40000;
    
    // 禁用WETH包装 - 0x80000 = 524288
    // WETH是以太坊的包装代币，用于ETH与其他代币的交换
    uint256 internal constant FLAG_DISABLE_WETH = 0x80000;
    
    // === Uniswap集成相关标志 ===
    // 禁用Uniswap Compound集成 - 0x100000 = 1048576
    // 仅在资产之一是ETH时有效，用于ETH与cToken的交换
    uint256 internal constant FLAG_DISABLE_UNISWAP_COMPOUND = 0x100000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
    
    // 禁用Uniswap Chai集成 - 0x200000 = 2097152
    // 仅在ETH<>DAI交换时有效，用于ETH与Chai的交换
    uint256 internal constant FLAG_DISABLE_UNISWAP_CHAI = 0x200000; // Works only when ETH<>DAI or FLAG_ENABLE_MULTI_PATH_ETH
    
    // 禁用Uniswap Aave集成 - 0x400000 = 4194304
    // 仅在资产之一是ETH时有效，用于ETH与aToken的交换
    uint256 internal constant FLAG_DISABLE_UNISWAP_AAVE = 0x400000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
    
    // 禁用Idle协议 - 0x800000 = 8388608
    // Idle是收益聚合协议，其idleToken可以用于交易
    uint256 internal constant FLAG_DISABLE_IDLE = 0x800000;
    
    // 禁用Mooniswap协议 - 0x1000000 = 16777216
    // Mooniswap是1inch团队开发的AMM协议，使用虚拟余额机制
    uint256 internal constant FLAG_DISABLE_MOONISWAP = 0x1000000;
    
    // === Uniswap V2相关标志 ===
    // 禁用Uniswap V2 - 0x2000000 = 33554432
    // Uniswap V2是第二代AMM协议，支持ERC20/ERC20交易对
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2 = 0x2000000;
    
    // 禁用Uniswap V2 ETH池 - 0x4000000 = 67108864
    // 专门用于ETH相关的交易对
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_ETH = 0x4000000;
    
    // 禁用Uniswap V2 DAI池 - 0x8000000 = 134217728
    // 专门用于DAI相关的交易对
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_DAI = 0x8000000;
    
    // 禁用Uniswap V2 USDC池 - 0x10000000 = 268435456
    // 专门用于USDC相关的交易对
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_USDC = 0x10000000;
    
    // === 全局禁用标志 ===
    // 禁用所有分割源 - 0x20000000 = 536870912
    // 禁用所有用于分割交易的DEX源
    uint256 internal constant FLAG_DISABLE_ALL_SPLIT_SOURCES = 0x20000000;
    
    // 禁用所有包装源 - 0x40000000 = 1073741824
    // 禁用所有用于包装交易的协议源
    uint256 internal constant FLAG_DISABLE_ALL_WRAP_SOURCES = 0x40000000;
    // === 更多Curve池相关标志 ===
    // 禁用Curve PAX池 - 0x80000000 = 2147483648
    // PAX是Paxos发行的稳定币
    uint256 internal constant FLAG_DISABLE_CURVE_PAX = 0x80000000;
    
    // 禁用Curve renBTC池 - 0x100000000 = 4294967296
    // renBTC是Ren协议发行的比特币代币
    uint256 internal constant FLAG_DISABLE_CURVE_RENBTC = 0x100000000;
    
    // 禁用Curve tBTC池 - 0x200000000 = 8589934592
    // tBTC是Keep Network发行的比特币代币
    uint256 internal constant FLAG_DISABLE_CURVE_TBTC = 0x200000000;
    
    // 已废弃的多路径USDT标志 - 0x400000000 = 17179869184
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_USDT = 0x400000000; // Deprecated, Turned off by default
    
    // 已废弃的多路径WBTC标志 - 0x800000000 = 34359738368
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_WBTC = 0x800000000; // Deprecated, Turned off by default
    
    // 已废弃的多路径TBTC标志 - 0x1000000000 = 68719476736
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_TBTC = 0x1000000000; // Deprecated, Turned off by default
    
    // 已废弃的多路径renBTC标志 - 0x2000000000 = 137438953472
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_RENBTC = 0x2000000000; // Deprecated, Turned off by default
    
    // === 其他协议标志 ===
    // 禁用DForce Swap - 0x4000000000 = 274877906944
    // DForce是DeFi协议聚合器
    uint256 internal constant FLAG_DISABLE_DFORCE_SWAP = 0x4000000000;
    
    // 禁用Shell协议 - 0x8000000000 = 549755813888
    // Shell是Shell Protocol的AMM协议
    uint256 internal constant FLAG_DISABLE_SHELL = 0x8000000000;
    
    // === 功能标志 ===
    // 启用CHI代币燃烧 - 0x10000000000 = 1099511627776
    // CHI是1inch的治理代币，燃烧可以节省gas费用
    uint256 internal constant FLAG_ENABLE_CHI_BURN = 0x10000000000;
    
    // 禁用mStable mUSD池 - 0x20000000000 = 2199023255552
    // mStable是稳定币聚合协议
    uint256 internal constant FLAG_DISABLE_MSTABLE_MUSD = 0x20000000000;
    
    // 禁用Curve sBTC池 - 0x40000000000 = 4398046511104
    // sBTC是Synthetix的合成比特币
    uint256 internal constant FLAG_DISABLE_CURVE_SBTC = 0x40000000000;
    
    // 禁用DMM协议 - 0x80000000000 = 8796093022208
    // DMM是Kyber的DMM协议
    uint256 internal constant FLAG_DISABLE_DMM = 0x80000000000;
    
    // === 全局协议禁用标志 ===
    // 禁用所有Uniswap V1 - 0x100000000000 = 17592186044416
    uint256 internal constant FLAG_DISABLE_UNISWAP_ALL = 0x100000000000;
    
    // 禁用所有Curve池 - 0x200000000000 = 35184372088832
    uint256 internal constant FLAG_DISABLE_CURVE_ALL = 0x200000000000;
    
    // 禁用所有Uniswap V2 - 0x400000000000 = 70368744177664
    uint256 internal constant FLAG_DISABLE_UNISWAP_V2_ALL = 0x400000000000;
    
    // 禁用分割重新计算 - 0x800000000000 = 140737488355328
    // 禁用分割算法的重新计算功能
    uint256 internal constant FLAG_DISABLE_SPLIT_RECALCULATION = 0x800000000000;
    
    // === Balancer协议相关标志 ===
    // 禁用所有Balancer池 - 0x1000000000000 = 281474976710656
    // Balancer是多代币AMM协议
    uint256 internal constant FLAG_DISABLE_BALANCER_ALL = 0x1000000000000;
    
    // 禁用Balancer第1个池 - 0x2000000000000 = 562949953421312
    uint256 internal constant FLAG_DISABLE_BALANCER_1 = 0x2000000000000;
    
    // 禁用Balancer第2个池 - 0x4000000000000 = 1125899906842624
    uint256 internal constant FLAG_DISABLE_BALANCER_2 = 0x4000000000000;
    
    // 禁用Balancer第3个池 - 0x8000000000000 = 2251799813685248
    uint256 internal constant FLAG_DISABLE_BALANCER_3 = 0x8000000000000;
    // === 已废弃的Kyber集成标志 ===
    // 已废弃的Kyber Uniswap储备 - 0x10000000000000 = 4503599627370496
    uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_UNISWAP_RESERVE = 0x10000000000000; // Deprecated, Turned off by default
    
    // 已废弃的Kyber Oasis储备 - 0x20000000000000 = 9007199254740992
    uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_OASIS_RESERVE = 0x20000000000000; // Deprecated, Turned off by default
    
    // 已废弃的Kyber Bancor储备 - 0x40000000000000 = 18014398509481984
    uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_BANCOR_RESERVE = 0x40000000000000; // Deprecated, Turned off by default
    
    // === 高级功能标志 ===
    // 启用推荐gas赞助 - 0x80000000000000 = 36028797018963968
    // 允许推荐人支付gas费用，默认关闭
    uint256 internal constant FLAG_ENABLE_REFERRAL_GAS_SPONSORSHIP = 0x80000000000000; // Turned off by default
    
    // 已废弃的多路径Compound标志 - 0x100000000000000 = 72057594037927936
    uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_COMP = 0x100000000000000; // Deprecated, Turned off by default
    
    // === Kyber协议相关标志 ===
    // 禁用所有Kyber - 0x200000000000000 = 144115188075855872
    uint256 internal constant FLAG_DISABLE_KYBER_ALL = 0x200000000000000;
    
    // 禁用Kyber第1个储备 - 0x400000000000000 = 288230376151711744
    uint256 internal constant FLAG_DISABLE_KYBER_1 = 0x400000000000000;
    
    // 禁用Kyber第2个储备 - 0x800000000000000 = 576460752303423488
    uint256 internal constant FLAG_DISABLE_KYBER_2 = 0x800000000000000;
    
    // 禁用Kyber第3个储备 - 0x1000000000000000 = 1152921504606846976
    uint256 internal constant FLAG_DISABLE_KYBER_3 = 0x1000000000000000;
    
    // 禁用Kyber第4个储备 - 0x2000000000000000 = 2305843009213693952
    uint256 internal constant FLAG_DISABLE_KYBER_4 = 0x2000000000000000;
    
    // === 高级功能标志 ===
    // 启用CHI代币燃烧（按交易发起者） - 0x4000000000000000 = 4611686018427387904
    // 从交易发起者地址燃烧CHI代币，而不是调用者地址
    uint256 internal constant FLAG_ENABLE_CHI_BURN_BY_ORIGIN = 0x4000000000000000;
    
    // === Mooniswap协议相关标志 ===
    // 禁用所有Mooniswap - 0x8000000000000000 = 9223372036854775808
    uint256 internal constant FLAG_DISABLE_MOONISWAP_ALL = 0x8000000000000000;
    
    // 禁用Mooniswap ETH池 - 0x10000000000000000 = 18446744073709551616
    uint256 internal constant FLAG_DISABLE_MOONISWAP_ETH = 0x10000000000000000;
    
    // 禁用Mooniswap DAI池 - 0x20000000000000000 = 36893488147419103232
    uint256 internal constant FLAG_DISABLE_MOONISWAP_DAI = 0x20000000000000000;
    
    // 禁用Mooniswap USDC池 - 0x40000000000000000 = 73786976294838206464
    uint256 internal constant FLAG_DISABLE_MOONISWAP_USDC = 0x40000000000000000;
    
    // 禁用Mooniswap池代币 - 0x80000000000000000 = 147573952589676412928
    uint256 internal constant FLAG_DISABLE_MOONISWAP_POOL_TOKEN = 0x80000000000000000;
}


// 1inch协议主接口合约
// 继承IOneSplitConsts，获得所有标志位常量
// 定义了1inch协议的核心功能接口
contract IOneSplit is IOneSplitConsts {
    
    // 获取预期返回金额函数
    // 这是1inch协议的核心查询函数，用于计算最优交易路径
    function getExpectedReturn(
        IERC20 fromToken,        // 源代币地址，使用address(0)表示ETH
        IERC20 destToken,        // 目标代币地址，使用address(0)表示ETH
        uint256 amount,          // 源代币数量
        uint256 parts,           // 分割数量，用于优化gas使用，建议在链下调用
        uint256 flags            // 标志位，控制哪些DEX被启用/禁用
    )
        public                  // 公共函数，任何人都可以调用
        view                    // 视图函数，不修改状态，不消耗gas
        returns(
            uint256 returnAmount,           // 预期返回的目标代币数量
            uint256[] memory distribution   // 分布数组，表示每个DEX的权重分配
        );

    // 考虑gas费用的预期返回金额函数
    // 在getExpectedReturn基础上，考虑gas费用对最终收益的影响
    function getExpectedReturnWithGas(
        IERC20 fromToken,                    // 源代币地址
        IERC20 destToken,                    // 目标代币地址
        uint256 amount,                      // 源代币数量
        uint256 parts,                       // 分割数量
        uint256 flags,                       // 标志位
        uint256 destTokenEthPriceTimesGasPrice  // 目标代币ETH价格 × gas价格，用于计算gas成本
    )
        public
        view
        returns(
            uint256 returnAmount,           // 考虑gas费用后的预期返回金额
            uint256 estimateGasAmount,       // 预估的gas消耗量
            uint256[] memory distribution   // 分布数组
        );

    // 执行代币交换函数
    // 这是1inch协议的核心执行函数，实际执行代币交换
    function swap(
        IERC20 fromToken,        // 源代币地址
        IERC20 destToken,        // 目标代币地址
        uint256 amount,          // 源代币数量
        uint256 minReturn,       // 最小返回金额，防止滑点过大
        uint256[] memory distribution,  // 分布数组，由getExpectedReturn返回
        uint256 flags            // 标志位，必须与getExpectedReturn使用相同的flags
    )
        public                  // 公共函数
        payable                 // 可接收ETH的函数
        returns(uint256 returnAmount);  // 实际返回的目标代币数量
}


// 1inch多路径交换接口合约
// 继承IOneSplit，扩展支持多步骤交换功能
// 允许通过多个中间代币进行复杂的交换路径
contract IOneSplitMulti is IOneSplit {
    
    // 多路径预期返回金额函数（考虑gas费用）
    // 支持通过多个代币的交换路径，如：TokenA -> TokenB -> TokenC
    function getExpectedReturnWithGasMulti(
        IERC20[] memory tokens,              // 代币路径数组，如[TokenA, TokenB, TokenC]
        uint256 amount,                      // 起始代币数量
        uint256[] memory parts,              // 每个步骤的分割数量数组
        uint256[] memory flags,              // 每个步骤的标志位数组
        uint256[] memory destTokenEthPriceTimesGasPrices  // 每个步骤的gas价格数组
    )
        public
        view
        returns(
            uint256[] memory returnAmounts,  // 每个步骤的返回金额数组
            uint256 estimateGasAmount,        // 总预估gas消耗
            uint256[] memory distribution    // 分布数组
        );

    // 多路径代币交换函数
    // 执行多步骤的代币交换，如：TokenA -> TokenB -> TokenC
    function swapMulti(
        IERC20[] memory tokens,              // 代币路径数组
        uint256 amount,                      // 起始代币数量
        uint256 minReturn,                   // 最终最小返回金额
        uint256[] memory distribution,       // 分布数组
        uint256[] memory flags              // 标志位数组
    )
        public
        payable
        returns(uint256 returnAmount);       // 最终返回的目标代币数量
}
