// 有一堆数字，如果除了一个数字以外，其他数字都出现了两次，那么如何找到出现一次的数字
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

func main() {
	fmt.Println("Hello World")
	reader := bufio.NewReader(os.Stdin)
	input, _ := reader.ReadString('\n')
	strNums := strings.Fields(input)
	mymap := make(map[int]int, 100)

	Nums := make([]int, 0, 100)
	for _, value := range strNums {
		num, _ := strconv.Atoi(value)
		Nums = append(Nums, num)
	}

	fmt.Println("Numbers", Nums)

	for _, value := range Nums {
		mymap[value]++
	}

	for i := 0; i < len(Nums); i++ {
		if mymap[Nums[i]] == 1 {
			fmt.Println("This is ret", Nums[i])
		}
	}

}
