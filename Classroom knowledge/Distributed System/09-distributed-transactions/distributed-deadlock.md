# 分布式死锁

## 📌 什么是死锁？

**死锁**：一组事务互相等待对方持有的资源

### 示例

```
T1: 持有A，等待B
T2: 持有B，等待A

T1 → B → T2 → A → T1 (循环等待)
```

## 🔍 死锁检测

### 等待图（Wait-For Graph）

**节点**：事务
**边**：Ti → Tj（Ti等待Tj）

**死锁 = 图中有环**

### 本地 vs 全局

**本地等待图**：
```
服务器A：T1 → T2
服务器B：T2 → T3
```

**全局等待图**：
```
合并：T1 → T2 → T3

可能的死锁：
T1 → T2 → T1（跨服务器）
```

## 🔧 死锁检测算法

### 1. 中心化检测

**流程**：
```
1. 各服务器发送本地等待图到中心节点
2. 中心节点构建全局等待图
3. 检测环
4. 如有环，选择事务中止
```

**缺点**：
- ❌ 单点故障
- ❌ 通信开销

### 2. 边追踪（Edge Chasing）

**原理**：在图中转发探测消息

```python
# 服务器X发现T1等待T2
def on_new_edge(T1, T2):
    send_probe(T1, T2, [T1, T2])

# 收到探测消息
def on_receive_probe(initiator, path):
    if initiator in path:
        # 检测到环！
        deadlock_detected(path)
    else:
        # 转发给当前等待的事务
        if waiting_for(T_next):
            send_probe(initiator, T_next, 
                      path + [T_next])
```

**示例**：
```
服务器A：T1等待T2
发送探测：(T1, [T1, T2]) → 服务器B

服务器B：T2等待T3  
转发探测：(T1, [T1, T2, T3]) → 服务器C

服务器C：T3等待T1
收到探测：T1在路径中 → 死锁！
```

## 🛡️ 死锁预防

### 1. 等待-死亡（Wait-Die）

```python
if T1.ts < T2.ts:  # T1更老
    wait()  # 等待
else:
    die()  # 中止并重启
```

### 2. 伤害-等待（Wound-Wait）

```python
if T1.ts < T2.ts:  # T1更老
    wound(T2)  # 中止T2
else:
    wait()  # 等待
```

### 3. 超时

```python
if wait_time > TIMEOUT:
    abort()  # 中止事务
```

**优点**：
- ✅ 简单
- ✅ 无需构建等待图

**缺点**：
- ❌ 可能误杀（不是死锁也中止）

## 🔑 关键要点

1. **死锁**：循环等待资源
2. **检测**：全局等待图、边追踪
3. **预防**：等待-死亡、超时
4. **权衡**：检测成本 vs 中止成本

---

**下一节**：[事务恢复](./事务恢复.md)

