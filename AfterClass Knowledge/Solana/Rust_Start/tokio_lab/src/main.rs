//! Tokio 执行器练习：基本 async/await、spawn、join_set、计时器与异步 IO 示例。
//! 运行：`cargo run -p tokio_lab`

use tokio::time::{sleep, Duration};
use std::{
    pin::Pin,
    task::{Context, Poll},
    future::Future,
};

/// Tokio 自带多线程/单线程 runtime，这里用宏生成入口。
#[tokio::main]
async fn main() {
    println!("== Tokio 练习 ==");

    // 并发任务：spawn 会把任务交给 Tokio 调度，返回 JoinHandle。
    let h1 = tokio::spawn(worker("A", 300));
    let h2 = tokio::spawn(worker("B", 100));

    // join 两个 handle，等待它们完成（失败会返回 JoinError）。
    let r1 = h1.await.expect("worker A panicked");
    let r2 = h2.await.expect("worker B panicked");
    println!("spawn results: {r1}, {r2}");

    // 用 JoinSet 管理一组动态任务。
    let mut set = tokio::task::JoinSet::new();
    for i in 0..3 {
        set.spawn(worker("Set", 50 * (i + 1)));
    }
    while let Some(res) = set.join_next().await {
        println!("join_set -> {}", res.expect("task panicked"));
    }

    // 计时器示例：sleep 不阻塞线程，只挂起当前任务。
    println!("sleeping 200ms...");
    sleep(Duration::from_millis(200)).await;
    println!("wake up");

    // 使用自定义 Future 示例
    let custom = MyFuture::new(3);
    let res = custom.await;
    println!("custom future => {res}");
}

/// 模拟工作任务：等待一段时间后返回字符串。
async fn worker(name: &str, ms: u64) -> String {
    sleep(Duration::from_millis(ms)).await;
    format!("worker {name} done after {ms}ms")
}

/// 一个简单的自定义 Future：
/// - 内部保存剩余轮次，每次 poll 消耗一轮
/// - 当计数归零时返回 Ready
struct MyFuture {
    remaining: u8,
}

impl MyFuture {
    fn new(times: u8) -> Self {
        Self { remaining: times }
    }
}

impl Future for MyFuture {
    type Output = &'static str;

    fn poll(mut self: Pin<&mut Self>, _cx: &mut Context<'_>) -> Poll<Self::Output> {
        // 每次 poll 消耗一轮，模拟异步进展
        if self.remaining > 0 {
            self.remaining -= 1;
            // 告诉执行器：还没准备好，下次再 poll
            Poll::Pending
        } else {
            // 条件满足，返回就绪结果
            Poll::Ready("done")
        }
    }
}
