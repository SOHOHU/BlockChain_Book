package main

import (
	"log"
	"os"
)

func main() {
	// SetOutput配置文件输出的位置，利用文件对象，我们通常会把这样的配置操作写到init函数中
	logtxt, _ := os.OpenFile("log.txt", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	// 保证后续日志写入这里
	log.SetOutput(logtxt)
	log.Println("这是一条很普通的日志。")
	v := "很普通的"
	log.Printf("这是一条%s日志。\n", v)

	// 可以自定义log，以对象的形式给出
	mylog := log.New(os.Stdout, "CXA", log.Ldate)
	mylog.Println("自己log")
	// SetPrefix函数用来设置输出前缀
	log.SetPrefix("[HSQ]")
	// Fatal系列函数会在写入日志信息后调用os.Exit(1)
	log.Fatal("我直接结束")
	// Panic系列函数会在写入日志信息后panic。
	log.Panicln("我直接Panic")
	// setflags能够输出更多的日志信息
	log.SetFlags(log.Llongfile | log.Lmicroseconds | log.Ldate)

}
