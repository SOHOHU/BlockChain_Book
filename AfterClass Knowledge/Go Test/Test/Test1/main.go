// 编写代码统计出字符串"hello沙河小王子"中汉字的数量
// 如之前所说，遍历字符肯定是识别不出中文字符的，应该使用for range实现
package main

import (
	"fmt"
	"unicode"
)

func main() {
	fmt.Println("Hello World")
	str := "hello沙河小王子"
	chineseCount := 0

	// rune，专门存放字符串的
	slice := []rune(str)
	for _, value := range slice {
		// 库函数，unicode Is（语言，值）判断是什么语言
		if unicode.Is(unicode.Han, value) {
			chineseCount++
			fmt.Println("Chinese contained", value)
		}
	}
	fmt.Println("Count", chineseCount)

	// 如果要输出所有汉字：
	chinese := make([]rune, 0, 100)
	for _, value := range slice {
		// 库函数，unicode Is（语言，值）判断是什么语言
		if unicode.Is(unicode.Han, value) {
			chinese = append(chinese, value)
		}
	}
	fmt.Println(string(chinese))

}
