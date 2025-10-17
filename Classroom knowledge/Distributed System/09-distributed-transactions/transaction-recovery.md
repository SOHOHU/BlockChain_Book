# 事务恢复

## 📌 问题

**故障后如何恢复到一致状态？**

### 故障类型

1. **事务中止**：程序错误
2. **系统崩溃**：掉电、内存丢失
3. **介质故障**：磁盘损坏

## 📝 日志（Logging）

### 日志内容

```
<START T>：事务T开始
<WRITE T, X, old, new>：T修改X
<COMMIT T>：T提交
<ABORT T>：T中止
```

### 写前日志（WAL）

**规则**：先写日志，再修改数据

```python
def write(transaction, item, new_value):
    # 1. 先写日志
    log.append(WRITE, transaction, item, 
               item.old_value, new_value)
    log.flush()  # 确保写入磁盘
    
    # 2. 再修改数据
    item.value = new_value
```

## 🔄 恢复算法

### UNDO

**用途**：中止未完成的事务

```python
def undo(transaction):
    for log_entry in reversed(log):
        if log_entry.transaction == transaction:
            if log_entry.type == WRITE:
                # 恢复旧值
                item = log_entry.item
                item.value = log_entry.old_value
```

### REDO

**用途**：重做已提交的事务

```python
def redo(transaction):
    for log_entry in log:
        if log_entry.transaction == transaction:
            if log_entry.type == WRITE:
                # 重新写入新值
                item = log_entry.item
                item.value = log_entry.new_value
```

### 恢复流程

```python
def recover():
    redo_list = []
    undo_list = []
    
    # 扫描日志
    for log_entry in log:
        if log_entry.type == START:
            undo_list.append(log_entry.transaction)
        elif log_entry.type == COMMIT:
            redo_list.append(log_entry.transaction)
            undo_list.remove(log_entry.transaction)
    
    # 恢复
    for t in undo_list:
        undo(t)
    
    for t in redo_list:
        redo(t)
```

## 💾 检查点（Checkpoint）

**目的**：限制恢复时需要扫描的日志

### 流程

```
1. 暂停接受新事务
2. 等待所有活跃事务完成
3. 将所有脏数据写入磁盘
4. 写检查点日志
5. 恢复接受新事务

恢复时：只需从最近检查点开始
```

### 模糊检查点

**优化**：不暂停事务

```
1. 记录活跃事务列表
2. 写检查点（异步）
3. 继续处理事务

恢复：从检查点开始，重做/撤销活跃事务
```

## 🌐 分布式恢复

### 问题

**不同节点的恢复必须协调**

### 解决：协调恢复

```
1. 协调者记录参与者列表
2. 参与者记录事务状态
3. 崩溃后：
   - 协调者：询问参与者状态
   - 参与者：询问协调者决定
4. 根据2PC协议恢复
```

## 🔑 关键要点

1. **日志**：记录事务操作
2. **WAL**：先写日志后修改数据
3. **UNDO/REDO**：恢复到一致状态
4. **检查点**：减少恢复时间
5. **分布式**：需要协调恢复

---

**相关章节**：
- 上一节：[分布式死锁](./分布式死锁.md)
- 项目总结：[README](../README.md)

**🎉 恭喜！你已完成所有章节的学习！**

