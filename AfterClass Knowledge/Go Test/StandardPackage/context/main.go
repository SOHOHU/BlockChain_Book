package main

import (
	"context"
	"fmt"
	"sync"
	"time"
)

var wg sync.WaitGroup

// 定义用于在Context中存储键的类型，避免键冲突
type TraceIDKey string

// worker 函数现在会检查取消信号，同时也会尝试从Context中读取TraceID
func worker(ctx context.Context) {
	// 尝试从Context中读取 TraceID
	traceID := ctx.Value(TraceIDKey("trace-id"))
	if traceID != nil {
		fmt.Printf("Worker started with TraceID: %v\n", traceID)
	}

LOOP:
	for i := 1; i <= 5; i++ { // 循环5次，以便演示超时
		fmt.Printf("Worker: running step %d\n", i)
		time.Sleep(time.Millisecond * 800) // 每次运行 800ms
		
		select {
		case <-ctx.Done(): // 等待上级通知（可能是超时或手动取消）
			// 打印退出原因
			fmt.Printf("Worker: received stop signal. Reason: %v\n", ctx.Err())
			break LOOP
		default:
		}
	}
	wg.Done()
}

func main() {
	// 1. 使用 context.WithTimeout 创建一个带超时的 Context
	// 设定 2.5 秒的超时时间
	// context.WithTimeout(context.Background(), 超时时间)，context.Background()代表此处为上下文（context生效范围的）顶层，返回
	timeoutCtx, timeoutCancel := context.WithTimeout(context.Background(), time.Second*2 + time.Millisecond*500)
	defer timeoutCancel() // 确保即使函数提前退出，也会取消Context，释放资源
	
	// 2. 使用 context.WithValue 在新的 Context 中嵌入 TraceID
	// 这是一个模拟的请求跟踪ID，A -> B，A的context对象就是需要传入的参数。另外是传入一对键值对，键一般用空结构体实现
	// 这个键值对一般是追踪 ID (Trace ID / Request ID): 用于日志记录，追踪单个请求在复杂系统中的完整路径。认证信息: 传递当前用户的 ID、认证令牌等。配置信息: 传递请求级别的配置（如租户 ID）
	valueCtx := context.WithValue(timeoutCtx, TraceIDKey("trace-id"), "REQ-12345-ABCDE")

	wg.Add(1)
	
	// 传入包含超时和值的 Context
	go worker(valueCtx) 
	
	// 主 goroutine 不再需要显式 sleep 和 cancel，
	// 因为超时（2.5s）会通过 valueCtx 自动通知 worker 结束。
	// 超时，timeoutCtx向所有子context传递超时通知，触发ctx.done。当然传递子context触发done是context的功能，不是专属于value方面的功能，我们这次只是为了利用value传递键值对

	wg.Wait()
	fmt.Println("Main: all workers finished. Over.")
}