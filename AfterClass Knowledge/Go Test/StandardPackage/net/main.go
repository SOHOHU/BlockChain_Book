package main

import (
	"fmt"
	"io"
	"net/http"
	"net/url"
)

func main() {
	resp, err := http.Get("https://www.liwenzhou.com/")
	if err != nil {
		fmt.Printf("get failed, err:%v\n", err)
		return
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	fmt.Println(string(body))

	apiURL := "http://127.0.0.1:9090/get"
	data := url.Values{}
	data.Set("name", "HSQ")
	data.Set("age", "18")
	u, _ := url.ParseRequestURI(apiURL)
	u.RawQuery = data.Encode()
	fmt.Println(u.String())

	resp2, _ := http.Get(u.String())
	defer resp2.Body.Close()
	body2, _ := io.ReadAll(resp2.Body)

	fmt.Println(string(body2))

	// post 使用http.post就好，注意请求头要作为参数，一般是json文件
	// 使用ListenAndServe快速启动服务器

	/* http.HandleFunc("/", sayHello)
	err := http.ListenAndServe(":9090", nil)
	if err != nil {
		fmt.Printf("http server failed, err:%v\n", err)
		return
	}
	*/

}
