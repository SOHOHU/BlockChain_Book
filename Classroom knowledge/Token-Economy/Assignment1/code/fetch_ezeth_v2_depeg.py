# fetch_steth_depeg_fixed.py
import time
from datetime import datetime, timezone, timedelta
from web3 import Web3
import pandas as pd
import matplotlib.pyplot as plt
from tqdm import tqdm

# ----------------------------
# =========== CONFIG =========
# ----------------------------
RPC_URL = "https://quick-polished-knowledge.quiknode.pro/ff8e71013418186e4e224cfc6d041e01356763b1/"  # <- 你的URL
PAIR_ADDRESS = "0x4028DAAC072e492d34a3Afdbef0ba7e35D8b55C4"  # Uniswap V2 stETH/WETH
STETH_ADDRESS = Web3.to_checksum_address("0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84")
WETH_ADDRESS  = Web3.to_checksum_address("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2")

# 时间区间 (UTC) —— 修改成你要的区间（例：2024-08-04 -> 2024-08-06）
START_TS = datetime(2024, 8, 4, 0, 0, tzinfo=timezone.utc)
END_TS   = datetime(2024, 8, 6, 23, 59, tzinfo=timezone.utc)

# 采样间隔（分钟）
SAMPLE_MINUTES = 10

# depeg 阈值（例如 0.99 表示低于 0.99 即被认为脱锚）
DEPEG_THRESHOLD = 0.99

# 输出文件名
OUT_CSV = "steth_weth_uniswapv2_20240804_06.csv"
OUT_PNG = "steth_weth_uniswapv2_20240804_06.png"

# ----------------------------
# =========== SETUP ==========
# ----------------------------
# 增加请求超时，避免短连接卡住
w3 = Web3(Web3.HTTPProvider(RPC_URL, request_kwargs={"timeout": 60}))

# 修正：使用 is_connected()
if not w3.is_connected():
    raise SystemExit("RPC 连接失败，请检查 RPC_URL 是否正确，且网络可访问。")

pair_addr = Web3.to_checksum_address(PAIR_ADDRESS)

# minimal ABI for pair contract (getReserves, token0, token1)
PAIR_ABI = [
    {"constant": True, "inputs": [], "name": "getReserves", "outputs": [
        {"name": "reserve0", "type": "uint112"},
        {"name": "reserve1", "type": "uint112"},
        {"name": "blockTimestampLast", "type": "uint32"},
    ], "type": "function"},
    {"constant": True, "inputs": [], "name": "token0", "outputs": [{"name": "", "type": "address"}], "type": "function"},
    {"constant": True, "inputs": [], "name": "token1", "outputs": [{"name": "", "type": "address"}], "type": "function"},
]

ERC20_ABI = [
    {"constant": True, "inputs": [], "name": "decimals", "outputs": [{"name": "", "type": "uint8"}], "type": "function"},
    {"constant": True, "inputs": [], "name": "symbol", "outputs": [{"name": "", "type": "string"}], "type": "function"},
]

pair = w3.eth.contract(address=pair_addr, abi=PAIR_ABI)

token0 = pair.functions.token0().call()
token1 = pair.functions.token1().call()
print("pair token0:", token0)
print("pair token1:", token1)

# detect which reserve maps to which token
if Web3.to_checksum_address(token0) == STETH_ADDRESS:
    steth_is_token0 = True
elif Web3.to_checksum_address(token1) == STETH_ADDRESS:
    steth_is_token0 = False
else:
    raise SystemExit("在 pair 合约中找不到 stETH 地址 —— 请确认 PAIR_ADDRESS 是否正确。")

# 获取 decimals
erc20_t0 = w3.eth.contract(address=Web3.to_checksum_address(token0), abi=ERC20_ABI)
erc20_t1 = w3.eth.contract(address=Web3.to_checksum_address(token1), abi=ERC20_ABI)
dec0 = erc20_t0.functions.decimals().call()
dec1 = erc20_t1.functions.decimals().call()
sym0 = erc20_t0.functions.symbol().call()
sym1 = erc20_t1.functions.symbol().call()
print(f"token0: {sym0} decimals={dec0}, token1: {sym1} decimals={dec1}")

# ----------------------------
# =========== HELPERS =========
# ----------------------------
def get_block_by_timestamp(target_ts, start_block=0, end_block=None, max_iter=80):
    """
    Binary search to find block whose timestamp is <= target_ts and next block timestamp > target_ts.
    Returns block number closest at or before target_ts.
    """
    if end_block is None:
        end_block = w3.eth.block_number

    lo = start_block
    hi = end_block
    for i in range(max_iter):
        mid = (lo + hi) // 2
        try:
            b = w3.eth.get_block(mid)
        except Exception as e:
            # 若 RPC 在某些区块出错，稍等并重试
            time.sleep(0.2)
            b = w3.eth.get_block(mid)
        ts = datetime.fromtimestamp(b.timestamp, tz=timezone.utc)
        if ts <= target_ts:
            lo = mid
        else:
            hi = mid
        if hi - lo <= 1:
            # ensure lo is not ahead of target
            b_lo = w3.eth.get_block(lo)
            if datetime.fromtimestamp(b_lo.timestamp, tz=timezone.utc) > target_ts:
                return max(0, lo-1)
            return lo
    return lo

def get_reserves_at_block(block_number):
    # getReserves at historical block
    r = pair.functions.getReserves().call(block_identifier=block_number)
    return r[0], r[1], r[2]

# ----------------------------
# =========== MAIN ============
# ----------------------------
ts_list = []
cur = START_TS
while cur <= END_TS:
    ts_list.append(cur)
    cur = cur + timedelta(minutes=SAMPLE_MINUTES)

print(f"Will sample {len(ts_list)} points from {START_TS} to {END_TS} every {SAMPLE_MINUTES} minutes.")

rows = []
latest_block = w3.eth.block_number

# convert start/end timestamps to block guesses for faster searches
start_block_guess = get_block_by_timestamp(START_TS, start_block=0, end_block=latest_block)
end_block_guess   = get_block_by_timestamp(END_TS, start_block=start_block_guess, end_block=latest_block)
print("Estimated block range:", start_block_guess, "-", end_block_guess)

for ts in tqdm(ts_list):
    try:
        blk = get_block_by_timestamp(ts, start_block=start_block_guess, end_block=end_block_guess)
        b = w3.eth.get_block(blk)
        reserve0, reserve1, block_ts_last = get_reserves_at_block(blk)
    except Exception as e:
        print("RPC error at timestamp", ts, ":", str(e))
        time.sleep(0.5)
        continue

    amt0 = reserve0 / (10 ** dec0)
    amt1 = reserve1 / (10 ** dec1)
    if steth_is_token0:
        steth_amt = amt0
        weth_amt  = amt1
    else:
        steth_amt = amt1
        weth_amt  = amt0
    price = (weth_amt / steth_amt) if steth_amt > 0 else None
    rows.append({
        "requested_time_utc": ts.isoformat(),
        "block": blk,
        "block_time_utc": datetime.fromtimestamp(b.timestamp, tz=timezone.utc).isoformat(),
        "steth_reserve": steth_amt,
        "weth_reserve": weth_amt,
        "price_steth_per_eth": price
    })
    time.sleep(0.05)  # polite sleep

df = pd.DataFrame(rows)
df.to_csv(OUT_CSV, index=False)
print("Saved CSV to", OUT_CSV)

# ========== 分析 & 绘图 ==========
df2 = df.dropna(subset=["price_steth_per_eth"]).copy()
df2["time"] = pd.to_datetime(df2["block_time_utc"])

min_price = df2["price_steth_per_eth"].min()
min_row = df2.loc[df2["price_steth_per_eth"].idxmin()]
print(f"Min price (stETH per ETH): {min_price:.6f} at block {int(min_row['block'])} time {min_row['block_time_utc']}")

depeg_pct = 1 - min_price
print(f"Depeg magnitude = {depeg_pct:.6%}")

# compute sustained depeg intervals
threshold = DEPEG_THRESHOLD
df2["is_depeg"] = df2["price_steth_per_eth"] < threshold

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

readable_intervals = []
for s, e in intervals:
    t0 = df2.iloc[s]["time"]
    t1 = df2.iloc[e]["time"]
    duration = t1 - t0
    min_p = df2.iloc[s:e+1]["price_steth_per_eth"].min()
    readable_intervals.append({"start": t0, "end": t1, "duration": duration, "min_price": min_p})

print("Detected depeg intervals (price < {:.3f}):".format(threshold))
for it in readable_intervals:
    print(" - from", it["start"], "to", it["end"], f"(duration {it['duration']}, min_price {it['min_price']:.6f})")

# Plot
plt.figure(figsize=(14, 8))
ax1 = plt.subplot(2, 1, 1)
ax1.plot(df2["time"], df2["price_steth_per_eth"], label="stETH per ETH", linewidth=1)
ax1.axhline(1.0, color="k", linestyle="--", linewidth=0.7, label="1.0 (peg)")
ax1.axhline(threshold, color="r", linestyle=":", linewidth=0.8, label=f"threshold {threshold}")
ax1.set_ylabel("stETH per ETH")
ax1.set_title("stETH vs ETH price (Uniswap V2 Pool)")
ax1.legend()
ax1.grid(True)
for it in readable_intervals:
    ax1.axvspan(it["start"], it["end"], alpha=0.15, color="red")

ax2 = plt.subplot(2, 1, 2, sharex=ax1)
ax2.plot(df2["time"], df2["steth_reserve"], label="stETH reserve", linewidth=1)
ax2.plot(df2["time"], df2["weth_reserve"], label="WETH reserve", linewidth=1)
ax2.set_ylabel("Token reserves (human units)")
ax2.legend()
ax2.grid(True)

plt.xlabel("UTC time")
plt.tight_layout()
plt.savefig(OUT_PNG, dpi=200)
print("Saved plot to", OUT_PNG)
plt.show()
