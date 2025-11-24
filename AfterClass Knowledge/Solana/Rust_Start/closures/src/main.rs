// 匿名函数（闭包）练习：捕获变量、move、迭代器配合使用
fn main() {
    println!("== 闭包练习 ==");
    test_closure();
}

struct person {
    first_name: String,
    last_name: String
}

fn test_closure() {
    // 简单的闭包， 类型为fn()但是我们从未给fn命名，说明闭包是匿名的，单行闭包可以不写花括号，多行必须写
    // 双杠是闭包的定义方式, 里面装参数给闭包主体
    let text = |x: i8, y: i8| println!("This is Closure, {} and {}", x , y);
    // 因为闭包是匿名函数。直接调用
    text(10, 20);
    // 闭包可以不显式设置返回值，只需要直接||参数+执行语句即可
    let num = |x: i32, y: i32| x + y;
    let a = num(10, 20);
    println!("{}", a);
    // 闭包的真正体现：内部函数体（||之后）调用闭包外部变量a
    let showresult = || println!("This is real closure, {}", (a + 8));
    showresult();
    
    //直接写的字符串是&str类型，必要的时候通过to_String进行转换
    let mut p: person = person { first_name: "HSQ".to_string(), last_name: "CXA".to_string()};
    // 下面我要通过闭包改变p, 想改变外部变量，闭包也必须是mut
    let mut changename = || {
        p.first_name = "LJH".to_string();
        p.last_name = "HGJ".to_string();
    };
    changename();
    println!("{}, {}", p.first_name, p.last_name);
    // 此处再使用changename();会报错，请闭包所有操作结束后再使用其他东西

    

}