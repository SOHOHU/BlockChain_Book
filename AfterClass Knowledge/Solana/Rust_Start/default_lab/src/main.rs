// Default 练习入口：后续在此添加实现 Default trait 的示例
// 用来自定义数据类型
fn main() {
    println!("== Default 练习 ==");
    default_example();
    // TODO: 在这里添加你的 Default 示例
}

// Default 无需定义，它是系统自带的trait
struct Student {
    name: String,
    age: u8,
    gpa: f32,
}

impl Default for Student {
    // 实例化default的方法，直接初始化一个student。再也不用另外写构造函数啦
    fn default() -> Self {
        Student {
            name: String::from("Unknown"),
            age: 0,
            gpa: 0.0,
        }
    }
}

fn default_example() {
    // 初始化
    let student1 = Student::default();
    println!("Default Student: Name: {}, Age: {}, GPA: {}", student1.name, student1.age, student1.gpa);

    let student2 = Student {
        name: String::from("Alice"),
        // 定义到一半可以直接启动default默认值
        ..Default::default()
    };
    println!("Student with custom name: Name: {}, Age: {}, GPA: {}", student2.name, student2.age, student2.gpa);

    let student3 = Student {
        age: 20,
        gpa: 3.8,
        ..Default::default()
    };
    println!("Student with custom age and gpa: Name: {}, Age: {}, GPA: {}", student3.name, student3.age, student3.gpa);

}

