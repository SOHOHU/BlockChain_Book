package main

import (
	"fmt"    // 导入 fmt 包，用于格式化输入输出
	"iter"   // 导入实验性的 iter 包，用于定义和操作迭代器（Sequence）
	"maps"   // 导入 maps 包，提供了对 map 的常用操作（如获取键列表）
	"slices" // 导入 slices 包，提供了对 slice 的常用操作（如排序）
)

// Set 是一个简单的泛型集合（Set）类型。
// [E comparable] 表示 Set 是一个泛型类型，其元素 E 必须是可比较的（comparable），
// 这样才能作为 map 的键。
type Set[E comparable] struct {
	// 集合的底层实现是一个 map。
	// 键 E 存储集合的元素；空结构体 struct{} 作为值，因为它不占用内存空间。
	m map[E]struct{}
}

// NewSet 是 Set 的构造函数。
// 返回一个指向新的 Set 结构体的指针。
func NewSet[E comparable]() *Set[E] {
	return &Set[E]{m: make(map[E]struct{})}
}

// Add 方法用于向集合中添加一个元素 v。
func (s *Set[E]) Add(v E) {
	// 向底层 map 中写入元素。由于值是空结构体，内存效率高。
	s.m[v] = struct{}{}
}

// All 返回一个迭代器（iter.Seq），遍历集合中每个元素。
// iter.Seq[E] 代表一个“推送（Push）”迭代器，它本身是一个函数类型。
// 传入一个泛型E的集合，前面定义过
func (s *Set[E]) All() iter.Seq[E] {
	// 返回的函数就是迭代器的实现体，它接收一个 yield 函数作为参数。
	// iter.Seq[E]本质是一个E序列，它的生成逻辑如下：
	return func(yield func(E) bool) {
		// 遍历集合的底层 map。Map 的遍历顺序是不确定的。
		for v := range s.m {
			// 调用 yield 函数来“产生”当前元素 v。
			// yield 返回一个布尔值：如果为 false，表示调用者希望停止迭代。
			if !yield(v) {
				// 如果 yield 返回 false，则立即退出循环，停止迭代。
				// 如果不是false，所有的v会被导入进一元序列iter.Seq[E]中
				return
			}
		}
	}
}

// Filter 是一个高阶函数，用于基于条件过滤迭代器（Seq）。
// 它接收一个原始迭代器 seq 和一个过滤函数 keep，返回一个新的迭代器。
// 迭代器本质虽然是一元序列，但是依然以函数体展示，所以必须返回匿名函数
func Filter[V any](seq iter.Seq[V], keep func(V) bool) iter.Seq[V] {
	// 返回一个新的迭代器函数。
	// 单反回for range必须以yield事先定义。不过yield值就是身后的bool
	return func(yield func(V) bool) {
		// 使用 for-range 语法遍历传入的原始迭代器 seq。
		// Go 编译器识别 iter.Seq 类型，并将其转换为可 range 的结构。
		for v := range seq {
			// 检查当前元素 v 是否满足过滤条件。
			if keep(v) {
				// 如果满足条件，则调用 yield 函数产生这个元素。
				// 检查 yield 的返回值，看调用者是否想要停止。
				if !yield(v) {
					return // 如果调用者停止，则返回。
				}
			}
		}
	}
}

// Count 返回一个迭代器，依次产生 0 到 n-1 的整数序列。
func Count(n int) iter.Seq[int] {
	// 返回实现 iter.Seq[int] 接口的函数。
	return func(yield func(int) bool) {
		// 循环从 0 到 n-1。
		for i := 0; i < n; i++ {
			// 产生当前整数 i。
			if !yield(i) {
				return // 如果 yield 返回 false，停止计数。
			}
		}
	}
}

// Pairs 将一个一元序列（Seq[V]）转换成一个二元序列（Seq2[V, V]），每两个连续元素组成一对。
func Pairs[V any](seq iter.Seq[V]) iter.Seq2[V, V] {
	// 返回一个新的二元迭代器函数。
	return func(yield func(V, V) bool) {
		// iter.Pull 是关键：它将 push 迭代器 seq 转换成一个 pull 迭代器。
		// pull迭代器和push迭代器不一样，push只能存储值，想要对push里面的值进行操作，必须先转成pull
		// next 是一个函数，每次调用都会返回下一个元素和是否成功的布尔值。
		// stop 是一个清理函数，用于释放资源。
		next, stop := iter.Pull(seq)
		// 使用 defer 确保在函数退出时调用 stop()，清理资源。
		defer stop()

		for {
			// 第一次调用 next()，尝试获取第一个元素 (first)。
			first, ok := next()
			if !ok {
				return // 如果获取失败（序列结束），则返回。
			}

			// 第二次调用 next()，尝试获取第二个元素 (second)。
			second, ok2 := next()
			// 即使第二个元素获取失败（ok2=false），我们仍然尝试 yield 结果。
			// yield 函数产生一对元素 (first, second)。
			// next就当成指针一个个向后，形成了类似c++的迭代器
			if !yield(first, second) {
				return // 如果调用者停止，则返回。
			}

			// 如果第二个元素获取失败，但在 yield 后才检查，此时迭代器也应结束。
			if !ok2 {
				return
			}
		}
	}
}

// 总结迭代器：
// 1、push迭代器本质是一元序列，以函数形式展现，这个函数就是这个序列存值的机制
// 2、因为是函数展示，return必须匿名函数，因为要用到单反回for/range，所以这个匿名函数的形参必须是一个yield函数
// 3、yield函数实现定义for/range的返回值v和退出机制，return机制等
// 4、push迭代器只存不取，如果要从迭代器取值，需要先转化为pull迭代器做相关操作，比较简单

func main() {
	// 创建一个字符串集合 s。
	s := NewSet[string]()
	// 向集合中添加几种编程语言。
	for _, lang := range []string{"Go", "Rust", "Java", "Python"} {
		s.Add(lang)
	}

	fmt.Println("使用 for-range 遍历 Set.All():")
	// for-range 直接作用于 s.All() 返回的 iter.Seq，这是 Go 1.22+ 的语法糖。
	for v := range s.All() {
		fmt.Println("  *", v)
	}

	fmt.Println("\n直接传入一个 yield 函数：")
	// s.All() 返回一个函数，此处直接调用该函数，传入一个自定义的 yield 函数。
	s.All()(func(v string) bool {
		fmt.Println("  ->", v)
		return true // 返回 true 表示继续迭代。
	})

	fmt.Println("\nFilter 只保留长度大于 3 的语言：")
	// Filter 接收 s.All() 和一个条件函数，返回一个新的 Seq。
	// for-range 遍历这个被过滤后的 Seq。
	for v := range Filter(s.All(), func(v string) bool { return len(v) > 3 }) {
		fmt.Println("  >", v)
	}

	fmt.Println("\n使用 iter.Pull 把数字序列凑成一对对：")
	// Count(5) 产生序列 0, 1, 2, 3, 4。
	// Pairs 函数将其转换为二元序列 (0, 1), (2, 3)。数字 4 被丢弃。
	// for a, b := range ... 用于遍历二元序列。
	for a, b := range Pairs(Count(5)) {
		fmt.Printf("  pair: %d %d\n", a, b)
	}

	fmt.Println("\n标准库 maps+slices 与迭代器配合：")
	// 定义一个 map 存储城市信息。
	cities := map[int]string{
		1: "Beijing",
		2: "Shanghai",
		3: "Hangzhou",
	}
	// maps.Keys(cities) 返回一个 iter.Seq[int]，是 map 中所有键的序列。
	// slices.Sorted(maps.Keys(cities)) 对这个序列进行排序，返回一个排序后的 []int 切片。
	for _, key := range slices.Sorted(maps.Keys(cities)) {
		fmt.Printf("  key=%d, value=%s\n", key, cities[key])
	}
}
