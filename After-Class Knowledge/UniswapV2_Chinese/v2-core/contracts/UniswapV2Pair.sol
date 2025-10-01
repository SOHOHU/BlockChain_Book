pragma solidity =0.5.16;

import './interfaces/IUniswapV2Pair.sol';
import './UniswapV2ERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Callee.sol';

contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {
    // 处理一些变量，防溢出
    using SafeMath for uint;
    using UQ112x112 for uint224;
    // 用于表示流动性池中的最小流动性份额，目的是防止初次注入流动性的人突然获取大量手续费
    uint public constant MINIMUM_LIQUIDITY = 10 ** 3;
    // 处理低级函数操作
    // 1、将操作字符化，transfer(address,uint256)变为'transfer(address,uint256)'
    // 2、调用byte将操作字节保存
    // 3、将操作化为hash值
    // 4、截取前四位字节
    // SELECTOR用于函数abi.encodeWithSelector(SELECTOR, to, value)之中，SELECTOR, to, value共同构成transfer(address,uint256)的功能
    // 这种处理低级操作的方法用于简化函数调用（虽然我没怎么觉得多简化了...）
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    //对应的UniswapV2Factory合约地址
    address public factory;
    // 交易对中的两个token地址
    address public token0;
    address public token1;
    // 两个token在交易对中的储备量
    // 注意数据类型是int
    uint112 private reserve0;
    uint112 private reserve1;
    // 相对于上一次更新储备量的时间间隔
    uint32 private blockTimestampLast;
    // 价格累计值
    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    // 常量乘积模型的k值
    uint public kLast;
    uint private unlocked = 1;
    // 防重入锁
    // 防止部分函数重复调用，在函数执行完成之后unlocked恢复为1
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // 获取token在交易对中的储备量和相对于上一次更新储备量的时间间隔
    // 依然是一种外部应用获取合约参数的方法
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    /**
     * @dev: 转账token函数
     * @param {address} token:进行转账的token地址
     * @param {address} to:接受转账的地址
     * @param {uint} uint:转账的数量
     */
    // 安全转账判定
    function _safeTransfer(address token, address to, uint value) private {
        // 执行简单调用函数，token是进行转账的地址。to是接受转账的地址，value是转的钱，执行完转账后返回bool success, bytes memory data两个值。
        // 用require进行安全判断，只有success为正，且转账数据data通过ERC20检验（即api.decode）即可完成安全转账
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    // 定义几个事件
    // Mint：铸造 LP token 时触发，记录了谁提供了流动性以及提供了多少代币。
    // Burn：销毁 LP token 时触发，记录了谁销毁了 LP token（Sender），以及取回了多少代币，代币存入哪里（to）。
    // Swap：进行代币兑换时触发，记录了兑换的输入和输出数量，包括两种代币输入输出的数量以及发起兑换的地址和接受代币的地址。
    // Sync：储备量更新时触发，记录了新的两种代币储备量
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    // 构造函数，工厂地址为部署者地址
    constructor() public {
        factory = msg.sender;
    }

    // 在部署时由工厂调用一次，简单的初始化
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    /**
     * @dev: 更新储备，并在每个区块的第一次调用时更新价格累加器
     * @param {uint} balance0:更新后tokenA的储备量
     * @param {uint} balance1:更新后tokenA的储备量
     * @param {uint112} _reserve0:当前tokenA的储备量
     * @param {uint112} _reserve1:当前tokenB的储备量
     */
    
    // 更新储备量和价格累计值
    // 关键字解析：
    // 1、block.timestamp: 当前区块的时间戳
    // 2、blockTimestampLast: 上一次更新的时间戳，后续会更新
    // 3、UQ112x112是专门用于处理定点数的库，其中.encode() 对参数进行定点转换操作（后续所有运算操作都会带有定点隐式转换），uqdiv将参数与前面一个参数进行定点除法
    // 功能解析：
    // 1、balance0 和 balance1: 这是当前合约中 token0 和 token1 的实际余额。这些值是通过 IERC20(token).balanceOf(address(this)) 获取的。
    // 2、_reserve0 和 _reserve1: 这是上一次记录的储备量。这些值是从合约的状态变量 reserve0 和 reserve1 中获取的。
    // * 二者区别在于，前者是系统检查到的实际情况，后者是账本，需要经常对账
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        // 通过对 2 ** 32取余，实现取时间戳的低32 位，防止溢出
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        // 时间间隔
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // 永远不会溢出，+ overflow是理想的
            // 分别计算两种代币的价值（x/y或者y/x）随时间的累加，实时更新，方便后续预言机计算TWAP
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        // 对账
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        // 更新时间
        blockTimestampLast = blockTimestamp;
        // 发送事件
        emit Sync(reserve0, reserve1);
    }

    /**
     * @dev: 如果打开收费功能，就约等于1/6的增长的根号(k)
     * @param {uint112} _reserve0:tokenA的储备量
     * @param {uint112} _reserve1:tokenB的储备量
     * @return {bool} feeOn: 返回是否接受手续费
     */
    // 计算手续费，准确来说是协议手续费，在用户增加或者移出流动性时候，回增加新的LP Token
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        // 获取收取手续费的地址，通过调用IUniswapV2Factory的feeTo方法实现。
        // 功能解释：factory本是地址变量，强制转化为接口后调用feeTo方法，返回一个地址赋予feeto
        address feeTo = IUniswapV2Factory(factory).feeTo();
        // 检查 feeTo 地址是否为零地址。如果不是，则表示手续费功能已开启。
        // 功能解释，如果feeTo != address(0);成立，feeOn=true，反之为false。
        feeOn = feeTo != address(0);
        // 节省gas
        // 将状态变量 kLast 的值读取到内存变量 _kLast 中。在 Solidity 中，读取内存变量比反复读取状态变量更节省 gas
        // kLast 是uniswap的恒定乘积，此处提醒。
        uint _kLast = kLast;
        if (feeOn) {
            // 确保了只有在已经发生过至少一次交易后，才开始计算手续费
            if (_kLast != 0) {
                // rootk=sqrt(_reserve0 * _reserve1)，即流动性，sqrt为平方根计算
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                // 上一次交易后的sqrt(k)值
                uint rootKLast = Math.sqrt(_kLast);
                // 流动性池的 k 值增加时（即 sqrt(k) 增加）才计算手续费，k值增加意味着流动池的价值增加了，只要有增加，在用户注入或者取出流动性时。uniswap都会收取0.05%的手续费
                if (rootK > rootKLast) {
                    // 接下来就是计算这个手续费
                    // 分子(lptoken总量*(rootK-rootKLast))，即总量 x 流动性增长量
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    // 分母(rooL*5+rooKLast)， 即 5* 当前流动 + 过去流动
                    uint denominator = rootK.mul(5).add(rootKLast);
                    // liquidity = ( totalSupply * ( sqrt(_reserve0 * _reserve1) -  sqrt(_kLast) ) ) / sqrt(_reserve0 * _reserve1) * 5 + sqrt(_kLast)
                    // 此为协议手续费公式
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    /**
     * @dev: 铸造lptoken
     * @param {address} to:接受lptoken的地址
     * @return {uint} liquidity: lptoken的数量
     */
    
    function mint(address to) external lock returns (uint liquidity) {
        //  节省gas
        // 获取当前存储的两个Token
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        // 获取进行添加流动性的两个token的数量
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        // 通过这个插值可以计算用户注入了多少两边货币
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);
        // 判断是否进行收取手续费，前面说过，这部分是协议手续费。
        bool feeOn = _mintFee(_reserve0, _reserve1);
        // 节省gas，必须在这里定义，因为totalSupply可以在_mintFee中更新
        uint _totalSupply = totalSupply;
        // 创建一个新的流动性池，或者第一次交易
        if (_totalSupply == 0) {
            // 定义初始需要的LP数量
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            // 永久锁定MINIMUM_LIQUIDITY
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            // 添加流动性所获得的lptoken数量(进行添加流动性的两种token的数量*目前lptoken的数量/当前token的储备量-->取较小值)
            // LP Token获取公式，之前已经上课上过了
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        // 铸造lptoken函数
        // 铸造 LP token 给接收者
        _mint(to, liquidity);
        // 更新储备函数
        _update(balance0, balance1, _reserve0, _reserve1);
        // 如果收取手续费，更新交易后的k值，因为收取手续费后_reserve0, _reserve1又有变化了
        if (feeOn) kLast = uint(reserve0).mul(reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    /**
     * @dev: 销毁lptoken退出流动性
     * @param {address} to:接受交易对返回token的地址
     * @return {uint} amount0: 返回获得的tokenA的数量
     * @return {uint} amount1: 返回获得的tokenB的数量
     */
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        // 节省gas
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); 
        address _token0 = token0; 
        address _token1 = token1; 
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        // 为什么用addres(this)?-->因为获取退出lptoken数量时，是在route合约中先将lptoken转到当前合约，然后直接获得当前合约lptoken的数量
        // 具体来说，合约不能直接销毁用户的LP Token，这是巨大的安全漏洞。根据ERC20标准，想要销毁代币，需要用户先把LP Token转账到Pair的合约上。由合约销毁自己账户上的LP Token，再打钱。
        // 合约上自己的LP Token一般是0，创建的时候设置的。因此直接访问即可
        uint liquidity = balanceOf[address(this)];
        // 收取手续费
        bool feeOn = _mintFee(_reserve0, _reserve1);
        // 节省gas，必须在这里定义，因为totalSupply可以在_mintFee中更新
        uint _totalSupply = totalSupply; 
        // 使用余额确保按比例分配-->(持有lptoken/总lptoken)*合约中持有token的数量
        // 公式，提取的两部分Token数量，上课也讲过了。
        amount0 = liquidity.mul(balance0) / _totalSupply; 
        amount1 = liquidity.mul(balance1) / _totalSupply; 
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        // 删除LP Token，再次强调，是合约自己账户上的
        _burn(address(this), liquidity);
        // 转账两种token
        // 实现安全转账，前面说过的函数
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        // 更新一下当前的两个代币
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        // 更新储备量函数
        _update(balance0, balance1, _reserve0, _reserve1);
         // 如果收取手续费，更新交易后的k值
        if (feeOn) kLast = uint(reserve0).mul(reserve1); 
        emit Burn(msg.sender, amount0, amount1, to);
    }

    //交易函数，顺便实现了闪电贷
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        // 检查是否有需要取出的两种代币，也可以是一种，如果简单交易则一个设为0即可
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        // 获取token在交易对中的储备量，节省gas
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        // 基本的判断就不再说了
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');
        uint balance0;
        uint balance1;
        {
            // _token{0,1}的作用域，避免堆栈过深的错误，同时此处执行后会从缓存中移出，节省gas
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
            // 转移代币，对非0进行安全转账
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); 
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); 
            // 用于回调合约来实现一些特定的业务逻辑或其他自定义功能(闪电贷....)
            // 功能解释：
            // 1、如果传递了额外的数据执行这个回调函数，向用户输出相关信息，没有就是普通交易
            // 2、这里成行的功能是uniswapV2Call，闪电贷
            if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            // 合约拥有两种token的数量
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        // 假设amount0Out非0，对应的amount1In也是非0，而amount0In是0。说明是用户投入Token1，得到了Token0
        // 假设是闪电贷，则都非0
        // 获得合约两种token的数量，前提是(balance > _reserve - amountOut)，就是当前合约拥有的token数量应该是大于(储备值-输出到to地址的值)，返回之间的差值
        // 在单纯交易的情况下，假设amount0Out非0，因为用户已转账，输入了Token1，所以判断得以进行。
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        // 投入金额不足
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        {
            // Adjusted{0,1}的作用域，避免堆栈过深的错误
            // balanceAdjusted = balance * 1000 - amountIn * 3(确保在计算余额调整后的值时不会因为小数精度问题而导致错误)
            // 基于前面的单纯交易假设，仅看balance1Adjusted即可
            // 功能解释:这里是balanceAdjusted是不考虑手续费下的换算情况，这样才可以确定恒定乘积公式的满足
            uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            // 确保在交易完成后，资金池的储备量满足 Uniswap V2 中的 K 恒定公式，即 K = _reserve0 * _reserve1
            require(
                // balance0Adjusted * balance1Adjusted >= _reserve0 * _reserve0 * 1000 ** 2
                balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000 ** 2),
                'UniswapV2: K'
            );
        }
        // 更新储备量函数
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    /**
     * @dev: 使两个token的余额与储备相等
     * @param {address} to:接受两个token的余额与储备之间差值的地址
     */
     // 验证，避免转账错误和闪电贷的计算错误
    function skim(address to) external lock {
        // 节省gas
        address _token0 = token0;
        address _token1 = token1;
        // 将多余的token0和token1返回给账户，IERC20(_token0).balanceOf(address(this))即可获取余额，前面说过
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    /**
     * @dev: 使两个token的储备与余额相匹配
     */
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}
