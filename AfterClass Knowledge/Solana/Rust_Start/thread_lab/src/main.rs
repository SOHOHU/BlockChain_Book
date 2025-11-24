use std::{
    ops::AddAssign,
    sync::{Mutex, MutexGuard},
    thread::{self, Scope, spawn},
};

// 线程相关练习入口：后续在此添加 std::thread / join / channel 等示例
fn main() {
    println!("== 线程练习 ==");
    // test_thread();// TODO: 在这里调用你的线程示例函数
    // test_scope();
    // 总之，用锁就要确保安全，完善代码避免死锁
    test_mutex();
}

fn test_thread() {
    // rust 中任意线程会绑定在一个CPU上执行
    let myfn1 = || {
        let mut x = 0u128;
        for i in 0..1000 {
            x = x + i;
            println!("1 is going");
        }
    };

    let myfn2 = || {
        let mut x = 0u128;
        for i in 0..1000 {
            x = x + i;
            println!("2 is going");
        }
    };
    // spawn,新键线程
    let handle: std::thread::JoinHandle<_> = spawn(myfn1);
    // join 可以让所有线程阻塞，直到现在的线程完成
    // 我新建了两个线程，这两个线程如果同时join，就会并行执行，阻塞两个进程外的其他进程
    let handle2: std::thread::JoinHandle<_> = spawn(myfn2);
    handle.join();
    handle2.join();
}

struct person {
    name: String,
} 

fn test_scope() {
    // scope
    let age = 34;
    let p1 = person{
        name: "HSQ".to_string(),
    };
    // 用了move才可以让作用在子线程的闭包从外部取变量，如这里的age
    // 但是对于复杂数据类型，如结构，move进闭包后父程序将永远失去这个变量，即外部不可用，Scope就是解决这个问题
    let print_age = || {
        println!("age is {}", age);
        println!("name is {}", p1.name);
    };
    // println!("{}", p1.name); 错误

    // 将子线程规定在scope内即可不需要move
    std::thread::scope(|scope|{
        scope.spawn(print_age).join();
    });

    println!("{}", p1.name);

}

fn test_mutex(){
    // 初始化一个锁，这个锁里面保存了一个初始值为0的变量
    let score: Mutex<i32> = Mutex::new(0);
    
    {
        // 访问锁内数据，同时上锁；作用域结束自动释放
        let mut guard = lock_unpoisoned(&score);
        guard.add_assign(5);
        // 输出5，非常正常
        println!("{}", guard);
    }

    let myfn = ||{
        // 若线程 panic 导致锁中毒，使用 into_inner 恢复
        let mut data = lock_unpoisoned(&score);
        println!("{}", data);
        for  i in 1..10  {
            data.add_assign(i);
            println!("{}", data);
            println!("Thread 1 is going")
        }
    };
    
    let myfn2 = ||{
        let mut data = lock_unpoisoned(&score);
        println!("{}", data);
        for  i in 1..10  {
            data.add_assign(i);
            println!("{}", data);
            println!("Thread 2 is going")
        }
    };
    
    _ = std::thread::scope(|scope|{
        // 因为是读取锁，线程会自动顺序执行
        scope.spawn(myfn).join();
        scope.spawn(myfn2).join();
    });

    println!("{}", score.lock().unwrap());

}

// 获取锁，若因线程 panic 中毒，则恢复内部数据继续使用
fn lock_unpoisoned<'a, T>(m: &'a Mutex<T>) -> MutexGuard<'a, T> {
    match m.lock() {
        Ok(guard) => guard,
        Err(poisoned) => {
            eprintln!("lock poisoned, recovering inner data");
            poisoned.into_inner()
        }
    }
}
