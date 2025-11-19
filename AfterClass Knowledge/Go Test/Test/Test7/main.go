package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

// --- 1. Student 结构体 (数据模型/对象) ---

// Student 定义学生信息的基本结构
type Student struct {
	ID    int
	Name  string
	Age   int
	Score float64
}

// String 方法：为 Student 结构体添加打印格式化能力 (面向对象中的 toString/repr)
func (s Student) String() string {
	return fmt.Sprintf("ID: %d, 姓名: %s, 年龄: %d, 分数: %.2f", s.ID, s.Name, s.Age, s.Score)
}

// --- 2. StudentManager 结构体 (管理器/控制器) ---

// StudentManager 包含学生列表和管理功能
type StudentManager struct {
	students []Student // 存储所有学生的切片
	nextID   int       // 用于生成下一个学生的 ID
}

// NewStudentManager 是构造函数，用于初始化 StudentManager 对象
func NewStudentManager() *StudentManager {
	return &StudentManager{
		students: make([]Student, 0),
		nextID:   1, // 从 ID 1 开始分配
	}
}

// --- 3. StudentManager 上的方法 (行为/功能) ---

// FindIndexByID 根据 ID 查找学生在切片中的索引
// 这是一个内部辅助方法
func (sm *StudentManager) FindIndexByID(id int) (int, bool) {
	for i, s := range sm.students {
		if s.ID == id {
			return i, true // 找到，返回索引和 true
		}
	}
	return -1, false // 未找到，返回 -1 和 false
}

// DisplayStudents 展示学生列表
func (sm *StudentManager) DisplayStudents() {
	if len(sm.students) == 0 {
		fmt.Println("\n-- 列表中没有学生信息 --")
		return
	}
	fmt.Println("\n--- 学生列表 ---")
	for _, s := range sm.students {
		fmt.Println(s) // 自动调用 Student 的 String() 方法
	}
	fmt.Println("-----------------")
}

// AddStudent 添加新学生
func (sm *StudentManager) AddStudent(name string, age int, score float64) {
	newStudent := Student{
		ID:    sm.nextID,
		Name:  name,
		Age:   age,
		Score: score,
	}
	sm.students = append(sm.students, newStudent)
	sm.nextID++ // 自动递增 ID
	fmt.Printf("\n✅ 成功添加学生: %s, ID: %d\n", name, newStudent.ID)
}

// EditStudent 编辑学生信息
func (sm *StudentManager) EditStudent(id int, name string, age int, score float64) bool {
	index, found := sm.FindIndexByID(id)
	if !found {
		return false
	}

	// 更新学生信息
	sm.students[index].Name = name
	sm.students[index].Age = age
	sm.students[index].Score = score
	return true
}

// DeleteStudent 删除学生
func (sm *StudentManager) DeleteStudent(id int) bool {
	index, found := sm.FindIndexByID(id)
	if !found {
		return false
	}

	// 删除切片中的元素 (Go 语言标准做法：[0:index]...[index+1:])
	sm.students = append(sm.students[:index], sm.students[index+1:]...)
	return true
}

// --- 4. 主程序 (用户界面和交互) ---

// 辅助函数：读取用户输入的数字
func readIntInput(prompt string) int {
	fmt.Print(prompt)
	reader := bufio.NewReader(os.Stdin)
	line, _ := reader.ReadString('\n')
	line = strings.TrimSpace(line)
	val, err := strconv.Atoi(line)
	if err != nil {
		fmt.Println("⚠️ 输入无效，请输入数字。")
		return -1
	}
	return val
}

// 辅助函数：读取用户输入的字符串
func readStringInput(prompt string) string {
	fmt.Print(prompt)
	reader := bufio.NewReader(os.Stdin)
	line, _ := reader.ReadString('\n')
	return strings.TrimSpace(line)
}

// 辅助函数：读取用户输入的分数
func readFloatInput(prompt string) float64 {
	fmt.Print(prompt)
	reader := bufio.NewReader(os.Stdin)
	line, _ := reader.ReadString('\n')
	line = strings.TrimSpace(line)
	val, err := strconv.ParseFloat(line, 64)
	if err != nil {
		fmt.Println("⚠️ 输入无效，请输入有效分数。")
		return -1.0
	}
	return val
}

func main() {
	// 实例化 StudentManager 对象
	manager := NewStudentManager()

	// 初始化一些示例数据
	manager.AddStudent("张三", 18, 85.5)
	manager.AddStudent("李四", 19, 92.0)

	reader := bufio.NewReader(os.Stdin)

	for {
		fmt.Println("\n\n--- 学生信息管理系统 ---")
		fmt.Println("1. 展示学生列表")
		fmt.Println("2. 添加学生")
		fmt.Println("3. 编辑学生信息")
		fmt.Println("4. 删除学生")
		fmt.Println("5. 退出系统")
		fmt.Print("请选择功能 (1-5): ")

		choice, _ := reader.ReadString('\n')
		choice = strings.TrimSpace(choice)

		switch choice {
		case "1":
			manager.DisplayStudents()
		case "2":
			fmt.Println("\n-- 添加学生 --")
			name := readStringInput("请输入姓名: ")
			age := readIntInput("请输入年龄: ")
			score := readFloatInput("请输入分数: ")
			if age >= 0 && score >= 0 {
				manager.AddStudent(name, age, score)
			}
		case "3":
			fmt.Println("\n-- 编辑学生信息 --")
			id := readIntInput("请输入要编辑的学生的 ID: ")
			if id == -1 {
				continue
			}

			name := readStringInput("请输入新姓名: ")
			age := readIntInput("请输入新年龄: ")
			score := readFloatInput("请输入新分数: ")

			if age >= 0 && score >= 0 {
				if manager.EditStudent(id, name, age, score) {
					fmt.Printf("✅ ID %d 的信息更新成功!\n", id)
				} else {
					fmt.Printf("❌ 错误: 未找到 ID %d 的学生。\n", id)
				}
			}
		case "4":
			fmt.Println("\n-- 删除学生 --")
			id := readIntInput("请输入要删除的学生的 ID: ")
			if id == -1 {
				continue
			}

			if manager.DeleteStudent(id) {
				fmt.Printf("✅ ID %d 的学生删除成功!\n", id)
			} else {
				fmt.Printf("❌ 错误: 未找到 ID %d 的学生。\n", id)
			}
		case "5":
			fmt.Println("👋 感谢使用，系统退出。")
			return
		default:
			fmt.Println("无效的选择，请重新输入。")
		}
	}
}
