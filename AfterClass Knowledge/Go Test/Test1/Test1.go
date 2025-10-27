package main

import (
	"errors"
	"fmt"
)

// math接口定义了基本运算方法，包括可能返回错误的除法
type math interface {
	sub() int
	pro() int
	div() (int, error) // 除法可能返回错误（除零）
}

// printtype函数演示空接口的使用，可接收任意类型并判断其实际类型
func printtype(num interface{}) {
	switch v := num.(type) {
	case int:
		fmt.Println("类型：int，值：", v)
	case string:
		fmt.Println("类型：string，值：", v)
	case error: // 支持判断错误类型
		fmt.Println("类型：error，内容：", v)
	default:
		fmt.Println("类型：未知，值：", v)
	}
}

// add函数实现两数相加
func add(x int, y int) int {
	return x + y
}

// sum函数：计算可变参数的总和（已修复累加逻辑）
func sum(nums ...int) int {
	sum := 0
	// 正确累加切片中的元素（而非索引）
	for _, num := range nums {
		sum += num
	}
	return sum
}

// calculator结构体用于实现math接口，包含两个运算数
type calculator struct {
	a, b int // a: 被除数, b: 除数
}

// sub实现math接口的减法运算
func (c calculator) sub() int {
	return c.b - c.a
}

// pro实现math接口的乘法运算
func (c calculator) pro() int {
	return c.a * c.b
}

// div实现math接口的除法运算，当除数为0时返回错误
func (c calculator) div() (int, error) {
	if c.b == 0 {
		return 0, errors.New("除法错误：除数不能为0")
	}
	return c.a / c.b, nil
}

// message结构体存储消息相关信息
type message struct {
	day      string
	officeid int
}

// user结构体包含用户信息和关联的消息
type user struct {
	newmessage message
	usrid      int
}

// createuser函数创建用户，包含参数校验并返回可能的错误
func createuser(usrid int, officeid int, day string) (bool, error) {
	if usrid <= 0 {
		return false, fmt.Errorf("用户创建失败：usrid=%d 无效（必须大于0）", usrid)
	}
	if len(day) == 0 {
		return false, errors.New("用户创建失败：day不能为空")
	}

	amessage := message{day: day, officeid: officeid}
	ausr := user{newmessage: amessage, usrid: usrid}
	fmt.Printf("用户创建成功：%+v\n", ausr)

	return true, nil
}

func main() {
	// 测试1：用户创建功能的错误处理
	fmt.Println("=== 测试用户创建 ===")
	success1, err1 := createuser(1001, 501, "Monday")
	if err1 != nil {
		fmt.Println("失败：", err1)
	} else {
		fmt.Println("创建结果：", success1)
	}

	success2, err2 := createuser(0, 502, "Tuesday")
	if err2 != nil {
		printtype(err2)
		fmt.Println("失败：", err2)
	} else {
		fmt.Println("创建结果：", success2)
	}

	// 测试2：计算器除法的错误处理
	fmt.Println("\n=== 测试除法运算 ===")
	calc1 := calculator{a: 30, b: 20}
	divResult1, divErr1 := calc1.div()
	if divErr1 != nil {
		fmt.Println("除法失败：", divErr1)
	} else {
		fmt.Printf("30 / 20 = %d\n", divResult1)
	}

	calc2 := calculator{a: 30, b: 0}
	divResult2, divErr2 := calc2.div()
	if divErr2 != nil {
		printtype(divErr2)
		fmt.Println("除法失败：", divErr2)
	} else {
		fmt.Printf("30 / 0 = %d\n", divResult2)
	}

	// 基础功能测试（含sum函数调用修复）
	fmt.Println("\n=== 基础功能测试 ===")
	congrats := "happy birthday"
	a, b, c := 20, "myname", 30
	fmt.Println("祝福语：", congrats)
	fmt.Println("整数a：", a, "，字符串b：", b)

	array := [10]int{0, 1, 2, 3, 4, 5}
	var array2 []int
	array3 := make([]int, 5) // 初始值：[0,0,0,0,0]

	d := add(a, c)
	fmt.Printf("\n加法结果：%d + %d = %d\n", a, c, d)

	// 数组遍历
	fmt.Println("\n数组array遍历：")
	for i := 0; i < len(array); i++ {
		fmt.Printf("索引%d：%d\n", i, array[i])
	}

	// 切片append操作
	fmt.Println("\n切片append操作（a从20→29）：")
	for a < c {
		fmt.Println("当前a值：", a)
		array2 = append(array2, a)
		array3 = append(array3, d) // d=50，每次追加50
		a++
	}

	mymap := make(map[string]int)
	mymap["a"] = 12


	// 修复核心错误：调用sum时用...展开切片（关键！）
	// array3[1:3]是[]int类型，传递给nums ...int需用...展开为多个int
	f := sum(array3[1:3]...)   // 正确：用...展开切片，等价于sum(0, 0)

	// 打印切片结果
	fmt.Println("\n切片array2：", array2)
	fmt.Println("切片array3：", array3)
	fmt.Println("切片f：", f)

	// 条件判断
	if d > 10 {
		fmt.Println("\ntoday is", a)
	} else {
		fmt.Println("\ntoday is", b)
	}
}
    