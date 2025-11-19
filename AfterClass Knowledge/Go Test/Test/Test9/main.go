/*
使用 goroutine 和 channel 实现一个计算int64随机数各位数和的程序，例如生成随机数61345，计算其每个位数上的数字之和为19。开启一个 goroutine 循环生成int64类型的随机数，发送到jobChan
开启24个 goroutine 从jobChan中取出随机数计算各位数的和，将结果发送到resultChan
主 goroutine 从resultChan取出结果并打印到终端输出
实现这道题
*/

package main

import (
	"fmt"
	"math/rand"
	"time"
)

func calsum(num int) int {
	var t int = num
	var sum int = 0
	for t > 0 {
		sum += t % 10
		t = t / 10
	}
	return sum
}

func calram(job chan int) {
	// seedd
	// 注意要源源不断的存
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	for {
		randomNumber := int(r.Int63n(1e9)) + 1
		job <- randomNumber
		time.Sleep(time.Millisecond * 10)
	}
}

func worker(job chan int, result chan int) {
	// seedd
	// for range 遍历管道不用箭头 注意源源不断的取
	for work := range job {
		ret := calsum(work)
		result <- ret
	}

}

func main() {
	// 1、实现各个位求和
	// 2、单开一个goroutine，把任务结果传进chan
	// 3、开24个 goroutine，从chan提取结果实现
	// 4、打印，使用sync
	job := make(chan int, 100)
	result := make(chan int, 100)
	go calram(job)

	for i := 0; i < 24; i++ {
		go worker(job, result)
	}

	for ret := range result {
		fmt.Println(ret)
		// 打印
	}

}

/*
// 设置工作 goroutine 数量
const numWorkers = 24

// -----------------------------------------------------
// 1. 各位数求和函数 (Worker 的核心逻辑)
// -----------------------------------------------------

// sumDigits 计算 int64 随机数各位数的和
func sumDigits(n int64) int64 {
	var sum int64 = 0
	// 循环直到 n 变为 0
	for n != 0 {
		sum += n % 10
		n /= 10
	}
	return sum
}

// -----------------------------------------------------
// 2. 生产者 (Generator)
// -----------------------------------------------------

// randomGenerator 循环生成随机数并发送到 jobChan
func randomGenerator(jobChan chan<- int64) {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))

	// 模拟无限生成任务
	for {
		// 生成一个 int64 随机数 (简化到亿级别)
		randomNumber := r.Int63n(1e9) + 1

		// 直接发送 int64 随机数
		jobChan <- randomNumber

		// 避免运行过快，稍微暂停
		time.Sleep(time.Millisecond * 10)
	}
}

// -----------------------------------------------------
// 3. 消费者/工作池 (Workers)
// -----------------------------------------------------

// worker 从 jobChan 接收 int64，计算结果，发送 [原数, 和] 到 resultChan
func worker(jobChan <-chan int64, resultChan chan<- [2]int64) {
	// 持续从 jobChan 接收任务
	for number := range jobChan {
		// 1. 计算各位数之和
		sum := sumDigits(number)

		// 2. 将结果打包成一个包含两个 int64 元素的数组 ([原数, 和])
		result := [2]int64{number, sum}

		// 3. 将结果发送到 resultChan
		resultChan <- result
	}
}

// -----------------------------------------------------
// 4. 主 goroutine (Result Collector)
// -----------------------------------------------------

func main() {
	// JobChan 传递 int64 随机数
	jobChan := make(chan int64, 10)
	// ResultChan 传递包含 [原数, 和] 的 int64 数组
	resultChan := make(chan [2]int64, 10)

	fmt.Printf("启动生产者和 %d 个 Worker goroutine...\n", numWorkers)

	// 1. 启动生产者 goroutine (1 个)
	go randomGenerator(jobChan)

	// 2. 启动工作池 goroutine (24 个)
	for i := 0; i < numWorkers; i++ {
		go worker(jobChan, resultChan)
	}

	// 3. 主 goroutine 从 resultChan 取出结果并打印
	fmt.Println("--------------------------------")
	fmt.Println("开始接收并打印结果 (前 50 个):")

	// 只打印前 50 个结果，否则程序会无限运行
	const maxResults = 50
	for i := 0; i < maxResults; i++ {
		result := <-resultChan // 从 resultChan 阻塞式接收结果

		originalNum := result[0]
		sumOfDigits := result[1]

		fmt.Printf("原数: %10d | 各位数之和: %d\n",
			originalNum, sumOfDigits)
	}

	fmt.Println("--------------------------------")
	fmt.Printf("已处理并打印前 %d 个结果。程序结束演示。\n", maxResults)
}
*/
