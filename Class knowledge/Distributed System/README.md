# SC6103 分布式系统 - 学习笔记与课程项目

> 南洋理工大学 SC6103 Distributed Systems 课程完整学习资料

```
01-fundamentals/                      # 分布式系统的本质特征与核心概念
├── definition-and-characteristics.md   # 分布式系统定义与特性
├── system-models.md                    # 系统模型
├── challenges-and-goals.md             # 挑战与设计目标
└── resource-sharing-and-web.md         # 资源共享与Web示例

02-communication/                      # 进程间如何交互与通信
├── data-representation-and-marshalling.md  # 数据表示与编组
├── client-server-communication.md         # 客户端服务器通信
├── group-communication.md                  # 组通信
└── communication-protocols.md              # 通信协议

03-centralized-services/              # 基于中心化架构的服务模型
├── client-server-model.md              # 客户端服务器模型
├── remote-procedure-call.md            # 远程过程调用RPC
├── remote-method-invocation.md         # 远程方法调用RMI
└── naming-services.md                  # 命名服务

04-distributed-storage/               # 分布式环境下的文件系统
├── distributed-file-systems-overview.md  # 分布式文件系统概述
├── nfs-architecture-and-implementation.md # NFS架构与实现
├── client-caching.md                      # 客户端缓存
└── andrew-and-coda-file-systems.md        # Andrew与Coda文件系统

05-decentralized-systems/             # P2P架构与去中心化设计
├── p2p-systems-overview.md             # P2P系统概述
├── napster-and-hybrid-architecture.md  # Napster与混合架构
├── routing-overlay-networks.md         # 路由覆盖网络
├── chord-protocol.md                   # Chord协议（深度详解）⭐
└── distributed-hash-table.md           # DHT分布式哈希表

06-time-and-state/                    # 分布式环境中的时间与全局状态
├── physical-clocks-and-synchronization.md  # 物理时钟与同步
├── logical-clocks.md                       # 逻辑时钟（深度详解）⭐
├── vector-clocks.md                        # 向量时钟
├── global-state.md                         # 全局状态
└── snapshot-algorithms.md                  # 快照算法（深度详解）⭐

07-coordination-and-consensus/        # 分布式进程的协调机制
├── mutual-exclusion.md                 # 互斥算法
├── leader-election.md                  # 领导者选举
├── consensus.md                        # 共识问题
└── byzantine-generals-problem.md       # 拜占庭将军问题

08-replication-and-fault-tolerance/   # 数据复制与一致性模型
├── replication-purpose-and-challenges.md   # 复制的目的与挑战
├── passive-and-active-replication.md       # 被动复制与主动复制
├── consistency-models.md                   # 一致性模型
└── gossip-protocol.md                      # Gossip协议

09-distributed-transactions/          # 事务处理与并发控制
├── distributed-transactions-overview.md    # 分布式事务概述
├── atomic-commit-protocols.md              # 原子提交协议（深度详解）⭐
├── concurrency-control.md                  # 并发控制
├── distributed-deadlock.md                 # 分布式死锁
└── transaction-recovery.md                 # 事务恢复
```

详细的学习笔记说明请查看：[distributed-systems-notes/README.md](./distributed-systems-notes/README.md)

---

### 期末课程项目（facility-booking-server/）

**项目名称**：设施预订服务器（Facility Booking Server）

```
facility-booking-server/
├── src/main/java/
│   └── edu/ntu/sc6103/booking/
│       ├── server/          # 服务器实现
│       │   ├── UDPServer.java
│       │   └── RequestProcessor.java
│       ├── client/          # 客户端实现
│       │   └── UDPClient.java
│       ├── core/            # 核心业务逻辑
│       │   ├── BookingManager.java
│       │   ├── Facility.java
│       │   └── Booking.java
│       └── protocol/        # 协议实现
│           └── MessageMarshaller.java
├── config/                  # 配置文件
├── demo-scripts/            # 演示脚本
└── Readme.md               # 详细使用说明

详细的项目文档请查看：[facility-booking-server/Readme.md](./facility-booking-server/Readme.md)
```
**Last Updated**: 2025-10

