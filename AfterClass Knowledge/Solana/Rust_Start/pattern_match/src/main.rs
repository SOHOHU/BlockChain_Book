
fn main() {
    println!("== 模式与 match ==");
    let ret = test_match(150);
    println!("{}",ret);
    let ret2 = test_arr_match();
    println!("{}",ret2);

}

fn test_match(age: i32) -> String {
    let myage = age;
    let y = 18;


    // 与其他语言的switch-case不同，match必须穷尽所有的可能，不过可以用_表示其他默认，用A..=B表示范围A - B，用|代表或
    match myage {
        // 多分支同时满足的时候优先满足最前面的
        0 => {
            println!("Baby");
        }
        35 | 0 => {
            println!("A little old");
        }
        35..=99 =>{
            println!("very old");
        }
        // match守卫，借助表达式（一般是if）来作为附加条件, 附加条件与原来的match条件构成且的关系
        100..=200 if y >= 18 => {
            println!("God");
        }
        100..=200 if y < 18 => {
            println!("not God");
        }
        // 此处表示y不被定义，虽然永远不会触发，但是没有就会报错
        100..=200 => {
            println!("messi");
        }
        // 如果=>末尾直接是值，那就是整个函数的返回值，当作return处理吗，但是用逗号和其他隔开。
        // 但是你要知道其他的分支不是不返回东西，他们返回()。所以要确保所有返回值一致的情况下才能用
        // 201 => "OK".to_string(), 报错，返回值不一致
        _ => {
            println!("nothing");
        }

    }
    // 必须要说的是，一个函数出现多个match，只有第一个match的返回模式可以生效, 尽可能一个match放一个函数里面
    return "Not".to_string();
}

fn test_arr_match() -> String {
    // match数组要说引入多少，类似切片的形式，左闭右闭
    // 书接上回，全部返回就可以确保一致。
    let array = [100, 200 ,300];
    match array[0..=1] {
        [100, 200] => "Right ARR".to_string(),
        // [100, 200, ..]可以代表这两个起头后的任意长度切片
        _ => "Not matched".to_string(),
    }
}
