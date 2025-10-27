# 组通信

## 📌 什么是组通信？

**组通信（Group Communication）**：一个进程向一组进程发送消息的通信模式。

### 与点对点通信的区别

**点对点通信**：
```
发送者 ──────> 接收者
```

**组通信**：
```
         ┌──> 接收者1
发送者 ──┼──> 接收者2
         └──> 接收者3
```

## 🎯 组通信的应用场景

### 1. 服务复制（Replication）

**场景**：更新所有副本
```
客户端──> 更新请求
          ↓
     ┌────┴────┬────────┐
     ▼         ▼        ▼
   副本1     副本2    副本3
   (更新)   (更新)   (更新)
```

### 2. 服务发现（Service Discovery）

**场景**：查找可用服务
```
客户端──> "谁提供打印服务?"
          ↓ (广播)
     ┌────┴────┬────────┐
     ▼         ▼        ▼
  服务器1   服务器2   服务器3
   (响应)              (响应)
```

### 3. 分布式通知（Notification）

**场景**：事件通知
```
事件源──> "数据已更新"
          ↓
     ┌────┴────┬────────┐
     ▼         ▼        ▼
  订阅者1   订阅者2   订阅者3
  (处理)    (处理)    (处理)
```

### 4. 协调一致（Coordination）

**场景**：分布式协议
```
协调者──> "准备提交?"
          ↓
     ┌────┴────┬────────┐
     ▼         ▼        ▼
  参与者1   参与者2   参与者3
  (投票)    (投票)    (投票)
```

## 📡 组通信的实现方式

### 1. 多播（Multicast）

**定义**：一次发送，多个接收者同时接收

#### IP多播

**特点**：
- 使用特殊的IP地址范围（224.0.0.0 - 239.255.255.255）
- 路由器支持多播转发
- 高效利用网络带宽

**工作原理**：
```
发送者发送一份数据包
    ↓
网络路由器复制数据包
    ↓
每个接收者收到一份副本
```

**优点**：
- ✅ 网络效率高
- ✅ 减少发送者负担

**缺点**：
- ❌ 不是所有网络都支持
- ❌ 不保证可靠性

### 2. 应用层多播

**定义**：在应用层实现的多播

#### 方法1：顺序单播

```python
def multicast(message, recipients):
    for recipient in recipients:
        send(recipient, message)
```

**示例**：
```
发送者 ─┬─> 接收者1 (t1)
        ├─> 接收者2 (t2)
        └─> 接收者3 (t3)

问题：不同接收者接收时间不同
```

**优点**：
- ✅ 简单实现
- ✅ 兼容性好

**缺点**：
- ❌ 发送者负担重
- ❌ 接收时间不一致
- ❌ 网络流量大

#### 方法2：覆盖网络（Overlay Network）

**树形结构**：
```
      发送者
        │
    ┌───┴───┐
    ▼       ▼
  节点1    节点2
    │       │
  ┌─┴─┐   ┌─┴─┐
  ▼   ▼   ▼   ▼
 接1  接2 接3  接4
```

**优点**：
- ✅ 分散负载
- ✅ 可扩展

**缺点**：
- ❌ 中间节点故障影响大
- ❌ 维护复杂

## 🔒 可靠组通信

### 可靠性级别

#### 1. 基本多播（Basic Multicast）

**保证**：
- 如果发送者不崩溃，所有正常进程都会接收到消息
- 不保证消息顺序

**问题**：
```
发送者 ─┬─> 接收者1 ✓
        ├─> 接收者2 ✗ (网络故障)
        └─> 接收者3 ✓

结果：不一致状态
```

#### 2. 可靠多播（Reliable Multicast）

**保证**：
- 如果一个正常进程接收到消息，所有正常进程最终都会接收到
- 即使发送者崩溃

**实现**：
```
接收者1收到消息后转发给其他接收者
确保所有人都收到
```

#### 3. 有序多播（Ordered Multicast）

**类型**：

##### FIFO顺序

**保证**：同一发送者的消息按发送顺序接收

```
发送者P: m1 → m2 → m3
所有接收者: m1 → m2 → m3 ✓
```

##### 因果顺序（Causal Order）

**保证**：有因果关系的消息按因果顺序接收

```
P1: m1 ──────┐
             ▼
P2:        m2 (依赖m1)

所有接收者必须先收到m1，再收到m2
```

##### 全序顺序（Total Order）

**保证**：所有进程以相同顺序接收所有消息

```
可能的顺序: m1, m2, m3
所有接收者看到相同的顺序
不一定是发送顺序
```

**示例应用**：
```
复制的数据库服务器
所有副本必须以相同顺序执行更新操作
```

### 顺序对比

| 顺序类型 | 保证 | 复杂度 | 应用 |
|---------|------|--------|------|
| FIFO | 每个发送者的消息有序 | 低 | 聊天系统 |
| 因果 | 因果相关的消息有序 | 中 | 协作编辑 |
| 全序 | 所有消息全局有序 | 高 | 数据库复制 |

## 🔄 组通信实现示例

### 1. 基于确认的可靠多播

```python
class ReliableMulticast:
    def __init__(self, group_members):
        self.members = group_members
        self.delivered = set()  # 已递交的消息
    
    def multicast(self, message):
        message_id = generate_id()
        
        # 发送给所有成员
        for member in self.members:
            send(member, message, message_id)
        
        # 等待所有确认
        acks = wait_for_acks(message_id, self.members)
        
        if len(acks) == len(self.members):
            return True
        else:
            # 重试未确认的成员
            retry(message, message_id, missing_acks)
    
    def receive(self, message, message_id):
        if message_id not in self.delivered:
            # 递交给应用层
            deliver(message)
            self.delivered.add(message_id)
            
            # 转发给其他成员（确保可靠性）
            forward_to_others(message, message_id)
        
        # 发送确认
        send_ack(message_id)
```

### 2. 基于序列号的FIFO多播

```python
class FIFOMulticast:
    def __init__(self):
        self.send_seq = {}      # 每个发送者的发送序列号
        self.receive_seq = {}   # 每个发送者的接收序列号
        self.hold_back = {}     # 延迟队列
    
    def multicast(self, sender_id, message):
        # 分配序列号
        seq = self.send_seq.get(sender_id, 0)
        self.send_seq[sender_id] = seq + 1
        
        # 发送消息
        send_to_group(message, sender_id, seq)
    
    def receive(self, message, sender_id, seq):
        expected_seq = self.receive_seq.get(sender_id, 0)
        
        if seq == expected_seq:
            # 按序到达，递交
            deliver(message)
            self.receive_seq[sender_id] = seq + 1
            
            # 检查延迟队列
            check_hold_back(sender_id)
        else:
            # 乱序到达，放入延迟队列
            self.hold_back[(sender_id, seq)] = message
```

### 3. 全序多播（使用序列器）

```python
class TotalOrderMulticast:
    def __init__(self, sequencer_id):
        self.sequencer = sequencer_id
        self.global_seq = 0
        self.hold_back = {}
        self.next_deliver = 0
    
    def multicast(self, message):
        # 发送给序列器
        send(self.sequencer, message)
    
    def sequencer_process(self, message):
        # 分配全局序列号
        seq = self.global_seq
        self.global_seq += 1
        
        # 多播消息和序列号
        multicast_to_group(message, seq)
    
    def receive(self, message, seq):
        if seq == self.next_deliver:
            # 按序到达
            deliver(message)
            self.next_deliver += 1
            
            # 检查延迟队列
            while self.next_deliver in self.hold_back:
                deliver(self.hold_back[self.next_deliver])
                del self.hold_back[self.next_deliver]
                self.next_deliver += 1
        else:
            # 乱序到达，延迟
            self.hold_back[seq] = message
```

## 🌐 实际系统示例

### 1. JGroups

**特点**：
- Java组通信库
- 支持多种协议栈
- 灵活配置

**示例**：
```java
JChannel channel = new JChannel();
channel.connect("MyCluster");

// 发送消息
channel.send(null, "Hello Group!");

// 接收消息
channel.setReceiver(new ReceiverAdapter() {
    public void receive(Message msg) {
        System.out.println("Received: " + msg.getObject());
    }
});
```

### 2. Apache Kafka

**特点**：
- 发布-订阅模型
- 高吞吐量
- 持久化存储

**架构**：
```
生产者 ──> Topic ──> 分区1 ──> 消费者组1
                ├─> 分区2 ──> 消费者组2
                └─> 分区3 ──> 消费者组3
```

### 3. Redis Pub/Sub

**特点**：
- 简单的发布-订阅
- 实时性好
- 不保证持久化

**示例**：
```python
# 发布者
redis.publish('channel1', 'Hello')

# 订阅者
pubsub = redis.pubsub()
pubsub.subscribe('channel1')
for message in pubsub.listen():
    print(message)
```

## 🔑 关键要点

1. **组通信**：一对多的通信模式
2. **可靠性**：基本、可靠、有序多播
3. **顺序保证**：FIFO、因果、全序
4. **实现方式**：IP多播、应用层多播
5. **实际应用**：消息队列、发布订阅系统

## 💡 思考问题

1. 为什么全序多播比FIFO多播更难实现？
2. 如何在不支持IP多播的网络上实现高效的组通信？
3. 什么场景下需要因果顺序而不是全序？

---

**相关章节**：
- 上一节：[客户端服务器通信](./客户端服务器通信.md)
- 下一节：[通信协议](./通信协议.md)
- 相关：[08-复制与容错](../08-复制与容错/)

