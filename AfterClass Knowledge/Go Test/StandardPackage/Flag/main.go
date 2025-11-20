// 用于开发命令行
// 只要是可执行都说main
package main

import (
	"flag"
	"fmt"
)

func main() {
	/* if len(os.Args) > 0 {
		for index, arg := range os.Args {
			// 注意arg用的是%v，表某个数组的值，如字符串
			// 加上\n 确保代码执行到换行符
			fmt.Printf("arg is %d %v\n", index, arg)
		}
	} */
	// flag变量定义，flag.Type(flag名, 默认值, 帮助信息),返回一个Type指针,-helpy引出使用提示
	name := flag.String("name", "HSQ", "姓名")
	age := flag.Int("age", 20, "年龄")
	// 这里是bool，命令行给bool赋值必须用等于法
	married := flag.Bool("married", true, "婚否")
	// 使用StringVar方法直接传入Address的地址作为指针
	var Address string
	flag.StringVar(&Address, "address", "China", "住址")
	flag.Parse()

	fmt.Println(*name, *age, *married, Address)
	//返回命令行参数后的其他参数
	fmt.Println(flag.Args())
	//返回命令行参数后的其他参数个数
	fmt.Println(flag.NArg())
	//返回使用的命令行参数个数
	fmt.Println(flag.NFlag())

}
