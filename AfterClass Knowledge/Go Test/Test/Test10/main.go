package main

import "fmt"

func biSearch(arr []int, value int) int {
	left := 0
	right := len(arr)

	for left <= right {
		mid := (left + right) / 2
		if arr[mid] < value {
			left = mid + 1
		} else if arr[mid] > value {
			right = mid - 1
		} else {
			fmt.Println("find it", arr[left])
		}
	}

	return arr[left]
}

func main() {
	slice1 := make([]int, 7, 100)
	for i := 0; i < 7; i++ {
		slice1 = append(slice1, i)
	}
	ret := biSearch(slice1, 5)
	println("result", ret)
}
