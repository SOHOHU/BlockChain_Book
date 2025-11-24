// 条件与控制流练习：if / match / loop / while / for
fn main() {
    println!("== 条件与控制流 ==");
    test_if();
    test_while();
    // test_loop();
    test_for();
}

fn test_if() {
    let age_to_drive: u8 = 16;
    println!("enter the age");

    // rust标准输入流程，先新建一个空的，可变类型的String指针，然后作为类型输入到标准输入函数read_line中
    // 记得删除最后的换行, 调用String类型的trim即可
    // unwrap用来直接提取内部的值
    // 类似于go, parse::<>用于将字符串转化为某种形式，这里应该用到了泛型
    let myinput: &mut String =&mut String::from("");
    std::io::stdin().read_line(myinput).unwrap();

    let age = myinput.trim().parse::<u8>().unwrap();

    if age > age_to_drive {
        println!("welcome to drive");
    } else if age == 16 {
        println!("nothing happened");
    } else {
        println!("error happened");
    }

    // rust的if-else语句可以直接作为赋值语句
    let licence: bool = if age > 16 { true } else { false };
    println!("{}", licence);
}

#[allow(dead_code)]
fn test_while() {
    let mut  num: u8 = 16;
    while num > 0 {
        num = num - 1;
        println!("this is num, {}", num);
        if num == 8 {
            break;
        }
    }
}

fn test_loop() {
    loop {
        // rust 不支持++和--语句
        println!("This is like while true");
        let mut num = 0;
        num = num + 1;
        if num == 5 {
            println!("{}", num);
            break;
        }
    }
}

fn test_for() {
    let age = [1,2,3,4,5];
    // rust中的for必须在数组或者切片中使用，想类似c语言做法必须自建一个递增数组
    for value in age {
        println!("This is value, {}", value);
        if value == 4 {
            println!("We got {}", value);
        }
    }
}