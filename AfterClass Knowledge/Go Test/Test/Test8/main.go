package main

import (
	"fmt"
)

// --- 1. Writer 接口定义 (抽象) ---

// Writer 定义了日志输出目标的行为。
// 任何实现了 Write(string) 方法的结构体，都是一个 Writer。
type Writer interface {
	Write(string)
}

// --- 2. ConsoleWriter (终端实现) ---

// ConsoleWriter 结构体，用于往终端写日志
type ConsoleWriter struct{}

// Write 实现 Writer 接口
// 【注意：方法签名与接口完全匹配】
func (cw *ConsoleWriter) Write(s string) {
	fmt.Println("[CONSOLE] " + s)
}

// --- 3. 主函数 (演示) ---

func main() {
	fmt.Println("--- 终端 Writer 演示 ---")

	// 1. 实例化 ConsoleWriter 对象
	cw := &ConsoleWriter{}

	// 2. 定义一个 Writer 接口变量
	var w Writer // 这是一个接口变量，它能容纳任何实现了 Writer 接口的类型

	// 3. 将 ConsoleWriter 赋值给 Writer 接口变量 w
	// 这就是接口的精髓：将具体实现赋值给抽象接口
	w = cw

	// 4. 通过接口变量 w 调用 Write 方法
	// 尽管我们调用的是 w.Write，但实际执行的是 ConsoleWriter 的 Write 方法
	w.Write("通过 Writer 接口写入的第一条日志。")
	w.Write("这是演示接口如何容纳具体实现的第二个例子。")

	// 5. 也可以直接使用结构体实例调用方法 (但不推荐，因为打破了面向接口的习惯)
	cw.Write("直接调用结构体方法。")

	fmt.Println("\n✅ 演示完成。")
}
