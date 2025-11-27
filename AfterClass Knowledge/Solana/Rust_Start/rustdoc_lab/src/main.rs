//! rustdoc 练习入口
//! - `cargo doc -p rustdoc_lab --open` 生成并打开文档
//! 这个文档会帮助其他人读取这个项目结构，包括Mod，fn和crate等等，是一个开发阶段非常常用的共用文档， 因为它是生成一个md格式的东西，所以多命名有一些要求，尽可能遵守
//! - 在函数/模块前写 `///` 文档注释，示例代码可用 doctest 形式
fn main() {
    println!("== rustdoc 练习 ==");
    // 调用示例函数，便于运行查看输出
    println!("add(2, 3) = {}", add(2, 3));
    let a = Article::new("Rustdoc", "Doc comments demo");
    println!("article summary: {}", a.summary());
}

/// 计算两个整数之和。
///
/// # Examples
/// ```
/// let sum = rustdoc_lab::add(2, 3);
/// assert_eq!(sum, 5);
/// ```
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

/// 简单的文章示例。
#[derive(Debug)]
pub struct Article {
    pub title: String,
    pub body: String,
}

impl Article {
    /// 创建一篇文章。
    pub fn new(title: &str, body: &str) -> Self {
        Self {
            title: title.to_string(),
            body: body.to_string(),
        }
    }

    /// 返回简短摘要。
    pub fn summary(&self) -> String {
        format!("{}: {}", self.title, self.body)
    }
}
