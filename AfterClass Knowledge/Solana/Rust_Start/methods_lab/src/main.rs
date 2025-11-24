// 我们在结构体练习的基础上继续进行方法练习
use std::cell::Cell;
fn main() {
    println!("== 方法练习 ==");
    let mut Hcar: Vehicle = Vehicle::newcar();
    // 逍遥输出自定义枚举，使用我们在option中的方法，#【derive（debug）】加在自定义类型声明之前，本例子就是enum
    println!("Hcar is {:?}, and {}", Hcar.color, Hcar.year );
    // 调用方法(枚举记得要完整调用，不能只写一个red)
    Hcar.paint(ColorType::Red);
    println!("Hcar is {:?}, and {}", Hcar.color, Hcar.year );
}
struct Vehicle {
    year: u16,
    color: ColorType,
}

#[derive(Debug)]
enum ColorType {
    Green,
    Blue,
    Red,
}

// 为结构Vehicle定义方法
impl Vehicle {
    // 第一种情况，用this实现对实例参数访问，要修改加mut,它的调用方式用.
    fn paint(&mut self, newcolor: ColorType) {
        self.color = newcolor;
    }
    // 第二种情况，没用this，直接对结构本身进行定义获或其他操作，它的调用方式用::
    fn newcar() -> Vehicle {
        let c1: Vehicle = Vehicle {
            year: 1992,
            color: ColorType::Blue,
        };
        return c1;
    }
}

