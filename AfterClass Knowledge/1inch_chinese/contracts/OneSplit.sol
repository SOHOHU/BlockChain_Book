// 指定Solidity编译器版本为0.5.0或更高版本
pragma solidity ^0.5.0;

// === 核心接口导入 ===
// 1inch协议主接口
import "./IOneSplit.sol";
// 1inch协议基础实现
import "./OneSplitBase.sol";

// === 各种DEX协议集成导入 ===
// Compound协议集成
import "./OneSplitCompound.sol";
// Fulcrum协议集成
import "./OneSplitFulcrum.sol";
// Chai协议集成
import "./OneSplitChai.sol";
// bDai协议集成
import "./OneSplitBdai.sol";
// iEarn协议集成
import "./OneSplitIearn.sol";
// Idle协议集成
import "./OneSplitIdle.sol";
// Aave协议集成
import "./OneSplitAave.sol";
// WETH协议集成
import "./OneSplitWeth.sol";
// mStable协议集成
import "./OneSplitMStable.sol";
// DMM协议集成
import "./OneSplitDMM.sol";
// Mooniswap池代币集成
import "./OneSplitMooniswapPoolToken.sol";


// === 1inch协议视图包装合约 ===
// 这个合约集成了所有DEX协议的视图功能
// 通过多重继承实现模块化的DEX集成
contract OneSplitViewWrap is
    OneSplitViewWrapBase,           // 基础视图功能
    OneSplitMStableView,            // mStable协议视图
    OneSplitChaiView,               // Chai协议视图
    OneSplitBdaiView,               // bDai协议视图
    OneSplitAaveView,               // Aave协议视图
    OneSplitFulcrumView,            // Fulcrum协议视图
    OneSplitCompoundView,           // Compound协议视图
    OneSplitIearnView,              // iEarn协议视图
    OneSplitIdleView,               // Idle协议视图
    OneSplitWethView,               // WETH协议视图
    OneSplitDMMView,                // DMM协议视图
    OneSplitMooniswapTokenView      // Mooniswap代币视图
{
    // === 状态变量 ===
    // 1inch协议视图合约地址
    // 用于委托视图查询功能
    IOneSplitView public oneSplitView;

    // === 构造函数 ===
    // 初始化合约，设置1inch协议视图合约地址
    constructor(IOneSplitView _oneSplit) public {
        oneSplitView = _oneSplit;
    }

    // === 视图函数 ===
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
        // 如果源代币和目标代币相同，直接返回原数量
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        // 调用父类的getExpectedReturnWithGas函数
        // 这里会使用所有集成的DEX协议进行计算
        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _getExpectedReturnRespectingGasFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        internal
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
}


contract OneSplitWrap is
    OneSplitBaseWrap,
    OneSplitMStable,
    OneSplitChai,
    OneSplitBdai,
    OneSplitAave,
    OneSplitFulcrum,
    OneSplitCompound,
    OneSplitIearn,
    OneSplitIdle,
    OneSplitWeth,
    OneSplitDMM,
    OneSplitMooniswapToken
{
    IOneSplitView public oneSplitView;
    IOneSplit public oneSplit;

    constructor(IOneSplitView _oneSplitView, IOneSplit _oneSplit) public {
        oneSplitView = _oneSplitView;
        oneSplit = _oneSplit;
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
        uint256[] memory dist;

        returnAmounts = new uint256[](tokens.length - 1);
        for (uint i = 1; i < tokens.length; i++) {
            if (tokens[i - 1] == tokens[i]) {
                returnAmounts[i - 1] = (i == 1) ? amount : returnAmounts[i - 2];
                continue;
            }

            IERC20[] memory _tokens = tokens;

            (
                returnAmounts[i - 1],
                amount,
                dist
            ) = getExpectedReturnWithGas(
                _tokens[i - 1],
                _tokens[i],
                (i == 1) ? amount : returnAmounts[i - 2],
                parts[i - 1],
                flags[i - 1],
                destTokenEthPriceTimesGasPrices[i - 1]
            );
            estimateGasAmount = estimateGasAmount.add(amount);

            if (distribution.length == 0) {
                distribution = new uint256[](dist.length);
            }
            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] = distribution[j].add(dist[j] << (8 * (i - 1)));
            }
        }
    }

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags
    ) public payable returns(uint256 returnAmount) {
        fromToken.universalTransferFrom(msg.sender, address(this), amount);
        uint256 confirmed = fromToken.universalBalanceOf(address(this));
        _swap(fromToken, destToken, confirmed, distribution, flags);

        returnAmount = destToken.universalBalanceOf(address(this));
        require(returnAmount >= minReturn, "OneSplit: actual return amount is less than minReturn");
        destToken.universalTransfer(msg.sender, returnAmount);
        fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));
    }

    function swapMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256[] memory flags
    ) public payable returns(uint256 returnAmount) {
        tokens[0].universalTransferFrom(msg.sender, address(this), amount);

        returnAmount = tokens[0].universalBalanceOf(address(this));
        for (uint i = 1; i < tokens.length; i++) {
            if (tokens[i - 1] == tokens[i]) {
                continue;
            }

            uint256[] memory dist = new uint256[](distribution.length);
            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (8 * (i - 1))) & 0xFF;
            }

            _swap(
                tokens[i - 1],
                tokens[i],
                returnAmount,
                dist,
                flags[i - 1]
            );
            returnAmount = tokens[i].universalBalanceOf(address(this));
            tokens[i - 1].universalTransfer(msg.sender, tokens[i - 1].universalBalanceOf(address(this)));
        }

        require(returnAmount >= minReturn, "OneSplit: actual return amount is less than minReturn");
        tokens[tokens.length - 1].universalTransfer(msg.sender, returnAmount);
    }

    function _swapFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        fromToken.universalApprove(address(oneSplit), amount);
        oneSplit.swap.value(fromToken.isETH() ? amount : 0)(
            fromToken,
            destToken,
            amount,
            0,
            distribution,
            flags
        );
    }
}
