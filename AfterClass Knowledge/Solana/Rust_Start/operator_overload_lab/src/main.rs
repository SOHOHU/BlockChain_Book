use std::ops::Add;

// 运算符重载练习入口：后续在此添加实现 std::ops::Add 等 trait 的示例
fn main() {
    println!("== 运算符重载练习 ==");
    // TODO: 在这里添加你的运算符重载示例
    let point1 = Point { x: 1, y: 2 };
    let point2 = Point { x: 3, y: 4 };
    // 不用调用add方法，直接+号即可
    let result = point1 + point2;
    println!("Result: x={}, y={}", result.x, result.y);
    let rectangle = Rectangle { width: 5, height: 10 };
    // point1 前面已被 move，若想复用需 clone
    let result = rectangle + point1.clone();
    println!("Result: x={}, y={}", result.x, result.y); 
}

// 和C++一样，先来几个类吧
#[derive(Clone, Copy)]
struct Point {
    x: i32,
    y: i32,
}


struct Rectangle {
    width: i32,
    height: i32,
}

// 重载模板。首先type定义输出类型，然后重写运算函数
impl Add for Point {
    type Output = Point;
    // 运算函数，返回一个点
    fn add(self, other: Point) -> Point {
        return Point {
            x: self.x + other.x,
            y: self.y + other.y,
        }
    }
}

// 如果要+不同的数据类型呢？
// 用<>说加号右边的东西
impl Add<Point> for Rectangle {
    type Output = Point;
    fn add(self, other: Point) -> Point {
        return Point {
            x: self.width + other.x,
            y: self.height + other.y,
        }
    }
}
