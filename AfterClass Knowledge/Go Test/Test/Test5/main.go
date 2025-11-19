// 写一个程序，统计一个字符串中每个单词出现的次数。比如：“how do you do"中how=1 do=2 you=1
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func main() {
	fmt.Println("Hello world")
	reader := bufio.NewReader(os.Stdin)
	input, _ := reader.ReadString('\n')
	str := strings.Fields(input)
	fmt.Println(str)

	var mymap = make(map[string]int, 100)
	for index, value := range str {
		word := strings.ToLower(value)
		mymap[word]++
		fmt.Println("Index", index)
	}

	for key, value := range mymap {
		fmt.Printf("单词 \"%s\" 出现了 %d 次\n", key, value)
	}

}
