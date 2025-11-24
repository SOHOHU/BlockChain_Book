use std::{ops::Sub, os::windows::thread, time::Duration};

use chrono::naive;

// 时间相关练习入口：后续在此添加 chrono/std::time 等示例
fn main() {
    println!("== 时间练习 ==");
    test_time();
    // TODO: 在这里调用时间相关的示例函数
}

fn test_time() {
    // Duration 直接换算当前时间
    let dur: Duration = Duration::from_secs(15);
    println!("{:?}", dur.as_millis());
    // 15s - 5.5s = 9.5s
    let dur2 = Duration::from_millis(550);
    let dur3 = dur.sub(dur2);
    println!("{:?}", dur3.as_millis());

    // check_sub，安全检查是否负数时间
    let dur4 = Duration::from_secs(10);
    let dur5 = Duration::from_secs(15);
    // 负数会返回None
    let dur6 = dur4.checked_sub(dur5);
    println!("{:?}", dur6);
    
    // Instant
    // 获取当前时间
    let now = std::time::Instant::now();
    std::thread::sleep(dur2);
    // 测延迟
    let dur7 = now.elapsed();
    println!("{:?}", dur7);

    // chrono
    let now = chrono::Utc::now();
    // 格式化输出用{}即可
    println!("{}", now.format("%Y %b %d"));

    let local = chrono::Local::now();
    println!("{}", local.format("%Y %b %d"));

    // NaiveDate 实现自定义时间
    let date = chrono::NaiveDate::from_isoywd_opt(2024, 8, chrono::Weekday::Fri).unwrap();
    println!("{}", date);
    // 延迟4天
    date.iter_days().take(4);
    println!("{}", date);


}