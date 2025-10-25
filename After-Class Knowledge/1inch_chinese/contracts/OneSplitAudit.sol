// 指定Solidity编译器版本为0.5.0或更高版本
pragma solidity ^0.5.0;

// === OpenZeppelin标准库导入 ===
// 数学运算库，提供最大值、最小值等数学函数
import "@openzeppelin/contracts/math/Math.sol";
// 所有权管理库，提供onlyOwner修饰符
import "@openzeppelin/contracts/ownership/Ownable.sol";

// === 接口导入 ===
// WETH接口，用于ETH包装
import "./interface/IWETH.sol";
// Uniswap V2交换接口
import "./interface/IUniswapV2Exchange.sol";
// 1inch协议接口
import "./IOneSplit.sol";
// ERC20统一处理库
import "./UniversalERC20.sol";


// === 辅助接口定义 ===
// CHI代币接口，用于gas优化
// CHI是1inch的治理代币，燃烧可以节省gas费用
contract IFreeFromUpTo is IERC20 {
    // 从指定地址燃烧CHI代币，返回燃烧的数量
    function freeFromUpTo(address from, uint256 value) external returns(uint256 freed);
}

// 推荐gas赞助接口
// 允许推荐人支付gas费用
interface IReferralGasSponsor {
    function makeGasDiscount(
        uint256 gasSpent,        // 消耗的gas数量
        uint256 returnAmount,    // 返回的代币数量
        bytes calldata msgSenderCalldata  // 调用者数据
    ) external;
}


// === 数组工具库 ===
// 提供数组操作的辅助函数
library Array {
    // 获取数组的第一个元素
    function first(IERC20[] memory arr) internal pure returns(IERC20) {
        return arr[0];
    }

    // 获取数组的最后一个元素
    function last(IERC20[] memory arr) internal pure returns(IERC20) {
        return arr[arr.length - 1];
    }
}


//
// === 安全假设说明 ===
// 1. 可以安全地无限授权任何代币给此智能合约，
//    因为它只能调用`transferFrom()`，且第一个参数必须等于msg.sender
// 2. 可以安全地调用`swap()`，只要`minReturn`参数可靠，
//    如果返回金额未达到`minReturn`值，整个交换将被回滚
// 3. 此外，CHI代币可以从调用者燃烧（当flags包含FLAG_ENABLE_CHI_BURN 0x10000000000时）
//    或从交易发起者燃烧（当flags包含FLAG_ENABLE_CHI_BURN_BY_ORIGIN 0x4000000000000000时）
//    燃烧的数量可以退还高达43%的gas费用
//
// === 1inch协议主审计合约 ===
// 这是1inch协议的主合约，负责处理实际的代币交换
// 继承IOneSplit接口和Ownable所有权管理
contract OneSplitAudit is IOneSplit, Ownable {
    // === 库导入声明 ===
    // 为uint256类型添加SafeMath安全数学运算
    using SafeMath for uint256;
    // 为IERC20类型添加UniversalERC20扩展功能
    using UniversalERC20 for IERC20;
    // 为IERC20[]类型添加Array扩展功能
    using Array for IERC20[];

    // === 常量定义 ===
    // WETH合约地址 - 以太坊主网标准WETH合约
    IWETH constant internal weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // CHI代币合约地址 - 1inch的治理代币，用于gas优化
    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    // === 状态变量 ===
    // 1inch协议实现合约地址
    // 使用代理模式，可以升级实现合约
    IOneSplitMulti public oneSplitImpl;

    // === 事件定义 ===
    // 实现合约更新事件
    event ImplementationUpdated(address indexed newImpl);

    // 交换完成事件
    // 记录每次交换的详细信息，用于监控和分析
    event Swapped(
        IERC20 indexed fromToken,        // 源代币
        IERC20 indexed destToken,        // 目标代币
        uint256 fromTokenAmount,         // 源代币数量
        uint256 destTokenAmount,         // 目标代币数量
        uint256 minReturn,               // 最小返回金额
        uint256[] distribution,          // 分配方案
        uint256[] flags,                 // 标志位
        address referral,                // 推荐人地址
        uint256 feePercent               // 手续费百分比
    );

    // === 构造函数 ===
    // 初始化合约，设置实现合约地址
    constructor(IOneSplitMulti impl) public {
        setNewImpl(impl);
    }

    // === 回退函数 ===
    // 防止直接向合约发送ETH
    function() external payable {
        // 要求调用者不是交易发起者，防止直接发送ETH
        require(msg.sender != tx.origin, "OneSplit: do not send ETH directly");
    }

    // === 管理员函数 ===
    // 设置新的实现合约地址
    // 只有合约所有者可以调用
    function setNewImpl(IOneSplitMulti impl) public onlyOwner {
        oneSplitImpl = impl;
        emit ImplementationUpdated(address(impl));
    }

    /// @notice Calculate expected returning amount of `destToken`
    /// @param fromToken (IERC20) Address of token or `address(0)` for Ether
    /// @param destToken (IERC20) Address of token or `address(0)` for Ether
    /// @param amount (uint256) Amount for `fromToken`
    /// @param parts (uint256) Number of pieces source volume could be splitted,
    /// works like granularity, higly affects gas usage. Should be called offchain,
    /// but could be called onchain if user swaps not his own funds, but this is still considered as not safe.
    /// @param flags (uint256) Flags for enabling and disabling some features, default 0
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See contants in IOneSplit.sol
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

    /// @notice Calculate expected returning amount of `destToken`
    /// @param fromToken (IERC20) Address of token or `address(0)` for Ether
    /// @param destToken (IERC20) Address of token or `address(0)` for Ether
    /// @param amount (uint256) Amount for `fromToken`
    /// @param parts (uint256) Number of pieces source volume could be splitted,
    /// works like granularity, higly affects gas usage. Should be called offchain,
    /// but could be called onchain if user swaps not his own funds, but this is still considered as not safe.
    /// @param flags (uint256) Flags for enabling and disabling some features, default 0
    /// @param destTokenEthPriceTimesGasPrice (uint256) destToken price to ETH multiplied by gas price
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
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
        return oneSplitImpl.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    /// @notice Calculate expected returning amount of first `tokens` element to
    /// last `tokens` element through ann the middle tokens with corresponding
    /// `parts`, `flags` and `destTokenEthPriceTimesGasPrices` array values of each step
    /// @param tokens (IERC20[]) Address of token or `address(0)` for Ether
    /// @param amount (uint256) Amount for `fromToken`
    /// @param parts (uint256[]) Number of pieces source volume could be splitted
    /// @param flags (uint256[]) Flags for enabling and disabling some features, default 0
    /// @param destTokenEthPriceTimesGasPrices (uint256[]) destToken price to ETH multiplied by gas price
    function getExpectedReturnWithGasMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256[] memory parts,
        uint256[] memory flags,
        uint256[] memory destTokenEthPriceTimesGasPrices
    )
        public
        view
        returns(
            uint256[] memory returnAmounts,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return oneSplitImpl.getExpectedReturnWithGasMulti(
            tokens,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrices
        );
    }

    /// @notice Swap `amount` of `fromToken` to `destToken`
    /// @param fromToken (IERC20) Address of token or `address(0)` for Ether
    /// @param destToken (IERC20) Address of token or `address(0)` for Ether
    /// @param amount (uint256) Amount for `fromToken`
    /// @param minReturn (uint256) Minimum expected return, else revert
    /// @param distribution (uint256[]) Array of weights for volume distribution returned by `getExpectedReturn`
    /// @param flags (uint256) Flags for enabling and disabling some features, default 0
    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags // See contants in IOneSplit.sol
    ) public payable returns(uint256) {
        return swapWithReferral(
            fromToken,
            destToken,
            amount,
            minReturn,
            distribution,
            flags,
            address(0),
            0
        );
    }

    /// @notice Swap `amount` of `fromToken` to `destToken`
    /// param fromToken (IERC20) Address of token or `address(0)` for Ether
    /// param destToken (IERC20) Address of token or `address(0)` for Ether
    /// @param amount (uint256) Amount for `fromToken`
    /// @param minReturn (uint256) Minimum expected return, else revert
    /// @param distribution (uint256[]) Array of weights for volume distribution returned by `getExpectedReturn`
    /// @param flags (uint256) Flags for enabling and disabling some features, default 0
    /// @param referral (address) Address of referral
    /// @param feePercent (uint256) Fees percents normalized to 1e18, limited to 0.03e18 (3%)
    function swapWithReferral(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags, // See contants in IOneSplit.sol
        address referral,
        uint256 feePercent
    ) public payable returns(uint256) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = fromToken;
        tokens[1] = destToken;

        uint256[] memory flagsArray = new uint256[](1);
        flagsArray[0] = flags;

        swapWithReferralMulti(
            tokens,
            amount,
            minReturn,
            distribution,
            flagsArray,
            referral,
            feePercent
        );
    }

    /// @notice Swap `amount` of first element of `tokens` to the latest element of `destToken`
    /// @param tokens (IERC20[]) Addresses of token or `address(0)` for Ether
    /// @param amount (uint256) Amount for `fromToken`
    /// @param minReturn (uint256) Minimum expected return, else revert
    /// @param distribution (uint256[]) Array of weights for volume distribution returned by `getExpectedReturn`
    /// @param flags (uint256[]) Flags for enabling and disabling some features, default 0
    function swapMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256[] memory flags
    ) public payable returns(uint256) {
        swapWithReferralMulti(
            tokens,
            amount,
            minReturn,
            distribution,
            flags,
            address(0),
            0
        );
    }

    /// @notice Swap `amount` of first element of `tokens` to the latest element of `destToken`
    /// @param tokens (IERC20[]) Addresses of token or `address(0)` for Ether
    /// @param amount (uint256) Amount for `fromToken`
    /// @param minReturn (uint256) Minimum expected return, else revert
    /// @param distribution (uint256[]) Array of weights for volume distribution returned by `getExpectedReturn`
    /// @param flags (uint256[]) Flags for enabling and disabling some features, default 0
    /// @param referral (address) Address of referral
    /// @param feePercent (uint256) Fees percents normalized to 1e18, limited to 0.03e18 (3%)
    function swapWithReferralMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256[] memory flags,
        address referral,
        uint256 feePercent
    ) public payable returns(uint256 returnAmount) {
        require(tokens.length >= 2 && amount > 0, "OneSplit: swap makes no sense");
        require(flags.length == tokens.length - 1, "OneSplit: flags array length is invalid");
        require((msg.value != 0) == tokens.first().isETH(), "OneSplit: msg.value should be used only for ETH swap");
        require(feePercent <= 0.03e18, "OneSplit: feePercent out of range");

        uint256 gasStart = gasleft();

        Balances memory beforeBalances = _getFirstAndLastBalances(tokens, true);

        // Transfer From
        if (amount == uint256(-1)) {
            amount = Math.min(
                tokens.first().balanceOf(msg.sender),
                tokens.first().allowance(msg.sender, address(this))
            );
        }
        tokens.first().universalTransferFromSenderToThis(amount);
        uint256 confirmed = tokens.first().universalBalanceOf(address(this)).sub(beforeBalances.ofFromToken);

        // Swap
        tokens.first().universalApprove(address(oneSplitImpl), confirmed);
        oneSplitImpl.swapMulti.value(tokens.first().isETH() ? confirmed : 0)(
            tokens,
            confirmed,
            minReturn,
            distribution,
            flags
        );

        Balances memory afterBalances = _getFirstAndLastBalances(tokens, false);

        // Return
        returnAmount = afterBalances.ofDestToken.sub(beforeBalances.ofDestToken);
        require(returnAmount >= minReturn, "OneSplit: actual return amount is less than minReturn");
        tokens.last().universalTransfer(referral, returnAmount.mul(feePercent).div(1e18));
        tokens.last().universalTransfer(msg.sender, returnAmount.sub(returnAmount.mul(feePercent).div(1e18)));

        emit Swapped(
            tokens.first(),
            tokens.last(),
            amount,
            returnAmount,
            minReturn,
            distribution,
            flags,
            referral,
            feePercent
        );

        // Return remainder
        if (afterBalances.ofFromToken > beforeBalances.ofFromToken) {
            tokens.first().universalTransfer(msg.sender, afterBalances.ofFromToken.sub(beforeBalances.ofFromToken));
        }

        if ((flags[0] & (FLAG_ENABLE_CHI_BURN | FLAG_ENABLE_CHI_BURN_BY_ORIGIN)) > 0) {
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            _chiBurnOrSell(
                ((flags[0] & FLAG_ENABLE_CHI_BURN_BY_ORIGIN) > 0) ? tx.origin : msg.sender,
                (gasSpent + 14154) / 41947
            );
        }
        else if ((flags[0] & FLAG_ENABLE_REFERRAL_GAS_SPONSORSHIP) > 0) {
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            IReferralGasSponsor(referral).makeGasDiscount(gasSpent, returnAmount, msg.data);
        }
    }

    function claimAsset(IERC20 asset, uint256 amount) public onlyOwner {
        asset.universalTransfer(msg.sender, amount);
    }

    function _chiBurnOrSell(address payable sponsor, uint256 amount) internal {
        IUniswapV2Exchange exchange = IUniswapV2Exchange(0xa6f3ef841d371a82ca757FaD08efc0DeE2F1f5e2);
        (uint256 sellRefund,,) = UniswapV2ExchangeLib.getReturn(exchange, chi, weth, amount);
        uint256 burnRefund = amount.mul(18_000).mul(tx.gasprice);

        if (sellRefund < burnRefund.add(tx.gasprice.mul(36_000))) {
            chi.freeFromUpTo(sponsor, amount);
        }
        else {
            chi.transferFrom(sponsor, address(exchange), amount);
            exchange.swap(0, sellRefund, address(this), "");
            weth.withdraw(weth.balanceOf(address(this)));
            sponsor.transfer(address(this).balance);
        }
    }

    struct Balances {
        uint256 ofFromToken;
        uint256 ofDestToken;
    }

    function _getFirstAndLastBalances(IERC20[] memory tokens, bool subValue) internal view returns(Balances memory) {
        return Balances({
            ofFromToken: tokens.first().universalBalanceOf(address(this)).sub(subValue ? msg.value : 0),
            ofDestToken: tokens.last().universalBalanceOf(address(this))
        });
    }
}
