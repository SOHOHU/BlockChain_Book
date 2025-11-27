// 正则表达式练习：使用 regex crate 展示匹配、捕获、替换
use regex::Regex;

fn main() {
    println!("== Regex 练习 ==");

    // 1) 简单匹配：检测字符串是否匹配模式
    let re_email = Regex::new(r"^[\\w.-]+@[\\w.-]+\\.\\w+$").unwrap();
    let s = "user@example.com";
    println!("{} is email? {}", s, re_email.is_match(s));

    // 2) 捕获组提取
    let re_kv = Regex::new(r"(?P<key>\\w+)=(?P<val>\\w+)").unwrap();
    let text = "foo=bar baz=qux";
    for caps in re_kv.captures_iter(text) {
        // 使用命名捕获组 key/val
        println!("key: {}, val: {}", &caps["key"], &caps["val"]);
    }

    // 3) 替换：把数字替换为 "#"
    let re_digit = Regex::new(r"\\d+").unwrap();
    let masked = re_digit.replace_all("Order 1234 costs 56", "#");
    println!("replace: {}", masked);

    // 4) 预编译 + 重用：Regex::new 在运行时编译，可重用以提升性能
    let re_word = Regex::new(r"\\b[a-zA-Z]{3}\\b").unwrap();
    let words: Vec<_> = re_word
        .find_iter("one two three four five six")
        .map(|m| m.as_str())
        .collect();
    println!("3-letter words: {:?}", words);
}
