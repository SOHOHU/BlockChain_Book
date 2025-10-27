# 远程方法调用（RMI）

## 📌 RMI vs RPC

**RMI（Remote Method Invocation）**：面向对象的RPC

| 特性 | RPC | RMI |
|------|-----|-----|
| 范式 | 过程式 | 面向对象 |
| 调用单位 | 函数/过程 | 对象方法 |
| 参数 | 基本类型、结构体 | 对象 |
| 状态 | 无状态 | 有状态（对象） |

## 🏗️ RMI架构

### 分布式对象

```
客户端                               服务器
┌──────────┐                      ┌──────────┐
│  客户端   │                      │  实际对象 │
│          │                      │          │
│    ↓     │                      │    ▲     │
│ 代理对象  │ ─────远程调用────>  │  骨架    │
│ (Proxy)  │                      │(Skeleton)│
└──────────┘                      └──────────┘
```

**关键概念**：

1. **远程对象（Remote Object）**：
   - 可以被远程调用的对象
   - 实现在服务器上

2. **代理对象（Proxy/Stub）**：
   - 客户端的本地对象
   - 转发调用到远程对象

3. **骨架（Skeleton）**：
   - 服务器端接收远程调用
   - 调用实际对象方法

## 💻 Java RMI示例

### 1. 定义远程接口

```java
import java.rmi.Remote;
import java.rmi.RemoteException;

public interface Calculator extends Remote {
    int add(int a, int b) throws RemoteException;
    int subtract(int a, int b) throws RemoteException;
    double divide(double a, double b) throws RemoteException;
}
```

**要点**：
- 继承`Remote`接口
- 所有方法抛出`RemoteException`

### 2. 实现远程对象

```java
import java.rmi.server.UnicastRemoteObject;
import java.rmi.RemoteException;

public class CalculatorImpl extends UnicastRemoteObject 
                            implements Calculator {
    
    public CalculatorImpl() throws RemoteException {
        super();
    }
    
    @Override
    public int add(int a, int b) throws RemoteException {
        return a + b;
    }
    
    @Override
    public int subtract(int a, int b) throws RemoteException {
        return a - b;
    }
    
    @Override
    public double divide(double a, double b) throws RemoteException {
        if (b == 0) {
            throw new RemoteException("Division by zero");
        }
        return a / b;
    }
}
```

### 3. 服务器端注册

```java
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;

public class Server {
    public static void main(String[] args) {
        try {
            // 创建远程对象
            Calculator calculator = new CalculatorImpl();
            
            // 创建注册表
            Registry registry = LocateRegistry.createRegistry(1099);
            
            // 绑定远程对象
            registry.rebind("Calculator", calculator);
            
            System.out.println("Server ready");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

### 4. 客户端调用

```java
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;

public class Client {
    public static void main(String[] args) {
        try {
            // 获取注册表
            Registry registry = LocateRegistry.getRegistry("localhost", 1099);
            
            // 查找远程对象
            Calculator calculator = (Calculator) registry.lookup("Calculator");
            
            // 调用远程方法（像本地方法一样）
            int sum = calculator.add(5, 3);
            System.out.println("5 + 3 = " + sum);
            
            double quotient = calculator.divide(10.0, 2.0);
            System.out.println("10 / 2 = " + quotient);
            
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

## 🔄 对象传递

### 1. 按引用传递（Pass by Reference）

**远程对象**：传递远程引用

```java
// 服务器创建远程对象
RemoteObject obj = new RemoteObjectImpl();

// 客户端接收到的是代理
RemoteObject proxy = server.getRemoteObject();
proxy.method();  // 远程调用
```

**流程**：
```
客户端                    服务器
  │                        │
  │<─── 远程引用 ─────────│
  │                        │
  │─── method()调用 ─────>│
  │                        │
  │<──── 结果 ────────────│
```

### 2. 按值传递（Pass by Value）

**可序列化对象**：复制整个对象

```java
// 定义可序列化类
public class Data implements Serializable {
    private int value;
    private String text;
    // ...
}

// 服务器接口
public interface DataService extends Remote {
    Data getData() throws RemoteException;
    void setData(Data data) throws RemoteException;
}

// 客户端调用
Data data = service.getData();  // 获得对象的副本
data.setValue(100);  // 修改本地副本
service.setData(data);  // 发送修改后的副本
```

**流程**：
```
客户端                    服务器
  │                        │
  │<─ Data对象的副本 ─────│
  │                        │
  │ 修改本地副本           │
  │                        │
  │─ 发送修改后的副本 ────>│
```

### 对比

| 传递方式 | 对象类型 | 开销 | 使用场景 |
|---------|---------|------|---------|
| 按引用 | 远程对象 | 低 | 大对象、有状态 |
| 按值 | 可序列化对象 | 高 | 小对象、数据传输 |

## 🎯 分布式对象模型：CORBA

**CORBA（Common Object Request Broker Architecture）**：跨语言的分布式对象标准

### 架构

```
┌──────────┐           ┌──────────┐           ┌──────────┐
│ Java客户端│           │   ORB    │           │ C++服务器 │
│          │<───────>  │(对象请求  │<───────> │          │
│  对象    │  IIOP    │  代理)   │   IIOP   │  对象    │
└──────────┘           └──────────┘           └──────────┘
```

**组件**：

1. **ORB（Object Request Broker）**：
   - 对象请求代理
   - 处理远程调用

2. **IDL（Interface Definition Language）**：
   - 接口定义语言
   - 语言无关

3. **IIOP（Internet Inter-ORB Protocol）**：
   - 通信协议
   - 基于TCP/IP

### IDL示例

```idl
// Calculator.idl
module calculator {
    interface Calculator {
        long add(in long a, in long b);
        long subtract(in long a, in long b);
        double divide(in double a, in double b);
    };
};
```

**编译IDL**：
```bash
# 生成Java代码
idlj -fall Calculator.idl

# 生成C++代码
idl2cpp Calculator.idl
```

## 🔒 对象生命周期

### 创建与销毁

```java
// 工厂模式创建远程对象
public interface ObjectFactory extends Remote {
    RemoteObject createObject() throws RemoteException;
    void destroyObject(RemoteObject obj) throws RemoteException;
}

// 客户端使用
ObjectFactory factory = ...;
RemoteObject obj = factory.createObject();
// 使用对象
obj.doSomething();
// 销毁对象
factory.destroyObject(obj);
```

### 垃圾回收

**分布式垃圾回收（DGC）**：

```
问题：
- 服务器如何知道对象不再被使用？
- 客户端持有引用时对象不能被回收

Java RMI解决方案：
1. 客户端租约（Lease）机制
2. 定期续约
3. 过期自动回收
```

**租约机制**：
```java
// 服务器端
class RemoteObjectImpl {
    private long leaseTime = 60000; // 60秒
    private long lastRenewal;
    
    public void renewLease() {
        lastRenewal = System.currentTimeMillis();
    }
    
    public boolean isExpired() {
        return System.currentTimeMillis() - lastRenewal > leaseTime;
    }
}

// 客户端定期续约
Timer timer = new Timer();
timer.schedule(new TimerTask() {
    public void run() {
        remoteObject.renewLease();
    }
}, 0, 30000);  // 每30秒续约一次
```

## 🔑 关键要点

1. **RMI**：面向对象的分布式计算
2. **透明性**：像使用本地对象一样使用远程对象
3. **对象传递**：引用传递 vs 值传递
4. **生命周期**：创建、使用、垃圾回收
5. **标准**：Java RMI、CORBA等

## 💡 思考问题

1. 为什么RMI中的远程方法要抛出RemoteException？
2. 什么情况下应该使用按值传递而不是按引用传递？
3. 分布式垃圾回收为什么比本地垃圾回收更复杂？

---

**相关章节**：
- 上一节：[远程过程调用RPC](./远程过程调用RPC.md)
- 下一节：[命名服务](./命名服务.md)
- 相关：[02-通信机制/数据表示与编组](../02-通信机制/数据表示与编组.md)

