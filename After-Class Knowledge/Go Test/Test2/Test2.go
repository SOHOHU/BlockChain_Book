package main

import (
	"fmt"
	"sync"
	"time"
)

// 1. 高阶函数：接收函数作为参数并嵌套调用
func advancedFunc(a, b, c int, op func(int, int) int) int {
	return op(op(a, b), c)
}

// 2. 柯里化函数：分步接收参数，返回待执行函数
func curry(a, b int, op func(int, int) int) func(int) int {
	return func(c int) int {
		return op(op(a, b), c)
	}
}

// 3. 基础运算函数（供高阶函数调用）
func add(x, y int) int {
	return x + y
}

func multiply(x, y int) int {
	return x * y
}

// 4. 泛型函数：将任意类型的切片从中间拆分（新增使用示例）
// 功能：接收[]T类型切片，返回两个子切片（前半部分和后半部分）
func splitSlice[T any](s []T) ([]T, []T) {
	if len(s) == 0 {
		return []T{}, []T{} // 处理空切片，避免索引越界
	}
	mid := len(s) / 2
	return s[:mid], s[mid:]
}

// 5. 指针操作函数
func getPointerValue(x *int) int {
	return *x // 返回指针指向的实际值
}

// 6. 并发计算函数（向通道发送结果）
func asyncCalculate(a, b int, op func(int, int) int, resultChan chan int) {
	time.Sleep(time.Duration(a%3) * 100 * time.Millisecond) // 随机延迟模拟计算耗时
	resultChan <- op(a, b)
}

// 7. 任务结果结构体（替代map，提高类型安全性）
type TaskResult struct {
	TaskID int // 任务ID
	Sum    int // 计算结果
}

// 8. 带标识的并发任务（用于range遍历通道）
func asyncTaskWithID(taskID int, data []int, resultChan chan TaskResult) {
	defer close(resultChan) // 任务完成后关闭通道，避免接收方死锁
	sum := 0
	for _, num := range data { // range遍历slice
		sum += num
	}
	resultChan <- TaskResult{TaskID: taskID, Sum: sum}
}

// 9. Mutex相关：共享资源保护
var (
	sharedCounter int        // 需要保护的共享计数器
	mu            sync.Mutex // 互斥锁
	wg            sync.WaitGroup
)

// 安全的计数器累加（使用Mutex）
func safeIncrement() {
	defer wg.Done()
	for i := 0; i < 1000; i++ {
		mu.Lock()         // 获取锁：独占访问共享资源
		sharedCounter++   // 临界区操作：安全修改共享变量
		mu.Unlock()       // 释放锁：允许其他goroutine访问
	}
}

// 安全的计数器读取（读操作也需要加锁，避免读取中间状态）
func safeReadCounter() int {
	mu.Lock()
	defer mu.Unlock()
	return sharedCounter
}

func main() {
	fmt.Println("=====================================")
	fmt.Println("=== 1. 基础功能测试 ===")
	a, b, c := 1, 2, 3
	d := &a // 指针变量：存储a的内存地址

	// 指针操作演示
	if d == nil {
		fmt.Println("指针为空")
	} else {
		fmt.Printf("指针指向的值（a）：%d\n", getPointerValue(d))
	}

	// 高阶函数测试（函数作为参数）
	addResult := advancedFunc(a, b, c, add)
	mulResult := advancedFunc(a, b, c, multiply)
	fmt.Printf("高阶函数加法：(%d+%d)+%d = %d\n", a, b, c, addResult)
	fmt.Printf("高阶函数乘法：(%d*%d)*%d = %d\n", a, b, c, mulResult)

	// 柯里化测试（分步传递参数）
	addCurry := curry(a, b, add)
	mulCurry := curry(a, b, multiply)
	fmt.Printf("柯里化加法：(%d+%d)+%d = %d\n", a, b, c, addCurry(c))
	fmt.Printf("柯里化乘法：(%d*%d)*%d = %d\n", a, b, c, mulCurry(c))

	fmt.Println("\n=====================================")
	fmt.Println("=== 2. 泛型函数测试（splitSlice） ===")
	// 测试int类型切片拆分
	intSlice := []int{1, 2, 3, 4, 5}
	firstInt, secondInt := splitSlice(intSlice)
	fmt.Printf("int切片拆分前：%v\n", intSlice)
	fmt.Printf("int切片拆分后（前半）：%v，（后半）：%v\n", firstInt, secondInt)

	// 测试string类型切片拆分（泛型支持任意类型）
	strSlice := []string{"a", "b", "c", "d"}
	firstStr, secondStr := splitSlice(strSlice)
	fmt.Printf("string切片拆分前：%v\n", strSlice)
	fmt.Printf("string切片拆分后（前半）：%v，（后半）：%v\n", firstStr, secondStr)

	fmt.Println("\n=====================================")
	fmt.Println("=== 3. range遍历测试 ===")
	// range遍历slice（索引+值）
	numbers := []int{10, 20, 30, 40, 50}
	fmt.Println("切片元素：", numbers)
	fmt.Println("range遍历切片（索引+值）：")
	for idx, val := range numbers {
		fmt.Printf("  索引%d: %d\n", idx, val)
	}

	// range遍历channel（需先关闭通道）
	chanWithRange := make(chan int, 3)
	chanWithRange <- 100
	chanWithRange <- 200
	chanWithRange <- 300
	close(chanWithRange) // 关闭通道，通知range遍历结束

	fmt.Println("\nrange遍历通道（FIFO顺序）：")
	for val := range chanWithRange {
		fmt.Printf("  通道值：%d\n", val)
	}

	fmt.Println("\n=====================================")
	fmt.Println("=== 4. select语句测试 ===")
	// 用select区分不同通道的结果
	addChan := make(chan int)
	mulChan := make(chan int)

	go asyncCalculate(10, 5, add, addChan)      // 计算10+5，结果发往addChan
	go asyncCalculate(10, 5, multiply, mulChan) // 计算10*5，结果发往mulChan

	// 接收两个结果（顺序取决于goroutine执行速度）
	fmt.Println("select接收结果（随机顺序）：")
	for i := 0; i < 2; i++ {
		select {
		case sum := <-addChan:
			fmt.Printf("  加法结果：10+5=%d\n", sum)
		case product := <-mulChan:
			fmt.Printf("  乘法结果：10*5=%d\n", product)
		}
	}

	// select超时控制（任务在超时前完成）
	timeoutChan := make(chan bool, 1)
	resultChan := make(chan string)

	// 启动超时计时器
	go func() {
		time.Sleep(800 * time.Millisecond) // 800ms后发送超时信号
		timeoutChan <- true
	}()
	// 启动任务（500ms完成，小于超时时间）
	go func() {
		time.Sleep(500 * time.Millisecond)
		resultChan <- "任务执行成功"
	}()

	// 等待结果或超时
	select {
	case res := <-resultChan:
		fmt.Println("select超时测试结果：", res)
	case <-timeoutChan:
		fmt.Println("select超时测试结果：任务超时")
	}

	fmt.Println("\n=====================================")
	fmt.Println("=== 5. Mutex（互斥锁）测试 ===")
	// 无锁的并发计数器（存在数据竞争，结果错误）
	sharedCounter = 0
	wg.Add(2)
	go func() {
		defer wg.Done()
		for i := 0; i < 1000; i++ {
			sharedCounter++ // 危险：多个goroutine同时修改
		}
	}()
	go func() {
		defer wg.Done()
		for i := 0; i < 1000; i++ {
			sharedCounter++ // 危险：数据竞争
		}
	}()
	wg.Wait()
	fmt.Printf("无锁计数器结果（错误）：%d（预期2000）\n", sharedCounter)

	// 带Mutex的并发计数器（互斥保护，结果正确）
	sharedCounter = 0
	wg.Add(2)
	go safeIncrement()
	go safeIncrement()
	wg.Wait()
	fmt.Printf("带Mutex计数器结果（正确）：%d（预期2000）\n", safeReadCounter())

	fmt.Println("\n=====================================")
	fmt.Println("=== 6. 多任务并发测试（综合示例） ===")
	// 多任务数据（不同长度的切片）
	taskData := [][]int{
		{1, 2, 3, 4},   // 任务0：总和10
		{5, 6, 7},      // 任务1：总和18
		{8, 9},         // 任务2：总和17
	}

	// 启动多个goroutine处理任务
	wg.Add(len(taskData)) // 注册任务数量
	for i, data := range taskData {
		resChan := make(chan TaskResult) // 每个任务一个结果通道
		go asyncTaskWithID(i, data, resChan) // 启动任务goroutine

		// 启动接收结果的goroutine
		go func(ch chan TaskResult) {
			defer wg.Done() // 任务完成后通知WaitGroup
			for result := range ch { // range遍历通道获取结果
				fmt.Printf("任务%d完成，数据总和：%d（数据：%v）\n", 
					result.TaskID, result.Sum, taskData[result.TaskID])
			}
		}(resChan)
	}
	wg.Wait() // 等待所有任务完成
	fmt.Println("所有任务执行完毕")
	fmt.Println("=====================================")
}
    