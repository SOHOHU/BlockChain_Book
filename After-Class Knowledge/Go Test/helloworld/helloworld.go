package main

import "fmt"

// Hello 函数返回问候语
func Hello() string {
	return "Hello, World!"
}

// myOtherFunction 调用 Hello 并打印
func myOtherFunction() {
	fmt.Println(Hello())
}

// main 作为入口，调用功能函数
func main() {
	myOtherFunction() // 运行后输出：Hello, World!
}
