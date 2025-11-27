// Async 练习入口：后续在此添加 async/await、runtime、并发示例。很像gorotine
use futures::join;
fn main() {
    println!("== Async 练习 ==");
    // TODO: 在这里添加你的 async 示例
    let num1 = async_example1();
    let num2 = async_example2();
    let num3 = async_example3();

    // 所有异步函数的返回值都被封装在future中，都是future类型，需要执行器解包。同时所有的async fn受执行器调度
    // let ret =smol::block_on(num1);
    // 处理多个Async，使用Join!宏加入执行器中。如果要启动分支可以使用Select，这里不做演示
    let mul_ret = smol::block_on(async{
        join!(num1, num2, num3)
    });
    // println!("This is {}", ret);
    println!("This is {:?}", mul_ret);
}

async fn async_example1() -> i32{
    std::thread::sleep(std::time::Duration::from_secs(2));
    println!("Async example 1");
    let num = 8;
    return num;
}

async fn async_example2() -> i32{
    std::thread::sleep(std::time::Duration::from_secs(2));
    println!("Async example 2");
    let num = 10;
    return num;
}

async fn async_example3() -> i32{
    std::thread::sleep(std::time::Duration::from_secs(2));
    println!("Async example 3");
    let num = 12;
    return num;
}

