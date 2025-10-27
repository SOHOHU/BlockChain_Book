# DHT分布式哈希表

## 📌 什么是DHT？

**DHT（Distributed Hash Table）**：分布式环境中的哈希表

### 本地哈希表 vs DHT

```
本地哈希表:
map["key"] = value

DHT:
dht.put("key", value)  # 存储到某个节点
value = dht.get("key")  # 从某个节点获取
```

## 🏗️ DHT接口

```python
put(key, value)  # 存储键值对
get(key)         # 获取值
delete(key)      # 删除键值对
```

## 🎯 DHT应用

1. **文件共享**：BitTorrent
2. **内容分发**：CDN
3. **分布式存储**：DynamoDB
4. **区块链**：IPFS

## 🔧 DHT实现

### Chord示例

```python
class ChordDHT:
    def put(self, key, value):
        node = find_successor(hash(key))
        node.store(key, value)
    
    def get(self, key):
        node = find_successor(hash(key))
        return node.retrieve(key)
```

## 🔑 关键要点

1. **DHT**：分布式键值存储
2. **Chord**：基于一致性哈希的DHT实现
3. **应用广泛**：P2P、存储、区块链

---

**相关章节**：
- 上一节：[Chord协议](./Chord协议.md)
- 下一章：[06-时间与状态](../06-时间与状态/)

