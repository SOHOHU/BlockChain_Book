fn main() {
    println!("Hello, world!");
    test_Vec();
    string_vec();
    struct_vec()
}

#[derive(Debug)]
struct Vehicle {
    year: u16,
    color: String,
}


fn test_Vec() {
    // 初始化操作
    let mut myvec: Vec<i32> = Vec::new();
    // 插值，从最后插值
    myvec.push(30);
    myvec.push(40);
    myvec.push(50);
    // 可以单个索引，但是不能使用..做范围索引
    // 普通使用[]索引到范围外会导致程序崩溃，使用get方法可以正常运行，输出形参后面的全部值，如果形参超过len显示None
    println!("{:?}, {}, {}, {:?}", myvec, myvec.len(), myvec[1], myvec.get(10));
    // 向量可以转换为其他类型，比如切片，这样就可以做范围索引了, 不过是以&引用形式存在，其他地方我们也要用&处理切片
    let slice1: &[i32] = myvec.as_slice();
    // 左闭右开
    println!("{:?}", &slice1[0..2]);

    // retain 过滤保留满足条件的元素，引入一个闭包，这个闭包满足条件的会返回True，最后保留为True的元素（原地修改）
    // 下面只保留 >= 40 的值
    myvec.retain(|x| *x >= 40);
    println!("after retain >=40: {:?}", myvec);
}


fn string_vec() {
    // 对于复杂类型使用直接初始化更好，new完插入可能报错
    let names: Vec<&str> = vec!["HSQ", "CXA", "LJH", "HGJ"];
    // 可以用for处理vec, 但是必须clone，因为for的过程会销毁这些向量的值
    for each in names.clone() {
        println!("This is {}", each);
    }

    println!("{:?}", names);

}

fn struct_vec() {
    // 对于更复杂的类型，我们还是建立一个空的[]，然后往里面加值吧
    // 如果要加东西 Vec请写成mut
    let mut carlist: Vec<Vehicle> = vec![];
    let mut carlist2: Vec<Vehicle> = vec![];
    // 用1..临时创造切片方便for使用
    for i in 1..5u16 {
        carlist.push(Vehicle{year: 100 + i, color: "Red".to_string()});
        carlist2.push(Vehicle{year: 200 + i, color: "Red".to_string()});
    }

    println!("{:?}", carlist);
    // push只能一个一个值的使用，如果要实现向量合并，可以使用append
    // 注意要以可变的引用传入
    carlist2.append(&mut carlist);
    println!("{:?}", carlist2);
    // 有趣的是这时候carlist被清空了
    println!("{:?}", carlist);

    // 还有一种办法就是insert(index, element)，这个很好理解，不展示了
    // 删除用remove(index), 也很好理解
    
}
