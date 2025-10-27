// 指定Solidity编译器版本为0.5.0或更高版本
pragma solidity ^0.5.0;

// === OpenZeppelin标准库导入 ===
// 安全数学运算库，防止整数溢出和下溢
import "@openzeppelin/contracts/math/SafeMath.sol";
// ERC20代币标准接口
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// === 各种DEX协议接口导入 ===
// Uniswap V1协议接口
import "./interface/IUniswapFactory.sol";

// Kyber Network协议接口
import "./interface/IKyberNetworkProxy.sol";
import "./interface/IKyberStorage.sol";
import "./interface/IKyberHintHandler.sol";

// Bancor协议接口
import "./interface/IBancorNetwork.sol";
import "./interface/IBancorContractRegistry.sol";
import "./interface/IBancorNetworkPathFinder.sol";
import "./interface/IBancorConverterRegistry.sol";
import "./interface/IBancorEtherToken.sol";
import "./interface/IBancorFinder.sol";

// Oasis协议接口
import "./interface/IOasisExchange.sol";

// WETH包装以太坊接口
import "./interface/IWETH.sol";

// Curve协议接口
import "./interface/ICurve.sol";

// 借贷协议接口
import "./interface/IChai.sol";
import "./interface/ICompound.sol";
import "./interface/ICompoundRegistry.sol";
import "./interface/IAaveToken.sol";
import "./interface/IAaveRegistry.sol";

// 其他AMM协议接口
import "./interface/IMooniswap.sol";
import "./interface/IUniswapV2Factory.sol";
import "./interface/IDForceSwap.sol";
import "./interface/IShell.sol";
import "./interface/IMStable.sol";
import "./interface/IBalancerRegistry.sol";

// === 1inch协议核心文件导入 ===
// 1inch协议接口定义
import "./IOneSplit.sol";
// ERC20代币统一处理库
import "./UniversalERC20.sol";
// Balancer协议集成库
import "./BalancerLib.sol";


// 1inch协议视图接口合约
// 继承IOneSplitConsts，获得所有标志位常量
// 定义只读查询功能的接口
contract IOneSplitView is IOneSplitConsts {
    // 获取预期返回金额函数
    // 用于查询最优交易路径，不执行实际交换
    function getExpectedReturn(
        IERC20 fromToken,        // 源代币地址
        IERC20 destToken,          // 目标代币地址
        uint256 amount,          // 源代币数量
        uint256 parts,           // 分割数量
        uint256 flags            // 标志位
    )
        public
        view
        returns(
            uint256 returnAmount,           // 预期返回金额
            uint256[] memory distribution   // 分布数组
        );

    // 考虑gas费用的预期返回金额函数
    // 在计算最优路径时考虑gas费用影响
    function getExpectedReturnWithGas(
        IERC20 fromToken,                    // 源代币地址
        IERC20 destToken,                    // 目标代币地址
        uint256 amount,                      // 源代币数量
        uint256 parts,                       // 分割数量
        uint256 flags,                       // 标志位
        uint256 destTokenEthPriceTimesGasPrice  // gas价格参数
    )
        public
        view
        returns(
            uint256 returnAmount,           // 预期返回金额
            uint256 estimateGasAmount,       // 预估gas消耗
            uint256[] memory distribution   // 分布数组
        );
}


// 标志位检查工具库
// 提供标志位检查的辅助函数
library DisableFlags {
    // 检查标志位是否被设置
    // 使用位运算AND操作检查特定标志位
    function check(uint256 flags, uint256 flag) internal pure returns(bool) {
        // 位运算AND：如果flags中包含flag，则返回true
        // 例如：flags=0x05, flag=0x01 -> 0x05 & 0x01 = 0x01 != 0 -> true
        return (flags & flag) != 0;
    }
}


// 1inch协议核心实现合约
// 继承IOneSplitView，实现所有核心功能
// 这是1inch协议的主要逻辑合约，包含所有DEX集成
contract OneSplitRoot is IOneSplitView {
    // === 库导入声明 ===
    // 为uint256类型添加SafeMath安全数学运算
    using SafeMath for uint256;
    // 为uint256类型添加标志位检查功能
    using DisableFlags for uint256;

    // 为IERC20类型添加UniversalERC20扩展功能
    using UniversalERC20 for IERC20;
    // 为IWETH类型添加UniversalERC20扩展功能
    using UniversalERC20 for IWETH;
    // 为IUniswapV2Exchange类型添加交换库功能
    using UniswapV2ExchangeLib for IUniswapV2Exchange;
    // 为IChai类型添加Chai辅助功能
    using ChaiHelper for IChai;

    // === 核心常量定义 ===
    // DEX数量常量：支持34个不同的DEX协议
    uint256 constant internal DEXES_COUNT = 34;
    
    // ETH地址常量：用于表示以太坊原生代币
    // 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE 是1inch协议中ETH的标准表示
    IERC20 constant internal ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    
    // 零地址常量：用于表示空地址
    IERC20 constant internal ZERO_ADDRESS = IERC20(0);

    // === 协议代币地址常量 ===
    // Bancor协议的ETH代币地址
    IBancorEtherToken constant internal bancorEtherToken = IBancorEtherToken(0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315);
    
    // WETH（Wrapped ETH）地址 - 以太坊主网标准WETH合约
    IWETH constant internal weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    // Chai代币地址 - DAI的收益代币
    IChai constant internal chai = IChai(0x06AF07097C9Eeb7fD685c692751D5C66dB49c215);
    
    // === 稳定币地址常量 ===
    // DAI - MakerDAO发行的去中心化稳定币
    IERC20 constant internal dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    
    // USDC - Circle发行的中心化稳定币
    IERC20 constant internal usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    
    // USDT - Tether发行的中心化稳定币
    IERC20 constant internal usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    
    // TUSD - TrustToken发行的稳定币
    IERC20 constant internal tusd = IERC20(0x0000000000085d4780B73119b644AE5ecd22b376);
    
    // BUSD - Binance发行的稳定币
    IERC20 constant internal busd = IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    
    // sUSD - Synthetix发行的合成美元
    IERC20 constant internal susd = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    
    // PAX - Paxos发行的稳定币
    IERC20 constant internal pax = IERC20(0x8E870D67F660D95d5be530380D0eC0bd388289E1);
    
    // === 比特币代币地址常量 ===
    // renBTC - Ren协议发行的比特币代币
    IERC20 constant internal renbtc = IERC20(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);
    
    // WBTC - Wrapped Bitcoin，最主流的比特币代币
    IERC20 constant internal wbtc = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    
    // tBTC - Keep Network发行的比特币代币
    IERC20 constant internal tbtc = IERC20(0x1bBE271d15Bb64dF0bc6CD28Df9Ff322F2eBD847);
    
    // hBTC - Huobi发行的比特币代币
    IERC20 constant internal hbtc = IERC20(0x0316EB71485b0Ab14103307bf65a021042c6d380);
    
    // sBTC - Synthetix发行的合成比特币
    IERC20 constant internal sbtc = IERC20(0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6);

    // === 协议合约地址常量 ===
    // Kyber Network协议合约地址
    IKyberNetworkProxy constant internal kyberNetworkProxy = IKyberNetworkProxy(0x9AAb3f75489902f3a48495025729a0AF77d4b11e);
    IKyberStorage constant internal kyberStorage = IKyberStorage(0xC8fb12402cB16970F3C5F4b48Ff68Eb9D1289301);
    IKyberHintHandler constant internal kyberHintHandler = IKyberHintHandler(0xa1C0Fa73c39CFBcC11ec9Eb1Afc665aba9996E2C);
    
    // Uniswap V1协议合约地址
    IUniswapFactory constant internal uniswapFactory = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    
    // Bancor协议合约地址
    IBancorContractRegistry constant internal bancorContractRegistry = IBancorContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
    IBancorNetworkPathFinder constant internal bancorNetworkPathFinder = IBancorNetworkPathFinder(0x6F0cD8C4f6F06eAB664C7E3031909452b4B72861);
    //IBancorConverterRegistry constant internal bancorConverterRegistry = IBancorConverterRegistry(0xf6E2D7F616B67E46D708e4410746E9AAb3a4C518);
    IBancorFinder constant internal bancorFinder = IBancorFinder(0x2B344e14dc2641D11D338C053C908c7A7D4c30B9);
    
    // Oasis协议合约地址
    IOasisExchange constant internal oasisExchange = IOasisExchange(0x794e6e91555438aFc3ccF1c5076A74F42133d08D);
    // === Curve协议合约地址 ===
    // Curve是专门用于稳定币交换的AMM协议
    ICurve constant internal curveCompound = ICurve(0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56);
    ICurve constant internal curveUSDT = ICurve(0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C);
    ICurve constant internal curveY = ICurve(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    ICurve constant internal curveBinance = ICurve(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27);
    ICurve constant internal curveSynthetix = ICurve(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);
    ICurve constant internal curvePAX = ICurve(0x06364f10B501e868329afBc005b3492902d6C763);
    ICurve constant internal curveRenBTC = ICurve(0x93054188d876f558f4a66B2EF1d97d16eDf0895B);
    ICurve constant internal curveTBTC = ICurve(0x9726e9314eF1b96E45f40056bEd61A088897313E);
    ICurve constant internal curveSBTC = ICurve(0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714);
    
    // === 其他AMM协议合约地址 ===
    // Shell协议合约地址
    IShell constant internal shell = IShell(0xA8253a440Be331dC4a7395B73948cCa6F19Dc97D);
    
    // === 借贷协议合约地址 ===
    // Aave借贷协议合约地址
    IAaveLendingPool constant internal aave = IAaveLendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);
    
    // Compound借贷协议合约地址
    ICompound constant internal compound = ICompound(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    ICompoundEther constant internal cETH = ICompoundEther(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
    
    // === 其他协议合约地址 ===
    // Mooniswap协议合约地址（1inch团队开发的AMM）
    IMooniswapRegistry constant internal mooniswapRegistry = IMooniswapRegistry(0x71CD6666064C3A1354a3B4dca5fA1E2D3ee7D303);
    
    // Uniswap V2协议合约地址
    IUniswapV2Factory constant internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    
    // DForce协议合约地址
    IDForceSwap constant internal dforceSwap = IDForceSwap(0x03eF3f37856bD08eb47E2dE7ABc4Ddd2c19B60F2);
    
    // mStable协议合约地址
    IMStable constant internal musd = IMStable(0xe2f2a5C287993345a840Db3B0845fbC70f5935a5);
    IMassetValidationHelper constant internal musd_helper = IMassetValidationHelper(0xaBcC93c3be238884cc3309C19Afd128fAfC16911);
    
    // Balancer协议合约地址
    IBalancerRegistry constant internal balancerRegistry = IBalancerRegistry(0x65e67cbc342712DF67494ACEfc06fe951EE93982);
    
    // === 辅助工具合约地址 ===
    // Curve计算器合约地址
    ICurveCalculator constant internal curveCalculator = ICurveCalculator(0xc1DB00a8E5Ef7bfa476395cdbcc98235477cDE4E);
    
    // Curve注册表合约地址
    ICurveRegistry constant internal curveRegistry = ICurveRegistry(0x7002B727Ef8F5571Cb5F9D70D13DBEEb4dFAe9d1);
    
    // Compound注册表合约地址
    ICompoundRegistry constant internal compoundRegistry = ICompoundRegistry(0xF451Dbd7Ba14BFa7B1B78A766D3Ed438F79EE1D1);
    
    // Aave注册表合约地址
    IAaveRegistry constant internal aaveRegistry = IAaveRegistry(0xEd8b133B7B88366E01Bb9E38305Ab11c26521494);
    
    // Balancer辅助工具合约地址
    IBalancerHelper constant internal balancerHelper = IBalancerHelper(0xA961672E8Db773be387e775bc4937C678F3ddF9a);

    // === 算法常量 ===
    // 极大负值常量，用于动态规划算法中的无效状态标记
    int256 internal constant VERY_NEGATIVE_VALUE = -1e72;

    // === 核心算法函数 ===
    // 最优分布算法：使用动态规划找到最佳DEX分配方案
    // 这是1inch协议的核心算法，用于计算如何在不同DEX之间分配交易量
    function _findBestDistribution(
        uint256 s,                // 分割数量（parts）
        int256[][] memory amounts // 各DEX的收益矩阵 [DEX][分割数]
    )
        internal
        pure
        returns(
            int256 returnAmount,           // 最大收益金额
            uint256[] memory distribution  // 最优分配方案
        )
    {
        // 获取DEX数量
        uint256 n = amounts.length;

        // 动态规划表：answer[i][j] 表示使用前i个DEX，分配j个部分的最大收益
        int256[][] memory answer = new int256[][](n); // int[n][s+1]
        // 路径追踪表：parent[i][j] 记录最优路径
        uint256[][] memory parent = new uint256[][](n); // int[n][s+1]

        // 初始化动态规划表
        for (uint i = 0; i < n; i++) {
            answer[i] = new int256[](s + 1);
            parent[i] = new uint256[](s + 1);
        }

        // 初始化第一行：只使用第一个DEX的情况
        for (uint j = 0; j <= s; j++) {
            answer[0][j] = amounts[0][j];  // 直接使用第一个DEX的收益
            for (uint i = 1; i < n; i++) {
                answer[i][j] = -1e72;      // 其他DEX初始化为无效值
            }
            parent[0][j] = 0;              // 第一个DEX的父节点为0
        }

        // 动态规划主循环：计算使用前i个DEX，分配j个部分的最大收益
        for (uint i = 1; i < n; i++) {
            for (uint j = 0; j <= s; j++) {
                // 初始值：不使用第i个DEX的收益
                answer[i][j] = answer[i - 1][j];
                parent[i][j] = j;

                // 尝试使用第i个DEX的不同分配量
                for (uint k = 1; k <= j; k++) {
                    // 如果使用k个部分给第i个DEX，剩余j-k个部分给前i-1个DEX
                    if (answer[i - 1][j - k] + amounts[i][k] > answer[i][j]) {
                        answer[i][j] = answer[i - 1][j - k] + amounts[i][k];
                        parent[i][j] = j - k;  // 记录最优路径
                    }
                }
            }
        }

        // 初始化分配结果数组
        distribution = new uint256[](DEXES_COUNT);

        // 回溯最优路径，构建最终分配方案
        uint256 partsLeft = s;
        for (uint curExchange = n - 1; partsLeft > 0; curExchange--) {
            // 计算当前DEX分配的部分数
            distribution[curExchange] = partsLeft - parent[curExchange][partsLeft];
            // 更新剩余部分数
            partsLeft = parent[curExchange][partsLeft];
        }

        // 返回最大收益，如果为无效值则返回0
        returnAmount = (answer[n - 1][s] == VERY_NEGATIVE_VALUE) ? 0 : answer[n - 1][s];
    }

    // === Kyber协议辅助函数 ===
    // 根据代币对获取Kyber储备ID
    // Kyber协议使用储备ID来标识不同的流动性提供者
    function _kyberReserveIdByTokens(
        IERC20 fromToken,        // 源代币
        IERC20 destToken         // 目标代币
    ) internal view returns(bytes32) {
        // 检查是否涉及ETH交易（Kyber主要处理ETH与其他代币的交换）
        if (!fromToken.isETH() && !destToken.isETH()) {
            return 0;  // 如果不涉及ETH，返回0表示无可用储备
        }

        // 从Kyber存储合约获取可用的储备ID列表
        // 根据源代币或目标代币（非ETH的那个）获取储备ID
        bytes32[] memory reserveIds = kyberStorage.getReserveIdsPerTokenSrc(
            fromToken.isETH() ? destToken : fromToken
        );

        // 遍历所有储备ID，找到合适的储备
        for (uint i = 0; i < reserveIds.length; i++) {
            // 过滤掉特定的储备ID：
            // 1. 桥接储备（0xBB开头）
            // 2. 特定的储备ID（可能是测试或特殊用途）
            if ((uint256(reserveIds[i]) >> 248) != 0xBB && // Bridge储备
                reserveIds[i] != 0xff4b796265722046707200000000000000000000000000000000000000000000 && // Reserve 1
                reserveIds[i] != 0xffabcd0000000000000000000000000000000000000000000000000000000000 && // Reserve 2
                reserveIds[i] != 0xff4f6e65426974205175616e7400000000000000000000000000000000000000)   // Reserve 3
            {
                return reserveIds[i];  // 返回第一个符合条件的储备ID
            }
        }

        return 0;  // 如果没有找到合适的储备，返回0
    }

    // === 价格计算辅助函数 ===
    // 缩放目标代币的ETH价格×gas价格
    // 用于将不同代币的gas价格统一到同一基准
    function _scaleDestTokenEthPriceTimesGasPrice(
        IERC20 fromToken,                    // 源代币
        IERC20 destToken,                    // 目标代币
        uint256 destTokenEthPriceTimesGasPrice  // 目标代币的ETH价格×gas价格
    ) internal view returns(uint256) {
        // 如果源代币和目标代币相同，直接返回原值
        if (fromToken == destToken) {
            return destTokenEthPriceTimesGasPrice;
        }

        // 获取目标代币相对于ETH的价格（使用0.01 ETH作为基准）
        uint256 mul = _cheapGetPrice(ETH_ADDRESS, destToken, 0.01 ether);
        // 获取源代币相对于ETH的价格
        uint256 div = _cheapGetPrice(ETH_ADDRESS, fromToken, 0.01 ether);
        
        // 如果源代币价格有效，进行价格换算
        if (div > 0) {
            // 将目标代币的gas价格换算为源代币的gas价格
            return destTokenEthPriceTimesGasPrice.mul(mul).div(div);
        }
        return 0;  // 如果无法获取源代币价格，返回0
    }

    // 快速获取代币价格
    // 使用简化的查询方式获取代币交换率，避免复杂的计算
    function _cheapGetPrice(
        IERC20 fromToken,        // 源代币
        IERC20 destToken,        // 目标代币
        uint256 amount           // 交换数量
    ) internal view returns(uint256 returnAmount) {
        // 使用getExpectedReturnWithGas获取价格，但禁用大部分DEX以减少gas消耗
        (returnAmount,,) = this.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            1,  // 只使用1个部分，简化计算
            // 禁用标志位组合，只保留少数几个DEX用于快速价格查询
            FLAG_DISABLE_SPLIT_RECALCULATION |  // 禁用分割重新计算
            FLAG_DISABLE_ALL_SPLIT_SOURCES |    // 禁用所有分割源
            FLAG_DISABLE_UNISWAP_V2_ALL |       // 禁用所有Uniswap V2
            FLAG_DISABLE_UNISWAP,               // 禁用Uniswap V1
            0   // gas价格参数为0
        );
    }

    // === 数学辅助函数 ===
    // 线性插值函数
    // 将总价值按比例分配到多个部分中
    function _linearInterpolation(
        uint256 value,           // 总价值
        uint256 parts            // 分割数量
    ) internal pure returns(uint256[] memory rets) {
        rets = new uint256[](parts);
        // 为每个部分计算累积价值
        for (uint i = 0; i < parts; i++) {
            // 第i个部分的价值 = 总价值 * (i+1) / 总部分数
            rets[i] = value.mul(i + 1).div(parts);
        }
    }

    // 代币相等性检查函数
    // 检查两个代币是否相等，包括ETH的特殊情况
    function _tokensEqual(IERC20 tokenA, IERC20 tokenB) internal pure returns(bool) {
        // 两个代币相等当且仅当：
        // 1. 都是ETH，或
        // 2. 是同一个代币合约地址
        return ((tokenA.isETH() && tokenB.isETH()) || tokenA == tokenB);
    }
}


// === 视图包装合约 ===
// 1inch协议视图功能的包装合约
// 继承IOneSplitView和OneSplitRoot，提供查询功能
contract OneSplitViewWrapBase is IOneSplitView, OneSplitRoot {
    
    // 获取预期返回金额（不考虑gas费用）
    // 这是最常用的查询函数，用于获取最优交易路径
    function getExpectedReturn(
        IERC20 fromToken,        // 源代币地址
        IERC20 destToken,         // 目标代币地址
        uint256 amount,          // 源代币数量
        uint256 parts,           // 分割数量
        uint256 flags            // 标志位，控制DEX选择
    )
        public
        view
        returns(
            uint256 returnAmount,           // 预期返回金额
            uint256[] memory distribution   // 分布数组
        )
    {
        // 调用考虑gas费用的版本，但将gas价格设为0
        (returnAmount, , distribution) = this.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0  // gas价格设为0，表示不考虑gas费用
        );
    }

    // 获取预期返回金额（考虑gas费用）
    // 在计算最优路径时考虑gas费用对最终收益的影响
    function getExpectedReturnWithGas(
        IERC20 fromToken,                    // 源代币地址
        IERC20 destToken,                    // 目标代币地址
        uint256 amount,                      // 源代币数量
        uint256 parts,                       // 分割数量
        uint256 flags,                       // 标志位
        uint256 destTokenEthPriceTimesGasPrice  // 目标代币ETH价格×gas价格
    )
        public
        view
        returns(
            uint256 returnAmount,           // 预期返回金额
            uint256 estimateGasAmount,       // 预估gas消耗
            uint256[] memory distribution   // 分布数组
        )
    {
        // 调用内部实现函数，考虑gas费用下限
        return _getExpectedReturnRespectingGasFloor(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    // 考虑gas费用下限的预期返回计算
    // 内部实现函数，确保gas费用不会超过收益
    function _getExpectedReturnRespectingGasFloor(
        IERC20 fromToken,                    // 源代币地址
        IERC20 destToken,                    // 目标代币地址
        uint256 amount,                      // 源代币数量
        uint256 parts,                       // 分割数量
        uint256 flags,                       // 标志位
        uint256 destTokenEthPriceTimesGasPrice  // gas价格参数
    )
        internal
        view
        returns(
            uint256 returnAmount,           // 预期返回金额
            uint256 estimateGasAmount,       // 预估gas消耗
            uint256[] memory distribution   // 分布数组
        );
}


// === 主视图合约 ===
// 1inch协议的核心视图实现合约
// 继承IOneSplitView和OneSplitRoot，实现所有查询功能
contract OneSplitView is IOneSplitView, OneSplitRoot {
    
    // 获取预期返回金额（不考虑gas费用）
    // 这是用户最常用的查询函数
    function getExpectedReturn(
        IERC20 fromToken,        // 源代币地址
        IERC20 destToken,         // 目标代币地址
        uint256 amount,          // 源代币数量
        uint256 parts,           // 分割数量
        uint256 flags            // 标志位，控制DEX选择
    )
        public
        view
        returns(
            uint256 returnAmount,           // 预期返回金额
            uint256[] memory distribution   // 分布数组
        )
    {
        // 调用考虑gas费用的版本，但将gas价格设为0
        (returnAmount, , distribution) = getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0  // gas价格设为0，表示不考虑gas费用
        );
    }

    // 获取预期返回金额（考虑gas费用）
    // 这是1inch协议的核心算法实现
    function getExpectedReturnWithGas(
        IERC20 fromToken,                    // 源代币地址
        IERC20 destToken,                    // 目标代币地址
        uint256 amount,                      // 源代币数量
        uint256 parts,                       // 分割数量
        uint256 flags,                       // 标志位
        uint256 destTokenEthPriceTimesGasPrice  // 目标代币ETH价格×gas价格
    )
        public
        view
        returns(
            uint256 returnAmount,           // 预期返回金额
            uint256 estimateGasAmount,       // 预估gas消耗
            uint256[] memory distribution   // 分布数组
        )
    {
        // 初始化分布数组，大小为DEX数量
        distribution = new uint256[](DEXES_COUNT);

        // 如果源代币和目标代币相同，直接返回原数量
        if (fromToken == destToken) {
            return (amount, 0, distribution);
        }

        // 获取所有可用的DEX储备函数
        // 这是一个函数指针数组，每个元素对应一个DEX的查询函数
        function(IERC20,IERC20,uint256,uint256,uint256) view returns(uint256[] memory, uint256)[DEXES_COUNT] memory reserves = _getAllReserves(flags);

        // 初始化收益矩阵和gas消耗数组
        int256[][] memory matrix = new int256[][](DEXES_COUNT);  // 收益矩阵
        uint256[DEXES_COUNT] memory gases;                       // gas消耗数组
        bool atLeastOnePositive = false;                         // 是否有正收益的标志

        // 遍历所有DEX，计算每个DEX的收益和gas消耗
        for (uint i = 0; i < DEXES_COUNT; i++) {
            uint256[] memory rets;
            // 调用第i个DEX的查询函数，获取收益分布和gas消耗
            (rets, gases[i]) = reserves[i](fromToken, destToken, amount, parts, flags);

            // 计算gas费用并构建收益矩阵
            // 将gas费用转换为目标代币价值，然后从收益中扣除
            int256 gas = int256(gases[i].mul(destTokenEthPriceTimesGasPrice).div(1e18));
            matrix[i] = new int256[](parts + 1);
            
            // 为每个分割数量计算净收益（收益 - gas费用）
            for (uint j = 0; j < rets.length; j++) {
                matrix[i][j + 1] = int256(rets[j]) - gas;  // 净收益 = 总收益 - gas费用
                atLeastOnePositive = atLeastOnePositive || (matrix[i][j + 1] > 0);  // 检查是否有正收益
            }
        }

        // 如果没有找到任何正收益，将所有零收益标记为无效
        if (!atLeastOnePositive) {
            for (uint i = 0; i < DEXES_COUNT; i++) {
                for (uint j = 1; j < parts + 1; j++) {
                    if (matrix[i][j] == 0) {
                        matrix[i][j] = VERY_NEGATIVE_VALUE;  // 标记为无效状态
                    }
                }
            }
        }

        // 使用动态规划算法找到最优分配方案
        (, distribution) = _findBestDistribution(parts, matrix);

        // 根据最优分配方案计算最终收益和gas消耗
        (returnAmount, estimateGasAmount) = _getReturnAndGasByDistribution(
            Args({
                fromToken: fromToken,
                destToken: destToken,
                amount: amount,
                parts: parts,
                flags: flags,
                destTokenEthPriceTimesGasPrice: destTokenEthPriceTimesGasPrice,
                distribution: distribution,
                matrix: matrix,
                gases: gases,
                reserves: reserves
            })
        );
        return (returnAmount, estimateGasAmount, distribution);
    }

    // === 参数结构体 ===
    // 用于传递计算参数的结构体，包含所有必要的计算数据
    struct Args {
        IERC20 fromToken;        // 源代币
        IERC20 destToken;        // 目标代币
        uint256 amount;          // 交换数量
        uint256 parts;           // 分割数量
        uint256 flags;           // 标志位
        uint256 destTokenEthPriceTimesGasPrice;  // gas价格参数
        uint256[] distribution;  // 分配方案
        int256[][] matrix;       // 收益矩阵
        uint256[DEXES_COUNT] gases;  // gas消耗数组
        function(IERC20,IERC20,uint256,uint256,uint256) view returns(uint256[] memory, uint256)[DEXES_COUNT] reserves;  // DEX函数指针数组
    }

    // === 根据分配方案计算收益和gas消耗 ===
    // 根据最优分配方案计算最终的收益金额和gas消耗
    function _getReturnAndGasByDistribution(
        Args memory args
    ) internal view returns(uint256 returnAmount, uint256 estimateGasAmount) {
        // DEX精确性标志数组
        // true表示该DEX支持精确计算，false表示需要重新计算
        bool[DEXES_COUNT] memory exact = [
            true,  // "Uniswap" - 支持精确计算
            false, // "Kyber" - 需要重新计算
            false, // "Bancor" - 需要重新计算
            false, // "Oasis" - 需要重新计算
            true,  // "Curve Compound" - 支持精确计算
            true,  // "Curve USDT" - 支持精确计算
            true,  // "Curve Y" - 支持精确计算
            true,  // "Curve Binance" - 支持精确计算
            true,  // "Curve Synthetix" - 支持精确计算
            true,  // "Uniswap Compound" - 支持精确计算
            true,  // "Uniswap CHAI" - 支持精确计算
            true,  // "Uniswap Aave" - 支持精确计算
            true,  // "Mooniswap 1" - 支持精确计算
            true,  // "Uniswap V2" - 支持精确计算
            true,  // "Uniswap V2 (ETH)" - 支持精确计算
            true,  // "Uniswap V2 (DAI)" - 支持精确计算
            true,  // "Uniswap V2 (USDC)" - 支持精确计算
            true,  // "Curve Pax" - 支持精确计算
            true,  // "Curve RenBTC" - 支持精确计算
            true,  // "Curve tBTC" - 支持精确计算
            true,  // "Dforce XSwap" - 支持精确计算
            false, // "Shell" - 需要重新计算
            true,  // "mStable" - 支持精确计算
            true,  // "Curve sBTC" - 支持精确计算
            true,  // "Balancer 1" - 支持精确计算
            true,  // "Balancer 2" - 支持精确计算
            true,  // "Balancer 3" - 支持精确计算
            true,  // "Kyber 1" - 支持精确计算
            true,  // "Kyber 2" - 支持精确计算
            true,  // "Kyber 3" - 支持精确计算
            true,  // "Kyber 4" - 支持精确计算
            true,  // "Mooniswap 2" - 支持精确计算
            true,  // "Mooniswap 3" - 支持精确计算
            true   // "Mooniswap 4" - 支持精确计算
        ];

        // 遍历所有DEX，根据分配方案计算最终收益
        for (uint i = 0; i < DEXES_COUNT; i++) {
            if (args.distribution[i] > 0) {  // 如果该DEX有分配
                // 判断是否可以使用预计算结果还是需要重新计算
                if (args.distribution[i] == args.parts || exact[i] || args.flags.check(FLAG_DISABLE_SPLIT_RECALCULATION)) {
                    // 使用预计算的收益矩阵（精确计算或禁用重新计算）
                    estimateGasAmount = estimateGasAmount.add(args.gases[i]);
                    int256 value = args.matrix[i][args.distribution[i]];
                    returnAmount = returnAmount.add(uint256(
                        (value == VERY_NEGATIVE_VALUE ? 0 : value) +  // 如果值为无效，使用0
                        int256(args.gases[i].mul(args.destTokenEthPriceTimesGasPrice).div(1e18))  // 加上gas费用
                    ));
                }
                else {
                    // 需要重新计算该DEX的收益（用于不精确的DEX）
                    (uint256[] memory rets, uint256 gas) = args.reserves[i](
                        args.fromToken, 
                        args.destToken, 
                        args.amount.mul(args.distribution[i]).div(args.parts),  // 计算分配的数量
                        1,  // 使用1个部分
                        args.flags
                    );
                    estimateGasAmount = estimateGasAmount.add(gas);
                    returnAmount = returnAmount.add(rets[0]);  // 添加实际收益
                }
            }
        }
    }

    function _getAllReserves(uint256 flags)
        internal
        pure
        returns(function(IERC20,IERC20,uint256,uint256,uint256) view returns(uint256[] memory, uint256)[DEXES_COUNT] memory)
    {
        bool invert = flags.check(FLAG_DISABLE_ALL_SPLIT_SOURCES);
        return [
            invert != flags.check(FLAG_DISABLE_UNISWAP_ALL | FLAG_DISABLE_UNISWAP)            ? _calculateNoReturn : calculateUniswap,
            _calculateNoReturn, // invert != flags.check(FLAG_DISABLE_KYBER) ? _calculateNoReturn : calculateKyber,
            invert != flags.check(FLAG_DISABLE_BANCOR)                                        ? _calculateNoReturn : calculateBancor,
            invert != flags.check(FLAG_DISABLE_OASIS)                                         ? _calculateNoReturn : calculateOasis,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_COMPOUND)       ? _calculateNoReturn : calculateCurveCompound,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_USDT)           ? _calculateNoReturn : calculateCurveUSDT,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_Y)              ? _calculateNoReturn : calculateCurveY,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_BINANCE)        ? _calculateNoReturn : calculateCurveBinance,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_SYNTHETIX)      ? _calculateNoReturn : calculateCurveSynthetix,
            invert != flags.check(FLAG_DISABLE_UNISWAP_ALL | FLAG_DISABLE_UNISWAP_COMPOUND)   ? _calculateNoReturn : calculateUniswapCompound,
            invert != flags.check(FLAG_DISABLE_UNISWAP_ALL | FLAG_DISABLE_UNISWAP_CHAI)       ? _calculateNoReturn : calculateUniswapChai,
            invert != flags.check(FLAG_DISABLE_UNISWAP_ALL | FLAG_DISABLE_UNISWAP_AAVE)       ? _calculateNoReturn : calculateUniswapAave,
            invert != flags.check(FLAG_DISABLE_MOONISWAP_ALL | FLAG_DISABLE_MOONISWAP)        ? _calculateNoReturn : calculateMooniswap,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_ALL | FLAG_DISABLE_UNISWAP_V2)      ? _calculateNoReturn : calculateUniswapV2,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_ALL | FLAG_DISABLE_UNISWAP_V2_ETH)  ? _calculateNoReturn : calculateUniswapV2ETH,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_ALL | FLAG_DISABLE_UNISWAP_V2_DAI)  ? _calculateNoReturn : calculateUniswapV2DAI,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_ALL | FLAG_DISABLE_UNISWAP_V2_USDC) ? _calculateNoReturn : calculateUniswapV2USDC,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_PAX)            ? _calculateNoReturn : calculateCurvePAX,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_RENBTC)         ? _calculateNoReturn : calculateCurveRenBTC,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_TBTC)           ? _calculateNoReturn : calculateCurveTBTC,
            invert != flags.check(FLAG_DISABLE_DFORCE_SWAP)                                   ? _calculateNoReturn : calculateDforceSwap,
            invert != flags.check(FLAG_DISABLE_SHELL)                                         ? _calculateNoReturn : calculateShell,
            invert != flags.check(FLAG_DISABLE_MSTABLE_MUSD)                                  ? _calculateNoReturn : calculateMStableMUSD,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_SBTC)           ? _calculateNoReturn : calculateCurveSBTC,
            invert != flags.check(FLAG_DISABLE_BALANCER_ALL | FLAG_DISABLE_BALANCER_1)        ? _calculateNoReturn : calculateBalancer1,
            invert != flags.check(FLAG_DISABLE_BALANCER_ALL | FLAG_DISABLE_BALANCER_2)        ? _calculateNoReturn : calculateBalancer2,
            invert != flags.check(FLAG_DISABLE_BALANCER_ALL | FLAG_DISABLE_BALANCER_3)        ? _calculateNoReturn : calculateBalancer3,
            invert != flags.check(FLAG_DISABLE_KYBER_ALL | FLAG_DISABLE_KYBER_1)              ? _calculateNoReturn : calculateKyber1,
            invert != flags.check(FLAG_DISABLE_KYBER_ALL | FLAG_DISABLE_KYBER_2)              ? _calculateNoReturn : calculateKyber2,
            invert != flags.check(FLAG_DISABLE_KYBER_ALL | FLAG_DISABLE_KYBER_3)              ? _calculateNoReturn : calculateKyber3,
            invert != flags.check(FLAG_DISABLE_KYBER_ALL | FLAG_DISABLE_KYBER_4)              ? _calculateNoReturn : calculateKyber4,
            invert != flags.check(FLAG_DISABLE_MOONISWAP_ALL | FLAG_DISABLE_MOONISWAP_ETH)    ? _calculateNoReturn : calculateMooniswapOverETH,
            invert != flags.check(FLAG_DISABLE_MOONISWAP_ALL | FLAG_DISABLE_MOONISWAP_DAI)    ? _calculateNoReturn : calculateMooniswapOverDAI,
            invert != flags.check(FLAG_DISABLE_MOONISWAP_ALL | FLAG_DISABLE_MOONISWAP_USDC)   ? _calculateNoReturn : calculateMooniswapOverUSDC
        ];
    }

    function _calculateNoGas(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 /*amount*/,
        uint256 /*parts*/,
        uint256 /*destTokenEthPriceTimesGasPrice*/,
        uint256 /*flags*/,
        uint256 /*destTokenEthPrice*/
    ) internal view returns(uint256[] memory /*rets*/, uint256 /*gas*/) {
        this;
    }

    // View Helpers

    struct Balances {
        uint256 src;
        uint256 dst;
    }

    function _calculateBalancer(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 poolIndex
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        address[] memory pools = balancerRegistry.getBestPoolsWithLimit(
            address(fromToken.isETH() ? weth : fromToken),
            address(destToken.isETH() ? weth : destToken),
            poolIndex + 1
        );
        if (poolIndex >= pools.length) {
            return (new uint256[](parts), 0);
        }

        rets = balancerHelper.getReturns(
            IBalancerPool(pools[poolIndex]),
            fromToken.isETH() ? weth : fromToken,
            destToken.isETH() ? weth : destToken,
            _linearInterpolation(amount, parts)
        );
        gas = 75_000 + (fromToken.isETH() || destToken.isETH() ? 0 : 65_000);
    }

    function calculateBalancer1(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateBalancer(
            fromToken,
            destToken,
            amount,
            parts,
            0
        );
    }

    function calculateBalancer2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateBalancer(
            fromToken,
            destToken,
            amount,
            parts,
            1
        );
    }

    function calculateBalancer3(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateBalancer(
            fromToken,
            destToken,
            amount,
            parts,
            2
        );
    }

    function calculateMStableMUSD(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = new uint256[](parts);

        if ((fromToken != usdc && fromToken != dai && fromToken != usdt && fromToken != tusd) ||
            (destToken != usdc && destToken != dai && destToken != usdt && destToken != tusd))
        {
            return (rets, 0);
        }

        for (uint i = 1; i <= parts; i *= 2) {
            (bool success, bytes memory data) = address(musd).staticcall(abi.encodeWithSelector(
                musd.getSwapOutput.selector,
                fromToken,
                destToken,
                amount.mul(parts.div(i)).div(parts)
            ));

            if (success && data.length > 0) {
                (,, uint256 maxRet) = abi.decode(data, (bool,string,uint256));
                if (maxRet > 0) {
                    for (uint j = 0; j < parts.div(i); j++) {
                        rets[j] = maxRet.mul(j + 1).div(parts.div(i));
                    }
                    break;
                }
            }
        }

        return (
            rets,
            700_000
        );
    }

    function _getCurvePoolInfo(
        ICurve curve,
        bool haveUnderlying
    ) internal view returns(
        uint256[8] memory balances,
        uint256[8] memory precisions,
        uint256[8] memory rates,
        uint256 amp,
        uint256 fee
    ) {
        uint256[8] memory underlying_balances;
        uint256[8] memory decimals;
        uint256[8] memory underlying_decimals;

        (
            balances,
            underlying_balances,
            decimals,
            underlying_decimals,
            /*address lp_token*/,
            amp,
            fee
        ) = curveRegistry.get_pool_info(address(curve));

        for (uint k = 0; k < 8 && balances[k] > 0; k++) {
            precisions[k] = 10 ** (18 - (haveUnderlying ? underlying_decimals : decimals)[k]);
            if (haveUnderlying) {
                rates[k] = underlying_balances[k].mul(1e18).div(balances[k]);
            } else {
                rates[k] = 1e18;
            }
        }
    }

    function _calculateCurveSelector(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        ICurve curve,
        bool haveUnderlying,
        IERC20[] memory tokens
    ) internal view returns(uint256[] memory rets) {
        rets = new uint256[](parts);

        int128 i = 0;
        int128 j = 0;
        for (uint t = 0; t < tokens.length; t++) {
            if (fromToken == tokens[t]) {
                i = int128(t + 1);
            }
            if (destToken == tokens[t]) {
                j = int128(t + 1);
            }
        }

        if (i == 0 || j == 0) {
            return rets;
        }

        bytes memory data = abi.encodePacked(
            uint256(haveUnderlying ? 1 : 0),
            uint256(i - 1),
            uint256(j - 1),
            _linearInterpolation100(amount, parts)
        );

        (
            uint256[8] memory balances,
            uint256[8] memory precisions,
            uint256[8] memory rates,
            uint256 amp,
            uint256 fee
        ) = _getCurvePoolInfo(curve, haveUnderlying);

        bool success;
        (success, data) = address(curveCalculator).staticcall(
            abi.encodePacked(
                abi.encodeWithSelector(
                    curveCalculator.get_dy.selector,
                    tokens.length,
                    balances,
                    amp,
                    fee,
                    rates,
                    precisions
                ),
                data
            )
        );

        if (!success || data.length == 0) {
            return rets;
        }

        uint256[100] memory dy = abi.decode(data, (uint256[100]));
        for (uint t = 0; t < parts; t++) {
            rets[t] = dy[t];
        }
    }

    function _linearInterpolation100(
        uint256 value,
        uint256 parts
    ) internal pure returns(uint256[100] memory rets) {
        for (uint i = 0; i < parts; i++) {
            rets[i] = value.mul(i + 1).div(parts);
        }
    }

    function calculateCurveCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = dai;
        tokens[1] = usdc;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveCompound,
            true,
            tokens
        ), 720_000);
    }

    function calculateCurveUSDT(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveUSDT,
            true,
            tokens
        ), 720_000);
    }

    function calculateCurveY(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = tusd;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveY,
            true,
            tokens
        ), 1_400_000);
    }

    function calculateCurveBinance(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = busd;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveBinance,
            true,
            tokens
        ), 1_400_000);
    }

    function calculateCurveSynthetix(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = susd;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveSynthetix,
            true,
            tokens
        ), 200_000);
    }

    function calculateCurvePAX(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = pax;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curvePAX,
            true,
            tokens
        ), 1_000_000);
    }

    function calculateCurveRenBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = renbtc;
        tokens[1] = wbtc;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveRenBTC,
            false,
            tokens
        ), 130_000);
    }

    function calculateCurveTBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = tbtc;
        tokens[1] = wbtc;
        tokens[2] = hbtc;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveTBTC,
            false,
            tokens
        ), 145_000);
    }

    function calculateCurveSBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = renbtc;
        tokens[1] = wbtc;
        tokens[2] = sbtc;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveSBTC,
            false,
            tokens
        ), 150_000);
    }

    function calculateShell(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        (bool success, bytes memory data) = address(shell).staticcall(abi.encodeWithSelector(
            shell.viewOriginTrade.selector,
            fromToken,
            destToken,
            amount
        ));

        if (!success || data.length == 0) {
            return (new uint256[](parts), 0);
        }

        uint256 maxRet = abi.decode(data, (uint256));
        return (_linearInterpolation(maxRet, parts), 300_000);
    }

    function calculateDforceSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        (bool success, bytes memory data) = address(dforceSwap).staticcall(
            abi.encodeWithSelector(
                dforceSwap.getAmountByInput.selector,
                fromToken,
                destToken,
                amount
            )
        );
        if (!success || data.length == 0) {
            return (new uint256[](parts), 0);
        }

        uint256 maxRet = abi.decode(data, (uint256));
        uint256 available = destToken.universalBalanceOf(address(dforceSwap));
        if (maxRet > available) {
            return (new uint256[](parts), 0);
        }

        return (_linearInterpolation(maxRet, parts), 160_000);
    }

    function _calculateUniswapFormula(uint256 fromBalance, uint256 toBalance, uint256 amount) internal pure returns(uint256) {
        if (amount == 0) {
            return 0;
        }
        return amount.mul(toBalance).mul(997).div(
            fromBalance.mul(1000).add(amount.mul(997))
        );
    }

    function _calculateUniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = amounts;

        if (!fromToken.isETH()) {
            IUniswapExchange fromExchange = uniswapFactory.getExchange(fromToken);
            if (fromExchange == IUniswapExchange(0)) {
                return (new uint256[](rets.length), 0);
            }

            uint256 fromTokenBalance = fromToken.universalBalanceOf(address(fromExchange));
            uint256 fromEtherBalance = address(fromExchange).balance;

            for (uint i = 0; i < rets.length; i++) {
                rets[i] = _calculateUniswapFormula(fromTokenBalance, fromEtherBalance, rets[i]);
            }
        }

        if (!destToken.isETH()) {
            IUniswapExchange toExchange = uniswapFactory.getExchange(destToken);
            if (toExchange == IUniswapExchange(0)) {
                return (new uint256[](rets.length), 0);
            }

            uint256 toEtherBalance = address(toExchange).balance;
            uint256 toTokenBalance = destToken.universalBalanceOf(address(toExchange));

            for (uint i = 0; i < rets.length; i++) {
                rets[i] = _calculateUniswapFormula(toEtherBalance, toTokenBalance, rets[i]);
            }
        }

        return (rets, fromToken.isETH() || destToken.isETH() ? 60_000 : 100_000);
    }

    function calculateUniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateUniswap(
            fromToken,
            destToken,
            _linearInterpolation(amount, parts),
            flags
        );
    }

    function _calculateUniswapWrapped(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 midTokenPrice,
        uint256 flags,
        uint256 gas1,
        uint256 gas2
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (!fromToken.isETH() && destToken.isETH()) {
            (rets, gas) = _calculateUniswap(
                midToken,
                destToken,
                _linearInterpolation(amount.mul(1e18).div(midTokenPrice), parts),
                flags
            );
            return (rets, gas + gas1);
        }
        else if (fromToken.isETH() && !destToken.isETH()) {
            (rets, gas) = _calculateUniswap(
                fromToken,
                midToken,
                _linearInterpolation(amount, parts),
                flags
            );

            for (uint i = 0; i < parts; i++) {
                rets[i] = rets[i].mul(midTokenPrice).div(1e18);
            }
            return (rets, gas + gas2);
        }

        return (new uint256[](parts), 0);
    }

    function calculateUniswapCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20 midPreToken;
        if (!fromToken.isETH() && destToken.isETH()) {
            midPreToken = fromToken;
        }
        else if (!destToken.isETH() && fromToken.isETH()) {
            midPreToken = destToken;
        }

        if (!midPreToken.isETH()) {
            ICompoundToken midToken = compoundRegistry.cTokenByToken(midPreToken);
            if (midToken != ICompoundToken(0)) {
                return _calculateUniswapWrapped(
                    fromToken,
                    midToken,
                    destToken,
                    amount,
                    parts,
                    midToken.exchangeRateStored(),
                    flags,
                    200_000,
                    200_000
                );
            }
        }

        return (new uint256[](parts), 0);
    }

    function calculateUniswapChai(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken == dai && destToken.isETH() ||
            fromToken.isETH() && destToken == dai)
        {
            return _calculateUniswapWrapped(
                fromToken,
                chai,
                destToken,
                amount,
                parts,
                chai.chaiPrice(),
                flags,
                180_000,
                160_000
            );
        }

        return (new uint256[](parts), 0);
    }

    function calculateUniswapAave(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20 midPreToken;
        if (!fromToken.isETH() && destToken.isETH()) {
            midPreToken = fromToken;
        }
        else if (!destToken.isETH() && fromToken.isETH()) {
            midPreToken = destToken;
        }

        if (!midPreToken.isETH()) {
            IAaveToken midToken = aaveRegistry.aTokenByToken(midPreToken);
            if (midToken != IAaveToken(0)) {
                return _calculateUniswapWrapped(
                    fromToken,
                    midToken,
                    destToken,
                    amount,
                    parts,
                    1e18,
                    flags,
                    310_000,
                    670_000
                );
            }
        }

        return (new uint256[](parts), 0);
    }

    function calculateKyber1(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateKyber(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0xff4b796265722046707200000000000000000000000000000000000000000000 // 0x63825c174ab367968EC60f061753D3bbD36A0D8F
        );
    }

    function calculateKyber2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateKyber(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0xffabcd0000000000000000000000000000000000000000000000000000000000 // 0x7a3370075a54B187d7bD5DceBf0ff2B5552d4F7D
        );
    }

    function calculateKyber3(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateKyber(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0xff4f6e65426974205175616e7400000000000000000000000000000000000000 // 0x4f32BbE8dFc9efD54345Fc936f9fEF1048746fCF
        );
    }

    function calculateKyber4(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        bytes32 reserveId = _kyberReserveIdByTokens(fromToken, destToken);
        if (reserveId == 0) {
            return (new uint256[](parts), 0);
        }

        return _calculateKyber(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            reserveId
        );
    }

    function _kyberGetRate(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags,
        bytes memory hint
    ) private view returns(uint256) {
        (, bytes memory data) = address(kyberNetworkProxy).staticcall(
            abi.encodeWithSelector(
                kyberNetworkProxy.getExpectedRateAfterFee.selector,
                fromToken,
                destToken,
                amount,
                (flags >> 255) * 10,
                hint
            )
        );

        return (data.length == 32) ? abi.decode(data, (uint256)) : 0;
    }

    function _calculateKyber(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        bytes32 reserveId
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        bytes memory fromHint;
        bytes memory destHint;
        {
            bytes32[] memory reserveIds = new bytes32[](1);
            reserveIds[0] = reserveId;

            (bool success, bytes memory data) = address(kyberHintHandler).staticcall(
                abi.encodeWithSelector(
                    kyberHintHandler.buildTokenToEthHint.selector,
                    fromToken,
                    IKyberHintHandler.TradeType.MaskIn,
                    reserveIds,
                    new uint256[](0)
                )
            );
            fromHint = success ? abi.decode(data, (bytes)) : bytes("");

            (success, data) = address(kyberHintHandler).staticcall(
                abi.encodeWithSelector(
                    kyberHintHandler.buildEthToTokenHint.selector,
                    destToken,
                    IKyberHintHandler.TradeType.MaskIn,
                    reserveIds,
                    new uint256[](0)
                )
            );
            destHint = success ? abi.decode(data, (bytes)) : bytes("");
        }

        uint256 fromTokenDecimals = 10 ** IERC20(fromToken).universalDecimals();
        uint256 destTokenDecimals = 10 ** IERC20(destToken).universalDecimals();
        rets = new uint256[](parts);
        for (uint i = 0; i < parts; i++) {
            if (i > 0 && rets[i - 1] == 0) {
                break;
            }
            rets[i] = amount.mul(i + 1).div(parts);

            if (!fromToken.isETH()) {
                if (fromHint.length == 0) {
                    rets[i] = 0;
                    break;
                }
                uint256 rate = _kyberGetRate(
                    fromToken,
                    ETH_ADDRESS,
                    rets[i],
                    flags,
                    fromHint
                );
                rets[i] = rate.mul(rets[i]).div(fromTokenDecimals);
            }

            if (!destToken.isETH() && rets[i] > 0) {
                if (destHint.length == 0) {
                    rets[i] = 0;
                    break;
                }
                uint256 rate = _kyberGetRate(
                    ETH_ADDRESS,
                    destToken,
                    rets[i],
                    10,
                    destHint
                );
                rets[i] = rate.mul(rets[i]).mul(destTokenDecimals).div(1e36);
            }
        }

        return (rets, 100_000);
    }

    function calculateBancor(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 /*amount*/,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return (new uint256[](parts), 0);
        // IBancorNetwork bancorNetwork = IBancorNetwork(bancorContractRegistry.addressOf("BancorNetwork"));

        // address[] memory path = bancorFinder.buildBancorPath(
        //     fromToken.isETH() ? bancorEtherToken : fromToken,
        //     destToken.isETH() ? bancorEtherToken : destToken
        // );

        // rets = _linearInterpolation(amount, parts);
        // for (uint i = 0; i < parts; i++) {
        //     (bool success, bytes memory data) = address(bancorNetwork).staticcall.gas(500000)(
        //         abi.encodeWithSelector(
        //             bancorNetwork.getReturnByPath.selector,
        //             path,
        //             rets[i]
        //         )
        //     );
        //     if (!success || data.length == 0) {
        //         for (; i < parts; i++) {
        //             rets[i] = 0;
        //         }
        //         break;
        //     } else {
        //         (uint256 ret,) = abi.decode(data, (uint256,uint256));
        //         rets[i] = ret;
        //     }
        // }

        // return (rets, path.length.mul(150_000));
    }

    function calculateOasis(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = _linearInterpolation(amount, parts);
        for (uint i = 0; i < parts; i++) {
            (bool success, bytes memory data) = address(oasisExchange).staticcall.gas(500000)(
                abi.encodeWithSelector(
                    oasisExchange.getBuyAmount.selector,
                    destToken.isETH() ? weth : destToken,
                    fromToken.isETH() ? weth : fromToken,
                    rets[i]
                )
            );

            if (!success || data.length == 0) {
                for (; i < parts; i++) {
                    rets[i] = 0;
                }
                break;
            } else {
                rets[i] = abi.decode(data, (uint256));
            }
        }

        return (rets, 500_000);
    }

    function calculateMooniswapMany(
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = new uint256[](amounts.length);

        IMooniswap mooniswap = mooniswapRegistry.pools(
            fromToken.isETH() ? ZERO_ADDRESS : fromToken,
            destToken.isETH() ? ZERO_ADDRESS : destToken
        );
        if (mooniswap == IMooniswap(0)) {
            return (rets, 0);
        }

        uint256 fee = mooniswap.fee();
        uint256 fromBalance = mooniswap.getBalanceForAddition(fromToken.isETH() ? ZERO_ADDRESS : fromToken);
        uint256 destBalance = mooniswap.getBalanceForRemoval(destToken.isETH() ? ZERO_ADDRESS : destToken);
        if (fromBalance == 0 || destBalance == 0) {
            return (rets, 0);
        }

        for (uint i = 0; i < amounts.length; i++) {
            uint256 amount = amounts[i].sub(amounts[i].mul(fee).div(1e18));
            rets[i] = amount.mul(destBalance).div(
                fromBalance.add(amount)
            );
        }

        return (rets, (fromToken.isETH() || destToken.isETH()) ? 80_000 : 110_000);
    }

    function calculateMooniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return calculateMooniswapMany(
            fromToken,
            destToken,
            _linearInterpolation(amount, parts)
        );
    }

    function calculateMooniswapOverETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken.isETH() || destToken.isETH()) {
            return (new uint256[](parts), 0);
        }

        (uint256[] memory results, uint256 gas1) = calculateMooniswap(fromToken, ZERO_ADDRESS, amount, parts, flags);
        (rets, gas) = calculateMooniswapMany(ZERO_ADDRESS, destToken, results);
        gas = gas.add(gas1);
    }

    function calculateMooniswapOverDAI(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken == dai || destToken == dai) {
            return (new uint256[](parts), 0);
        }

        (uint256[] memory results, uint256 gas1) = calculateMooniswap(fromToken, dai, amount, parts, flags);
        (rets, gas) = calculateMooniswapMany(dai, destToken, results);
        gas = gas.add(gas1);
    }

    function calculateMooniswapOverUSDC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken == usdc || destToken == usdc) {
            return (new uint256[](parts), 0);
        }

        (uint256[] memory results, uint256 gas1) = calculateMooniswap(fromToken, usdc, amount, parts, flags);
        (rets, gas) = calculateMooniswapMany(usdc, destToken, results);
        gas = gas.add(gas1);
    }

    function calculateUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateUniswapV2(
            fromToken,
            destToken,
            _linearInterpolation(amount, parts),
            flags
        );
    }

    function calculateUniswapV2ETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken.isETH() || fromToken == weth || destToken.isETH() || destToken == weth) {
            return (new uint256[](parts), 0);
        }

        return _calculateUniswapV2OverMidToken(
            fromToken,
            weth,
            destToken,
            amount,
            parts,
            flags
        );
    }

    function calculateUniswapV2DAI(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken == dai || destToken == dai) {
            return (new uint256[](parts), 0);
        }

        return _calculateUniswapV2OverMidToken(
            fromToken,
            dai,
            destToken,
            amount,
            parts,
            flags
        );
    }

    function calculateUniswapV2USDC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken == usdc || destToken == usdc) {
            return (new uint256[](parts), 0);
        }

        return _calculateUniswapV2OverMidToken(
            fromToken,
            usdc,
            destToken,
            amount,
            parts,
            flags
        );
    }

    function _calculateUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = new uint256[](amounts.length);

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 destTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(fromTokenReal, destTokenReal);
        if (exchange != IUniswapV2Exchange(0)) {
            uint256 fromTokenBalance = fromTokenReal.universalBalanceOf(address(exchange));
            uint256 destTokenBalance = destTokenReal.universalBalanceOf(address(exchange));
            for (uint i = 0; i < amounts.length; i++) {
                rets[i] = _calculateUniswapFormula(fromTokenBalance, destTokenBalance, amounts[i]);
            }
            return (rets, 50_000);
        }
    }

    function _calculateUniswapV2OverMidToken(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = _linearInterpolation(amount, parts);

        uint256 gas1;
        uint256 gas2;
        (rets, gas1) = _calculateUniswapV2(fromToken, midToken, rets, flags);
        (rets, gas2) = _calculateUniswapV2(midToken, destToken, rets, flags);
        return (rets, gas1 + gas2);
    }

    function _calculateNoReturn(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 /*amount*/,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        this;
        return (new uint256[](parts), 0);
    }
}


contract OneSplitBaseWrap is IOneSplit, OneSplitRoot {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags // See constants in IOneSplit.sol
    ) internal {
        if (fromToken == destToken) {
            return;
        }

        _swapFloor(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _swapFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 /*flags*/ // See constants in IOneSplit.sol
    ) internal;
}


contract OneSplit is IOneSplit, OneSplitRoot {
    IOneSplitView public oneSplitView;

    constructor(IOneSplitView _oneSplitView) public {
        oneSplitView = _oneSplitView;
    }

    function() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        (returnAmount, , distribution) = getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return oneSplitView.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags  // See constants in IOneSplit.sol
    ) public payable returns(uint256 returnAmount) {
        if (fromToken == destToken) {
            return amount;
        }

        function(IERC20,IERC20,uint256,uint256)[DEXES_COUNT] memory reserves = [
            _swapOnUniswap,
            _swapOnNowhere,
            _swapOnBancor,
            _swapOnOasis,
            _swapOnCurveCompound,
            _swapOnCurveUSDT,
            _swapOnCurveY,
            _swapOnCurveBinance,
            _swapOnCurveSynthetix,
            _swapOnUniswapCompound,
            _swapOnUniswapChai,
            _swapOnUniswapAave,
            _swapOnMooniswap,
            _swapOnUniswapV2,
            _swapOnUniswapV2ETH,
            _swapOnUniswapV2DAI,
            _swapOnUniswapV2USDC,
            _swapOnCurvePAX,
            _swapOnCurveRenBTC,
            _swapOnCurveTBTC,
            _swapOnDforceSwap,
            _swapOnShell,
            _swapOnMStableMUSD,
            _swapOnCurveSBTC,
            _swapOnBalancer1,
            _swapOnBalancer2,
            _swapOnBalancer3,
            _swapOnKyber1,
            _swapOnKyber2,
            _swapOnKyber3,
            _swapOnKyber4,
            _swapOnMooniswapETH,
            _swapOnMooniswapDAI,
            _swapOnMooniswapUSDC
        ];

        require(distribution.length <= reserves.length, "OneSplit: Distribution array should not exceed reserves array size");

        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i] > 0) {
                parts = parts.add(distribution[i]);
                lastNonZeroIndex = i;
            }
        }

        if (parts == 0) {
            if (fromToken.isETH()) {
                msg.sender.transfer(msg.value);
                return msg.value;
            }
            return amount;
        }

        fromToken.universalTransferFrom(msg.sender, address(this), amount);
        uint256 remainingAmount = fromToken.universalBalanceOf(address(this));

        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i] == 0) {
                continue;
            }

            uint256 swapAmount = amount.mul(distribution[i]).div(parts);
            if (i == lastNonZeroIndex) {
                swapAmount = remainingAmount;
            }
            remainingAmount -= swapAmount;
            reserves[i](fromToken, destToken, swapAmount, flags);
        }

        returnAmount = destToken.universalBalanceOf(address(this));
        require(returnAmount >= minReturn, "OneSplit: Return amount was not enough");
        destToken.universalTransfer(msg.sender, returnAmount);
        fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));
    }

    // Swap helpers

    function _swapOnCurveCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) + (fromToken == usdc ? 2 : 0);
        int128 j = (destToken == dai ? 1 : 0) + (destToken == usdc ? 2 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveCompound), amount);
        curveCompound.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveUSDT(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveUSDT), amount);
        curveUSDT.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveY(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == tusd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == tusd ? 4 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveY), amount);
        curveY.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveBinance(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == busd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == busd ? 4 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveBinance), amount);
        curveBinance.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveSynthetix(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == susd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == susd ? 4 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveSynthetix), amount);
        curveSynthetix.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurvePAX(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == pax ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == pax ? 4 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curvePAX), amount);
        curvePAX.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnShell(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        fromToken.universalApprove(address(shell), amount);
        shell.swapByOrigin(
            address(fromToken),
            address(destToken),
            amount,
            0,
            now + 50
        );
    }

    function _swapOnMStableMUSD(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        fromToken.universalApprove(address(musd), amount);
        musd.swap(
            fromToken,
            destToken,
            amount,
            address(this)
        );
    }

    function _swapOnCurveRenBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == renbtc ? 1 : 0) +
            (fromToken == wbtc ? 2 : 0);
        int128 j = (destToken == renbtc ? 1 : 0) +
            (destToken == wbtc ? 2 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveRenBTC), amount);
        curveRenBTC.exchange(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveTBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == tbtc ? 1 : 0) +
            (fromToken == wbtc ? 2 : 0) +
            (fromToken == hbtc ? 3 : 0);
        int128 j = (destToken == tbtc ? 1 : 0) +
            (destToken == wbtc ? 2 : 0) +
            (destToken == hbtc ? 3 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveTBTC), amount);
        curveTBTC.exchange(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveSBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == renbtc ? 1 : 0) +
            (fromToken == wbtc ? 2 : 0) +
            (fromToken == sbtc ? 3 : 0);
        int128 j = (destToken == renbtc ? 1 : 0) +
            (destToken == wbtc ? 2 : 0) +
            (destToken == sbtc ? 3 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveSBTC), amount);
        curveSBTC.exchange(i - 1, j - 1, amount, 0);
    }

    function _swapOnDforceSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        fromToken.universalApprove(address(dforceSwap), amount);
        dforceSwap.swap(fromToken, destToken, amount);
    }

    function _swapOnUniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        uint256 returnAmount = amount;

        if (!fromToken.isETH()) {
            IUniswapExchange fromExchange = uniswapFactory.getExchange(fromToken);
            if (fromExchange != IUniswapExchange(0)) {
                fromToken.universalApprove(address(fromExchange), returnAmount);
                returnAmount = fromExchange.tokenToEthSwapInput(returnAmount, 1, now);
            }
        }

        if (!destToken.isETH()) {
            IUniswapExchange toExchange = uniswapFactory.getExchange(destToken);
            if (toExchange != IUniswapExchange(0)) {
                returnAmount = toExchange.ethToTokenSwapInput.value(returnAmount)(1, now);
            }
        }
    }

    function _swapOnUniswapCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        if (!fromToken.isETH()) {
            ICompoundToken fromCompound = compoundRegistry.cTokenByToken(fromToken);
            fromToken.universalApprove(address(fromCompound), amount);
            fromCompound.mint(amount);
            _swapOnUniswap(IERC20(fromCompound), destToken, IERC20(fromCompound).universalBalanceOf(address(this)), flags);
            return;
        }

        if (!destToken.isETH()) {
            ICompoundToken toCompound = compoundRegistry.cTokenByToken(destToken);
            _swapOnUniswap(fromToken, IERC20(toCompound), amount, flags);
            toCompound.redeem(IERC20(toCompound).universalBalanceOf(address(this)));
            destToken.universalBalanceOf(address(this));
            return;
        }
    }

    function _swapOnUniswapChai(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        if (fromToken == dai) {
            fromToken.universalApprove(address(chai), amount);
            chai.join(address(this), amount);
            _swapOnUniswap(IERC20(chai), destToken, IERC20(chai).universalBalanceOf(address(this)), flags);
            return;
        }

        if (destToken == dai) {
            _swapOnUniswap(fromToken, IERC20(chai), amount, flags);
            chai.exit(address(this), chai.balanceOf(address(this)));
            return;
        }
    }

    function _swapOnUniswapAave(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        if (!fromToken.isETH()) {
            IAaveToken fromAave = aaveRegistry.aTokenByToken(fromToken);
            fromToken.universalApprove(aave.core(), amount);
            aave.deposit(fromToken, amount, 1101);
            _swapOnUniswap(IERC20(fromAave), destToken, IERC20(fromAave).universalBalanceOf(address(this)), flags);
            return;
        }

        if (!destToken.isETH()) {
            IAaveToken toAave = aaveRegistry.aTokenByToken(destToken);
            _swapOnUniswap(fromToken, IERC20(toAave), amount, flags);
            toAave.redeem(toAave.balanceOf(address(this)));
            return;
        }
    }

    function _swapOnMooniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        IMooniswap mooniswap = mooniswapRegistry.pools(
            fromToken.isETH() ? ZERO_ADDRESS : fromToken,
            destToken.isETH() ? ZERO_ADDRESS : destToken
        );
        fromToken.universalApprove(address(mooniswap), amount);
        mooniswap.swap.value(fromToken.isETH() ? amount : 0)(
            fromToken.isETH() ? ZERO_ADDRESS : fromToken,
            destToken.isETH() ? ZERO_ADDRESS : destToken,
            amount,
            0,
            0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5
        );
    }

    function _swapOnMooniswapETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnMooniswap(fromToken, ZERO_ADDRESS, amount, flags);
        _swapOnMooniswap(ZERO_ADDRESS, destToken, address(this).balance, flags);
    }

    function _swapOnMooniswapDAI(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnMooniswap(fromToken, dai, amount, flags);
        _swapOnMooniswap(dai, destToken, dai.balanceOf(address(this)), flags);
    }

    function _swapOnMooniswapUSDC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnMooniswap(fromToken, usdc, amount, flags);
        _swapOnMooniswap(usdc, destToken, usdc.balanceOf(address(this)), flags);
    }

    function _swapOnNowhere(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 /*amount*/,
        uint256 /*flags*/
    ) internal {
        revert("This source was deprecated");
    }

    function _swapOnKyber1(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnKyber(
            fromToken,
            destToken,
            amount,
            flags,
            0xff4b796265722046707200000000000000000000000000000000000000000000
        );
    }

    function _swapOnKyber2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnKyber(
            fromToken,
            destToken,
            amount,
            flags,
            0xffabcd0000000000000000000000000000000000000000000000000000000000
        );
    }

    function _swapOnKyber3(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnKyber(
            fromToken,
            destToken,
            amount,
            flags,
            0xff4f6e65426974205175616e7400000000000000000000000000000000000000
        );
    }

    function _swapOnKyber4(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnKyber(
            fromToken,
            destToken,
            amount,
            flags,
            _kyberReserveIdByTokens(fromToken, destToken)
        );
    }

    function _swapOnKyber(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags,
        bytes32 reserveId
    ) internal {
        uint256 returnAmount = amount;

        bytes32[] memory reserveIds = new bytes32[](1);
        reserveIds[0] = reserveId;

        if (!fromToken.isETH()) {
            bytes memory fromHint = kyberHintHandler.buildTokenToEthHint(
                fromToken,
                IKyberHintHandler.TradeType.MaskIn,
                reserveIds,
                new uint256[](0)
            );

            fromToken.universalApprove(address(kyberNetworkProxy), amount);
            returnAmount = kyberNetworkProxy.tradeWithHintAndFee(
                fromToken,
                returnAmount,
                ETH_ADDRESS,
                address(this),
                uint256(-1),
                0,
                0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5,
                (flags >> 255) * 10,
                fromHint
            );
        }

        if (!destToken.isETH()) {
            bytes memory destHint = kyberHintHandler.buildEthToTokenHint(
                destToken,
                IKyberHintHandler.TradeType.MaskIn,
                reserveIds,
                new uint256[](0)
            );

            returnAmount = kyberNetworkProxy.tradeWithHintAndFee.value(returnAmount)(
                ETH_ADDRESS,
                returnAmount,
                destToken,
                address(this),
                uint256(-1),
                0,
                0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5,
                (flags >> 255) * 10,
                destHint
            );
        }
    }

    function _swapOnBancor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        IBancorNetwork bancorNetwork = IBancorNetwork(bancorContractRegistry.addressOf("BancorNetwork"));
        address[] memory path = bancorNetworkPathFinder.generatePath(
            fromToken.isETH() ? bancorEtherToken : fromToken,
            destToken.isETH() ? bancorEtherToken : destToken
        );
        fromToken.universalApprove(address(bancorNetwork), amount);
        bancorNetwork.convert.value(fromToken.isETH() ? amount : 0)(path, amount, 1);
    }

    function _swapOnOasis(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        if (fromToken.isETH()) {
            weth.deposit.value(amount)();
        }

        IERC20 approveToken = fromToken.isETH() ? weth : fromToken;
        approveToken.universalApprove(address(oasisExchange), amount);
        oasisExchange.sellAllAmount(
            fromToken.isETH() ? weth : fromToken,
            amount,
            destToken.isETH() ? weth : destToken,
            1
        );

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnUniswapV2Internal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal returns(uint256 returnAmount) {
        if (fromToken.isETH()) {
            weth.deposit.value(amount)();
        }

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 toTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(fromTokenReal, toTokenReal);
        bool needSync;
        bool needSkim;
        (returnAmount, needSync, needSkim) = exchange.getReturn(fromTokenReal, toTokenReal, amount);
        if (needSync) {
            exchange.sync();
        }
        else if (needSkim) {
            exchange.skim(0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5);
        }

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint256(address(fromTokenReal)) < uint256(address(toTokenReal))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnUniswapV2OverMid(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnUniswapV2Internal(
            midToken,
            destToken,
            _swapOnUniswapV2Internal(
                fromToken,
                midToken,
                amount,
                flags
            ),
            flags
        );
    }

    function _swapOnUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnUniswapV2Internal(
            fromToken,
            destToken,
            amount,
            flags
        );
    }

    function _swapOnUniswapV2ETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnUniswapV2OverMid(
            fromToken,
            weth,
            destToken,
            amount,
            flags
        );
    }

    function _swapOnUniswapV2DAI(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnUniswapV2OverMid(
            fromToken,
            dai,
            destToken,
            amount,
            flags
        );
    }

    function _swapOnUniswapV2USDC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnUniswapV2OverMid(
            fromToken,
            usdc,
            destToken,
            amount,
            flags
        );
    }

    function _swapOnBalancerX(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/,
        uint256 poolIndex
    ) internal {
        address[] memory pools = balancerRegistry.getBestPoolsWithLimit(
            address(fromToken.isETH() ? weth : fromToken),
            address(destToken.isETH() ? weth : destToken),
            poolIndex + 1
        );

        if (fromToken.isETH()) {
            weth.deposit.value(amount)();
        }

        (fromToken.isETH() ? weth : fromToken).universalApprove(pools[poolIndex], amount);
        IBalancerPool(pools[poolIndex]).swapExactAmountIn(
            fromToken.isETH() ? weth : fromToken,
            amount,
            destToken.isETH() ? weth : destToken,
            0,
            uint256(-1)
        );

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnBalancer1(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnBalancerX(fromToken, destToken, amount, flags, 0);
    }

    function _swapOnBalancer2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnBalancerX(fromToken, destToken, amount, flags, 1);
    }

    function _swapOnBalancer3(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnBalancerX(fromToken, destToken, amount, flags, 2);
    }
}
