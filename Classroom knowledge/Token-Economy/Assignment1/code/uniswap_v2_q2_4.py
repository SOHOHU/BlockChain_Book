# q2_4_verify_by_reserves.py
"""
Verify Uniswap V2 swap (Q2.4) by fetching pre-swap reserves and simulating integer math.

How to use:
  - pip install web3
  - Edit RPC_URL if needed
  - Run: python q2_4_verify_by_reserves.py

This script uses the pair address and raw amounts we observed from the transaction logs.
If you have different raw amounts (from your log decode), replace them accordingly.
"""
from web3 import Web3
import sys

RPC_URL = "https://quick-polished-knowledge.quiknode.pro/ff8e71013418186e4e224cfc6d041e01356763b1/"  # your QuickNode
TX_HASH = "0x62399318598c544610a7aa62bf41cce0048a727f084c93ad9eec0c881525542c"

# pair we observed in logs (WETH/USDC)
PAIR_ADDR = Web3.to_checksum_address("0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc")

# RAW amounts extracted from the Swap log in earlier inspection
# amount_in_raw = WETH raw (wei)
# amount_out_raw = USDC raw (6 decimals)
amount_in_raw = 590938840873296854    # from earlier decode: 0x08336fbeae3be3d6
amount_out_raw_onchain = 1024229000   # from earlier decode: 0x3d0c7e88

w3 = Web3(Web3.HTTPProvider(RPC_URL, request_kwargs={"timeout": 60}))
if not w3.is_connected():
    print("RPC connection failed. Check RPC_URL.")
    sys.exit(1)

# minimal ABI
PAIR_ABI = [
    {"constant": True, "inputs": [], "name": "getReserves", "outputs": [
        {"name": "reserve0", "type": "uint112"},
        {"name": "reserve1", "type": "uint112"},
        {"name": "blockTimestampLast", "type": "uint32"}], "type": "function"},
    {"constant": True, "inputs": [], "name": "token0", "outputs": [{"name": "", "type": "address"}], "type": "function"},
    {"constant": True, "inputs": [], "name": "token1", "outputs": [{"name": "", "type": "address"}], "type": "function"},
]

pair = w3.eth.contract(address=PAIR_ADDR, abi=PAIR_ABI)

# get tx receipt to know block
try:
    receipt = w3.eth.get_transaction_receipt(TX_HASH)
except Exception as e:
    print("Failed to fetch tx receipt:", e)
    sys.exit(1)

tx_block = receipt.blockNumber
print("Transaction block:", tx_block, "tx index:", receipt.transactionIndex)

# fetch token0/token1
try:
    token0 = pair.functions.token0().call()
    token1 = pair.functions.token1().call()
    print("Pair token0:", token0)
    print("Pair token1:", token1)
except Exception as e:
    print("Failed to read token0/token1:", e)
    token0 = token1 = None

# get reserves at block tx_block-1 (pre-swap)
pre_block = max(0, tx_block - 1)
try:
    reserves = pair.functions.getReserves().call(block_identifier=pre_block)
    reserve0_raw = int(reserves[0])
    reserve1_raw = int(reserves[1])
    print(f"Reserves at pre-swap block {pre_block}: reserve0={reserve0_raw}, reserve1={reserve1_raw}")
except Exception as e:
    print("Failed to fetch reserves at pre-swap block:", e)
    sys.exit(1)

# Decide which token is input and output based on earlier inspection:
# From log inspection we saw Router transferred WETH into pair and pair transferred USDC out,
# so token_in is WETH and token_out is USDC.
# Identify which token is WETH by address (WETH mainnet):
WETH_ADDR = Web3.to_checksum_address("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2")

if Web3.to_checksum_address(token0) == WETH_ADDR:
    token_in_is_token0 = True
    print("WETH is token0 in this pair.")
elif Web3.to_checksum_address(token1) == WETH_ADDR:
    token_in_is_token0 = False
    print("WETH is token1 in this pair.")
else:
    print("WETH not found in token0/token1 of pair! Check pair address.")
    token_in_is_token0 = None

# Map reserves
if token_in_is_token0 is True:
    reserve_in = reserve0_raw
    reserve_out = reserve1_raw
    token_in_addr = token0
    token_out_addr = token1
else:
    reserve_in = reserve1_raw
    reserve_out = reserve0_raw
    token_in_addr = token1
    token_out_addr = token0

print("reserve_in:", reserve_in)
print("reserve_out:", reserve_out)

# Uniswap V2 integer simulation with 0.3% fee -> multiplier 997/1000
FEE_NUM = 997
FEE_DEN = 1000

amount_in_with_fee = amount_in_raw * FEE_NUM
numerator = amount_in_with_fee * reserve_out
denominator = reserve_in * FEE_DEN + amount_in_with_fee

if denominator == 0:
    amount_out_sim = 0
else:
    amount_out_sim = numerator // denominator  # integer floor division

print("\nSimulation (integer math):")
print(" amount_in_raw:", amount_in_raw)
print(" amount_in_with_fee (raw*997):", amount_in_with_fee)
print(" numerator:", numerator)
print(" denominator:", denominator)
print(" simulated amount_out (raw):", amount_out_sim)
print(" on-chain amount_out (raw from earlier decode):", amount_out_raw_onchain)

# fetch decimals & symbols for human readable output
ERC20_ABI = [
    {"constant": True, "inputs": [], "name": "decimals", "outputs": [{"name": "", "type": "uint8"}], "type": "function"},
    {"constant": True, "inputs": [], "name": "symbol", "outputs": [{"name": "", "type": "string"}], "type": "function"}
]

try:
    t_in = w3.eth.contract(address=token_in_addr, abi=ERC20_ABI)
    dec_in = t_in.functions.decimals().call()
    sym_in = t_in.functions.symbol().call()
    t_out = w3.eth.contract(address=token_out_addr, abi=ERC20_ABI)
    dec_out = t_out.functions.decimals().call()
    sym_out = t_out.functions.symbol().call()
    human_in = amount_in_raw / (10 ** dec_in)
    human_out_onchain = amount_out_raw_onchain / (10 ** dec_out)
    human_out_sim = amount_out_sim / (10 ** dec_out)
    print(f"\nHuman readable:")
    print(f" Input: {human_in:.18f} {sym_in}")
    print(f" On-chain output: {human_out_onchain:.6f} {sym_out}")
    print(f" Simulated output: {human_out_sim:.6f} {sym_out}")
except Exception as e:
    print("Warning: failed to fetch token decimals/symbols:", e)

# Comparison
if amount_out_sim == amount_out_raw_onchain:
    print("\nRESULT: Simulation MATCHES on-chain amount_out exactly.")
else:
    diff = amount_out_raw_onchain - amount_out_sim
    print("\nRESULT: MISMATCH.")
    print(" Difference (on-chain - simulated):", diff)
    if amount_out_raw_onchain != 0:
        print(" Relative diff:", diff / amount_out_raw_onchain)
