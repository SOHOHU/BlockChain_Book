// 泛型练习入口：后续在此添加你的泛型示例函数
fn main() {
    println!("== 泛型练习 ==");
    createPerson();
}

// 相当于抽象类,Trait里面可以直接写接口（不是函数，是指代于自己和子类的接口），要求子类全部实现
trait Animal {
    fn makesound(&self) -> ();
}

struct Dog {

}

struct Cat {

}

// 类可以继承多个Trait。想要传入具有多个Trait的泛型用+，如Pettype: Animal + Notdangers + Feed。这些Trait构成并集关系，只有成立才可以初始化
struct Person<Pettype: Animal> {
    // 用抽象类trait声明的时候记得加上dyn
    // 不过我们可以用泛型，直接给person传入一个trait也可以
    pet: Pettype,
    name: String,

}

// 让Dog继承Animal并且实现Animal的任何方法（不能有任何自己的方法，否则报错），因为我们这里的Animal没用方法，它必须为空
impl Animal for Dog { 
    fn makesound(&self) -> () {
        println!("wolf");
    }
} 
impl Animal for Cat { 
    fn makesound(&self) -> () {
        println!("meow");
    }
} 

fn createPerson() {
    let pet1: Dog = Dog{};
    let pet2: Cat = Cat {  };
    // 多态，因为Dog继承了Animal，作为子类直接覆盖父类
    let p1: Person<Dog> = Person{
        name: "HSQ".to_string(),
        pet: pet1,
    };
    // 继续熟悉结构的初始化
    let p2: Person<Cat> = Person{
        name: "CXA".to_string(),
        pet: pet2,
    };
    println!("{}", p1.name);
    // 带Self的函数，Self不算实参传入()中
    p1.pet.makesound();
    p2.pet.makesound();
}