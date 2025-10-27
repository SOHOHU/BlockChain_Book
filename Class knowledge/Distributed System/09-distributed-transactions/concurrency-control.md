# 并发控制

## 📌 问题

**并发事务可能导致数据不一致**

### 示例：丢失更新

```
初始：x = 100

T1: 读x(100) → x+50 → 写x(150)
T2: 读x(100) → x+30 → 写x(130)

最终：x = 130（T1的更新丢失！）
正确结果应该是：180
```

## 🔒 锁机制

### 两阶段锁（2PL）

**规则**：
1. **增长阶段**：只能获取锁，不能释放
2. **收缩阶段**：只能释放锁，不能获取

```python
# 正确的2PL
lock(A)
lock(B)
操作A和B
unlock(A)
unlock(B)

# 错误：不遵循2PL
lock(A)
unlock(A)  # 过早释放
lock(B)    # 收缩阶段又获取锁
```

### 锁类型

**读锁（共享锁）**：
- 多个事务可同时持有
- 允许并发读

**写锁（排他锁）**：
- 只有一个事务可持有
- 互斥

### 分布式锁

**问题**：锁分散在多个节点

**解决**：
1. **中心锁管理器**：单点故障
2. **分布式锁算法**：如Chubby, Zookeeper

## ⏰ 时间戳排序

### 原理

每个事务分配唯一时间戳，按时间戳顺序执行

```python
class TimestampOrdering:
    def __init__(self):
        self.read_ts = {}  # 最后读时间戳
        self.write_ts = {}  # 最后写时间戳
    
    def read(self, transaction, item):
        if transaction.ts < self.write_ts[item]:
            abort(transaction)  # 读已被新事务写过的数据
        else:
            self.read_ts[item] = max(transaction.ts, 
                                     self.read_ts[item])
            return item.value
    
    def write(self, transaction, item, value):
        if transaction.ts < self.read_ts[item]:
            abort(transaction)  # 写已被新事务读过的数据
        elif transaction.ts < self.write_ts[item]:
            pass  # 忽略过时的写
        else:
            item.value = value
            self.write_ts[item] = transaction.ts
```

## 🎯 乐观并发控制

### 原理

**假设**：冲突罕见

**流程**：
```
1. 读阶段：自由读取
2. 验证阶段：检查冲突
3. 写阶段：如果无冲突，写入
```

### 示例

```python
class OptimisticCC:
    def execute_transaction(self, transaction):
        # 阶段1：读取并记录
        read_set = transaction.read_phase()
        
        # 阶段2：验证
        if self.validate(transaction, read_set):
            # 阶段3：写入
            transaction.write_phase()
            commit()
        else:
            abort()
            retry()
```

**优点**：
- ✅ 读不阻塞
- ✅ 适合读多写少

**缺点**：
- ❌ 高冲突时性能差

## 🔑 关键要点

1. **并发控制**：保证事务隔离性
2. **锁机制**：2PL保证可串行化
3. **时间戳**：无锁方案
4. **乐观控制**：读多写少场景

---

**下一节**：[分布式死锁](./分布式死锁.md)

