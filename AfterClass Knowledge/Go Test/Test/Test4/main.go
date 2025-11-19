package main

import (
	"bufio"
	"fmt"
	"os"
	"sort" // 导入 sort 包用于排序
	"strconv"
	"strings"
)

// 定义目标和，方便修改
const TargetSum = 8

func main() {
	reader := bufio.NewReader(os.Stdin)

	// 提示用户输入数据，以空格分隔
	fmt.Printf("请输入数字（以空格分隔），程序将找出和为 %d 的元素对：\n", TargetSum)
	input, _ := reader.ReadString('\n')

	// --- 输入解析部分 (保持不变) ---
	strNums := strings.Fields(input)

	Nums := make([]int, 0)
	for _, value := range strNums {
		// 忽略错误处理，简化代码
		num, _ := strconv.Atoi(value)
		Nums = append(Nums, num)
	}
	// --------------------------------

	if len(Nums) < 2 {
		fmt.Println("数组元素不足两个，无法进行两数之和查找。")
		return
	}

	// ----------------------------------------------------
	// --- 核心修改部分：实现双指针 ---
	// ----------------------------------------------------

	// 【修改 1】：对数组进行排序。这是使用双指针的前提。
	// 注意：排序后，数组元素的原始位置信息丢失！
	sort.Ints(Nums)

	fmt.Printf("排序后的数组: %v\n", Nums)

	var front int = 0
	// 【修改 2】：behind 指针初始化为切片的最后一个元素的下标
	var behind int = len(Nums) - 1

	fmt.Println("找到的元素对 (下标为排序后的数组下标):")

	// 【修改 3】：循环条件改为 front < behind
	for front < behind {
		sum := Nums[front] + Nums[behind]

		if sum > TargetSum {
			// 【修改 4】：和太大，右指针左移
			behind--
		} else if sum < TargetSum {
			// 【修改 5】：和太小，左指针右移
			front++
		} else {
			// 和等于目标值
			// 【修改 6】：打印排序后的下标和对应的值
			fmt.Printf("  找到！下标 (%d, %d) 对应值 (%d, %d)\n",
				front, behind, Nums[front], Nums[behind])

			// 【修改 7】：找到一组解后，必须移动指针，否则将无限循环
			front++
			behind--
		}
	}

	// ----------------------------------------------------

	// 如果需要处理用户输入的数据，原有的 map 统计部分可以移除，因为它与双指针逻辑冲突。
}
