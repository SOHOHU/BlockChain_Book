## 1、具体的DeFi借贷例子

假设设定了以下参数：

| 参数名称 | 符号 | 设定值 | 含义 |
| :--- | :--- | :--- | :--- |
| **抵押率** (Liquidation Threshold) | $\text{LT}$ | $\mathbf{80\%}$ | 抵押品价值跌至借款价值的80%时，触发清算。 |
| **清算价差** (Liquidation Bonus) | $\text{LB}$ | $\mathbf{5\%}$ | 清算人进行清算时，将获得$5\%$的折扣/奖励。 |
| **平仓系数** (Close Factor) | $\text{CF}$ | $\mathbf{50\%}$ | 单次清算中，最多只能偿还借款债务的$50\%$。 |

### 1.1 初始设置

---

1. **您存入的抵押品 (Collateral):** $10 \text{ ETH}$
2. **当前 $\text{ETH}$ 价格 (Price):** $2,000 \text{ USD/ETH}$
3. **抵押品总价值 (Collateral Value):** $10 \text{ ETH} \times 2,000 \text{ USD/ETH} = \mathbf{20,000 \text{ USD}}$
4. **您借出的债务 (Borrowed Debt):** $\mathbf{10,000 \text{ DAI}}$（假设 $\text{DAI}$ 恒定为 $1 \text{ USD}$）

### 1.2 健康因子 (Health Factor) 的计算

我们首先计算您目前的健康因子（HF），它显示了您的头寸有多安全：

$$
\text{健康因子} = \frac{\text{抵押品总价值} \times \text{抵押率}}{\text{借款总价值}}
$$

$$
\text{HF} = \frac{20,000 \text{ USD} \times 80\%}{10,000 \text{ USD}} = \frac{16,000 \text{ USD}}{10,000 \text{ USD}} = \mathbf{1.6}
$$

**结果：** 您的 $\text{HF} = 1.6$，**大于 $1$**，您的贷款头寸非常安全。

---

### 1.3 清算门槛

现在假设 $\text{ETH}$ 价格下跌到 $\mathbf{1,250 \text{ USD/ETH}}$。

1. **新的抵押品总价值:** $10 \text{ ETH} \times 1,250 \text{ USD/ETH} = \mathbf{12,500 \text{ USD}}$
2. **新的健康因子计算:**
    $$
    \text{HF} = \frac{12,500 \text{ USD} \times 80\%}{10,000 \text{ USD}} = \frac{10,000 \text{ USD}}{10,000 \text{ USD}} = \mathbf{1.0}
    $$

**结果：** 您的 $\text{HF}$ 跌至 $\mathbf{1.0}$，这意味着您的贷款头寸已达到**清算门槛**，可以被清算人介入。

---

### 1.4 清算价差和平仓系数的应用

清算人（Liquidator）看到您的头寸可以清算了，决定介入：

#### A. 平仓系数 (Close Factor) 的应用

清算人希望偿还您的全部 10,000 DAI 债务，但协议的平仓系数是 $\mathbf{50\%}$。

* **单次最多可偿还的债务:** $10,000 \text{ DAI} \times 50\% = \mathbf{5,000 \text{ DAI}}$

#### B. 清算价差 (Liquidation Bonus) 的应用

清算人偿还了 $5,000 DAI 的债务，作为回报，他将获得价值高于 $5,000 DAI 的 ETH 抵押品。

* **清算人获得抵押品的价值:** $5,000 \text{ USD} \times (1 + \text{LB})$
  
  $$
  ,000 \text{ USD} \times (1 + 5\%) = 5,000 \text{ USD} \times 1.05 = \mathbf{5,250 \text{ USD}}
  $$
* **清算人实际获得的 $\text{ETH}$ 数量:** （当前 $\text{ETH}$ 价格为 $1,250 \text{ USD}$）
  
  $$
  frac{5,250 \text{ USD}}{1,250 \text{ USD/ETH}} = \mathbf{4.2 \text{ ETH}}
  $$

---

### 1.5. 杠杆

我们将一切回到初始设置：

* **初始抵押品：** $10 \text{ ETH}$
* **$\text{ETH}$ 价格：** $2,000 \text{ USD/ETH}$
* **抵押品价值：** $20,000 \text{ USD}$
* **已借债务：** $10,000 \text{ DAI}$
* **健康因子（HF）：** $\mathbf{1.6}$
  在借贷的过程中，我们事实上已经触发了杠杆：

1. **第一步：初始借款**
   
   * 抵押 $10 \text{ ETH}，借出 $10,000 DAI（$10,000 \text{ USD}$）。
2. **第二步：购买更多 $\text{ETH}$ (Leverage Up)**
   
   * 用借来的 $10,000 \text{ DAI}$ 在交易所或DEX上**全部买入 $\text{ETH}$**。
   * 购买数量：$10,000 \text{ USD} / 2,000 \text{ USD/ETH} = \mathbf{5 \text{ ETH}}$。
3. **第三步：再抵押 (Deposit & Repeat)**
   
   * 将新买的 $5 \text{ ETH}$ **重新存入**借贷协议，作为新的抵押品。
   * **新的总抵押品：** $10 \text{ ETH} (\text{原始}) + 5 \text{ ETH} (\text{新购}) = \mathbf{15 \text{ ETH}}$。
   * **新的总抵押品价值：** $15 \text{ ETH} \times 2,000 \text{ USD/ETH} = \mathbf{30,000 \text{ USD}}$。
4. **第四步：继续借款（可选）**
   
   * 利用这 $5 \text{ ETH} 的新抵押品，您可以**再次借出**更多的 DAI，并重复步骤 2 和 3，直到您的健康因子接近 $1$。

在完成前三步后：

* 最初只投入了 $10 \text{ ETH}，但现在您**控制的 $\text{ETH}$ 总量是 $15 \text{ ETH}$**。
* 这相当于的 $\text{ETH}$ 仓位放大了 $\mathbf{1.5}$ **倍**（$15 \text{ ETH} / 10 \text{ ETH}$）。

**这就是杠杆的作用：用 $1$ 份资金，持有了 $1.5$ 份资产。**

---

##### 那么贬值发生了又是什么情况？

杠杆操作极大地提高了您的**清算风险**。我们换一个例子。
通过循环借贷，最终达到了以下状态（**$2 \text{ ETH} 初始投入，最终控制 $5 \text{ ETH}$ 仓位**）：

* **总抵押：** $5 \text{ ETH}$
* **总债务：** $6,250 \text{ DAI}$
* **当前 $\text{ETH}$ 价：** $2,000 \text{ USD}$

$$
\text{清算点价值} = \frac{\text{债务}}{\text{LT}} = \frac{6,250 \text{ USD}}{80\%} = 7,812.5 \text{ USD}
$$

$$
\text{清算 } \text{ETH} \text{ 价} = \frac{7,812.5 \text{ USD}}{5 \text{ ETH}} = \mathbf{1,562.5 \text{ USD/ETH}}
$$

**安全边际：** $2,000 \text{ USD} 到 $1,562.5 \text{ USD}$，你只需要 $\text{ETH}$ 跌幅达到约 $\mathbf{21.8\%}$ 就会被清算。

杠杆操作就像是把清算线的**安全距离**不断上推，使其更贴近市场价格。即使是正常的市场波动（如 $20\%$ 的回调），在高杠杆头寸中也足以触发清算。因此，杠杆极大地牺牲了你的**安全边际**，使清算风险呈指数级增长。



