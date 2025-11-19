package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"time"
)

// 自定义类型
type myInt int

// 类型别名
type yourInt = int

// 结构体声明，用空格或换行分隔字段

type Address struct {
	province string
	city     string
}

// 结构体的匿名字段, 相同类型只有一个
type Person struct {
	string
	int
}

type person struct {
	name string
	city string
	age  int
}

type person2 struct {
	name    string
	gender  string
	address Address // 嵌套结构体
	age     int
}

// 构造函数，go没有构造函数的概念，可以用普通函数模拟
func newPerson(name string, city string, age int) *person {
	return &person{ // 传指针出去节省内存
		name: name,
		city: city,
		age:  age,
	}
}

// 继承
type Animal struct {
	name string
}

func (a *Animal) move() {
	fmt.Printf("%s is moving", a.name)
}

type Dog struct {
	feet    int
	*Animal // 匿名字段，实现继承(继承的时候一般不再写字段名)
}

type cat struct {
	mouth int
	*Animal
}

func (d *Dog) bjn() {
	fmt.Printf("%s is barking\n", d.name)
}

// 首字母大写的结构体或函数是公有的，小写的是私有的
type MyStruct struct {
	Field1 int    // 公有字段，外部的包可以获取
	field2 string // 私有字段，外部的包不可以获取
}

// Json序列化
type Class struct {
	Title    string `json:"title"` // tag功能：结构体标签，指定json的key名称
	Students []string
}

// 可以初始化，不可赋值，var n int = 100可以。var n int后 n = 100 不行
// 全局变量
var n myInt = 100
var m yourInt = 200

// 函数
func sayHello() {
	fmt.Println("Hello, Go!")
	fmt.Println("Global n =", n)
}

// 变量 + 类型（和C语言不同）
func sayHelloTo(name string) {
	fmt.Printf("Hello, %s!\n", name)
}

// 函数返回值类型跟在小括号后面
func initSum(a int, b int) int {
	return a + b
}

// 函数接受可变参数。可变参数必须是函数的最后一个参数
func variadicSum(c int, nums ...int) int {
	fmt.Println("Numbers:", nums)
	sum := 0
	fmt.Println(c)
	for _, num := range nums {
		sum += num
	}
	return sum
}

// 多返回值
func cal(a int, b int) (int, int) {
	return a + b, a - b
}

// 方法：作用于特定类型的函数（相当于给某个类加了一个方法）
func (p person) Dream() {
	fmt.Println(p.name, "的梦想是学好Go语言")
}

func (p *person) setAge(age int) {
	p.age = age
}

// 接口，只要是实现同一类型方法的类型都可以看作是实现了该接口
// 方法名(参数列表)返回值列表
type sayer interface {
	say()
}

type behave interface {
	sayer
	dogmove()
}

// 空接口, 可以接受任何类型
// 1、可以作为函数参数，接受任何类型的参数
// 2、可以作为map的value，存储任意类型的值
// 3、可以作为切片的元素类型，存储任意类型的值
type empty interface{}

// 实例化，不同类型实现同一接口
func (c *cat) say() {
	fmt.Println("Meow")
}

func (d *Dog) say() {
	fmt.Println("Woof")
}

func (d *Dog) dogmove() {
	fmt.Printf("%s is moving", d.name)
}

func hit(arg sayer) {
	arg.say()
}

// init函数，自动执行,一般用于初始化操作，在main函数之前执行
// 全局变量声明 -> 包init函数 -> main的init函数 -> main函数
// 每个文件可以有自己的init函数
func init() {
	fmt.Println("Init function called")
}

func main() {
	// fmt实现格式化输入输出的功能
	fmt.Println("Hello World")
	// 调用函数
	sayHello()
	sayHelloTo("Golang")
	cat1 := &cat{
		mouth:  2,
		Animal: &Animal{name: "Kitty"},
	}
	dog1 := &Dog{
		feet:   4,
		Animal: &Animal{name: "Doggy"},
	}
	// 接口调用,不要需要调用针对cat或者dog的方法，因为这两个方法都有say，那他们就都属于sayer，所以可以作为hit函数的参数
	// 其他没用say()方法的函数不能作为hit的参数，因为不是sayer接口类型
	// 空接口存储任何值
	var em empty
	em = 100
	fmt.Println("Empty interface em =", em)
	em = "Now I'm a string"
	fmt.Println("Empty interface em =", em)

	hit(cat1)
	hit(dog1)
	var s sayer // 声明接口类型变量
	// 多态：属于这个接口类型的变量(如有say的猫狗)可以直接赋值(或者赋指针)给接口类型变量
	// 如果赋值是指针，那么值将无法调用方法，反之亦然
	// s = cat1.Animal // 错误，Animal没有实现sayer接口
	s = cat1
	s.say()
	s = dog1
	s.say()
	// 一个接口可以多个方法，并且接口可以嵌套
	var be behave
	be = dog1
	be.dogmove()
	be.say()
	// 此时接口变量be可以赋值给cat1吗？不行，因为cat1没有dogmove方法，即使它有say方法也不行，只有完全实现了behave接口的类型才能赋值给be
	/*be = cat1
	be.say()
	be.dogmove()*/

	// defer延迟调用，main函数最后执行
	defer fmt.Println("Goodbye, Go!")
	fmt.Println("Sum:", initSum(10, 20))
	fmt.Println("Variadic Sum:", variadicSum(1, 2, 3, 4, 5))
	fmt.Println(cal(10, 20))
	// 匿名函数
	returnValue := func(x int, y int) int {
		return x * y
	}
	fmt.Println("Anonymous Function Result:", returnValue(5, 6))
	// 立即执行的匿名函数
	returnValue2 := func(s string) string {
		fmt.Println("Anonymous Function says:", s)
		return s
	}("Hello from anonymous function!")
	fmt.Println(returnValue2)
	// 匿名函数作为返回值
	factory := func(factor int) func(int) int {
		return func(x int) int {
			return x * factor
		}
	}
	// 闭包, 匿名函数的返回函数引用外部参数
	factory2 := func(factor int) func(int) int {
		a := 10
		return func(i int) int {
			return a + i + factor
		}
	}
	double := factory(2)
	triple := factory(3)
	fmt.Println("Double 5:", double(5))
	fmt.Println("Triple 5:", triple(5))
	double2 := factory2(2)
	fmt.Println("Double 5", double2(5))
	// 标准声明，声明一个一个来
	var firstInt int = 10
	var firstString string = "Golang"
	fmt.Println(firstInt, firstString)

	var p person
	p.name = "Alice"
	p.city = "New York"
	p.age = 30
	fmt.Println("Person:", p)
	// 匿名结构体. 适合临时使用
	var user struct {
		name    string
		married bool
	}
	user.name = "Bob"
	user.married = false
	fmt.Println("User:", user)
	// 指针接收者和值接收者的方法调用似乎没有区别？
	// 但是值接收者的方法不能修改结构体的成员变量
	// 指针接收者的方法可以修改结构体的成员变量，这是浅拷贝和深拷贝的区别
	p.Dream()    // 值接收者，这时候的p是值拷贝，不能修改p的成员变量
	p.setAge(35) // 指针接收者，可以修改p的成员变量

	newp := Person{
		string: "Bob",
		int:    30,
	}
	fmt.Println("Person with anonymous fields:", newp)

	// 键值对初始化, 可以不写部分字段，未写的字段会使用默认值，推荐
	p3 := person{
		name: "David",
		city: "Shanghai",
		age:  28,
	}
	fmt.Println("Person 3:", p3)

	C1 := Class{
		Title:    "Math",
		Students: make([]string, 0, 20),
	}

	for i := 0; i < 10; i++ {
		newStudent := newPerson("Alice", "City", 20+i)
		C1.Students = append(C1.Students, newStudent.name)
	}

	fmt.Println("Class:", C1)

	// JSON序列化。如果结构体的字段首字母小写，则无法被json包访问到，序列化会忽略这些字段
	data, err := json.Marshal(C1)
	if err != nil {
		fmt.Println("Error serializing to JSON:", err)
	} else {
		fmt.Println("JSON Data:", string(data))
	}
	// JSON反序列化
	var C2 Class
	err = json.Unmarshal(data, &C2) //err 前面已经声明，不可再：=
	if err != nil {
		fmt.Println("Error deserializing from JSON:", err)
	} else {
		fmt.Println("Deserialized Class:", C2)
	}

	// 列表初始化
	p4 := person{"Eva", "Beijing", 22}
	fmt.Println("Person 4:", p4)

	p5 := newPerson("Frank", "Chicago", 35)
	fmt.Println("Person 5:", *p5)

	newp2 := person2{
		name:   "Grace",
		gender: "Male",
		address: Address{
			province: "Zhejiang",
			city:     "Hangzhou",
		},
		age: 29,
	}
	fmt.Println("Person2 with nested struct:", newp2.address.city)
	// 注意值嵌套和指针嵌套的区别，address: Address和Animal: &Animal
	d1 := Dog{
		feet:   4,
		Animal: &Animal{name: "Buddy"},
	}
	d1.bjn()
	d1.move()
	// 结构指针
	var p2 = new(person)
	// 结构指针的变量访问成员，用.号，不用->
	p2.name = "Charlie"
	p2.city = "Los Angeles"
	p2.age = 25
	fmt.Println("Person 2:", *p2)
	// 批量声明，多个一起来
	var (
		a yourInt = 20
		b string  = "Batch"
	)
	fmt.Println(a, b)
	// 类型推导，初始化不用讲类型
	var c = 30
	var d = "Type Inference"
	fmt.Println(c, d)
	// 短变量声明，只能在函数体内使用
	// 类型推导和短变量声明是常用的
	e := 40
	f := "Short Declaration"
	fmt.Println(e, f)

	// panic 和 recover. 让程序能够顺利结束
	defer func() {
		err := recover()
		if err != nil {
			fmt.Println("This is an error")
		}
	}()
	panic("a maybe error")

	// 常量声明，常量声明后必须立刻赋值
	const pi = 3.14
	const (
		// 类型推导
		statusOK    = 200
		notFoundErr = 404
		unknown     // 未赋值，默认和上一行一样
	)
	fmt.Println("Pi:", pi)
	fmt.Println("Status OK:", statusOK)
	fmt.Println("Not Found Error:", notFoundErr)
	fmt.Println("Unknown:", unknown)

	const (
		a1 = iota // 0
		a2        // 1
		a3        // 2
	)

	const (
		b1 = iota // 每一次出现const关键字，iota都会重置为0
		b2 = 100  // 即使赋值了，iota也不会停止自增
		_         // 占位符，跳过这个值
		b3 = iota // b3 = 3
	)

	fmt.Println("a1:", a1, "a2:", a2, "a3:", a3)
	fmt.Println("b1:", b1, "b2:", b2, "b3:", b3)

	const (
		KB = 1 << (10 * iota) // 1左移0位
		MB                    // 1左移10位
		GB                    // 1左移20位
		TB                    // 1左移30位
		PB                    // 1左移40位
	)

	fmt.Println("KB:", KB)
	fmt.Println("MB:", MB)
	fmt.Println("GB:", GB)
	fmt.Println("TB:", TB)
	fmt.Println("PB:", PB)

	// 浮点数
	var floatNum float32 = 3.14
	fmt.Println("Float Number:", floatNum)

	// 布尔值
	var boolVal bool = true
	fmt.Println("Boolean Value:", boolVal)

	// 字符
	var charVal rune = 'A'
	fmt.Println("Character Value:", charVal)
	var charVal2 string = "Hello"
	var lenChar int = len(charVal2)
	fmt.Println("Length of String 'Hello':", lenChar)
	fmt.Println("String Value:", charVal2)
	fmt.Println(charVal2 + " World")

	// 转义符
	fmt.Println("This is a line.\nThis is another line.")
	fmt.Println("C:\\code\\main.go")
	fmt.Println(`\n`)

	// 流程控制
	num := 15
	// 与C语言的区别就是没有括号
	if num%2 == 0 {
		fmt.Println(num, "is even")
	} else {
		fmt.Println(num, "is odd")
	}
	// 与C语言的区别就是没有括号,没Int
	for i := 0; i < 5; i++ {
		fmt.Println("Iteration:", i)
		if i > 3 {
			break
		}
	}

	age := 20
	switch age {
	case 16, 17:
		fmt.Println("16, 17 years old")
	case 18:
		fmt.Println("18 years old")
	case 20:
		fmt.Println("20 years old")
	default:
		fmt.Println("Age not matched")
	}

	// 数组
	// 数组的类型是长度+元素类型，因此下面两个数组类型不同，数组定义不初始化为全0
	var array1 [3]int
	var array2 [4]int
	fmt.Println("Array a:", array1)
	fmt.Println("Array b:", array2)

	var cityNames = [3]string{"Beijing", "Shanghai", "Guangzhou"}
	fmt.Println("City Names:", cityNames)
	cityNames[1] = "Shenzhen"
	fmt.Println("Updated City Names:", cityNames)

	// 未定长度数组用...代替长度
	var fruits = [...]string{"Apple", "Banana", "Cherry", "Date"}
	fmt.Println("Fruits:", fruits)

	var fruits2 = [...]string{1: "Banana", 3: "Date"}
	fmt.Println("Fruits2:", fruits2)

	// for range遍历数组
	// 常规遍历
	for i := 0; i < len(fruits); i++ {
		fmt.Printf("Index %d: %s\n", i, fruits[i])
	}

	// for range遍历
	for index, value := range fruits {
		fmt.Printf("Index %d: %s\n", index, value)
	}
	for index, value := range cityNames {
		fmt.Printf("Index %d: %s\n", index, value)
	}

	// 二维数组
	var matrix = [2][3]int{
		{1, 2, 3},
		{4, 5, 6},
	}
	fmt.Println("Matrix:", matrix)
	// for range遍历不要漏了冒号
	for i, row := range matrix {
		for j, value := range row {
			fmt.Printf("matrix[%d][%d] = %d\n", i, j, value)
		}
	}

	// 切片
	// 区别就是没有长度，可以直接初始化，
	var slice1 = []int{2, 4, 6, 8}
	fmt.Println("Slice1:", slice1)

	// 从数组切片
	var slice2 = fruits[1:3] // 包含索引1，不包含索引3（左闭右开）
	fmt.Println("Slice2:", slice2)
	// 切片的容量是从起始索引到数组末尾的长度，这里是4-1=3和2，至于为什么cap是3，是因为底层数组从索引1到末尾有3个元素
	fmt.Println("Capacity of Slice2:", cap(slice2))
	fmt.Println("Length of Slice2:", len(slice2))

	// 切片再切片
	var slice3 = slice1[1:3]
	fmt.Println("Slice3:", slice3)

	// 用make切片
	var slice4 = make([]string, 3) // 长度3，初始值为空字符串
	fmt.Println("Slice4:", slice4)

	// nil，如果是空切片是不能直接使用索引赋值，会报错
	var slice5 []int // nil切片，就是空切片。长度和容量都是0
	if slice5 == nil {
		fmt.Println("Slice5 is nil")
		fmt.Println("Length of Slice5:", len(slice5))
		fmt.Println("Capacity of Slice5:", cap(slice5))
	} else {
		fmt.Println("Slice5 is not nil")
	}

	// 切片的赋值与拷贝
	slice6 := []int{10, 20, 30}
	slice7 := slice6 // 引用赋值，slice6和slice7指向同一个底层数组
	slice7[0] = 100
	fmt.Println("Slice6 after modifying Slice7:", slice6) // slice6[0]也变成100

	// 切片拷贝
	slice8 := make([]int, len(slice6))
	copy(slice8, slice6)
	fmt.Println("Slice8 after copying Slice6:", slice8)
	slice6[1] = 200
	fmt.Println("Slice6 after modification:", slice6)
	fmt.Println("Slice8 remains unchanged:", slice8) // slice8[1]仍然是20

	// append函数，append（原切片，新增元素1，新增元素2，...）
	slice9 := []int{1, 2, 3}
	slice9 = append(slice9, 4, 5) // 需要接收返回值，如果底层数组扩容了，会返回新的切片
	fmt.Println("Slice9 after append:", slice9)

	// 切片删除
	slice10 := []int{10, 20, 30, 40, 50}
	// 因为没用专门用于删除的函数，我们需要自己操作切片实现删除，比如删除索引2的元素30
	indexToDelete := 2
	slice10 = append(slice10[:indexToDelete], slice10[indexToDelete+1:]...)
	fmt.Println("Slice10 after deletion:", slice10)

	// 切片遍历
	// 和数组一模一样
	for i, v := range slice9 {
		fmt.Printf("Index %d: %d\n", i, v)
	}

	// map
	// 使用make创建map初始化
	mymap := make(map[string]int, 5) // 初始容量5，一旦超出容量会自动扩容，扩容机制和切片类似，创建一个更大的map然后复制数据过去，会浪费一些内存
	mymap["Alice"] = 25
	mymap["Bob"] = 30
	fmt.Println("Map:", mymap)
	// 直接声明并初始化(本质是申请内存)
	mymap2 := map[int]string{
		1: "One",
		2: "Two",
		3: "Three",
	}
	fmt.Println("Map2:", mymap2)

	// map访问元素
	age, exists := mymap["Alice"] // 双赋值，exists是bool类型，表示key是否存在
	if exists {
		fmt.Println("Alice's age is", age)
	} else {
		fmt.Println("Alice not found in map")
	}

	// map 遍历，map是无序的
	for key, value := range mymap {
		fmt.Printf("Key: %s, Value: %d\n", key, value)
	}

	// map删除元素,delete(map, key)
	delete(mymap, "Bob") // 删除键即可
	fmt.Println("Map after deletion:", mymap)

	// map的排序, 按照key排序
	var ScoreMap = make(map[string]int, 50)
	for i := 0; i < 50; i++ {
		key := fmt.Sprintf("stu%02d", i) // "stu%02d"的意思是数字不足两位时前面补0
		value := 100 - i
		ScoreMap[key] = value
	}

	/*
		for k, v := range ScoreMap {
			fmt.Printf("Key: %s, Value: %d\n", k, v)
		}
	*/

	keys := make([]string, 0, len(ScoreMap)) // 这里的keys的类型是[]string切片，容量是ScoreMap的长度，0是初始长度
	for k := range ScoreMap {                // 只遍历key，不需要value。因为我们要对key排序。 可能你会问为什么不是for k, _ := range ScoreMap，这样写也是可以的，但是Go语言中如果变量不使用会报错，所以用下划线_表示忽略这个变量更合适
		keys = append(keys, k)
	}

	sort.Strings(keys)       // 对key切片进行排序
	for _, k := range keys { // 直接按顺序遍历排序后的，然后再map查到一样的值即可
		fmt.Printf("Sorted Key: %s, Value: %d\n", k, ScoreMap[k])
	}

	// map切片
	var newMap = make(map[string]int, 5)
	fmt.Println("New Map:", newMap)

	var mapSlice = make([]map[string]int, 3) // var ScoreMap = make(map[string]int, 50) 区分map初始化, 区分传统数据类型切片初始化slice8 := make([]int, len(slice6))
	for i := range mapSlice {
		mapSlice[i] = make(map[string]int)                // 对切片的每一个map都要初始化
		mapSlice[i][fmt.Sprintf("mapkey%d", i)] = i * 100 //给key一个初始值 第一个[]是切片索引，第二个[]是map的key
	}

	v, ok := mapSlice[1]["mapkey1"] // 访问map切片的元素
	if ok {
		fmt.Println("mapSlice[1][\"mapkey1\"] =", v)
	} else {
		fmt.Println("Key not found in mapSlice[1]")
	}

	// 指针
	Af := 10
	fmt.Printf("%p,%d", &Af, Af)
	var myPtr *int = &Af
	myValue := *myPtr
	fmt.Println(myValue)

	// 类型断言, 猜测空接口当前的具体类型
	ret, ok := em.(string) // 断言em是string类型，可以用ok接收是否成功
	if ok {
		fmt.Println("Type assertion succeeded:", ret)
	} else {
		fmt.Println("Type assertion failed")
	}

	// time package 使用
	// 可以用now获取当前时间
	now := time.Now()
	fmt.Println("Current Time:", now)
	fmt.Println("Year:", now.Year())
	fmt.Println("Month:", now.Month())
	fmt.Println("Day:", now.Day())
	fmt.Println("Hour:", now.Hour())
	fmt.Println("Minute:", now.Minute())
	fmt.Println("Second:", now.Second())
	// 时间戳
	timestamp := now.Unix()
	fmt.Println("Unix Timestamp:", timestamp)
	// 时间间隔
	duration := time.Duration(2*time.Hour + 30*time.Minute)
	fmt.Println("Duration:", duration)
	// 时间加减
	future := now.Add(24 * time.Hour) // 24小时后，本质上是now.Add(duration)
	fmt.Println("Future Time (24 hours later):", future)
	past := now.Add(-24 * time.Hour) // 24小时前
	fmt.Println("Past Time (24 hours earlier):", past)
	// 计时器
	for tmp := range time.Tick(2 * time.Second) { // 每隔2秒执行一次
		fmt.Println("Tick at", tmp)
		break // 只执行一次，避免死循环
	}
	// 格式化时间
	// Go语言使用特定的时间"2006-01-02 15:04:05"作为格式化模板
	formatted := now.Format("2006-01-02 15:04:05")
	fmt.Println("Formatted Time:", formatted)

	// 文件操作
	// 打开文件
	fileobj, err := os.Open("./test.txt")
	if err != nil {
		fmt.Println("Error opening file:", err)
	} else {
		defer fileobj.Close()
	}

	// 用defer避免忘记
	defer fileobj.Close()
	var temp = make([]byte, 128) // var 就不要：=
	n, err := fileobj.Read(temp)
	if err != nil {
		fmt.Println("Error reading file:", err)
	} else {
		fmt.Printf("Read %d bytes: %s\n", n, string(temp[:n])) // string(temp[:n]) 只转换读取的部分
	}

	// 另一种读取文件方法，按行读取bufio
	// 读取一行
	reader := bufio.NewReader(fileobj)
	line, err := reader.ReadString('\n') // 读取到换行符为止
	if err != nil {
		fmt.Println("Error reading line:", err)
	} else {
		fmt.Println("Read line:", line)
	}

	// 另一种读取方法，os直接读取整个文件
	reader2, err := os.ReadFile("./test.txt") // 读取整个文件
	if err != nil {
		fmt.Println("Error reading file:", err)
	} else {
		fmt.Println("Read entire file:", string(reader2))
	}

	// 写文件
	// 先打开新文件
	// os.O_CREATE|os.O_WRONLY|os.O_TRUNC 表示创建文件、只写模式、清空文件
	// 0644 是文件权限，表示所有者可读写，组用户和其他用户可读
	fileobj2, err := os.OpenFile("./test_write.txt", os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0644)
	if err != nil {
		fmt.Println("Error opening file for writing:", err)
	} else {
		defer fileobj2.Close()
	}
	defer fileobj2.Close()

	// 方法1：直接写入字节切片
	str1 := "Hello, this is a test write.\n"
	bytewrite := []byte(str1)
	n2, err := fileobj2.Write(bytewrite)
	if err != nil {
		fmt.Println("Error writing to file:", err)
	} else {
		fmt.Printf("Wrote %d bytes to file.\n", n2)
	}

	// 方法2：使用bufio写入
	writetext := bufio.NewWriter(fileobj2)
	str2 := "This is another line written using bufio.\n"
	writetext.WriteString(str2)
	writetext.Flush() // 别忘了刷新缓冲区

	// 方法3：使用os.WriteFile直接写入整个文件
	// 这种方法会覆盖原文件内容
	str3 := "This line is written using os.WriteFile.\n"
	err = os.WriteFile("./test_write.txt", []byte(str3), 0644)
	if err != nil {
		fmt.Println("Error writing file using os.WriteFile:", err)
	} else {
		fmt.Println("Successfully wrote file using os.WriteFile.")
	}

}
