use std::fmt;

fn main() {
    println!("Hello, world!");
    let ret: Option<u8> = test_option_type();
    println!("{}", ret.unwrap());
    let ret2:Option<MyEnum> = test_option_multitype();
    // 依然只能收获一个值，因为Bar和foo本质上都是myenum的元素，他们一个就可以继承enum，想要输出多个就多个myenum
    println!("{}", ret2.unwrap());
    demo_option_usage();
}

// option 即枚举，用泛型表示元素类型
fn test_option_type() -> Option<u8> {
    // 先建立一个空的枚举，后面再说
    let mut op1 = None;
    // 给option加东西用some关键字
    op1 = Some(10);
    let mut num = 10;
    while num > 0 {
        op1 = Some(num);
        num = num -1;
    }
    return op1;
    // op1依然只有一个值，因为定义的泛型是<u8>，一个类型，一个值。多个类型，或者数组，或者枚举enmu本身，可以上多个值
}


// 比如我有一个现成的枚举或者数组，也可以直接放进 Option 里
// #[derive(Debug)] 会为类型自动生成 Debug trait 的实现。println!("{:?}", ...) 或 {:#?} 需要被打印的类型实现 Debug，否则编译器报错。给 MyEnum 派生 Debug 后，println!("{:?}", ret2.unwrap()); 就能用调试格式打印枚举变体的内容了。
// Debug trait就是课堂上写的impl fmt::Debug for Type { ... }。每当我们使用自定义格式到底时候，如这里的Myenmu，foo等等，都要做这件事
// Debug trait解决了编译器不知道enum中是什么类型的问题
// 如果我需要强行实现值打印内容，使用{}而不使用{：？}, 那么我应该向编译器解释这个enum的输出方法，毕竟里面的自定义类型是不符合编译器输出方法的
// 一般就是解析为字符串
#[derive(Debug)]
pub enum MyEnum {
    // 定义一个元组变体，叫foo，可以被初始化
    Foo(i32, i32),
    // 定义一个字符串变体，叫Bar，可以被初始化
    Bar(String),
}

impl fmt::Display for MyEnum {
    // fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result：Display 约定的方法，fmt 里写入输出内容。默认用
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            // 把格式化后的文本写入 Formatter，返回 fmt::Result。
            MyEnum::Foo(a, b) => write!(f, "Foo({a}, {b})"),
            MyEnum::Bar(s) => write!(f, "Bar({s})"),
        }
    }
}


fn test_option_multitype() -> Option<MyEnum> {
    // Option 包裹枚举
    let mut op2: Option<MyEnum> = None;
    op2 = Some(MyEnum::Bar("OK".to_string()));
    op2 = Some(MyEnum::Foo(22, 33));
    return op2;
}

// 如何利用 Option 中的值的简单示例
fn demo_option_usage() {
    let maybe_num: Option<i32> = Some(5);

    // 解包：将枚举maybe_num的值传递出去，用some含着一个变量n装下，此时这个n可以视为正常变量
    if let Some(n) = maybe_num {
        println!("if let got {}", n);
    }

    // 如果要直接处理枚举内部值，使用枚举的map，map装下类型+处理后的内部值，直接导出即可
    let doubled = maybe_num.map(|n| n * 2).unwrap_or(0);
    println!("map + unwrap_or -> {}", doubled);
}
