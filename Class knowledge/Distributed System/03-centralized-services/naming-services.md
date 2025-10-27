# 命名服务

## 📌 为什么需要命名服务？

在分布式系统中，需要通过名字来定位资源：
- 用户通过名字访问文件
- 程序通过名字调用服务
- 客户端通过名字连接服务器

**问题**：如何将名字映射到实际的资源（IP地址、端口、对象引用等）？

**答案**：命名服务（Name Service）

## 🎯 命名服务的功能

### 核心功能

1. **名字解析（Name Resolution）**：
   - 输入：名字
   - 输出：资源的地址或引用

2. **名字绑定（Name Binding）**：
   - 将名字与资源关联

3. **名字管理**：
   - 添加、删除、更新名字

### 示例

```
名字: "www.example.com"
    ↓ (解析)
IP地址: "93.184.216.34"
    ↓
访问网站
```

## 📖 命名空间

### 1. 扁平命名空间（Flat Namespace）

**特点**：
- 名字无结构
- 全局唯一
- 类似数据库主键

**示例**：
```
- UUID: 550e8400-e29b-41d4-a716-446655440000
- MAC地址: 00:1A:2B:3C:4D:5E
- 身份证号: 110101199001011234
```

**优点**：
- ✅ 简单
- ✅ 保证唯一性

**缺点**：
- ❌ 不易记忆
- ❌ 无语义
- ❌ 难以管理

### 2. 结构化命名空间（Structured Namespace）

**特点**：
- 层次化结构
- 有语义
- 相对/绝对路径

#### 文件系统命名

```
/home/alice/documents/report.pdf
 │    │     │          │
 └─── 根目录
      └──── 用户目录
            └──── 文档目录
                  └──── 文件名
```

#### DNS命名

```
www.example.com
 │   │       │
 └── 主机名
     └───── 二级域名
           └──── 顶级域名
```

**优点**：
- ✅ 易于理解
- ✅ 便于管理
- ✅ 支持层次化组织

## 🌐 DNS：域名系统

### DNS架构

```
┌─────────────────────────────────┐
│         根域名服务器 (.)         │
│                                 │
└──────────┬─────────┬────────────┘
           │         │
    ┌──────▼────┐   └──────┬──────────┐
    │  .com服务器│         │  .org服务器│
    └──────┬────┘         └───────────┘
           │
    ┌──────▼────────┐
    │example.com服务器│
    └───────────────┘
```

### DNS解析过程

**迭代查询**：

```
1. 客户端 → 本地DNS: "www.example.com是什么?"
2. 本地DNS → 根DNS: "www.example.com是什么?"
3. 根DNS → 本地DNS: "去问.com服务器"
4. 本地DNS → .com DNS: "www.example.com是什么?"
5. .com DNS → 本地DNS: "去问example.com服务器"
6. 本地DNS → example.com DNS: "www.example.com是什么?"
7. example.com DNS → 本地DNS: "IP是93.184.216.34"
8. 本地DNS → 客户端: "IP是93.184.216.34"
```

**递归查询**：

```
1. 客户端 → 本地DNS: "www.example.com是什么?"
2. 本地DNS → 根DNS: "www.example.com是什么?"
3. 根DNS → .com DNS: "www.example.com是什么?"
4. .com DNS → example.com DNS: "www.example.com是什么?"
5. example.com DNS → .com DNS: "IP是93.184.216.34"
6. .com DNS → 根DNS: "IP是93.184.216.34"
7. 根DNS → 本地DNS: "IP是93.184.216.34"
8. 本地DNS → 客户端: "IP是93.184.216.34"
```

### DNS记录类型

| 类型 | 含义 | 示例 |
|------|------|------|
| A | IPv4地址 | example.com → 93.184.216.34 |
| AAAA | IPv6地址 | example.com → 2606:2800:220:1:... |
| CNAME | 别名 | www.example.com → example.com |
| MX | 邮件服务器 | example.com → mail.example.com |
| NS | 名字服务器 | example.com → ns1.example.com |
| TXT | 文本信息 | example.com → "v=spf1 ..." |

### DNS缓存

**作用**：减少查询次数，提高性能

```
┌─────────────┐
│   客户端    │
│  (缓存)     │
└──────┬──────┘
       │
┌──────▼──────┐
│   本地DNS   │
│  (缓存)     │
└──────┬──────┘
       │
┌──────▼──────┐
│  权威DNS    │
└─────────────┘
```

**TTL（Time To Live）**：
```
example.com.  3600  IN  A  93.184.216.34
               ↑
              TTL(秒)
           缓存有效期
```

## 🔍 目录服务

### LDAP（Lightweight Directory Access Protocol）

**用途**：
- 用户认证
- 组织结构管理
- 资源目录

**数据模型**：

```
树形结构:
dc=example,dc=com
  │
  ├─ ou=People
  │   ├─ cn=Alice
  │   └─ cn=Bob
  │
  └─ ou=Groups
      ├─ cn=Developers
      └─ cn=Admins
```

**查询示例**：

```ldap
# 搜索所有用户
ldapsearch -b "ou=People,dc=example,dc=com" "(objectClass=person)"

# 查找特定用户
ldapsearch -b "ou=People,dc=example,dc=com" "(cn=Alice)"
```

## 📍 服务发现

### 需求

在微服务架构中，服务实例动态变化：
- 服务启动/停止
- 扩容/缩容
- 故障转移

**问题**：客户端如何找到可用的服务实例？

### Consul示例

**架构**：

```
┌─────────┐      ┌─────────┐      ┌─────────┐
│服务实例1 │      │服务实例2 │      │服务实例3 │
└────┬────┘      └────┬────┘      └────┬────┘
     │                │                │
     └────────────────┼────────────────┘
                      │ 注册
               ┌──────▼──────┐
               │   Consul    │
               │  (服务注册)  │
               └──────▲──────┘
                      │ 发现
               ┌──────┴──────┐
               │   客户端    │
               └─────────────┘
```

**服务注册**：

```json
{
  "ID": "service-1",
  "Name": "web-service",
  "Tags": ["v1", "production"],
  "Address": "192.168.1.10",
  "Port": 8080,
  "Check": {
    "HTTP": "http://192.168.1.10:8080/health",
    "Interval": "10s"
  }
}
```

**服务发现**：

```bash
# 查询服务
curl http://consul:8500/v1/catalog/service/web-service

# 响应
[
  {
    "ID": "service-1",
    "Address": "192.168.1.10",
    "Port": 8080
  },
  {
    "ID": "service-2",
    "Address": "192.168.1.11",
    "Port": 8080
  }
]
```

### 健康检查

**作用**：确保只返回健康的服务实例

```python
# 服务端提供健康检查端点
@app.route('/health')
def health_check():
    # 检查数据库连接
    if database.is_connected():
        return {"status": "healthy"}, 200
    else:
        return {"status": "unhealthy"}, 503

# Consul定期调用健康检查
# 不健康的实例会被标记并从服务列表中移除
```

## 🔧 实现技术

### 1. Java RMI Registry

```java
// 服务注册
Registry registry = LocateRegistry.createRegistry(1099);
registry.bind("Calculator", calculatorImpl);

// 服务查找
Registry registry = LocateRegistry.getRegistry("localhost", 1099);
Calculator calc = (Calculator) registry.lookup("Calculator");
```

### 2. ZooKeeper

**特点**：
- 分布式协调服务
- 高可用
- 强一致性

**用途**：
- 配置管理
- 命名服务
- 分布式锁
- 组成员管理

```java
// 注册服务
ZooKeeper zk = new ZooKeeper("localhost:2181", 3000, null);
zk.create("/services/web-service-1", 
          "192.168.1.10:8080".getBytes(),
          ZooDefs.Ids.OPEN_ACL_UNSAFE,
          CreateMode.EPHEMERAL);

// 发现服务
List<String> services = zk.getChildren("/services", false);
for (String service : services) {
    byte[] data = zk.getData("/services/" + service, false, null);
    String address = new String(data);
}
```

### 3. Etcd

**特点**：
- 分布式键值存储
- Kubernetes默认使用
- 基于Raft共识算法

```bash
# 注册服务
etcdctl put /services/web-service-1 "192.168.1.10:8080"

# 查询服务
etcdctl get --prefix /services/

# 监听变化
etcdctl watch --prefix /services/
```

## 🔑 关键要点

1. **命名服务**：将名字映射到资源
2. **DNS**：互联网的命名服务
3. **目录服务**：层次化的信息存储（LDAP）
4. **服务发现**：微服务架构的关键组件
5. **实现**：RMI Registry、ZooKeeper、Consul、Etcd

## 💡 思考问题

1. 为什么DNS使用缓存？这会带来什么问题？
2. 服务发现和DNS有什么区别？
3. 如何设计一个高可用的命名服务？

---

**相关章节**：
- 上一节：[远程方法调用RMI](./远程方法调用RMI.md)
- 下一章：[04-分布式存储](../04-分布式存储/)
- 相关：[05-去中心化系统](../05-去中心化系统/)

