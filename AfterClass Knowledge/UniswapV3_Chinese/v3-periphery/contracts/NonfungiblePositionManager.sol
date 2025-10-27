// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint128.sol';
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';

import './interfaces/INonfungiblePositionManager.sol';
import './interfaces/INonfungibleTokenPositionDescriptor.sol';
import './libraries/PositionKey.sol';
import './libraries/PoolAddress.sol';
import './base/LiquidityManagement.sol';
import './base/PeripheryImmutableState.sol';
import './base/Multicall.sol';
import './base/ERC721Permit.sol';
import './base/PeripheryValidation.sol';
import './base/SelfPermit.sol';
import './base/PoolInitializer.sol';

/// @title NFT positions
/// @notice Wraps Uniswap V3 positions in the ERC721 non-fungible token interface
contract NonfungiblePositionManager is
    INonfungiblePositionManager,
    Multicall,
    ERC721Permit,
    PeripheryImmutableState,
    PoolInitializer,
    LiquidityManagement,
    PeripheryValidation,
    SelfPermit
{
    // details about the uniswap position
    // 这是一个非常关键的数据结构，它定义了每个头寸拥有的所有数据
    // 1、一个区间，多个头寸；如果多个用户对一个区间注入流动性，那么该区间会有多个position对应这些用户注入的流动性
    // 2、一个用户，多个头寸；如果一个用户对不同的区间注入了流动性，那么也会产生不同的position保存这个用户在不同区间的流动性注入数据
    struct Position {
        // 用于权限验证的计数器
        uint96 nonce;
        // 被授权管理此 LP Token 的地址
        address operator;
        // 该 LP Token 对应的流动性池的唯一标识符
        uint80 poolId;
        // 该 LP Token 所在的流动性价格区间
        int24 tickLower;
        int24 tickUpper;
        // 该 LP Token 所代表的流动性数量
        uint128 liquidity;
        // 记录了上次操作时，在指定价格区间内累积的费用增长快照。这用于计算未领取的费用
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        // 未被领取的费用数量
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    /// 将流动性池地址映射到一个唯一的 poolId
    mapping(address => uint80) private _poolIds;

    /// 将 poolId 映射回完整的 PoolKey 结构体
    // 这里用连续映射取代了二维映射，节省空间
    mapping(uint80 => PoolAddress.PoolKey) private _poolIdToPoolKey;

    /// 将每个 LP Token 的 tokenId 映射到其对应的 Position 结构体
    mapping(uint256 => Position) private _positions;

    /// 下一个将被铸造的 LP Token 的 ID。从 1 开始，因为 0 代表空值
    uint176 private _nextId = 1;
    /// 下一个将被分配 ID 的流动性池的 ID。也从 1 开始
    uint80 private _nextPoolId = 1;

    /// 存储了 NonfungibleTokenPositionDescriptor 合约的地址
    address private immutable _tokenDescriptor;
    // 构造函数，比较简单
    constructor(
        address _factory,
        address _WETH9,
        address _tokenDescriptor_
    ) ERC721Permit('Uniswap V3 Positions NFT-V1', 'UNI-V3-POS', '1') PeripheryImmutableState(_factory, _WETH9) {
        _tokenDescriptor = _tokenDescriptor_;
    }

    /// @inheritdoc INonfungiblePositionManager
    // 用于查询特定 tokenId LP Token 的所有详细数据 
    // view+external 说明公共可见不可改，比较简单 
    function positions(uint256 tokenId)
        external
        view
        override
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        Position memory position = _positions[tokenId];
        require(position.poolId != 0, 'Invalid token ID');
        PoolAddress.PoolKey memory poolKey = _poolIdToPoolKey[position.poolId];
        return (
            position.nonce,
            position.operator,
            poolKey.token0,
            poolKey.token1,
            poolKey.fee,
            position.tickLower,
            position.tickUpper,
            position.liquidity,
            position.feeGrowthInside0LastX128,
            position.feeGrowthInside1LastX128,
            position.tokensOwed0,
            position.tokensOwed1
        );
    }

    /// @dev Caches a pool key
    // 这是一个内部（private）函数，用于为新的流动性池分配一个唯一的 poolId，并将池子的 PoolKey 存储在映射中 
    function cachePoolKey(address pool, PoolAddress.PoolKey memory poolKey) private returns (uint80 poolId) {
        // 这行代码尝试从一个映射（mapping）中查找该流动性池的 ID。
        poolId = _poolIds[pool];
        // 如果 poolId 为 0，表示这是一个新的池子，需要为其分配一个新的 poolId。
        if (poolId == 0) {
            // 这行代码是这个函数最核心的部分。
            // `_nextPoolId` 是一个计数器，每次为新池子分配 ID 时，它都会自动递增。
            // `(poolId = _nextPoolId++)` 这段代码的意思是：
            // 1. 将 `_nextPoolId` 的当前值赋给 `poolId`。
            // 2. 然后，`_nextPoolId` 自身加 1，为下一个新池子做准备。
            _poolIds[pool] = (poolId = _nextPoolId++);

            // 这行代码将新分配的 poolId 与完整的 PoolKey 结构体关联起来。
            // 就像是把完整的“门禁卡信息”存储在了一个“查询表”里，以便未来需要时可以查阅。
            _poolIdToPoolKey[poolId] = poolKey;
        }
    }

    /// @inheritdoc INonfungiblePositionManager
    // 用户创建一个新的 LP Token，将代币存入流动性池
    function mint(MintParams calldata params)
        external
        payable
        override
        checkDeadline(params.deadline)
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        IUniswapV3Pool pool;
        // 它计算了实际存入的流动性和代币数量
        // 尽管铸造 LP Token 的权利对公众开放，但这个过程是完全安全的，基于以下三点
        // 1、只有在这些代币成功转移，并且 liquidity 大于 0 的情况下，addLiquidity 才会成功返回
        // 2、_mint 函数它必须是在用户的代币已经存入池子并计算出相应的流动性之后才能进行。
        // 3、每个铸造出来的 LP Token（NFT）都与一个 Position 结构体绑定
        (liquidity, amount0, amount1, pool) = addLiquidity(
            AddLiquidityParams({
                token0: params.token0,
                token1: params.token1,
                fee: params.fee,
                recipient: address(this),
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                amount0Desired: params.amount0Desired,
                amount1Desired: params.amount1Desired,
                amount0Min: params.amount0Min,
                amount1Min: params.amount1Min
            })
        );
        // 调用 ERC-721 父合约中的内部函数，为指定地址 (params.recipient) 铸造一个新代币，并递增 _nextId
        _mint(params.recipient, (tokenId = _nextId++));

        // 获取LP Token
        bytes32 positionKey = PositionKey.compute(address(this), params.tickLower, params.tickUpper);
        // 获取当前价格范围内的费用增长情况
        (, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) = pool.positions(positionKey);

        // idempotent set
        // 获取poolId
        uint80 poolId =
            cachePoolKey(
                address(pool),
                PoolAddress.PoolKey({token0: params.token0, token1: params.token1, fee: params.fee})
            );
        //使用新生成的 tokenId 作为键，存储一个完整的 Position 结构体，包括流动性数量和费用快照等信息，代表这个LP Token铸造成功
        _positions[tokenId] = Position({
            nonce: 0,
            operator: address(0),
            poolId: poolId,
            tickLower: params.tickLower,
            tickUpper: params.tickUpper,
            liquidity: liquidity,
            feeGrowthInside0LastX128: feeGrowthInside0LastX128,
            feeGrowthInside1LastX128: feeGrowthInside1LastX128,
            tokensOwed0: 0,
            tokensOwed1: 0
        });

        emit IncreaseLiquidity(tokenId, liquidity, amount0, amount1);
    }
    // 在执行函数前进行权限验证。
    modifier isAuthorizedForToken(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), 'Not approved');
        _;
    }
    // 用于返回指定 tokenId LP Token 的元数据 URI
    function tokenURI(uint256 tokenId) public view override(ERC721, IERC721Metadata) returns (string memory) {
        require(_exists(tokenId));
        return INonfungibleTokenPositionDescriptor(_tokenDescriptor).tokenURI(this, tokenId);
    }

    // save bytecode by removing implementation of unused method
    // 通过移除未使用的函数实现来节省字节码
    function baseURI() public pure override returns (string memory) {}

    /// @inheritdoc INonfungiblePositionManager
    // 允许 LP Token 持有者向已有的tick中增加更多流动性
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        override
        checkDeadline(params.deadline)
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        // 获取指定 tokenId 对应的LP Token数据，`storage` 关键字意味着直接操作链上存储
        Position storage position = _positions[params.tokenId];

        PoolAddress.PoolKey memory poolKey = _poolIdToPoolKey[position.poolId];

        IUniswapV3Pool pool;
        // 调用父合约的 addLiquidity 函数，增加流动性
        (liquidity, amount0, amount1, pool) = addLiquidity(
            AddLiquidityParams({
                token0: poolKey.token0,
                token1: poolKey.token1,
                fee: poolKey.fee,
                tickLower: position.tickLower,
                tickUpper: position.tickUpper,
                amount0Desired: params.amount0Desired,
                amount1Desired: params.amount1Desired,
                amount0Min: params.amount0Min,
                amount1Min: params.amount1Min,
                recipient: address(this)
            })
        );
        // 计算 positionKey，用于在 Pool 合约中标识该LP Token的位置
        bytes32 positionKey = PositionKey.compute(address(this), position.tickLower, position.tickUpper);

        // 调用 Uniswap V3 核心池子的 positions 视图函数，获取最新的费用增长数据
        (, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) = pool.positions(positionKey);

        // 计算并更新 LP Token 已经累积但尚未被收集的费用
        // Uniswap V3 的设计理念是懒惰更新。它不会主动去遍历每一个 LP Token，实时更新他们的价值
        // 它只在以下两种情况被动地进行计算和更新：
        // 1、有人在你所在的 tick 价格区间内进行交易：这会导致 feeGrowthInside 值的更新。
        // 2、你作为 LP，主动与合约交互：当你调用 increaseLiquidity、decreaseLiquidity 或 collect 函数时，合约会：
        // 读取当前的公共 feeGrowthInside 值。读取你 LP Token 中存储的旧快照值（feeGrowthInside...LastX128）。用两者之差来计算你在这段时间里应得的费用。将这部分费用加到你的 tokensOwed 余额上。用最新的 feeGrowthInside 值来更新你的快照，以便下次计算
        // 换句话说，因为手续费不断堆积在feeGrowthInside中（两种代币都会），每次再添加或者移除流动性的时候，才会把这个多出来的价值交给你
        // 多出来的价值以tokensOwed0和tokensOwed1的形式存储
        position.tokensOwed0 += uint128(
            FullMath.mulDiv(
                feeGrowthInside0LastX128 - position.feeGrowthInside0LastX128,
                position.liquidity,
                FixedPoint128.Q128
            )
        );
        position.tokensOwed1 += uint128(
            FullMath.mulDiv(
                feeGrowthInside1LastX128 - position.feeGrowthInside1LastX128,
                position.liquidity,
                FixedPoint128.Q128
            )
        );
        // 更新 LP Token 的状态
        position.feeGrowthInside0LastX128 = feeGrowthInside0LastX128;
        position.feeGrowthInside1LastX128 = feeGrowthInside1LastX128;
        position.liquidity += liquidity;

        emit IncreaseLiquidity(params.tokenId, liquidity, amount0, amount1);
    }

    /// @inheritdoc INonfungiblePositionManager
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        override
        isAuthorizedForToken(params.tokenId)
        checkDeadline(params.deadline)
        returns (uint256 amount0, uint256 amount1)
    {
        // 确保用户想要移除的流动性数量大于零
        require(params.liquidity > 0);
        Position storage position = _positions[params.tokenId];

        uint128 positionLiquidity = position.liquidity;
        // 它确保用户请求移除的流动性数量不超过其 LP Token 当前持有的流动性总量
        require(positionLiquidity >= params.liquidity);

        // 移除LP Token 比较简单，burn函数后面会说
        PoolAddress.PoolKey memory poolKey = _poolIdToPoolKey[position.poolId];
        IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));
        (amount0, amount1) = pool.burn(position.tickLower, position.tickUpper, params.liquidity);
        // 滑点保护（slippage protection）。它检查实际收回的代币数量是否满足用户设定的最低要求
        require(amount0 >= params.amount0Min && amount1 >= params.amount1Min, 'Price slippage check');

        bytes32 positionKey = PositionKey.compute(address(this), position.tickLower, position.tickUpper);
        // this is now updated to the current transaction
        (, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) = pool.positions(positionKey);
        // 同理，不多赘述
        position.tokensOwed0 +=
            uint128(amount0) +
            uint128(
                FullMath.mulDiv(
                    feeGrowthInside0LastX128 - position.feeGrowthInside0LastX128,
                    positionLiquidity,
                    FixedPoint128.Q128
                )
            );
        position.tokensOwed1 +=
            uint128(amount1) +
            uint128(
                FullMath.mulDiv(
                    feeGrowthInside1LastX128 - position.feeGrowthInside1LastX128,
                    positionLiquidity,
                    FixedPoint128.Q128
                )
            );

        position.feeGrowthInside0LastX128 = feeGrowthInside0LastX128;
        position.feeGrowthInside1LastX128 = feeGrowthInside1LastX128;
        // subtraction is safe because we checked positionLiquidity is gte params.liquidity
        position.liquidity = positionLiquidity - params.liquidity;

        emit DecreaseLiquidity(params.tokenId, params.liquidity, amount0, amount1);
    }

    /// @inheritdoc INonfungiblePositionManager
    function collect(CollectParams calldata params)
        external
        payable
        override
        isAuthorizedForToken(params.tokenId)
        returns (uint256 amount0, uint256 amount1)
    {
        require(params.amount0Max > 0 || params.amount1Max > 0);
        // allow collecting to the nft position manager address with address 0
        // 通过将 recipient 地址设置为 0，设置地址为合约地址。让合约来执行这个事儿
        address recipient = params.recipient == address(0) ? address(this) : params.recipient;

        Position storage position = _positions[params.tokenId];

        PoolAddress.PoolKey memory poolKey = _poolIdToPoolKey[position.poolId];

        IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));

        (uint128 tokensOwed0, uint128 tokensOwed1) = (position.tokensOwed0, position.tokensOwed1);

        // trigger an update of the position fees owed and fee growth snapshots if it has any liquidity
        // 仍有流动性，触发一次费用更新，并更新费用增长快照
        if (position.liquidity > 0) {
            // 并不会移除任何流动性。它的唯一目的就是触发 Uniswap V3 核心池子合约，强制其在这次交易中更新 LP Token 所在价格区间的 feeGrowthInside 状态
            pool.burn(position.tickLower, position.tickUpper, 0);
            (, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) =
                pool.positions(PositionKey.compute(address(this), position.tickLower, position.tickUpper));

            tokensOwed0 += uint128(
                FullMath.mulDiv(
                    feeGrowthInside0LastX128 - position.feeGrowthInside0LastX128,
                    position.liquidity,
                    FixedPoint128.Q128
                )
            );
            tokensOwed1 += uint128(
                FullMath.mulDiv(
                    feeGrowthInside1LastX128 - position.feeGrowthInside1LastX128,
                    position.liquidity,
                    FixedPoint128.Q128
                )
            );

            position.feeGrowthInside0LastX128 = feeGrowthInside0LastX128;
            position.feeGrowthInside1LastX128 = feeGrowthInside1LastX128;
        }

        // compute the arguments to give to the pool#collect method
        // 计算实际要领取的费用数量，这个三元运算符之前见过很多次了
        (uint128 amount0Collect, uint128 amount1Collect) =
            (
                params.amount0Max > tokensOwed0 ? tokensOwed0 : params.amount0Max,
                params.amount1Max > tokensOwed1 ? tokensOwed1 : params.amount1Max
            );

        // the actual amounts collected are returned
        // 实际收集的代币数量被返回
        (amount0, amount1) = pool.collect(
            recipient,
            position.tickLower,
            position.tickUpper,
            amount0Collect,
            amount1Collect
        );

        // sometimes there will be a few less wei than expected due to rounding down in core, but we just subtract the full amount expected
        // instead of the actual amount so we can burn the token
        // 更新LP Token的情况
        (position.tokensOwed0, position.tokensOwed1) = (tokensOwed0 - amount0Collect, tokensOwed1 - amount1Collect);

        emit Collect(params.tokenId, recipient, amount0Collect, amount1Collect);
    }

    /// @inheritdoc INonfungiblePositionManager
    function burn(uint256 tokenId) external payable override isAuthorizedForToken(tokenId) {
        Position storage position = _positions[tokenId];
        // 这是一个至关重要的安全检查。它要求 LP Token 完全清零后才能被销毁
        // 具体来说，liquidity（流动性数量）和 tokensOwed0、tokensOwed1（应收费用）都必须为零
        // 确保了用户不会意外地销毁仍有价值的头寸，防止资产丢失
        require(position.liquidity == 0 && position.tokensOwed0 == 0 && position.tokensOwed1 == 0, 'Not cleared');
        // 从合约的存储中删除该 LP Token 对应的 Position 结构体数据
        delete _positions[tokenId];
        //调用继承自 ERC-721 父合约的内部函数，执行真正的销毁操作
        _burn(tokenId);
    }

    // 它返回指定 tokenId 的当前 nonce（随机数），然后将其加一
    // 它用于防止重放攻击（Replay Attack）。在签名交易中，nonce 确保了每次签名都只能被使用一次
    function _getAndIncrementNonce(uint256 tokenId) internal override returns (uint256) {
        return uint256(_positions[tokenId].nonce++);
    }

    // 获取代币授权地址
    function getApproved(uint256 tokenId) public view override(ERC721, IERC721) returns (address) {
        // 首先检查该 LP Token 是否存在，如果不存在则回滚并报错
        require(_exists(tokenId), 'ERC721: approved query for nonexistent token');
        // 直接返回 Position 结构体中的 operator 字段。这个字段就是被授权可以操作该 LP Token 的地址
        return _positions[tokenId].operator;
    }

    // 设置 LP Token 的授权地址
    function _approve(address to, uint256 tokenId) internal override(ERC721) {
        // 将 Position 结构体中的 operator 字段直接设置为目标地址 to
        _positions[tokenId].operator = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
}
