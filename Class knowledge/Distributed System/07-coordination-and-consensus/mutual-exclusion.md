# 互斥算法

## 📌 问题

**临界区（Critical Section）**：同一时刻只能有一个进程访问的代码段

### 要求

1. **安全性（Safety）**：最多一个进程在临界区
2. **活性（Liveness）**：请求最终被满足
3. **公平性**：按顺序授予访问权

## 🔧 算法

### 1. 中心服务器算法

**原理**：中心服务器持有令牌，授予访问权

```python
# 服务器
token_holder = None
queue = []

def request_token(client_id):
    if token_holder is None:
        grant_token(client_id)
    else:
        queue.append(client_id)

def release_token():
    token_holder = None
    if queue:
        grant_token(queue.pop(0))
```

**优点**：✅ 简单，公平
**缺点**：❌ 单点故障

### 2. 环形算法

**原理**：令牌在环中传递

```
P1 → P2 → P3 → P4 → P1
   令牌
```

**优点**：✅ 去中心化
**缺点**：❌ 令牌丢失问题

### 3. Ricart-Agrawala算法

**原理**：请求所有进程的许可

```python
def enter_critical_section():
    timestamp = lamport_clock.tick()
    send_to_all("REQUEST", timestamp)
    wait_for_all_replies()
    enter()

def on_receive_request(sender, ts):
    if not in_critical_section and not want_to_enter:
        send(sender, "REPLY")
    elif ts < my_timestamp:
        send(sender, "REPLY")
    else:
        queue.append(sender)

def exit_critical_section():
    for p in queue:
        send(p, "REPLY")
    queue.clear()
```

**优点**：✅ 去中心化，公平
**缺点**：❌ 消息开销大（O(N)）

## 🔑 关键要点

1. **互斥**：保证临界区互斥访问
2. **算法**：中心化、环形、分布式
3. **权衡**：性能 vs 容错 vs 复杂度

---

**下一节**：[领导者选举](./领导者选举.md)

