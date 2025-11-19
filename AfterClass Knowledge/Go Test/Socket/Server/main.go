package main

import (
	"bufio"
	"fmt"
	"net"
)

func process(conn net.Conn) {
	// 进行发送或接受操作
	defer conn.Close()
	for {
		reader := bufio.NewReader(conn)
		var buf [1024]byte
		n, err := reader.Read(buf[:])
		if err != nil {
			fmt.Println("Error")
			return
		}
		recv := string(buf[:n])
		fmt.Println("接受数据", recv)

		// 返回接收数据给客户端
		conn.Write([]byte("ok"))
	}
}

func main() {
	fmt.Println("Hello Go")
	// 开启服务
	listen, ok := net.Listen("tcp", "127.0.0.1:8080")
	if ok == nil {
		fmt.Println("Error")
		return
	}

	for {
		// 等待客户端进行连接
		conn, err := listen.Accept()
		if err != nil {
			fmt.Println("Error")
			continue
		}
		// 启动一个gorotine处理连接
		go process(conn)

	}

}
