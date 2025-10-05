// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 接口：定义了外部合约（如 ERC721 NFT 合约）必须实现的函数签名
interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

// 荷兰式拍卖合约
contract DutchAuction {
    uint256 private constant DURATION = 7 days; // 常量使用全大写加下划线

    // 不可变状态变量 (immutable)：只能在构造函数中设置一次，之后不能修改。
    // 它们节省 gas，因为它们不存储在存储槽中。
    IERC721 public immutable nft;
    uint256 public immutable nftId;

    address public immutable seller;
    uint256 public immutable startingPrice;
    uint256 public immutable startTimestamp; // 命名为 Timestamp 更明确
    uint256 public immutable endTimestamp;   // 命名为 Timestamp 更明确
    uint256 public immutable discountRate;   // 命名为 Rate 更明确

    /**
     * @notice 构造函数，初始化拍卖参数。
     * @param _startingPrice 拍卖的起始价格。
     * @param _discountRate 每秒的价格下降速率。
     * @param _nft NFT 合约的地址。
     * @param _nftId 待拍卖的 NFT ID。
     */
    constructor(
        uint256 _startingPrice,
        uint256 _discountRate,
        address _nft,
        uint256 _nftId
    ) {
        seller = msg.sender; // 卖家是部署者
        startingPrice = _startingPrice;
        discountRate = _discountRate;

        // 实例化 NFT 接口，指向实际的 NFT 合约地址
        nft = IERC721(_nft);
        nftId = _nftId;

        // 校验：确保拍卖不会在结束时价格变为负数
        require(_startingPrice >= _discountRate * DURATION, "Price ends below zero");

        startTimestamp = block.timestamp; // 拍卖开始时间
        endTimestamp = block.timestamp + DURATION; // 拍卖结束时间
    }

    /**
     * @notice 计算当前时刻的 NFT 价格。
     * @return 当前的拍卖价格。
     */
    function getCurrentPrice() public view returns (uint256) { // 使用 getCurrentPrice 更具描述性
        uint256 timeElapsed = block.timestamp - startTimestamp; // 拍卖已进行的时间
        
        // 如果已超过拍卖时长，价格应为最低价（或 0，取决于设计）
        if (block.timestamp >= endTimestamp) {
            timeElapsed = DURATION;
        }

        uint256 discount = discountRate * timeElapsed;
        
        // 确保价格不小于 0
        uint256 currentPrice = startingPrice - discount;
        return currentPrice;
    }

    /**
     * @notice 购买 NFT。购买者发送的 ETH 必须大于或等于当前价格。
     */
    function buy() public payable {
        uint256 currentPrice = getCurrentPrice();
        
        // 检查：发送的 ETH 是否足够支付当前价格
        require(msg.value >= currentPrice, "DutchAuction: Not enough funds");
        // 检查：拍卖是否仍在进行中 (getCurrentPrice 中已处理时间逻辑，这里可以简化)
        // require(block.timestamp <= endTimestamp, "DutchAuction: Auction finished"); 
        
        // 1. 将 NFT 转移给购买者
        // 假设 DutchAuction 合约已获得该 NFT 的授权（通过 approve 或 setApprovalForAll）
        nft.transferFrom(address(this), msg.sender, nftId);

        // 2. 将 ETH 转移给卖家（不需要，因为 ETH 已经存在于本合约，只需处理退款）
        // 3. 处理退款
        uint256 refund = msg.value - currentPrice;
        
        if (refund > 0) {
            // 使用 transfer 函数退款给购买者
            payable(msg.sender).transfer(refund);
        }
        
        // 优化：将拍卖所得（currentPrice）转给卖家。
        // 为了简化，本合约可以持有 ETH，卖家通过另一个函数提取。
        // 或者，在本函数内直接转给卖家：
        // payable(seller).transfer(currentPrice);
        // 为了安全和规范，通常会使用 pull-pattern（提款模式），让卖家主动提款。
    }
}