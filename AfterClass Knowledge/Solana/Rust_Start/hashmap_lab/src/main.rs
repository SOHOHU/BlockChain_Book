// 用Hashmap需要提前导入的
use std::collections::{HashMap, HashSet, btree_set::Difference, hash_set};

// HashMap 练习入口：后续在此添加你的示例
fn main() {
    println!("== HashMap 练习 ==");
    test_hashmap();
    // TODO: 在这里调用你的 HashMap 示例函数
}

fn test_hashmap() {
    // 初始化
    let mut stocklist: HashMap<String, f32> = HashMap::new();
    // 添加元素
    stocklist.insert("HSQ".to_string(), 18.0);

    let len = stocklist.len();
    println!("{}", len);
    if stocklist.is_empty() {
        println!("stocklist is empty");
    } else {
        println!("stocklist is not empty");
    }

    println!("{:#?}", stocklist);

    stocklist.insert("CXA".to_string(), 18.5);
    // 删除元素
    // 插入必须用好String，但是删除用&str就好
    stocklist.remove("HSQ");
    println!("{:#?}", stocklist);

    // 更新，插入一般同样的键不同的值即可
    stocklist.insert("CXA".to_string(), 19.0);
    println!("{:#?}", stocklist);

    // 遍历, 可以直接用for获取键值对
    for (key, value) in stocklist {
        println!("key: {}, value: {}", key, value);
    }

    // hashset，存储无法重复的元素
    // 初始化
    let mut planets: HashSet<&str> = HashSet::from(["Earth", "Mars"]);
    println!("{:#?}", planets);
    let planets2: HashSet<&str> = HashSet::from(["Earth", "Jupiter"]);
    // a - b, 用Difference
    let Difference: hash_set::Difference<'_, &str, std::hash::RandomState> = planets.difference(&planets2);
    println!("{:#?}", Difference);
    // 插入
    planets.insert("Jupiter");
    println!("{:#?}", planets);
    // 删除
    planets.remove("Earth");
    println!("{:#?}", planets);


}
