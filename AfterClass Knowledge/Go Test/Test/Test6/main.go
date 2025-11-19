/*
你有50枚金币，需要分配给以下几个人：Matthew,Sarah,Augustus,Heidi,Emilie,Peter,Giana,Adriano,Aaron,Elizabeth。
分配规则如下：
a. 名字中每包含1个'e'或'E'分1枚金币
b. 名字中每包含1个'i'或'I'分2枚金币
c. 名字中每包含1个'o'或'O'分3枚金币
d: 名字中每包含1个'u'或'U'分4枚金币
写一个程序，计算每个用户分到多少金币，以及最后剩余多少金币？
程序结构如下，请实现 ‘dispatchCoin’ 函数
*/

package main

import "fmt"

var (
	coins = 50
	users = []string{
		"Matthew", "Sarah", "Augustus", "Heidi", "Emilie", "Peter", "Giana", "Adriano", "Aaron", "Elizabeth",
	}
	distribution = make(map[string]int, len(users))
)

func dispatchCoin() int {
	userCoins := 0
	for _, value := range users {
		// 字符串也用for range
		for _, char := range value {
			switch char {
			case 'e', 'E':
				// 规则 a: 名字中每包含1个'e'或'E'分1枚金币
				userCoins += 1
			case 'i', 'I':
				// 规则 b: 名字中每包含1个'i'或'I'分2枚金币
				userCoins += 2
			case 'o', 'O':
				// 规则 c: 名字中每包含1个'o'或'O'分3枚金币
				userCoins += 3
			case 'u', 'U':
				// 规则 d: 名字中每包含1个'u'或'U'分4枚金币
				userCoins += 4
			}
		}
		if userCoins > 50 {
			println("not enough")
			break
		}
	}
	return 50 - userCoins
}

func main() {
	left := dispatchCoin()
	fmt.Println("剩下：", left)
}
