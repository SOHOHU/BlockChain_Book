手续费：
手续费始终由发送方支付，接收方只拿到转账金额，不需要承担手续费。

以太坊的手续费公式是：（区块链导论，Lecture 4）
Gas Used × Gas Price
(EIP-1559 之后：Gas Price = Base Fee + Priority Fee, 单位Gwei)
其中：
Gas Used = 实际消耗的 Gas 单位（比如 21,000）
Base Fee = 区块链网络根据拥堵情况动态调整的基础费
Priority Fee (Tip) = 给矿工/验证者的小费，用来激励他们优先打包

在实际情况中，发送方会声明GasLimit（愿意最大承担的Gas），如果Gas Used > Gas Limit,交易不能实现
因为发送方需要预付Gas Limit × Gas Price的费用给以太网络，支付完 = Gas Used × Gas Price费用后，多余预付退回