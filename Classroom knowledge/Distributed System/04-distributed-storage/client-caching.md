# 客户端缓存

## 📌 为什么需要缓存？

**目标**：减少网络访问，提高性能

### 缓存的好处

```
无缓存：每次访问都需要网络通信
有缓存：命中缓存时无需网络通信

性能提升：10-100倍
```

## 🔄 缓存策略

### 1. Write-Through（写穿）

**策略**：写操作立即同步到服务器

```python
def write(data):
    cache.update(data)
    server.write(data)  # 立即写入
```

**优点**：✅ 强一致性
**缺点**：❌ 写性能差

### 2. Write-Back（写回）

**策略**：写操作先写缓存，延迟写入服务器

```python
def write(data):
    cache.update(data)
    mark_dirty()
    # 稍后异步写入服务器
```

**优点**：✅ 写性能好
**缺点**：❌ 弱一致性，数据可能丢失

### 3. Write-On-Close

**策略**：关闭文件时写入服务器

```python
def close():
    if dirty:
        server.write(cache_data)
```

## 🔒 缓存一致性

### NFS方法：轮询验证

```python
if time.now() - last_validation > TTL:
    attr = server.getattr(file)
    if attr.mtime > cache.mtime:
        invalidate_cache()
```

### AFS方法：回调承诺

```python
# 服务器承诺：如果文件被修改，通知客户端
server.register_callback(client, file)

# 文件被其他客户端修改时
server.notify(client, file)  # 使缓存失效
```

## 💡 思考问题

1. Write-Through和Write-Back各适合什么场景？
2. 如何在一致性和性能之间取得平衡？

---

**相关章节**：
- 上一节：[NFS架构与实现](./NFS架构与实现.md)
- 下一节：[Andrew与Coda文件系统](./Andrew与Coda文件系统.md)

