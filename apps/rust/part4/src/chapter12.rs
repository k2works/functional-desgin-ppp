//! 第12章: Visitor パターン
//!
//! Visitor パターンは、オブジェクト構造の要素に対して実行される操作を表します。
//! Rust では enum のパターンマッチングが Visitor パターンの自然な代替となります。

use std::collections::HashMap;

// =============================================================================
// 1. 基本的な Visitor パターン（trait ベース）
// =============================================================================

/// 図形のビジター trait
pub trait ShapeVisitor<T> {
    fn visit_circle(&self, circle: &Circle) -> T;
    fn visit_rectangle(&self, rectangle: &Rectangle) -> T;
    fn visit_triangle(&self, triangle: &Triangle) -> T;
}

/// 図形 trait
pub trait Shape {
    fn accept<T>(&self, visitor: &dyn ShapeVisitor<T>) -> T;
}

/// 円
#[derive(Debug, Clone, PartialEq)]
pub struct Circle {
    pub radius: f64,
}

impl Shape for Circle {
    fn accept<T>(&self, visitor: &dyn ShapeVisitor<T>) -> T {
        visitor.visit_circle(self)
    }
}

/// 長方形
#[derive(Debug, Clone, PartialEq)]
pub struct Rectangle {
    pub width: f64,
    pub height: f64,
}

impl Shape for Rectangle {
    fn accept<T>(&self, visitor: &dyn ShapeVisitor<T>) -> T {
        visitor.visit_rectangle(self)
    }
}

/// 三角形
#[derive(Debug, Clone, PartialEq)]
pub struct Triangle {
    pub base: f64,
    pub height: f64,
}

impl Shape for Triangle {
    fn accept<T>(&self, visitor: &dyn ShapeVisitor<T>) -> T {
        visitor.visit_triangle(self)
    }
}

/// 面積計算ビジター
pub struct AreaCalculator;

impl ShapeVisitor<f64> for AreaCalculator {
    fn visit_circle(&self, circle: &Circle) -> f64 {
        std::f64::consts::PI * circle.radius * circle.radius
    }

    fn visit_rectangle(&self, rectangle: &Rectangle) -> f64 {
        rectangle.width * rectangle.height
    }

    fn visit_triangle(&self, triangle: &Triangle) -> f64 {
        0.5 * triangle.base * triangle.height
    }
}

/// 周囲長計算ビジター
pub struct PerimeterCalculator;

impl ShapeVisitor<f64> for PerimeterCalculator {
    fn visit_circle(&self, circle: &Circle) -> f64 {
        2.0 * std::f64::consts::PI * circle.radius
    }

    fn visit_rectangle(&self, rectangle: &Rectangle) -> f64 {
        2.0 * (rectangle.width + rectangle.height)
    }

    fn visit_triangle(&self, triangle: &Triangle) -> f64 {
        // 簡略化：正三角形として計算
        3.0 * triangle.base
    }
}

// =============================================================================
// 2. 関数型アプローチ（enum + パターンマッチング）
// =============================================================================

/// 図形 enum
#[derive(Debug, Clone, PartialEq)]
pub enum ShapeEnum {
    Circle { radius: f64 },
    Rectangle { width: f64, height: f64 },
    Triangle { base: f64, height: f64 },
}

impl ShapeEnum {
    pub fn circle(radius: f64) -> Self {
        ShapeEnum::Circle { radius }
    }

    pub fn rectangle(width: f64, height: f64) -> Self {
        ShapeEnum::Rectangle { width, height }
    }

    pub fn triangle(base: f64, height: f64) -> Self {
        ShapeEnum::Triangle { base, height }
    }

    /// 面積計算
    pub fn area(&self) -> f64 {
        match self {
            ShapeEnum::Circle { radius } => std::f64::consts::PI * radius * radius,
            ShapeEnum::Rectangle { width, height } => width * height,
            ShapeEnum::Triangle { base, height } => 0.5 * base * height,
        }
    }

    /// 周囲長計算
    pub fn perimeter(&self) -> f64 {
        match self {
            ShapeEnum::Circle { radius } => 2.0 * std::f64::consts::PI * radius,
            ShapeEnum::Rectangle { width, height } => 2.0 * (width + height),
            ShapeEnum::Triangle { base, .. } => 3.0 * base,
        }
    }

    /// 説明を生成
    pub fn describe(&self) -> String {
        match self {
            ShapeEnum::Circle { radius } => format!("Circle with radius {}", radius),
            ShapeEnum::Rectangle { width, height } => {
                format!("Rectangle {}x{}", width, height)
            }
            ShapeEnum::Triangle { base, height } => {
                format!("Triangle with base {} and height {}", base, height)
            }
        }
    }
}

// =============================================================================
// 3. 式ツリーのビジター
// =============================================================================

/// 式ノード
#[derive(Debug, Clone, PartialEq)]
pub enum Expr {
    Number(f64),
    Variable(String),
    Add(Box<Expr>, Box<Expr>),
    Sub(Box<Expr>, Box<Expr>),
    Mul(Box<Expr>, Box<Expr>),
    Div(Box<Expr>, Box<Expr>),
}

impl Expr {
    pub fn number(n: f64) -> Self {
        Expr::Number(n)
    }

    pub fn variable(name: &str) -> Self {
        Expr::Variable(name.to_string())
    }

    pub fn add(left: Expr, right: Expr) -> Self {
        Expr::Add(Box::new(left), Box::new(right))
    }

    pub fn sub(left: Expr, right: Expr) -> Self {
        Expr::Sub(Box::new(left), Box::new(right))
    }

    pub fn mul(left: Expr, right: Expr) -> Self {
        Expr::Mul(Box::new(left), Box::new(right))
    }

    pub fn div(left: Expr, right: Expr) -> Self {
        Expr::Div(Box::new(left), Box::new(right))
    }

    /// 式を評価
    pub fn evaluate(&self, env: &HashMap<String, f64>) -> Result<f64, String> {
        match self {
            Expr::Number(n) => Ok(*n),
            Expr::Variable(name) => env
                .get(name)
                .copied()
                .ok_or_else(|| format!("Undefined variable: {}", name)),
            Expr::Add(left, right) => Ok(left.evaluate(env)? + right.evaluate(env)?),
            Expr::Sub(left, right) => Ok(left.evaluate(env)? - right.evaluate(env)?),
            Expr::Mul(left, right) => Ok(left.evaluate(env)? * right.evaluate(env)?),
            Expr::Div(left, right) => {
                let r = right.evaluate(env)?;
                if r == 0.0 {
                    Err("Division by zero".to_string())
                } else {
                    Ok(left.evaluate(env)? / r)
                }
            }
        }
    }

    /// 式を文字列に変換
    pub fn to_string(&self) -> String {
        match self {
            Expr::Number(n) => format!("{}", n),
            Expr::Variable(name) => name.clone(),
            Expr::Add(left, right) => format!("({} + {})", left.to_string(), right.to_string()),
            Expr::Sub(left, right) => format!("({} - {})", left.to_string(), right.to_string()),
            Expr::Mul(left, right) => format!("({} * {})", left.to_string(), right.to_string()),
            Expr::Div(left, right) => format!("({} / {})", left.to_string(), right.to_string()),
        }
    }

    /// 式を簡約
    pub fn simplify(&self) -> Expr {
        match self {
            Expr::Number(_) | Expr::Variable(_) => self.clone(),
            Expr::Add(left, right) => {
                let l = left.simplify();
                let r = right.simplify();
                match (&l, &r) {
                    (Expr::Number(0.0), _) => r,
                    (_, Expr::Number(0.0)) => l,
                    (Expr::Number(a), Expr::Number(b)) => Expr::Number(a + b),
                    _ => Expr::Add(Box::new(l), Box::new(r)),
                }
            }
            Expr::Sub(left, right) => {
                let l = left.simplify();
                let r = right.simplify();
                match (&l, &r) {
                    (_, Expr::Number(0.0)) => l,
                    (Expr::Number(a), Expr::Number(b)) => Expr::Number(a - b),
                    _ => Expr::Sub(Box::new(l), Box::new(r)),
                }
            }
            Expr::Mul(left, right) => {
                let l = left.simplify();
                let r = right.simplify();
                match (&l, &r) {
                    (Expr::Number(0.0), _) | (_, Expr::Number(0.0)) => Expr::Number(0.0),
                    (Expr::Number(1.0), _) => r,
                    (_, Expr::Number(1.0)) => l,
                    (Expr::Number(a), Expr::Number(b)) => Expr::Number(a * b),
                    _ => Expr::Mul(Box::new(l), Box::new(r)),
                }
            }
            Expr::Div(left, right) => {
                let l = left.simplify();
                let r = right.simplify();
                match (&l, &r) {
                    (Expr::Number(0.0), _) => Expr::Number(0.0),
                    (_, Expr::Number(1.0)) => l,
                    (Expr::Number(a), Expr::Number(b)) if *b != 0.0 => Expr::Number(a / b),
                    _ => Expr::Div(Box::new(l), Box::new(r)),
                }
            }
        }
    }

    /// 変数を収集
    pub fn variables(&self) -> Vec<String> {
        match self {
            Expr::Number(_) => vec![],
            Expr::Variable(name) => vec![name.clone()],
            Expr::Add(left, right)
            | Expr::Sub(left, right)
            | Expr::Mul(left, right)
            | Expr::Div(left, right) => {
                let mut vars = left.variables();
                vars.extend(right.variables());
                vars.sort();
                vars.dedup();
                vars
            }
        }
    }
}

// =============================================================================
// 4. DOM ノードのビジター
// =============================================================================

/// DOM ノード
#[derive(Debug, Clone, PartialEq)]
pub enum DomNode {
    Element {
        tag: String,
        attributes: HashMap<String, String>,
        children: Vec<DomNode>,
    },
    Text(String),
    Comment(String),
}

impl DomNode {
    pub fn element(tag: &str, children: Vec<DomNode>) -> Self {
        DomNode::Element {
            tag: tag.to_string(),
            attributes: HashMap::new(),
            children,
        }
    }

    pub fn element_with_attrs(tag: &str, attrs: HashMap<String, String>, children: Vec<DomNode>) -> Self {
        DomNode::Element {
            tag: tag.to_string(),
            attributes: attrs,
            children,
        }
    }

    pub fn text(content: &str) -> Self {
        DomNode::Text(content.to_string())
    }

    pub fn comment(content: &str) -> Self {
        DomNode::Comment(content.to_string())
    }

    /// HTML に変換
    pub fn to_html(&self) -> String {
        match self {
            DomNode::Element {
                tag,
                attributes,
                children,
            } => {
                let attrs = attributes
                    .iter()
                    .map(|(k, v)| format!(" {}=\"{}\"", k, v))
                    .collect::<String>();
                let children_html = children.iter().map(|c| c.to_html()).collect::<String>();
                format!("<{}{}>{})</{}>", tag, attrs, children_html, tag)
            }
            DomNode::Text(content) => content.clone(),
            DomNode::Comment(content) => format!("<!-- {} -->", content),
        }
    }

    /// テキストを抽出
    pub fn text_content(&self) -> String {
        match self {
            DomNode::Element { children, .. } => {
                children.iter().map(|c| c.text_content()).collect()
            }
            DomNode::Text(content) => content.clone(),
            DomNode::Comment(_) => String::new(),
        }
    }

    /// 要素数をカウント
    pub fn element_count(&self) -> usize {
        match self {
            DomNode::Element { children, .. } => {
                1 + children.iter().map(|c| c.element_count()).sum::<usize>()
            }
            _ => 0,
        }
    }

    /// 特定のタグを検索
    pub fn find_by_tag(&self, target_tag: &str) -> Vec<&DomNode> {
        match self {
            DomNode::Element { tag, children, .. } => {
                let mut results = Vec::new();
                if tag == target_tag {
                    results.push(self);
                }
                for child in children {
                    results.extend(child.find_by_tag(target_tag));
                }
                results
            }
            _ => vec![],
        }
    }
}

// =============================================================================
// 5. ファイルシステムのビジター
// =============================================================================

/// ファイルシステムエントリ
#[derive(Debug, Clone, PartialEq)]
pub enum FsEntry {
    File { name: String, size: u64 },
    Directory { name: String, children: Vec<FsEntry> },
}

impl FsEntry {
    pub fn file(name: &str, size: u64) -> Self {
        FsEntry::File {
            name: name.to_string(),
            size,
        }
    }

    pub fn directory(name: &str, children: Vec<FsEntry>) -> Self {
        FsEntry::Directory {
            name: name.to_string(),
            children,
        }
    }

    /// 合計サイズを計算
    pub fn total_size(&self) -> u64 {
        match self {
            FsEntry::File { size, .. } => *size,
            FsEntry::Directory { children, .. } => children.iter().map(|c| c.total_size()).sum(),
        }
    }

    /// ファイル数をカウント
    pub fn file_count(&self) -> usize {
        match self {
            FsEntry::File { .. } => 1,
            FsEntry::Directory { children, .. } => children.iter().map(|c| c.file_count()).sum(),
        }
    }

    /// ディレクトリ数をカウント
    pub fn dir_count(&self) -> usize {
        match self {
            FsEntry::File { .. } => 0,
            FsEntry::Directory { children, .. } => {
                1 + children.iter().map(|c| c.dir_count()).sum::<usize>()
            }
        }
    }

    /// すべてのファイル名を収集
    pub fn all_file_names(&self) -> Vec<String> {
        match self {
            FsEntry::File { name, .. } => vec![name.clone()],
            FsEntry::Directory { children, .. } => {
                children.iter().flat_map(|c| c.all_file_names()).collect()
            }
        }
    }

    /// 特定の拡張子のファイルを検索
    pub fn find_by_extension(&self, ext: &str) -> Vec<&FsEntry> {
        match self {
            FsEntry::File { name, .. } => {
                if name.ends_with(ext) {
                    vec![self]
                } else {
                    vec![]
                }
            }
            FsEntry::Directory { children, .. } => {
                children.iter().flat_map(|c| c.find_by_extension(ext)).collect()
            }
        }
    }
}

// =============================================================================
// テスト
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    // -------------------------------------------------------------------------
    // ShapeVisitor テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_area_visitor() {
        let calculator = AreaCalculator;

        let circle = Circle { radius: 1.0 };
        assert!((circle.accept(&calculator) - std::f64::consts::PI).abs() < 0.001);

        let rectangle = Rectangle {
            width: 3.0,
            height: 4.0,
        };
        assert_eq!(rectangle.accept(&calculator), 12.0);
    }

    #[test]
    fn test_perimeter_visitor() {
        let calculator = PerimeterCalculator;

        let circle = Circle { radius: 1.0 };
        assert!((circle.accept(&calculator) - 2.0 * std::f64::consts::PI).abs() < 0.001);

        let rectangle = Rectangle {
            width: 3.0,
            height: 4.0,
        };
        assert_eq!(rectangle.accept(&calculator), 14.0);
    }

    // -------------------------------------------------------------------------
    // ShapeEnum テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_shape_enum_area() {
        let circle = ShapeEnum::circle(1.0);
        assert!((circle.area() - std::f64::consts::PI).abs() < 0.001);

        let rect = ShapeEnum::rectangle(3.0, 4.0);
        assert_eq!(rect.area(), 12.0);

        let tri = ShapeEnum::triangle(4.0, 3.0);
        assert_eq!(tri.area(), 6.0);
    }

    #[test]
    fn test_shape_enum_describe() {
        let circle = ShapeEnum::circle(5.0);
        assert_eq!(circle.describe(), "Circle with radius 5");
    }

    // -------------------------------------------------------------------------
    // Expr テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_expr_evaluate() {
        let expr = Expr::add(Expr::number(2.0), Expr::mul(Expr::number(3.0), Expr::number(4.0)));
        let env = HashMap::new();
        assert_eq!(expr.evaluate(&env).unwrap(), 14.0);
    }

    #[test]
    fn test_expr_with_variables() {
        let expr = Expr::mul(Expr::variable("x"), Expr::number(2.0));
        let mut env = HashMap::new();
        env.insert("x".to_string(), 5.0);
        assert_eq!(expr.evaluate(&env).unwrap(), 10.0);
    }

    #[test]
    fn test_expr_to_string() {
        let expr = Expr::add(Expr::number(1.0), Expr::number(2.0));
        assert_eq!(expr.to_string(), "(1 + 2)");
    }

    #[test]
    fn test_expr_simplify() {
        let expr = Expr::add(Expr::number(0.0), Expr::variable("x"));
        let simplified = expr.simplify();
        assert_eq!(simplified, Expr::Variable("x".to_string()));
    }

    #[test]
    fn test_expr_variables() {
        let expr = Expr::add(Expr::variable("x"), Expr::mul(Expr::variable("y"), Expr::variable("x")));
        let vars = expr.variables();
        assert_eq!(vars, vec!["x".to_string(), "y".to_string()]);
    }

    // -------------------------------------------------------------------------
    // DomNode テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_dom_text_content() {
        let dom = DomNode::element(
            "div",
            vec![DomNode::text("Hello "), DomNode::element("span", vec![DomNode::text("World")])],
        );
        assert_eq!(dom.text_content(), "Hello World");
    }

    #[test]
    fn test_dom_element_count() {
        let dom = DomNode::element(
            "div",
            vec![DomNode::element("p", vec![]), DomNode::element("span", vec![])],
        );
        assert_eq!(dom.element_count(), 3);
    }

    #[test]
    fn test_dom_find_by_tag() {
        let dom = DomNode::element(
            "div",
            vec![
                DomNode::element("p", vec![]),
                DomNode::element("div", vec![DomNode::element("p", vec![])]),
            ],
        );
        let found = dom.find_by_tag("p");
        assert_eq!(found.len(), 2);
    }

    // -------------------------------------------------------------------------
    // FsEntry テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_fs_total_size() {
        let fs = FsEntry::directory(
            "root",
            vec![
                FsEntry::file("a.txt", 100),
                FsEntry::directory("sub", vec![FsEntry::file("b.txt", 200)]),
            ],
        );
        assert_eq!(fs.total_size(), 300);
    }

    #[test]
    fn test_fs_file_count() {
        let fs = FsEntry::directory(
            "root",
            vec![
                FsEntry::file("a.txt", 100),
                FsEntry::file("b.txt", 200),
                FsEntry::directory("sub", vec![FsEntry::file("c.txt", 300)]),
            ],
        );
        assert_eq!(fs.file_count(), 3);
    }

    #[test]
    fn test_fs_find_by_extension() {
        let fs = FsEntry::directory(
            "root",
            vec![
                FsEntry::file("a.txt", 100),
                FsEntry::file("b.rs", 200),
                FsEntry::file("c.txt", 300),
            ],
        );
        let found = fs.find_by_extension(".txt");
        assert_eq!(found.len(), 2);
    }
}
