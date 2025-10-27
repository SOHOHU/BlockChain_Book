# uniswap_v2_sim.py
"""
模拟 Uniswap V2 单次 swap 的函数。

函数签名：
    simulate_uniswap_v2_swap(amount_in, token_in, reserves, fee=0.003)

参数：
 - amount_in : float or int
      输入代币数量（以 human units 表示，例如 ETH 单位为 ETH，不是 wei）
 - token_in : str
      表示哪个代币进入池子，必须是 'token0' 或 'token1'
 - reserves : dict
      池子的储备，形式例如 {'token0': 1000.0, 'token1': 2000000.0}
      储备单位须与 amount_in 一致（都为 human units）
 - fee : float, optional (默认 0.003 表示 0.3%)
      交易费率（如 0.003 表示 0.3%）。也可传入 0 表示无手续费。

返回：
 - amount_out : float
      从池子中被输出（取出）的代币数量（human units）
 - details : dict
      计算细节（包括 amount_in_with_fee, reserve_in, reserve_out，用于调试/报告）
"""
from typing import Tuple, Dict

def simulate_uniswap_v2_swap(amount_in: float,
                             token_in: str,
                             reserves: Dict[str, float],
                             fee: float = 0.003) -> Tuple[float, Dict]:
    # 基本输入校验
    if token_in not in ("token0", "token1"):
        raise ValueError("token_in must be 'token0' or 'token1'")
    if "token0" not in reserves or "token1" not in reserves:
        raise ValueError("reserves must be dict with keys 'token0' and 'token1'")
    if amount_in <= 0:
        return 0.0, {"reason": "amount_in <= 0"}
    if reserves["token0"] <= 0 or reserves["token1"] <= 0:
        raise ValueError("Reserves must be positive numbers")

    # 确定输入/输出储备
    if token_in == "token0":
        reserve_in = float(reserves["token0"])
        reserve_out = float(reserves["token1"])
        out_token = "token1"
    else:
        reserve_in = float(reserves["token1"])
        reserve_out = float(reserves["token0"])
        out_token = "token0"

    # 处理 fee 参数（确保是 0<=fee<1）
    if fee < 0 or fee >= 1:
        raise ValueError("fee must be between 0 (inclusive) and 1 (exclusive)")

    # 关键计算（按数学公式逐步计算）
    # 1) 计算 amount_in_with_fee = amount_in * (1 - fee)
    amount_in_with_fee = float(amount_in) * (1.0 - float(fee))

    # 2) 计算 amount_out = (amount_in_with_fee * reserve_out) / (reserve_in + amount_in_with_fee)
    numerator = amount_in_with_fee * reserve_out
    denominator = reserve_in + amount_in_with_fee

    # 防除以0保护（实际不应发生，因为 reserves > 0 且 amount_in_with_fee >= 0）
    if denominator == 0:
        amount_out = 0.0
    else:
        amount_out = numerator / denominator

    # 明确返回额外信息，便于调试与写报告
    details = {
        "token_in": token_in,
        "token_out": out_token,
        "amount_in_raw": float(amount_in),
        "fee": float(fee),
        "amount_in_with_fee": amount_in_with_fee,
        "reserve_in": reserve_in,
        "reserve_out": reserve_out,
        "numerator": numerator,
        "denominator": denominator,
        "amount_out": amount_out
    }
    return amount_out, details


if __name__ == "__main__":
    # 示例：假设 pool reserve0=500 stETH, reserve1=1000 WETH，用户用 0.5 token0 进行交换（token0 -> token1）手续费0.3%
    reserves_example = {"token0": 500.0, "token1": 1000.0}
    amount_in_example = 0.5
    token_in_example = "token0"
    amount_out, info = simulate_uniswap_v2_swap(amount_in_example, token_in_example, reserves_example, fee=0.003)
    print("Simulation example:")
    for k, v in info.items():
        print(f"  {k}: {v}")
    print(f"  => amount_out = {amount_out:.12f} {info['token_out']}")
