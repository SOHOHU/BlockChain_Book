use clap::{Arg, Parser, command};
use reqwest::blocking; // 同步 HTTP 客户端
use serde::{Deserialize, Serialize};

// 常用 CLI 提示（在 workspace 根执行）：
// cargo build -p cargo_tools_lab
// cargo run   -p cargo_tools_lab -- -n Bob -v 7 --fetch https://httpbin.org/get --post https://httpbin.org/post
// cargo test  -p cargo_tools_lab
// cargo check -p cargo_tools_lab
// cargo doc   -p cargo_tools_lab --open

/// 简单的 CLI 参数，使用 clap 自动解析，前置这两个点可以让Arg变成参数设置
#[derive(Parser, Debug)]
#[command(author, version, about = "Cargo 工具练习 CLI")]
struct Args {
    /// 要翻倍的数值
    #[arg(short = 'v', long, default_value_t = 5)]
    value: i32,
    /// 用于问候的名字
    #[arg(short = 'n', long, default_value = "Cargo")]
    name: String,
    /// 是否打印原始命令行
    #[arg(long, default_value_t = false)]
    show_raw: bool,
    /// 可选：请求这个 URL 并打印响应体
    #[arg(long)]
    fetch: Option<String>,
    /// 可选：POST 到这个 URL，发送 JSON
    #[arg(long)]
    post: Option<String>,
    /// policy 示例：可传入策略名（例如 none / retry / fallback），仅演示用途
    #[arg(long, default_value = "none")]
    policy: String,
}

fn main() {
    println!("== Cargo 工具练习 ==");
    // 用parse解析参数，解析的结构体必须符合规范
    let args = Args::parse();
    println!("double({}) = {}", args.value, double(args.value));
    println!("greet: {}", greet(&args.name));

    if args.show_raw {
        let raw: Vec<String> = std::env::args().collect();
        println!("raw args: {:?}", raw);
    }

    // 简单的 serde 示例

    let (json, back) = serde_demo(&args.name, args.value);
    println!("serde json = {}", json);
    println!("serde back = {:?}", back);

    // 如果提供了 --fetch，则演示 reqwest 
    // 这个功能很像python的request
    if let Some(url) = args.fetch {
        match fetch_once(&url) {
            Ok(body) => println!("fetch ok (len={}): {}", body.len(), body),
            Err(e) => eprintln!("fetch error: {e}"),
        }
    }

    if let Some(url) = args.post {
        match post_json(&url, &args.name, args.value, &args.policy) {
            Ok(body) => println!("post ok (len={}): {}", body.len(), body),
            Err(e) => eprintln!("post error: {e}"),
        }
    }
}


// 声明使用的依赖到结构体中
#[derive(Debug, Serialize, Deserialize, PartialEq)]
// 准备序列化的结构体
struct Person {
    name: String,
    age: u8,
}

/// 把数字翻倍
pub fn double(n: i32) -> i32 {
    n * 2
}

/// 简单问候
///
/// # Examples
/// ```
/// let msg = cargo_tools_lab::greet("Rust");
/// assert_eq!(msg, "Hello, Rust!");
/// ```
pub fn greet(name: &str) -> String {
    format!("Hello, {name}!")
}

/// 演示 serde 序列化/反序列化
pub fn serde_demo(name: &str, age: i32) -> (String, Person) {
    // clamp 防止超出 u8 范围
    let age_u8 = age.clamp(0, u8::MAX as i32) as u8;
    // 初始化结构体
    let p = Person {
        name: name.to_string(),
        age: age_u8,
    };
    // 序列化为字符串
    let json = serde_json::to_string(&p).expect("serialize");
    // 反序列化为结构体
    let back: Person = serde_json::from_str(&json).expect("deserialize");
    // 返回结果
    (json, back)
}

/// 用 reqwest::blocking 发起一次 GET 请求
fn fetch_once(url: &str) -> Result<String, reqwest::Error> {
    // 1) 发送 GET 请求
    let resp = blocking::get(url)?;
    // 2) 读取响应体为字符串
    let text = resp.text()?;
    // 3) 返回字符串
    Ok(text)
}

/// 用 reqwest::blocking 发送 POST JSON 请求
fn post_json(url: &str, name: &str, age: i32, policy: &str) -> Result<String, reqwest::Error> {
    // 构造要发送的 JSON 负载
    let payload = serde_json::json!({
        "name": name,
        "age": age,
        "policy": policy,
    });
    // 发送 POST 请求，并自动设置 Content-Type: application/json
    let resp = blocking::Client::new().post(url).json(&payload).send()?;
    // 读取响应体为字符串
    let text = resp.text()?;
    Ok(text)
}
