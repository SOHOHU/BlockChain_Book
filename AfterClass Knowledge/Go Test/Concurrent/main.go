package main

import (
	"fmt"
	"runtime"
	"sync"
	"time"
)

var wg sync.WaitGroup // 创建 WaitGroup 对象
var wg3 sync.WaitGroup
var wg4 sync.WaitGroup

// x默认为0
var x int64
var lock sync.Mutex
var rwlock sync.RWMutex
var m = make(map[int]int)
var m2 = sync.Map{}

func hello() {
	fmt.Println("Hello, Go Test Concurrent!")
	wg.Done()
}

func a() {
	for i := 0; i < 5; i++ {
		fmt.Println("Hello, A")
	}
}

func b() {
	for i := 0; i < 5; i++ {
		fmt.Println("Hello, B")
	}
}

// 两个通过channe实现的协同goroutine
// ch chan<- int 表示只写通道
// ch <-chan int 表示只读通道
func f1(ch chan<- int) {
	for i := 0; i < 100; i++ {
		ch <- i
	}
	close(ch)
}

// ch1取值交给ch2
func f2(ch1 <-chan int, ch2 chan<- int) {
	for {
		tmp, ok := <-ch1
		if !ok {
			break
		}
		ch2 <- tmp * tmp
	}
	close(ch2)
}

func worker(id int, jobs <-chan int, results chan<- int) {
	for job := range jobs {
		fmt.Printf("Worker %d processing job %d\n", id, job)
		results <- job * job
	}
}

func add() {
	for i := 0; i < 50; i++ {
		lock.Lock()
		x = x + 1
		lock.Unlock()
	}
	wg.Done()
}

func read() {
	// 读也要锁上，否则会导致前后读写不一致
	rwlock.RLock()
	time.Sleep(time.Millisecond)
	rwlock.RUnlock()
	wg3.Done()
}

func write() {
	rwlock.Lock()
	x = x + 1
	time.Sleep(time.Millisecond * 10)
	rwlock.Unlock()
	wg3.Done()
}

func get(key int) int {
	return m[key]
}

func set(key int, value int) {
	m[key] = value
}

func main() {
	// 设定使用的最大 CPU 核心数为 1，强制进行协程调度
	// 如果是1 先执行完一个再执行另一个
	// 如果是大于1 则可能交替执行
	runtime.GOMAXPROCS(1)
	go a()
	go b()
	for i := 0; i < 5; i++ {
		go hello()
		wg.Add(1)
	}

	// 并发同步与锁
	go add()
	go add()
	wg.Add(2)
	// 启动一个新的 goroutine 来运行 hello 函数
	// 可能在主函数完成前还没来得及执行
	wg.Add(1) // 增加一个等待计数
	go hello()
	fmt.Println("Main function completed.")

	wg.Wait() // 等待所有 goroutine 完成
	// time.Sleep(1 * time.Second) // 等待一秒钟，确保 goroutine 有时间执行
	fmt.Println("This is x", x)
	time.Sleep(1 * time.Second) // 等待一秒钟，确保 goroutine 有时间执行

	//通道要记得先初始化
	var ch1 chan int = make(chan int, 1)
	ch1 <- 10
	x := <-ch1
	fmt.Println("Channel value:", x)
	close(ch1)

	// 无缓冲通道(同步通道)直接传递值会报错：
	// var ch2 chan int = make(chan int)

	// goroutine + channel
	ch2 := make(chan int, 100)
	ch3 := make(chan int, 100)

	go f1(ch2)
	go f2(ch2, ch3)

	for v := range ch3 {
		fmt.Println("Received from ch3:", v)
	}

	// goroutine池
	jobs := make(chan int, 100)
	results := make(chan int, 100)

	// 启动3个goroutine作为worker
	numWorkers := 3
	var wg2 sync.WaitGroup // 用于等待所有 worker 完成
	for w := 1; w <= numWorkers; w++ {
		wg2.Add(1)

		go func(id int) {
			defer wg2.Done() //因为一个进程执行了多个任务，所以统一任务全部做完写done
			worker(id, jobs, results)
		}(w)
	}

	// 发送5个任务到jobs通道
	for w := 0; w < 5; w++ {
		jobs <- w
	}
	close(jobs)

	// 在另一个 goroutine 中等待所有 worker 完成，然后关闭 results
	// 这部分最好单开一个goroutine
	go func() {
		wg2.Wait()
		close(results)
	}()

	// 读取并输出所有结果
	for result := range results {
		fmt.Println("Result:", result)
	}

	// select 多路复用
	// 如果有多个条件满足，则随机选一个执行
	ch4 := make(chan int, 100)
	for i := 0; i < 10; i++ {
		select {
		case x := <-ch4:
			fmt.Println("receive", x)
		case ch4 <- i:
			fmt.Println("input", i)
		default:
			fmt.Println("nothing")
		}
	}

	// 读写互斥锁：读不修改，可以不锁
	start := time.Now()

	for i := 0; i < 1000; i++ {
		wg3.Add(1)
		go read()
	}

	for i := 0; i < 10; i++ {
		wg3.Add(1)
		go write()
	}

	wg3.Wait()
	fmt.Println(time.Now().Sub(start))

	// sync.once可以保证多个goroutine总共只执行一次某个任务（如初始化）
	// sync.map安全map, 并发对map做写操作会报错
	for i := 0; i < 20; i++ {
		wg4.Add(1)
		go func(i int) {
			// store(key, value), 不需要make初始化，直接用store进行键值对保存
			m2.Store(i, i+100)
			value, _ := m2.Load(i)
			fmt.Println("This is safe map", value)
			wg4.Done()
		}(i)
	}
	wg4.Wait()

}
