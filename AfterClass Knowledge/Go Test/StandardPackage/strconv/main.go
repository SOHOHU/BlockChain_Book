package main

import (
	"fmt"
	"strconv"
)

func main() {
	// ParseInt/ParseUint 将字符串解析成整数
	// ParseInt(字符串，指定进制，溢出值（int32就写32）)
	numStr := "42"
	if v, err := strconv.ParseInt(numStr, 10, 64); err == nil {
		fmt.Printf("ParseInt(%q) => %d\n", numStr, v)
	}

	// Atoi/Itoa 是 ParseInt/FormatInt 的封装
	n, _ := strconv.Atoi("100")
	fmt.Printf("Atoi(\"100\") => %d\n", n)
	fmt.Printf("Itoa(%d) => %q\n", n, strconv.Itoa(n))

	// ParseFloat/FormatFloat 解析与格式化浮点数
	// ParseFloat，与ParseInt类似，就是没进制
	floatStr := "3.14159"
	if f, err := strconv.ParseFloat(floatStr, 64); err == nil {
		fmt.Printf("ParseFloat(%q) => %f\n", floatStr, f)
		fmt.Printf("FormatFloat(%f, 'f', 2, 64) => %q\n", f, strconv.FormatFloat(f, 'f', 2, 64))
	}

	// ParseBool/FormatBool 处理布尔值
	// ParseBool，与ParseInt类似，没进制也没溢出值
	boolStr := "true"
	if b, err := strconv.ParseBool(boolStr); err == nil {
		fmt.Printf("ParseBool(%q) => %v\n", boolStr, b)
		fmt.Printf("FormatBool(%v) => %q\n", b, strconv.FormatBool(b))
	}
}
