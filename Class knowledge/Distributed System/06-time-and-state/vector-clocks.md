# 向量时钟

## 📌 问题

Lamport时钟无法判断并发事件

## 🎯 向量时钟

### 算法

```python
class VectorClock:
    def __init__(self, process_id, n_processes):
        self.id = process_id
        self.clock = [0] * n_processes
    
    def tick(self):
        self.clock[self.id] += 1
    
    def send_event(self):
        self.tick()
        return self.clock.copy()
    
    def receive_event(self, other_clock):
        for i in range(len(self.clock)):
            self.clock[i] = max(self.clock[i], other_clock[i])
        self.tick()
```

### 比较规则

```
V1 < V2：V1[i] ≤ V2[i] 对所有i，且存在j使V1[j] < V2[j]
V1 || V2：V1和V2并发（无法比较）
```

## 🔑 关键要点

1. **Lamport时钟**：提供全序，但无法检测并发
2. **向量时钟**：可以检测因果关系和并发
3. **代价**：向量时钟空间复杂度O(N)

---

**下一节**：[全局状态](./全局状态.md)

