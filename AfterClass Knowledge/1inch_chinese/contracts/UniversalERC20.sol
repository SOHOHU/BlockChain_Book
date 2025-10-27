// 指定Solidity编译器版本为0.5.0或更高版本
pragma solidity ^0.5.0;

// === OpenZeppelin标准库导入 ===
// 安全数学运算库，防止溢出和下溢
import "@openzeppelin/contracts/math/SafeMath.sol";
// ERC20标准接口
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// 安全ERC20操作库，提供安全的代币操作
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


// === 通用ERC20处理库 ===
// 这个库提供了统一的代币操作接口，可以同时处理ETH和ERC20代币
// 这是1inch协议的核心工具库，简化了代币操作的复杂性
library UniversalERC20 {

    // === 库导入声明 ===
    // 为uint256类型添加SafeMath安全数学运算
    using SafeMath for uint256;
    // 为IERC20类型添加SafeERC20安全操作
    using SafeERC20 for IERC20;

    // === 常量定义 ===
    // 零地址常量，用于表示空地址
    IERC20 private constant ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);
    // ETH地址常量，用于表示原生ETH
    // 这是一个特殊的地址，用于在代码中区分ETH和ERC20代币
    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // === 通用转账函数 ===
    // 统一的代币转账函数，可以处理ETH和ERC20代币
    function universalTransfer(IERC20 token, address to, uint256 amount) internal returns(bool) {
        // 如果转账金额为0，直接返回成功
        if (amount == 0) {
            return true;
        }

        // 判断是否为ETH转账
        if (isETH(token)) {
            // ETH转账：直接调用transfer函数
            address(uint160(to)).transfer(amount);
        } else {
            // ERC20代币转账：使用SafeERC20安全转账
            token.safeTransfer(to, amount);
            return true;
        }
    }

    // === 通用转账函数（从指定地址） ===
    // 从指定地址转账到目标地址，支持ETH和ERC20代币
    function universalTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        // 如果转账金额为0，直接返回
        if (amount == 0) {
            return;
        }

        // 判断是否为ETH转账
        if (isETH(token)) {
            // ETH转账：要求from必须是msg.sender，且msg.value必须大于等于amount
            require(from == msg.sender && msg.value >= amount, "Wrong useage of ETH.universalTransferFrom()");
            // 如果目标地址不是当前合约，则转账ETH
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            // 如果msg.value大于amount，退还多余的ETH
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            // ERC20代币转账：使用SafeERC20安全转账
            token.safeTransferFrom(from, to, amount);
        }
    }

    // === 通用转账函数（从发送者到当前合约） ===
    // 从消息发送者转账到当前合约，支持ETH和ERC20代币
    function universalTransferFromSenderToThis(IERC20 token, uint256 amount) internal {
        // 如果转账金额为0，直接返回
        if (amount == 0) {
            return;
        }

        // 判断是否为ETH转账
        if (isETH(token)) {
            // ETH转账：如果msg.value大于amount，退还多余的ETH
            if (msg.value > amount) {
                // 退还多余的ETH
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            // ERC20代币转账：从发送者转账到当前合约
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    // === 通用授权函数 ===
    // 统一的代币授权函数，可以处理ERC20代币的授权
    function universalApprove(IERC20 token, address to, uint256 amount) internal {
        // 只有ERC20代币需要授权，ETH不需要
        if (!isETH(token)) {
            // 如果授权金额为0，则撤销授权
            if (amount == 0) {
                token.safeApprove(to, 0);
                return;
            }

            // 检查当前授权额度
            uint256 allowance = token.allowance(address(this), to);
            // 如果当前授权额度小于所需额度，则更新授权
            if (allowance < amount) {
                // 如果当前有授权，先撤销
                if (allowance > 0) {
                    token.safeApprove(to, 0);
                }
                // 设置新的授权额度
                token.safeApprove(to, amount);
            }
        }
    }

    // === 通用余额查询函数 ===
    // 统一的余额查询函数，可以查询ETH和ERC20代币余额
    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        // 判断是否为ETH
        if (isETH(token)) {
            // ETH余额：直接查询地址余额
            return who.balance;
        } else {
            // ERC20代币余额：调用balanceOf函数
            return token.balanceOf(who);
        }
    }

    // === 通用精度查询函数 ===
    // 统一的精度查询函数，可以查询ETH和ERC20代币的精度
    function universalDecimals(IERC20 token) internal view returns (uint256) {
        // ETH的精度固定为18
        if (isETH(token)) {
            return 18;
        }

        // 尝试调用decimals()函数
        (bool success, bytes memory data) = address(token).staticcall.gas(10000)(
            abi.encodeWithSignature("decimals()")
        );
        // 如果失败，尝试调用DECIMALS()函数（某些代币使用大写）
        if (!success || data.length == 0) {
            (success, data) = address(token).staticcall.gas(10000)(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
    }

    function isETH(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(ETH_ADDRESS));
    }

    function eq(IERC20 a, IERC20 b) internal pure returns(bool) {
        return a == b || (isETH(a) && isETH(b));
    }

    function notExist(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(-1));
    }
}
