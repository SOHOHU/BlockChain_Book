use std::cell::Cell;

// 结构体练习入口：基本 struct、元组 struct、带关联函数与方法

// 定义方法，元素名：类型。如果是外部函数直接调用，结构声明极其内部变量声明都要pub。间接调用（写一个pub初始化，main调用初始化）,可以不用
// 介绍一个特殊的数据类型，Cell。当结构体使用Cell时候，在结构体本身不mut的情况下，只有声明为Cell的可以修改，记得开头use
struct Person {
    first_name: String,
    last_name: String,
    birth_year: u16,
    birth_mouth: Cell<u8>,
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


fn newcar() -> Vehicle {
    let c1: Vehicle = Vehicle {
        year: 1992,
        color: ColorType::Blue,
    };
    return c1;
}

fn newperson() -> Person {
    // 经典键值对初始化
    // 要修改结构体实例的元素，给实例声明的时候加mut就好
    let p1 = Person{
        first_name: "Alice".to_string(),
        last_name: "Bob".to_string(),
        birth_year: 12,
        // Cell依然使用键值对初始化，但是要用Cell自己的方法from
        birth_mouth: Cell::from(22),
    };
    return p1;
}

// 对于rust而言，结构就是类，可以使用impl为结构增加函数
impl Vehicle {
    fn run(&self) {
        println!("Vehicle run");
    }
}

impl Person {
    fn run(&self) {
        println!("Person run");
    }
}

fn main() {
    println!("== 结构体练习 ==");
    let HSQ: Person = newperson();
    // 只有Cell对象自己的get才可以得到纯粹的值，类似upwarp
    println!("HSQ is {} and {}", HSQ.first_name, HSQ.birth_mouth.get());

    // Cell对象想改变值不能直接= ，需要用set方法
    HSQ.birth_mouth.set(0);
    println!("HSQ is {} and {}", HSQ.first_name, HSQ.birth_mouth.get());
    let Hcar: Vehicle = newcar();
    // 逍遥输出自定义枚举，使用我们在option中的方法，#【derive（debug）】加在自定义类型声明之前，本例子就是enum
    println!("Hcar is {:?}, and {}", Hcar.color, Hcar.year );
    Hcar.run();
    HSQ.run();
}
