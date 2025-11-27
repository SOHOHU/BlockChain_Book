use std::{
    fs::{self, File},
    io::{Read, Write},
    path::PathBuf,
};

// 文件交互练习：创建目录、创建/写入文件、读取文件
fn main() {
    println!("== 文件交互练习 ==");
    if let Err(e) = run_demo() {
        eprintln!("error: {e}");
    }
}

fn run_demo() -> std::io::Result<()> {
    // 1) 创建目录
    let dir = PathBuf::from("tmp_io_demo");
    fs::create_dir_all(&dir)?;

    // 2) 创建文件并写入
    // 先建立一个路径对象PathBuf
    let file_path = dir.join("sample.txt");
    let mut file = File::create(&file_path)?;
    file.write_all(b"Hello, file IO!")?;

    // 3) 读取文件
    let mut content = String::new();
    File::open(&file_path)?.read_to_string(&mut content)?;
    println!("read content: {}", content);

    Ok(())
}
