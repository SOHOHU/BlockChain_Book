package main

import (
	"bufio"
	"fmt"
	"net"
	"os"
	"strings"
)

func main() {
	// 连接服务器
	conn, err := net.Dial("tcp", "127.0.0.1:8080")
	if err != nil {
		fmt.Println("Error")
	}
	// 接受数据
	input := bufio.NewReader(os.Stdin)
	for {
		s, _ := input.ReadString('\n')
		s = strings.TrimSpace(s)
		if strings.ToUpper(s) == "Q" {
			return
		}

		_, err := conn.Write([]byte(s))
		if err != nil {
			fmt.Println("Error")
			return
		}

		var buf [1024]byte
		n, err := conn.Read(buf[:])
		if err != nil {
			fmt.Println("Error")
		}

		fmt.Println("收到", string(buf[:n]))
	}

}
