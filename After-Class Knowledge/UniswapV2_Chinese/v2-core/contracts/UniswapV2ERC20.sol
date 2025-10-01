pragma solidity =0.5.16;

import './interfaces/IUniswapV2ERC20.sol';
import './libraries/SafeMath.sol';

contract UniswapV2ERC20 is IUniswapV2ERC20 {
    // 关键字解析：for，融合库，码将 SafeMath 库附加到 uint（无符号整数）类型上
    using SafeMath for uint;
    // 关键字解析：constant即const于C++
    string public constant name = 'Uniswap V2';
    string public constant symbol = 'UNI-V2';
    // 代币小数位数
    uint8 public constant decimals = 18;
    uint public totalSupply;
    // 一级映射，代表了某个以太坊address所持有的代币余额（看到目前为止什么代币暂不清楚）
    mapping(address => uint) public balanceOf;
    // 二级映射：关键字语法在factory已经讲过。
    // 功能解析：记录了授权信息。第一个 address 是 授权者（owner），第二个 address 是 被授权者（spender），uint 则是被授权者可以从授权者账户中花费的代币数量（到目前为止意义暂不清楚）
    mapping(address => mapping(address => uint)) public allowance;
    // DOMAIN_SEPARATOR 包含了本条链的 chainId, 当前合约名称, 版本, 合约地址等信息
    bytes32 public DOMAIN_SEPARATOR;
    // PERMIT_TYPEHASH 的值是通过对 permit 函数的参数进行哈希计算而得到的固定值，用于验证 permit 函数的调用
    // 来自于keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")，后续会说这个函数
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // DOMAIN_SEPARATOR和PERMIT_TYPEHASH被添加到签名信息中, 目的是让这个签名只能用于本条链, 本合约, 本功能(Permit)使用, 从而避免这个签名被拿到其他合约或者其他链的合约实施重放攻击
    // 某个地址的nonce值
    // 功能解析：一个地址成功使用签名进行授权后，其对应的 nonce 值就会加一。这确保了同一个签名不能被使用两次。
    mapping(address => uint) public nonces;
    // 定义一下相关事件
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    // 构造函数，初始化合约中的一些变量
    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid
        }
        // 对本条链的 chainId, 当前合约名称, 版本, 合约地址等信息进行加密
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev: 铸造UNI-V2token函数
     * @param {address} to:接受token地址
     * @param {uint} value:接受token数量
     */
    // 铸造出Value个Token给To地址
    // 关键字解析：internal，说明该函数只能为合约内部函数和子函数调用。private是子函数也不能调用
    function _mint(address to, uint value) internal {
        // Token总量更新
        totalSupply = totalSupply.add(value);
        // 更新接受地址的token总量
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    /**
     * @dev: 销毁UNI-V2token函数
     * @param {address} from:销毁token地址
     * @param {uint} value:销毁token数量
     */
    // 功能解析：
    // 在Pair中我们曾说过合约无法直接删除用户地址的代币，这是ERC20规定的安全性。
    // 此处的设计看似和ERC20冲突，实则它执行的是销毁的第二步，即合约销毁自己账户上的Token，因此才使用了internal定义
    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    /**
     * @dev: 授权某个地址能使用某个地址token函数
     * @param {address} owner:授权地址
     * @param {address} spender:被授权地址
     * @param {uint} value:授权token数量
     */
    // 此代码用作owner授权给spender可用额度
    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev: 转账token函数
     * @param {address} from:进行转账的地址
     * @param {address} to:接受转账的地址
     * @param {uint} value:转账的数量
     */
    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev: 授权某个地址能使用msg.sender地址token函数
     * @param {address} spender:被授权地址
     * @param {uint} value:授权token数量
     */
    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev: 转账token函数
     * @param {address} to:接受转账的地址
     * @param {uint} value:转账的数量
     * @return {bool}:是否转账成功
     */
    // 由用户执行，一般设计用户用户之间点对点的交易，如转账
    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev: 已被授权地址转账token函数
     * @param {address} from:进行转账的地址
     * @param {address} to:接受转账的地址
     * @param {uint} value:转账的数量
     * @return {bool}: 是否转账成功
     */
    // 由合约执行，用来满足用户想要通过合约实现的一些功能（因为合约不能直接访问用户钱包，只能授权）
    function transferFrom(address from, address to, uint value) external returns (bool) {
        // 判断是否已经被授权
        if (allowance[from][msg.sender] != uint(-1)) {
            // 先对授权金额进行减少，其中若授权金额小于转账金额会require失败
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev: 判断签名的有效性
     * @param {address} owner:授权地址
     * @param {address} spender:被授权地址
     * @param {uint} value:授权金额
     * @param {uint} deadline:签名有效时间内的时间戳
     * @param {uint8} v:原始签名的v
     * @param {bytes32} r:原始签名的r
     * @param {bytes32} s:原始签名的s
     */
    // 允许用户在链下对一笔授权进行签名，我们仅需要对链下的签名验证即可
    // 功能解析（区块链导论，S6101）
    // 链下
    // 1、私钥->公钥->地址
    // 2、准备完成相应的参数owner（你的地址，0x...Alice），spender（被授权的合约地址，如 Uniswap 路由器），value（授权金额），deadline（签名有效期），nonce（你的地址的当前使用次数）
    // 3、生成digest，这里生成digest链下生成，没有调用permit，但是方法一致
    // digest = keccak256(DOMAIN_SEPARATOR, keccak256(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline))
    // 4、基于私钥对digest进行签名（签名原理详见密码学导论，S6103）
    // 5、签名完成后系统会返回签名用到的三个关键参数
    // 链上
    // 6、调用permit，重新构造一个链上的digest，这个digest和链下的相同
    // 7、既然digest一致，那签名<->链上digest，v, r, s的映射就能成立，使用ecrecover恢复出owner地址
    // 8、通过owner地址判断后，证明链下签名有效。
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        // 判断是否在有效时间内
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        // 外层哈希计算
        bytes32 digest = keccak256(
            // 将多个变量打包为紧密压缩的字节数组
            abi.encodePacked(
                //EIP-712 协议的规范。它的作用是防止签名被用作其他用途
                '\x19\x01',
                // 这是已经有的签名，开始定义过
                DOMAIN_SEPARATOR,
                // PERMIT_TYPEHASH是链下生成，对于常量字符串keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")的哈希结果，这也是开局把它定为常量的原因
                // 配合其他数据形成新的哈希值
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        // ecrecover 函数可以返回与签名者对应的公钥地址
        // v,r,s这三个参数共同构成了 ECDSA 签名，是生成地址address owner需要的参数
        address recoveredAddress = ecrecover(digest, v, r, s);
        // 判断签名者对应的公钥地址与授权地址是否一致
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}
