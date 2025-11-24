// rust的include就是pub，由此导入外部的库和包
pub mod helpers;

fn main() {
    println!("Hello, world!");
    // 使用嵌套module实现
    let myname: String = helpers::namehelpers::get_full_name("SOHO", "HU");
    println!("Hello,{0}", myname);
}

// 注意函数声明方式和形参声明方式，入参多用 &str 以减少拷贝；需要修改内容或持有所有权时使用 String（这是堆上的可变版本）
