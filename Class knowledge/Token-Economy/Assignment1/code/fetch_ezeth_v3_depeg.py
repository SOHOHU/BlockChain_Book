# fetch_ezeth_depeg_v3.py
"""
Fetch price (ezETH vs ETH) and range liquidity from a Uniswap V3 pool over a time interval.

Pool: 0xBE80225f09645f172B079394312220637C440A63 (Uniswap V3)
Time window: 2024-08-04 00:00 UTC  -> 2024-08-06 23:59 UTC

Output:
 - CSV with sampled points (timestamp, block, sqrtPriceX96, price_weth_per_ezeth, liquidity)
 - PNG plot with price and liquidity time series
 - Terminal prints min price and depeg summary
"""
import time
from datetime import datetime, timezone, timedelta
from web3 import Web3
import pandas as pd
import matplotlib.pyplot as plt
from tqdm import tqdm
import math

# ----------------------------
# =========== CONFIG =========
# ----------------------------
RPC_URL = "https://quick-polished-knowledge.quiknode.pro/ff8e71013418186e4e224cfc6d041e01356763b1/"  # <- 你的 QuickNode URL
POOL_ADDRESS = "0xBE80225f09645f172B079394312220637C440A63"  # Uniswap V3 pool (ezETH / WETH)
WETH_ADDRESS  = Web3.to_checksum_address("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2")

# 采样时间范围（UTC）
START_TS = datetime(2024, 8, 4, 0, 0, tzinfo=timezone.utc)
END_TS   = datetime(2024, 8, 6, 23, 59, tzinfo=timezone.utc)

# 每隔多少分钟采样一次（越小越精细 / 越慢）
SAMPLE_MINUTES = 10

# depeg 阈值（若 price < THRESHOLD 被视作脱锚）
DEPEG_THRESHOLD = 0.99

# 输出文件
OUT_CSV = "ezeth_weth_uniswapv3_20240804_06.csv"
OUT_PNG = "ezeth_weth_uniswapv3_20240804_06.png"

# ----------------------------
# =========== SETUP ==========
# ----------------------------
w3 = Web3(Web3.HTTPProvider(RPC_URL, request_kwargs={"timeout": 60}))
if not w3.is_connected():
    raise SystemExit("RPC 连接失败：请检查 RPC_URL 是否正确且可用。")

pool = w3.eth.contract(address=Web3.to_checksum_address(POOL_ADDRESS), abi=[
    # minimal ABI for Uniswap V3 pool: slot0, liquidity, token0, token1
    {"constant": True, "inputs": [], "name": "slot0", "outputs": [
        {"name": "sqrtPriceX96", "type": "uint160"},
        {"name": "tick", "type": "int24"},
        {"name": "observationIndex", "type": "uint16"},
        {"name": "observationCardinality", "type": "uint16"},
        {"name": "observationCardinalityNext", "type": "uint16"},
        {"name": "feeProtocol", "type": "uint8"},
        {"name": "unlocked", "type": "bool"}
    ], "type": "function"},
    {"constant": True, "inputs": [], "name": "liquidity", "outputs": [{"name": "", "type": "uint128"}], "type": "function"},
    {"constant": True, "inputs": [], "name": "token0", "outputs": [{"name": "", "type": "address"}], "type": "function"},
    {"constant": True, "inputs": [], "name": "token1", "outputs": [{"name": "", "type": "address"}], "type": "function"},
])

# ERC20 minimal ABI for decimals and symbol
ERC20_ABI = [
    {"constant": True, "inputs": [], "name": "decimals", "outputs": [{"name": "", "type": "uint8"}], "type": "function"},
    {"constant": True, "inputs": [], "name": "symbol", "outputs": [{"name": "", "type": "string"}], "type": "function"},
]

token0 = pool.functions.token0().call()
token1 = pool.functions.token1().call()
print("pool token0:", token0)
print("pool token1:", token1)

# determine which side is WETH and which is ezETH
if Web3.to_checksum_address(token0) == WETH_ADDRESS:
    weth_is_token0 = True
    ez_token_addr = Web3.to_checksum_address(token1)
elif Web3.to_checksum_address(token1) == WETH_ADDRESS:
    weth_is_token0 = False
    ez_token_addr = Web3.to_checksum_address(token0)
else:
    raise SystemExit("在池子 token0/token1 中未发现 WETH 地址，请检查 POOL_ADDRESS 是否正确。")

# fetch decimals & symbols
erc0 = w3.eth.contract(address=Web3.to_checksum_address(token0), abi=ERC20_ABI)
erc1 = w3.eth.contract(address=Web3.to_checksum_address(token1), abi=ERC20_ABI)
dec0 = erc0.functions.decimals().call()
dec1 = erc1.functions.decimals().call()
sym0 = erc0.functions.symbol().call()
sym1 = erc1.functions.symbol().call()
print(f"token0: {sym0} decimals={dec0}, token1: {sym1} decimals={dec1}")

# ----------------------------
# =========== HELPERS =========
# ----------------------------
def get_block_by_timestamp(target_ts, start_block=0, end_block=None, max_iter=90):
    """
    Binary search for block <= target_ts (UTC datetime).
    Returns the largest block number whose timestamp <= target_ts.
    """
    if end_block is None:
        end_block = w3.eth.block_number
    lo = start_block
    hi = end_block
    for _ in range(max_iter):
        mid = (lo + hi) // 2
        b = w3.eth.get_block(mid)
        ts = datetime.fromtimestamp(b.timestamp, tz=timezone.utc)
        if ts <= target_ts:
            lo = mid
        else:
            hi = mid
        if hi - lo <= 1:
            b_lo = w3.eth.get_block(lo)
            if datetime.fromtimestamp(b_lo.timestamp, tz=timezone.utc) > target_ts:
                return max(0, lo-1)
            return lo
    return lo

def get_slot0_and_liquidity(block_number):
    "Return (sqrtPriceX96:int, tick:int, liquidity:int) at specific historical block."
    s = pool.functions.slot0().call(block_identifier=block_number)
    sqrtPriceX96 = s[0]
    tick = s[1]
    liq = pool.functions.liquidity().call(block_identifier=block_number)
    return int(sqrtPriceX96), int(tick), int(liq)

def sqrtPriceX96_to_price(sqrtPriceX96):
    """
    Convert sqrtPriceX96 to raw price = token1 / token0 (raw units).
    price_raw = (sqrtPriceX96 / 2**96) ** 2
    """
    # use float (should be OK); for extreme precision use Decimal
    return (sqrtPriceX96 / (2**96)) ** 2

def price_weth_per_ezeth_from_slot(sqrtPriceX96, dec_token0, dec_token1, weth_is_token0):
    """
    Compute price expressed as WETH per ezETH (human units).
    Steps:
      - raw_price = token1/token0 (in raw integer units) computed from sqrtPriceX96
      - convert to human unit: price_human = raw_price * 10**(decimals_token0 - decimals_token1)
      - map to WETH per ezETH depending on token ordering:
            if token0 == ezETH and token1 == WETH: weth_per_ez = price_human
            if token0 == WETH and token1 == ezETH: weth_per_ez = 1 / price_human
    """
    raw_price = sqrtPriceX96_to_price(sqrtPriceX96)
    # price_human = token1(token units)/token0(units) in human decimals
    price_human = raw_price * (10 ** (dec_token0 - dec_token1))
    if weth_is_token0:
        # token0 == WETH, token1 == ezETH => raw price = ezETH per WETH => invert
        if price_human == 0:
            return None
        return 1.0 / price_human
    else:
        # token0 == ezETH, token1 == WETH => raw price = WETH per ezETH
        return price_human

# ----------------------------
# =========== MAIN ============
# ----------------------------
# build timestamps to sample
ts_list = []
cur = START_TS
while cur <= END_TS:
    ts_list.append(cur)
    cur = cur + timedelta(minutes=SAMPLE_MINUTES)
print(f"Will sample {len(ts_list)} points from {START_TS} to {END_TS} every {SAMPLE_MINUTES} minutes.")

rows = []
latest_block = w3.eth.block_number

# speedup: estimate start/end blocks
start_block_guess = get_block_by_timestamp(START_TS, start_block=0, end_block=latest_block)
end_block_guess   = get_block_by_timestamp(END_TS, start_block=start_block_guess, end_block=latest_block)
print("Estimated block range:", start_block_guess, "-", end_block_guess)

for ts in tqdm(ts_list):
    try:
        blk = get_block_by_timestamp(ts, start_block=start_block_guess, end_block=end_block_guess)
        b = w3.eth.get_block(blk)
        sqrtPriceX96, tick, liq = get_slot0_and_liquidity(blk)
    except Exception as e:
        print("RPC error at", ts, ":", str(e))
        time.sleep(0.2)
        continue

    price_weth_per_ez = price_weth_per_ezeth_from_slot(sqrtPriceX96, dec0, dec1, weth_is_token0)
    # store values (sqrtPriceX96 large int, liquidity int, price (float) )
    rows.append({
        "requested_time_utc": ts.isoformat(),
        "block": int(blk),
        "block_time_utc": datetime.fromtimestamp(b.timestamp, tz=timezone.utc).isoformat(),
        "sqrtPriceX96": int(sqrtPriceX96),
        "tick": int(tick),
        "liquidity": int(liq),
        "price_weth_per_ezeth": price_weth_per_ez
    })
    # polite sleep to avoid hitting rate limits
    time.sleep(0.05)

df = pd.DataFrame(rows)
df.to_csv(OUT_CSV, index=False)
print("Saved CSV to", OUT_CSV)

# ========== 分析 & 绘图 ==========
df2 = df.dropna(subset=["price_weth_per_ezeth"]).copy()
df2["time"] = pd.to_datetime(df2["block_time_utc"])

# minimal price and depeg magnitude
min_price = df2["price_weth_per_ezeth"].min()
min_row = df2.loc[df2["price_weth_per_ezeth"].idxmin()]
print(f"Min price (WETH per ezETH): {min_price:.6f} at block {int(min_row['block'])} time {min_row['block_time_utc']}")
depeg_pct = 1 - min_price
print(f"Depeg magnitude = {depeg_pct:.6%}")

# detect contiguous intervals price < threshold (coarse)
threshold = DEPEG_THRESHOLD
df2["is_depeg"] = df2["price_weth_per_ezeth"] < threshold

intervals = []
in_interval = False
start_idx = None
for i, row in df2.reset_index().iterrows():
    if row["is_depeg"] and not in_interval:
        in_interval = True
        start_idx = i
    if (not row["is_depeg"]) and in_interval:
        in_interval = False
        end_idx = i - 1
        intervals.append((start_idx, end_idx))
        start_idx = None
if in_interval and start_idx is not None:
    intervals.append((start_idx, df2.shape[0] - 1))

print("Detected coarse depeg intervals (price < {:.3f}):".format(threshold))
if len(intervals) == 0:
    print(" None")
else:
    for s,e in intervals:
        rs = df2.reset_index().iloc[s]
        re = df2.reset_index().iloc[e]
        t0 = rs["time"]
        t1 = re["time"]
        min_p = df2.iloc[s:e+1]["price_weth_per_ezeth"].min()
        print(f" - from {t0} to {t1}, min_price={min_p:.6f}")

# Plot: price (top) and liquidity (bottom)
plt.figure(figsize=(14, 8))

ax1 = plt.subplot(2, 1, 1)
ax1.plot(df2["time"], df2["price_weth_per_ezeth"], label="WETH per ezETH", linewidth=1)
ax1.axhline(1.0, color="k", linestyle="--", linewidth=0.7, label="peg 1.0")
ax1.axhline(threshold, color="r", linestyle=":", linewidth=0.8, label=f"threshold {threshold}")
ax1.set_ylabel("WETH per ezETH")
ax1.set_title("ezETH vs ETH price (Uniswap V3 pool)")
ax1.legend()
ax1.grid(True)

# shade coarse depeg regions
for s,e in intervals:
    t0 = df2.reset_index().iloc[s]["time"]
    t1 = df2.reset_index().iloc[e]["time"]
    ax1.axvspan(t0, t1, alpha=0.12, color="red")

ax2 = plt.subplot(2, 1, 2, sharex=ax1)
ax2.plot(df2["time"], df2["liquidity"], label="V3 current range liquidity", linewidth=1)
ax2.set_ylabel("liquidity (raw uint128)")
ax2.legend()
ax2.grid(True)

plt.xlabel("UTC time")
plt.tight_layout()
plt.savefig(OUT_PNG, dpi=200)
print("Saved plot to", OUT_PNG)
plt.show()
