use std::f32::consts::E;

// 迭代器练习入口：后续在此添加你的示例
fn main() {
    println!("== 迭代器练习 ==");
    test_iterator();
    // TODO: 在这里调用你的迭代器示例函数
}

fn test_iterator() {
    let myvec: Vec<&str> = vec!["a", "b", "c"];

    // 迭代器作为for中的遍历对象，这只是最基础的，但是迭代器也会被因此消耗
    for mystr in myvec.iter() {
        println!("{}", mystr);
    }

    // 如果还要继续用迭代器，重新获取一个可变的迭代器再调用 next
    let mut myiter = myvec.iter();

    // next决定迭代器指针走向
    // 第一个元素
    let item: Option<&&str> = myiter.next();
    // 第二个元素，没保存返回值，视为跳过
    myiter.next();
    // 第三个元素
    let item3: Option<&&str> = myiter.next();
    // 注意对于option的输出
    println!("{:?}, {:?}", item.unwrap(), item3.unwrap());

    // chain
    let myvec2: Vec<&str> = vec!["d", "e", "f"];
    let mut myiter2 = myvec2.iter();
    let mut myiter3 = myvec.iter();
    // chain的用法，在一个迭代器chain另一个迭代器，实现拼接
    let myiter4 = myiter3.chain(myiter2);
    for mystr in myiter4.clone() {
        println!("{}", mystr);
    }

    // 用map处理迭代器数据。在map中实现闭包即可，比如我们改变所有数据类型
    let myiter5 = myvec2.iter();
    // 全部变为大写
    let myiter6 = myiter5.map(|e| String::from(*e));
    let myiter7 = myiter6.map(|e| e.to_uppercase());
    for mystr in myiter7.clone() {
        println!("{}", mystr);
    }

    // stepby
    let myiter8 = myvec2.iter();
    // 步长为2, 于是e就被跳过了
    let myiter9 = myiter8.step_by(2);
    for mystr in myiter9.clone() {
        println!("{}", mystr);
    }

    // zip
    let myvec3: Vec<&str> = vec!["g", "h", "i"];
    let myvec4: Vec<&str> = vec!["j", "k", "l"];
    let myiter10 = myvec3.iter();
    let myiter11 = myvec4.iter();   
    // zip将两个迭代器合并成元组，（1，1），（2，2），（3，3）
    let myiter12 = myiter10.zip(myiter11);
    for (mystr1, mystr2) in myiter12.clone() {
        println!("{}, {}", mystr1, mystr2);
    }

    

}
