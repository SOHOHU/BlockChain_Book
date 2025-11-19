package main

import "fmt"

func min[T int | float64](a, b T) T {
	if a <= b {
		return a
	}
	return b
}


func main() {
	m1 := min[int](1, 2)  // 1
	fmt.Println("This is", m1)
}