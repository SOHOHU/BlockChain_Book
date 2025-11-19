package main

import (
	"fmt"
	"reflect"
)

func reflectType(x interface{}) {
	// 获取类型信息
	obj := reflect.TypeOf(x)
	fmt.Printf("Type: %s\n", obj.Name())

	if obj.Kind() == reflect.Struct {
		// 遍历结构体字段
		// NumField()获取字段数量，Field(i)获取第i个字段的信息
		for i := 0; i < obj.NumField(); i++ {
			field := obj.Field(i)
			fmt.Printf("Field Name: %s, Type: %s, Tag: %s\n", field.Name, field.Type, field.Tag)
			fmt.Printf("  json tag: %s\n", field.Tag.Get("json"))
			fmt.Printf("  init tag: %s\n", field.Tag.Get("init"))
		}

		// 类型检查, 如果存在名为 "Name" 的字段，获取该字段的信息
		field, ok := obj.FieldByName("Name")
		if ok {
			fmt.Printf("Found field 'Name': Type: %s, Tag: %s\n", field.Type, field.Tag)
		} else {
			fmt.Println("Field 'Name' not found")
		}

		// 遍历结构体方法
		// NumMethod()获取方法数量，Method(i)获取第i个方法的信息
		for i := 0; i < obj.NumMethod(); i++ {
			// 引出方法，然后打印方法名和类型
			method := obj.Method(i)
			fmt.Printf("Method Name: %s, Type: %s\n", method.Name, method.Type)
		}

	}
}

// 反射可以修改空接口作为参数的交互问题，如果传入的是指针，可以通过Elem()获取指针指向的值
func reflectValue(x interface{}) {
	v := reflect.ValueOf(x)
	fmt.Printf("Value: %v\n", v.Interface())
	// 加ELem用于指针
	// kind()和typeof的区别是，kind()是分类，typeof是具体类型
	k := v.Elem().Kind()
	switch k {
	case reflect.Int:
		v.Elem().SetInt(200) // 修改指针指向的值
		fmt.Printf("Int value: %d\n", v.Elem().Int())
	case reflect.Array:
		v.Elem().Set(reflect.ValueOf([3]int{4, 5, 6}))
		fmt.Printf("Array value: %v\n", v.Interface())
	case reflect.Slice:
		fmt.Printf("Slice value: %v\n", v.Interface())
	default:
		fmt.Printf("Other type: %s\n", k)
	}
}

// 结构体反射
type student struct {
	// 指定两个tag，第一个用于json序列化，第二个用于初始化
	Name string `json:"name" init:"s_name"`
	Age  int    `json:"age" init:"s_age"`
}

type cat struct {
	name string
	age  int
}

func (s student) meow() {
	fmt.Println("Meow!")
}

func main() {
	var a int = 100
	var array1 = [3]int{1, 2, 3}
	var slice1 = []int{}
	slice1 = append(slice1, 10)
	cat1 := cat{
		name: "Tom",
		age:  3,
	}
	reflectType(cat1)   // Type: cat
	reflectType(a)      // Type: int
	reflectType(array1) // Type: [3]int
	reflectType(slice1) // Type: []int
	reflectValue(&cat1) // Value: {Tom 3}
	reflectValue(&a)    // Value: 100
	reflectValue(&a)

	student1 := student{
		Name: "Alice",
		Age:  20,
	}
	student1.meow()
	reflectType(student1) // Type: student
}
