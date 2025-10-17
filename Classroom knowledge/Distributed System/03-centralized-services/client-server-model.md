# 客户端服务器模型

## 📌 什么是客户端-服务器模型？

**客户端-服务器（Client-Server）模型**是分布式系统中最基本和广泛使用的架构模式。

### 核心概念

```
┌──────────┐                  ┌──────────┐
│  Client  │ ─────请求──────> │  Server  │
│ (客户端)  │ <────响应────── │ (服务器)  │
└──────────┘                  └──────────┘
```

**客户端（Client）**：
- 发起请求的进程
- 等待服务器响应
- 主动方

**服务器（Server）**：
- 等待并处理客户端请求
- 提供服务
- 被动方（但会主动监听）

## 🎯 服务器的角色与职责

### 服务器的主要功能

1. **管理资源**
   - 文件、数据库、打印机等
   - 维护资源状态
   - 控制访问权限

2. **提供服务**
   - 响应客户端请求
   - 执行操作
   - 返回结果

3. **并发处理**
   - 同时服务多个客户端
   - 资源调度
   - 负载管理

### 服务器类型

#### 1. 无状态服务器（Stateless Server）

**特点**：
- 不保存客户端状态
- 每个请求独立
- 服务器可以自由重启

**示例**：HTTP服务器
```http
# 第一个请求
GET /page1.html
# 服务器不记住这个客户端

# 第二个请求
GET /page2.html
# 服务器把它当作全新请求处理
```

**优点**：
- ✅ 简单
- ✅ 可扩展（易于添加服务器）
- ✅ 容错性好（服务器崩溃影响小）

**缺点**：
- ❌ 每次请求可能需要传输更多信息
- ❌ 无法优化连续请求

#### 2. 有状态服务器（Stateful Server）

**特点**：
- 保存客户端状态
- 请求之间有关联
- 可以优化性能

**示例**：FTP服务器
```
# 登录
USER alice
PASS secret123

# 切换目录（服务器记住当前目录）
CWD /documents

# 下载文件（从当前目录）
RETR file.txt
```

**优点**：
- ✅ 减少数据传输
- ✅ 可以优化连续操作
- ✅ 更好的用户体验

**缺点**：
- ❌ 复杂性高
- ❌ 难以扩展
- ❌ 服务器崩溃影响大

### 状态管理策略

**混合方案：软状态（Soft State）**

```
服务器端：缓存客户端状态，但可以重建
客户端：保存必要信息，可以重新发送

示例：HTTP Cookie + Session
```

## 🏗️ 服务器架构

### 1. 迭代服务器（Iterative Server）

**特点**：一次处理一个请求

```python
# 迭代服务器伪代码
server_socket = create_socket()
server_socket.bind(address, port)
server_socket.listen()

while True:
    client_socket = server_socket.accept()
    request = client_socket.receive()
    response = process_request(request)
    client_socket.send(response)
    client_socket.close()
```

**流程**：
```
服务器
  │
  ├─ 接受连接1 ─> 处理 ─> 响应 ─> 关闭
  │
  ├─ 接受连接2 ─> 处理 ─> 响应 ─> 关闭
  │
  └─ 接受连接3 ─> 处理 ─> 响应 ─> 关闭
```

**优点**：
- ✅ 简单
- ✅ 易于调试

**缺点**：
- ❌ 低效
- ❌ 一个慢请求阻塞所有后续请求

**适用**：请求处理时间短且可预测的服务

### 2. 并发服务器（Concurrent Server）

#### 2.1 多线程服务器

**特点**：为每个客户端创建一个线程

```python
# 多线程服务器伪代码
import threading

server_socket = create_socket()
server_socket.bind(address, port)
server_socket.listen()

def handle_client(client_socket):
    request = client_socket.receive()
    response = process_request(request)
    client_socket.send(response)
    client_socket.close()

while True:
    client_socket = server_socket.accept()
    thread = threading.Thread(target=handle_client, 
                             args=(client_socket,))
    thread.start()
```

**流程**：
```
服务器
  │
  ├─ 接受连接1 ──> 线程1处理
  │
  ├─ 接受连接2 ──> 线程2处理
  │
  └─ 接受连接3 ──> 线程3处理
       (同时进行)
```

**优点**：
- ✅ 并发处理
- ✅ 响应快
- ✅ 共享内存

**缺点**：
- ❌ 线程开销
- ❌ 线程数量受限
- ❌ 同步复杂

#### 2.2 线程池服务器

**特点**：预先创建固定数量的线程

```python
from concurrent.futures import ThreadPoolExecutor

server_socket = create_socket()
server_socket.bind(address, port)
server_socket.listen()

# 创建线程池
executor = ThreadPoolExecutor(max_workers=100)

def handle_client(client_socket):
    request = client_socket.receive()
    response = process_request(request)
    client_socket.send(response)
    client_socket.close()

while True:
    client_socket = server_socket.accept()
    executor.submit(handle_client, client_socket)
```

**架构**：
```
       请求队列
         │
    ┌────┴────┬────────┬────────┐
    ▼         ▼        ▼        ▼
  线程1     线程2    线程3    线程4
  (工作)   (空闲)   (工作)   (空闲)
```

**优点**：
- ✅ 控制并发度
- ✅ 避免线程创建开销
- ✅ 资源可控

**缺点**：
- ❌ 线程池满时需要等待

#### 2.3 事件驱动服务器

**特点**：单线程+事件循环+非阻塞I/O

```python
import select

server_socket = create_socket()
server_socket.bind(address, port)
server_socket.listen()
server_socket.setblocking(False)

sockets = [server_socket]

while True:
    readable, writable, exceptional = select.select(
        sockets, [], sockets)
    
    for s in readable:
        if s is server_socket:
            # 新连接
            client_socket, addr = s.accept()
            client_socket.setblocking(False)
            sockets.append(client_socket)
        else:
            # 数据到达
            data = s.recv(4096)
            if data:
                response = process_request(data)
                s.send(response)
            else:
                sockets.remove(s)
                s.close()
```

**架构**：
```
事件循环
  │
  ├─ 检测事件
  ├─ 分发事件
  └─ 处理事件
      │
      ├─ 新连接
      ├─ 数据可读
      └─ 数据可写
```

**优点**：
- ✅ 高效（单线程，无上下文切换）
- ✅ 可扩展（支持大量连接）
- ✅ 无同步问题

**缺点**：
- ❌ 复杂性高
- ❌ CPU密集型任务会阻塞
- ❌ 调试困难

**适用**：高并发、I/O密集型服务

### 3. 多进程服务器

**特点**：为每个客户端创建一个进程

```python
import os

server_socket = create_socket()
server_socket.bind(address, port)
server_socket.listen()

while True:
    client_socket = server_socket.accept()
    
    pid = os.fork()
    if pid == 0:  # 子进程
        server_socket.close()
        request = client_socket.receive()
        response = process_request(request)
        client_socket.send(response)
        client_socket.close()
        exit(0)
    else:  # 父进程
        client_socket.close()
```

**优点**：
- ✅ 隔离性好（进程间独立）
- ✅ 稳定性高（一个崩溃不影响其他）

**缺点**：
- ❌ 开销大
- ❌ 进程间通信复杂
- ❌ 不共享内存

## 🔄 客户端架构

### 1. 瘦客户端（Thin Client）

**特点**：
- 大部分逻辑在服务器端
- 客户端只负责显示
- 依赖服务器

**示例**：
```
Web浏览器 → 请求HTML → Web服务器
         ← 渲染页面 ← (生成HTML)
```

**优点**：
- ✅ 易于维护
- ✅ 安全性好
- ✅ 客户端要求低

**缺点**：
- ❌ 依赖网络
- ❌ 服务器负担重
- ❌ 响应可能较慢

### 2. 胖客户端（Thick Client）

**特点**：
- 大部分逻辑在客户端
- 服务器主要提供数据
- 相对独立

**示例**：
```
邮件客户端 → 请求邮件数据 → 邮件服务器
          ← 邮件列表 ←
          (客户端处理显示、搜索等)
```

**优点**：
- ✅ 响应快
- ✅ 离线功能
- ✅ 减轻服务器负担

**缺点**：
- ❌ 维护复杂
- ❌ 安全风险
- ❌ 客户端要求高

## 🌐 经典示例

### 1. Web服务器

**Apache HTTP Server架构**：
```
主进程（监听连接）
  │
  ├─ 工作进程1
  ├─ 工作进程2
  ├─ 工作进程3
  └─ 工作进程4
     (处理请求)
```

### 2. 数据库服务器

**MySQL架构**：
```
客户端连接
  │
  ▼
连接线程
  │
  ├─ 查询解析
  ├─ 查询优化
  ├─ 查询执行
  └─ 结果返回
```

### 3. 文件服务器

**NFS架构**：
```
客户端 → RPC请求 → NFS服务器
       ← 文件数据 ← (访问本地文件系统)
```

## 🔑 关键要点

1. **Client-Server模型**：最基本的分布式架构
2. **状态管理**：无状态简单可扩展，有状态复杂但高效
3. **服务器架构**：迭代、多线程、事件驱动各有优劣
4. **客户端类型**：瘦客户端 vs 胖客户端
5. **设计权衡**：性能、可扩展性、复杂度

## 💡 思考问题

1. 为什么HTTP被设计为无状态协议？
2. 什么场景下事件驱动服务器比多线程服务器更好？
3. 如何设计一个既可扩展又能保持状态的服务器？

---

**相关章节**：
- 下一节：[远程过程调用RPC](./远程过程调用RPC.md)
- 相关：[01-基础概念/系统模型](../01-基础概念/系统模型.md)
- 对比：[05-去中心化系统/P2P系统概述](../05-去中心化系统/P2P系统概述.md)

