// 这个项目专门用来测试rust中不同的变量类型
fn main() {
    println!("== 基础变量展示 ==");
    test_func();
}

fn test_func() {
    // rust 使用 ：定义变量
    // 记住rust有加分号，这是与go不同的地方
    // 单元类型，直接定义为一个（）, 不包含任何内容的空，很像void
    let x: () = () ;
    // let x: () = 5 //此时赋值任何数据类型就会报错
    // i代表int，有符号整数，u代表uint, rust必须指定大小
    println!("{:?}", x);
    let a: i8 = -5;
    let b: u8 = 5;
    // println! 是标准输出宏：格式化后输出并自动换行
    println!("输出 ab 示例: {}, {}", a, b); 
    // f就是浮点，这里不说了,f最小是32哦，16不稳定
    let c: f32 = 5.5;
    // 需要说的是rust必须相同类型才可做运算，浮点 - 整型 会报错如
    // let d: f16 = c - a //错误
    let d: u8 = b + 8;
    // as 强制转换
    let e: f32 = a as f32;
    let f: f32 = e - c;
    println!("These are c to f, {}, {}, {}, {}", c, d, e, f);
    // bool, 没什么好说的
    // 此处引出rust一个性质，在rust的变量分成可变和不可变两种，默认是不可变的，想要变成可变需要加上mut关键字
    let mut g: bool = false;
    // 此处没mut就会报错
    g = true;
    // 字符与字符串,注意字符串的定义
    let mychar: char = 'A';
    let mystr: &str = "HSQ";
    println!("{},{}", mychar, mystr);

    //元组，小括号：可以储存多个不同数据类型的特殊数组
    let name: (&str, i8) = ("HSQ", 18);
    // 元组的特殊输出法则
    // println!("{}", name); 错误
    println!("{:?}", name);

    // 数组, 中括号，用【类型，大小】表示这个数组的类型
    let age: [i8; 3] = [18,20,22];
    println!("{:?}", age);

    // 切片，底层原理和go类似
    // 记住切片的数据类型，指针+没用大小，引用格式也是类似于指针。[]使用左闭右开
    let ages: [i8; 6] = [18,20,22,24,26,30];
    let newages: &[i8] = &ages[1..4];
    println!("{:?}", newages);
}
