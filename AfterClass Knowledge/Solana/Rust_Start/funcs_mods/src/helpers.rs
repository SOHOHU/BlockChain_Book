// 现在helpers是main的子模块，helper是一个大的模块，以文件展示，但是它也可以有自己的子模块
pub mod namehelpers {
    // 外部属性，这个外部属性允许函数不被使用
    #[allow(dead_code)]

    // 使用pub将默认private的函数改为公有
    pub fn get_full_name(first: &str, last: &str) -> String {
        // format,顺序格式化字符串,可返回
        let full_name: String = format!("{0}, {1}", first, last);
        return full_name;
    }
}


