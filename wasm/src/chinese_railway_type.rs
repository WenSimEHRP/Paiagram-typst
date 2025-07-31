use once_cell::sync::Lazy;
use regex::Regex;

pub struct PatternType {
    pub regex: Lazy<Regex>,
    pub typ: &'static str,
}

#[rustfmt::skip]
pub static PATTERNS: Lazy<Vec<PatternType>> = Lazy::new(|| vec![
    PatternType { regex: Lazy::new(|| Regex::new(r"^G\d+").unwrap()),          typ: "高速" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^D\d+").unwrap()),          typ: "动车组" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^C\d+").unwrap()),          typ: "城际" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^Z\d+").unwrap()),          typ: "直达特快" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^T\d+").unwrap()),          typ: "特快" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^K\d+").unwrap()),          typ: "快速" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^S\d+").unwrap()),          typ: "市郊" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^[1-5]\d{3}$").unwrap()),   typ: "普快" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^[1-5]\d{3}\D").unwrap()),  typ: "普快" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^6\d{3}$").unwrap()),       typ: "普客" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^6\d{3}\D").unwrap()),      typ: "普客" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^7[0-5]\d{2}$").unwrap()),  typ: "普客" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^7[0-5]\d{2}\D").unwrap()), typ: "普客" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^7\d{3}$").unwrap()),       typ: "通勤" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^7\d{3}\D").unwrap()),      typ: "通勤" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^8\d{3}$").unwrap()),       typ: "通勤" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^8\d{3}\D").unwrap()),      typ: "通勤" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^Y\d+").unwrap()),          typ: "旅游" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^57\d+").unwrap()),         typ: "路用" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^X1\d{2}").unwrap()),       typ: "特快行包" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^DJ\d+").unwrap()),         typ: "动检" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^0[GDCZTKY]\d+").unwrap()), typ: "客车底" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^L\d+").unwrap()),          typ: "临客" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^0\d{4}").unwrap()),        typ: "客车底" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^X\d{3}\D").unwrap()),      typ: "行包" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^X\d{3}$").unwrap()),       typ: "行包" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^X\d{4}").unwrap()),        typ: "班列" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^1\d{4}").unwrap()),        typ: "直达" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^2\d{4}").unwrap()),        typ: "直货" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^3\d{4}").unwrap()),        typ: "区段" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^4[0-4]\d{3}").unwrap()),   typ: "摘挂" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^4[5-9]\d{3}").unwrap()),   typ: "小运转" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^5[0-2]\d{3}").unwrap()),   typ: "单机" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^5[3-4]\d{3}").unwrap()),   typ: "补机" },
    PatternType { regex: Lazy::new(|| Regex::new(r"^55\d{3}").unwrap()),       typ: "试运转" },
]);
