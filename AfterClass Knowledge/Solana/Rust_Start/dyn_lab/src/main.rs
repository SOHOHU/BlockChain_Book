// dyn 相关练习入口：trait 对象、动态分发示例请在此扩展
fn main() {
    println!("== dyn 练习 ==");
    trait_test();
    dyn_test();
}

// Trait 可叠加， Trait1 + Trait2 ... 这样可用聚合多个Trait
// Trait Animal ： Trait1 + Trait2 ...

fn dyn_test() {
    // TODO: 在这里添加你的 dyn/trait object 示例
    // 如果我们使用dyn新建一个指针，那么这些定义的变量都会被纳入dyn animal备选项中，我在函数直接声明dyn animal的形参，他们三个都有可能被选择
    let Dog: &dyn Animal = &dog{};
    let Cat: &dyn Animal = &cat{};
    let Baer: &dyn Animal = &baer{};
    // 但是依然满足多态，执行什么取决于传入什么, 这似乎是更接近传统编译语言的多态特性
    Animalbehavior(Dog);
    Animalbehavior(Cat);
    Animalbehavior(Baer);
    let Dog02 = get_animal();
    Dog02.eat_food();
    Dog02.make_sound();
}

// 也可以作为返回值, 但是需要用Box装起来, 返回一个Box
fn get_animal() -> Box<dyn Animal> {
    Box::new(dog{})
}

fn Animalbehavior (a: &dyn Animal) {
    a.eat_food();
    a.make_sound();
    match a {
        dog => {
            print!("Dog sleep");
        }
        cat => {
            print!("Cat sleep");
        }
        baer => {
            print!("Bear sleep");
        }
    }
}

fn trait_test() {
    let Dog = dog{};
    let Cat = cat{};
    let Baer = baer{};
    Dog.eat_food();
    Dog.make_sound();
    Cat.eat_food();
    Cat.make_sound();
    Baer.eat_food();
    Baer.make_sound();
    AnimalSleep(Dog);
    AnimalSleep(Cat);
    AnimalSleep(Baer);
}

// 多态在泛型和形参的体现。
// 1、泛型约束，定义一个类型A，必须是Animal类型，后续可用
// 2、形参多态，可用传入一个泛型声明过的A类型
fn AnimalSleep <A: Animal> (animal: A) {
    match animal {
        dog => {
            print!("Dog sleep");
        }
        cat => {
            print!("Cat sleep");
        }
        baer => {
            print!("Bear sleep");
        }
    }
}

// 简单复习一下之前的Trait
struct dog {}

struct cat {}

struct baer{}

// 抽象类装接口，调用者必须完全实现所有接口
trait Animal {  
    fn eat_food(&self);
    fn make_sound(&self);
}

impl Animal for dog {
    fn eat_food(&self) {
        println!("Dog eat bone");
    }
    fn make_sound(&self) {
        println!("Dog bark");
    }
}

impl Animal for cat {
    fn eat_food(&self) {
        println!("Cat eat fish");
    }
    fn make_sound(&self) {
        println!("Cat meow");
    }
}

impl Animal for baer {
    fn eat_food(&self) {
        println!("Bear eat meat");
    }
    fn make_sound(&self) {
        println!("Bear growl");
    }

}