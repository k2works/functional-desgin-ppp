//! 第7章: Composite パターン
//!
//! Composite パターンは、オブジェクトをツリー構造で構成し、
//! 個々のオブジェクトとオブジェクトの集合を同じように扱えるようにするパターンです。

use std::collections::HashSet;
use std::f64::consts::PI;

// =============================================================================
// 1. Shape の例 - 図形の Composite パターン
// =============================================================================

/// 2D座標
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

impl Point {
    pub fn new(x: f64, y: f64) -> Point {
        Point { x, y }
    }

    pub fn add(&self, other: &Point) -> Point {
        Point::new(self.x + other.x, self.y + other.y)
    }

    pub fn scale(&self, factor: f64) -> Point {
        Point::new(self.x * factor, self.y * factor)
    }
}

/// バウンディングボックス
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct BoundingBox {
    pub top_left: Point,
    pub bottom_right: Point,
}

impl BoundingBox {
    pub fn new(top_left: Point, bottom_right: Point) -> BoundingBox {
        BoundingBox {
            top_left,
            bottom_right,
        }
    }

    pub fn width(&self) -> f64 {
        self.bottom_right.x - self.top_left.x
    }

    pub fn height(&self) -> f64 {
        self.bottom_right.y - self.top_left.y
    }

    pub fn area(&self) -> f64 {
        self.width() * self.height()
    }

    /// 二つのバウンディングボックスを結合
    pub fn union(&self, other: &BoundingBox) -> BoundingBox {
        BoundingBox::new(
            Point::new(
                self.top_left.x.min(other.top_left.x),
                self.top_left.y.min(other.top_left.y),
            ),
            Point::new(
                self.bottom_right.x.max(other.bottom_right.x),
                self.bottom_right.y.max(other.bottom_right.y),
            ),
        )
    }
}

/// 図形（enum による ADT）
#[derive(Debug, Clone, PartialEq)]
pub enum Shape {
    Circle {
        center: Point,
        radius: f64,
    },
    Square {
        top_left: Point,
        side: f64,
    },
    Rectangle {
        top_left: Point,
        width: f64,
        height: f64,
    },
    Triangle {
        p1: Point,
        p2: Point,
        p3: Point,
    },
    Composite {
        shapes: Vec<Shape>,
    },
}

impl Shape {
    // コンストラクタ
    pub fn circle(center: Point, radius: f64) -> Shape {
        Shape::Circle { center, radius }
    }

    pub fn square(top_left: Point, side: f64) -> Shape {
        Shape::Square { top_left, side }
    }

    pub fn rectangle(top_left: Point, width: f64, height: f64) -> Shape {
        Shape::Rectangle {
            top_left,
            width,
            height,
        }
    }

    pub fn triangle(p1: Point, p2: Point, p3: Point) -> Shape {
        Shape::Triangle { p1, p2, p3 }
    }

    pub fn composite(shapes: Vec<Shape>) -> Shape {
        Shape::Composite { shapes }
    }

    /// 図形を移動する
    pub fn translate(&self, dx: f64, dy: f64) -> Shape {
        match self {
            Shape::Circle { center, radius } => Shape::Circle {
                center: Point::new(center.x + dx, center.y + dy),
                radius: *radius,
            },
            Shape::Square { top_left, side } => Shape::Square {
                top_left: Point::new(top_left.x + dx, top_left.y + dy),
                side: *side,
            },
            Shape::Rectangle {
                top_left,
                width,
                height,
            } => Shape::Rectangle {
                top_left: Point::new(top_left.x + dx, top_left.y + dy),
                width: *width,
                height: *height,
            },
            Shape::Triangle { p1, p2, p3 } => Shape::Triangle {
                p1: Point::new(p1.x + dx, p1.y + dy),
                p2: Point::new(p2.x + dx, p2.y + dy),
                p3: Point::new(p3.x + dx, p3.y + dy),
            },
            Shape::Composite { shapes } => Shape::Composite {
                shapes: shapes.iter().map(|s| s.translate(dx, dy)).collect(),
            },
        }
    }

    /// 図形を拡大/縮小する
    pub fn scale(&self, factor: f64) -> Shape {
        match self {
            Shape::Circle { center, radius } => Shape::Circle {
                center: *center,
                radius: radius * factor,
            },
            Shape::Square { top_left, side } => Shape::Square {
                top_left: *top_left,
                side: side * factor,
            },
            Shape::Rectangle {
                top_left,
                width,
                height,
            } => Shape::Rectangle {
                top_left: *top_left,
                width: width * factor,
                height: height * factor,
            },
            Shape::Triangle { p1, p2, p3 } => {
                // 中心を基準にスケール
                let cx = (p1.x + p2.x + p3.x) / 3.0;
                let cy = (p1.y + p2.y + p3.y) / 3.0;
                Shape::Triangle {
                    p1: Point::new(cx + (p1.x - cx) * factor, cy + (p1.y - cy) * factor),
                    p2: Point::new(cx + (p2.x - cx) * factor, cy + (p2.y - cy) * factor),
                    p3: Point::new(cx + (p3.x - cx) * factor, cy + (p3.y - cy) * factor),
                }
            }
            Shape::Composite { shapes } => Shape::Composite {
                shapes: shapes.iter().map(|s| s.scale(factor)).collect(),
            },
        }
    }

    /// 面積を計算する
    pub fn area(&self) -> f64 {
        match self {
            Shape::Circle { radius, .. } => PI * radius * radius,
            Shape::Square { side, .. } => side * side,
            Shape::Rectangle { width, height, .. } => width * height,
            Shape::Triangle { p1, p2, p3 } => {
                ((p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y)).abs() / 2.0
            }
            Shape::Composite { shapes } => shapes.iter().map(|s| s.area()).sum(),
        }
    }

    /// バウンディングボックスを取得
    pub fn bounding_box(&self) -> BoundingBox {
        match self {
            Shape::Circle { center, radius } => BoundingBox::new(
                Point::new(center.x - radius, center.y - radius),
                Point::new(center.x + radius, center.y + radius),
            ),
            Shape::Square { top_left, side } => BoundingBox::new(
                *top_left,
                Point::new(top_left.x + side, top_left.y + side),
            ),
            Shape::Rectangle {
                top_left,
                width,
                height,
            } => BoundingBox::new(
                *top_left,
                Point::new(top_left.x + width, top_left.y + height),
            ),
            Shape::Triangle { p1, p2, p3 } => {
                let min_x = p1.x.min(p2.x).min(p3.x);
                let min_y = p1.y.min(p2.y).min(p3.y);
                let max_x = p1.x.max(p2.x).max(p3.x);
                let max_y = p1.y.max(p2.y).max(p3.y);
                BoundingBox::new(Point::new(min_x, min_y), Point::new(max_x, max_y))
            }
            Shape::Composite { shapes } => {
                if shapes.is_empty() {
                    BoundingBox::new(Point::new(0.0, 0.0), Point::new(0.0, 0.0))
                } else {
                    shapes
                        .iter()
                        .skip(1)
                        .fold(shapes[0].bounding_box(), |acc, s| {
                            acc.union(&s.bounding_box())
                        })
                }
            }
        }
    }

    /// Composite に図形を追加
    pub fn add(&self, shape: Shape) -> Shape {
        match self {
            Shape::Composite { shapes } => {
                let mut new_shapes = shapes.clone();
                new_shapes.push(shape);
                Shape::Composite { shapes: new_shapes }
            }
            _ => Shape::Composite {
                shapes: vec![self.clone(), shape],
            },
        }
    }

    /// 図形の数を取得
    pub fn count(&self) -> usize {
        match self {
            Shape::Composite { shapes } => shapes.len(),
            _ => 1,
        }
    }

    /// ネストした Composite を平坦化
    pub fn flatten(&self) -> Vec<Shape> {
        match self {
            Shape::Composite { shapes } => shapes
                .iter()
                .flat_map(|s| match s {
                    Shape::Composite { .. } => s.flatten(),
                    _ => vec![s.clone()],
                })
                .collect(),
            _ => vec![self.clone()],
        }
    }
}

// =============================================================================
// 2. Switchable の例 - スイッチの Composite パターン
// =============================================================================

/// スイッチ可能なデバイス
#[derive(Debug, Clone, PartialEq)]
pub enum Switchable {
    Light {
        name: String,
        on: bool,
    },
    DimmableLight {
        name: String,
        intensity: u8,
    },
    Fan {
        name: String,
        speed: u8,
    },
    Group {
        name: String,
        devices: Vec<Switchable>,
    },
}

impl Switchable {
    pub fn light(name: &str) -> Switchable {
        Switchable::Light {
            name: name.to_string(),
            on: false,
        }
    }

    pub fn dimmable_light(name: &str) -> Switchable {
        Switchable::DimmableLight {
            name: name.to_string(),
            intensity: 0,
        }
    }

    pub fn fan(name: &str) -> Switchable {
        Switchable::Fan {
            name: name.to_string(),
            speed: 0,
        }
    }

    pub fn group(name: &str, devices: Vec<Switchable>) -> Switchable {
        Switchable::Group {
            name: name.to_string(),
            devices,
        }
    }

    pub fn turn_on(&self) -> Switchable {
        match self {
            Switchable::Light { name, .. } => Switchable::Light {
                name: name.clone(),
                on: true,
            },
            Switchable::DimmableLight { name, .. } => Switchable::DimmableLight {
                name: name.clone(),
                intensity: 100,
            },
            Switchable::Fan { name, .. } => Switchable::Fan {
                name: name.clone(),
                speed: 3,
            },
            Switchable::Group { name, devices } => Switchable::Group {
                name: name.clone(),
                devices: devices.iter().map(|d| d.turn_on()).collect(),
            },
        }
    }

    pub fn turn_off(&self) -> Switchable {
        match self {
            Switchable::Light { name, .. } => Switchable::Light {
                name: name.clone(),
                on: false,
            },
            Switchable::DimmableLight { name, .. } => Switchable::DimmableLight {
                name: name.clone(),
                intensity: 0,
            },
            Switchable::Fan { name, .. } => Switchable::Fan {
                name: name.clone(),
                speed: 0,
            },
            Switchable::Group { name, devices } => Switchable::Group {
                name: name.clone(),
                devices: devices.iter().map(|d| d.turn_off()).collect(),
            },
        }
    }

    pub fn is_on(&self) -> bool {
        match self {
            Switchable::Light { on, .. } => *on,
            Switchable::DimmableLight { intensity, .. } => *intensity > 0,
            Switchable::Fan { speed, .. } => *speed > 0,
            Switchable::Group { devices, .. } => devices.iter().any(|d| d.is_on()),
        }
    }

    pub fn all_on(&self) -> bool {
        match self {
            Switchable::Group { devices, .. } => !devices.is_empty() && devices.iter().all(|d| d.is_on()),
            _ => self.is_on(),
        }
    }

    pub fn name(&self) -> &str {
        match self {
            Switchable::Light { name, .. } => name,
            Switchable::DimmableLight { name, .. } => name,
            Switchable::Fan { name, .. } => name,
            Switchable::Group { name, .. } => name,
        }
    }

    pub fn set_intensity(&self, value: u8) -> Switchable {
        match self {
            Switchable::DimmableLight { name, .. } => Switchable::DimmableLight {
                name: name.clone(),
                intensity: value.min(100),
            },
            _ => self.clone(),
        }
    }

    pub fn set_speed(&self, value: u8) -> Switchable {
        match self {
            Switchable::Fan { name, .. } => Switchable::Fan {
                name: name.clone(),
                speed: value.min(5),
            },
            _ => self.clone(),
        }
    }
}

// =============================================================================
// 3. FileSystem の例 - ファイルシステムの Composite パターン
// =============================================================================

/// ファイルシステムエントリ
#[derive(Debug, Clone, PartialEq)]
pub enum FileSystemEntry {
    File {
        name: String,
        size: u64,
        parent_path: String,
    },
    Directory {
        name: String,
        children: Vec<FileSystemEntry>,
        parent_path: String,
    },
}

impl FileSystemEntry {
    pub fn file(name: &str, size: u64) -> FileSystemEntry {
        FileSystemEntry::File {
            name: name.to_string(),
            size,
            parent_path: String::new(),
        }
    }

    pub fn directory(name: &str) -> FileSystemEntry {
        FileSystemEntry::Directory {
            name: name.to_string(),
            children: Vec::new(),
            parent_path: String::new(),
        }
    }

    pub fn name(&self) -> &str {
        match self {
            FileSystemEntry::File { name, .. } => name,
            FileSystemEntry::Directory { name, .. } => name,
        }
    }

    pub fn path(&self) -> String {
        match self {
            FileSystemEntry::File {
                name, parent_path, ..
            } => {
                if parent_path.is_empty() {
                    name.clone()
                } else {
                    format!("{}/{}", parent_path, name)
                }
            }
            FileSystemEntry::Directory {
                name, parent_path, ..
            } => {
                if parent_path.is_empty() {
                    name.clone()
                } else {
                    format!("{}/{}", parent_path, name)
                }
            }
        }
    }

    pub fn size(&self) -> u64 {
        match self {
            FileSystemEntry::File { size, .. } => *size,
            FileSystemEntry::Directory { children, .. } => children.iter().map(|c| c.size()).sum(),
        }
    }

    /// ディレクトリにエントリを追加
    pub fn add(&self, entry: FileSystemEntry) -> FileSystemEntry {
        match self {
            FileSystemEntry::Directory {
                name,
                children,
                parent_path,
            } => {
                let new_entry = match entry {
                    FileSystemEntry::File {
                        name: fname, size, ..
                    } => FileSystemEntry::File {
                        name: fname,
                        size,
                        parent_path: self.path(),
                    },
                    FileSystemEntry::Directory {
                        name: dname,
                        children: dchildren,
                        ..
                    } => FileSystemEntry::Directory {
                        name: dname,
                        children: dchildren,
                        parent_path: self.path(),
                    },
                };
                let mut new_children = children.clone();
                new_children.push(new_entry);
                FileSystemEntry::Directory {
                    name: name.clone(),
                    children: new_children,
                    parent_path: parent_path.clone(),
                }
            }
            _ => self.clone(),
        }
    }

    /// 指定した条件に一致するエントリを検索
    pub fn find<F>(&self, predicate: F) -> Vec<FileSystemEntry>
    where
        F: Fn(&FileSystemEntry) -> bool + Clone,
    {
        let mut results = Vec::new();
        if predicate(self) {
            results.push(self.clone());
        }
        if let FileSystemEntry::Directory { children, .. } = self {
            for child in children {
                results.extend(child.find(predicate.clone()));
            }
        }
        results
    }

    /// ファイル数を取得
    pub fn file_count(&self) -> usize {
        match self {
            FileSystemEntry::File { .. } => 1,
            FileSystemEntry::Directory { children, .. } => {
                children.iter().map(|c| c.file_count()).sum()
            }
        }
    }

    /// ディレクトリ数を取得
    pub fn directory_count(&self) -> usize {
        match self {
            FileSystemEntry::File { .. } => 0,
            FileSystemEntry::Directory { children, .. } => {
                children.iter().fold(0, |acc, c| {
                    acc + match c {
                        FileSystemEntry::File { .. } => 0,
                        FileSystemEntry::Directory { .. } => 1 + c.directory_count(),
                    }
                })
            }
        }
    }
}

// =============================================================================
// 4. Menu の例 - メニューの Composite パターン
// =============================================================================

/// メニュー項目
#[derive(Debug, Clone, PartialEq)]
pub enum MenuItem {
    Single {
        name: String,
        price: i64,
        is_vegetarian: bool,
        description: String,
    },
    Set {
        name: String,
        items: Vec<MenuItem>,
        discount: i64,
        description: String,
    },
}

impl MenuItem {
    pub fn single(name: &str, price: i64, is_vegetarian: bool, description: &str) -> MenuItem {
        MenuItem::Single {
            name: name.to_string(),
            price,
            is_vegetarian,
            description: description.to_string(),
        }
    }

    pub fn set(name: &str, items: Vec<MenuItem>, discount: i64, description: &str) -> MenuItem {
        MenuItem::Set {
            name: name.to_string(),
            items,
            discount,
            description: description.to_string(),
        }
    }

    pub fn name(&self) -> &str {
        match self {
            MenuItem::Single { name, .. } => name,
            MenuItem::Set { name, .. } => name,
        }
    }

    pub fn price(&self) -> i64 {
        match self {
            MenuItem::Single { price, .. } => *price,
            MenuItem::Set { items, discount, .. } => {
                let total: i64 = items.iter().map(|i| i.price()).sum();
                total - discount
            }
        }
    }

    pub fn is_vegetarian(&self) -> bool {
        match self {
            MenuItem::Single { is_vegetarian, .. } => *is_vegetarian,
            MenuItem::Set { items, .. } => items.iter().all(|i| i.is_vegetarian()),
        }
    }

    pub fn original_price(&self) -> i64 {
        match self {
            MenuItem::Single { price, .. } => *price,
            MenuItem::Set { items, .. } => items.iter().map(|i| i.price()).sum(),
        }
    }

    pub fn discount_rate(&self) -> f64 {
        match self {
            MenuItem::Single { .. } => 0.0,
            MenuItem::Set { discount, items, .. } => {
                let original: i64 = items.iter().map(|i| i.price()).sum();
                if original > 0 {
                    (*discount as f64 / original as f64) * 100.0
                } else {
                    0.0
                }
            }
        }
    }
}

// =============================================================================
// 5. Expression の例 - 数式の Composite パターン
// =============================================================================

/// 数式
#[derive(Debug, Clone, PartialEq)]
pub enum Expression {
    Number(f64),
    Variable { name: String, value: Option<f64> },
    Add(Box<Expression>, Box<Expression>),
    Subtract(Box<Expression>, Box<Expression>),
    Multiply(Box<Expression>, Box<Expression>),
    Divide(Box<Expression>, Box<Expression>),
}

impl Expression {
    pub fn number(value: f64) -> Expression {
        Expression::Number(value)
    }

    pub fn variable(name: &str) -> Expression {
        Expression::Variable {
            name: name.to_string(),
            value: None,
        }
    }

    pub fn variable_with_value(name: &str, value: f64) -> Expression {
        Expression::Variable {
            name: name.to_string(),
            value: Some(value),
        }
    }

    pub fn add(left: Expression, right: Expression) -> Expression {
        Expression::Add(Box::new(left), Box::new(right))
    }

    pub fn subtract(left: Expression, right: Expression) -> Expression {
        Expression::Subtract(Box::new(left), Box::new(right))
    }

    pub fn multiply(left: Expression, right: Expression) -> Expression {
        Expression::Multiply(Box::new(left), Box::new(right))
    }

    pub fn divide(left: Expression, right: Expression) -> Expression {
        Expression::Divide(Box::new(left), Box::new(right))
    }

    /// 数式を評価
    pub fn evaluate(&self) -> Result<f64, String> {
        match self {
            Expression::Number(n) => Ok(*n),
            Expression::Variable { name, value } => {
                value.ok_or_else(|| format!("Variable {} has no value", name))
            }
            Expression::Add(left, right) => Ok(left.evaluate()? + right.evaluate()?),
            Expression::Subtract(left, right) => Ok(left.evaluate()? - right.evaluate()?),
            Expression::Multiply(left, right) => Ok(left.evaluate()? * right.evaluate()?),
            Expression::Divide(left, right) => {
                let r = right.evaluate()?;
                if r == 0.0 {
                    Err("Division by zero".to_string())
                } else {
                    Ok(left.evaluate()? / r)
                }
            }
        }
    }

    /// 数式を簡約
    pub fn simplify(&self) -> Expression {
        match self {
            Expression::Number(_) => self.clone(),
            Expression::Variable { value: Some(v), .. } => Expression::Number(*v),
            Expression::Variable { .. } => self.clone(),
            Expression::Add(left, right) => {
                let l = left.simplify();
                let r = right.simplify();
                match (&l, &r) {
                    (Expression::Number(0.0), _) => r,
                    (_, Expression::Number(0.0)) => l,
                    (Expression::Number(a), Expression::Number(b)) => Expression::Number(a + b),
                    _ => Expression::Add(Box::new(l), Box::new(r)),
                }
            }
            Expression::Subtract(left, right) => {
                let l = left.simplify();
                let r = right.simplify();
                match (&l, &r) {
                    (_, Expression::Number(0.0)) => l,
                    (Expression::Number(a), Expression::Number(b)) => Expression::Number(a - b),
                    _ if l == r => Expression::Number(0.0),
                    _ => Expression::Subtract(Box::new(l), Box::new(r)),
                }
            }
            Expression::Multiply(left, right) => {
                let l = left.simplify();
                let r = right.simplify();
                match (&l, &r) {
                    (Expression::Number(0.0), _) | (_, Expression::Number(0.0)) => {
                        Expression::Number(0.0)
                    }
                    (Expression::Number(1.0), _) => r,
                    (_, Expression::Number(1.0)) => l,
                    (Expression::Number(a), Expression::Number(b)) => Expression::Number(a * b),
                    _ => Expression::Multiply(Box::new(l), Box::new(r)),
                }
            }
            Expression::Divide(left, right) => {
                let l = left.simplify();
                let r = right.simplify();
                match (&l, &r) {
                    (Expression::Number(0.0), _) => Expression::Number(0.0),
                    (_, Expression::Number(1.0)) => l,
                    (Expression::Number(a), Expression::Number(b)) if *b != 0.0 => {
                        Expression::Number(a / b)
                    }
                    _ if l == r => Expression::Number(1.0),
                    _ => Expression::Divide(Box::new(l), Box::new(r)),
                }
            }
        }
    }

    /// 変数のセットを取得
    pub fn variables(&self) -> HashSet<String> {
        match self {
            Expression::Number(_) => HashSet::new(),
            Expression::Variable { name, value } => {
                if value.is_none() {
                    let mut set = HashSet::new();
                    set.insert(name.clone());
                    set
                } else {
                    HashSet::new()
                }
            }
            Expression::Add(left, right)
            | Expression::Subtract(left, right)
            | Expression::Multiply(left, right)
            | Expression::Divide(left, right) => {
                let mut vars = left.variables();
                vars.extend(right.variables());
                vars
            }
        }
    }

    /// 変数に値を束縛
    pub fn bind(&self, bindings: &std::collections::HashMap<String, f64>) -> Expression {
        match self {
            Expression::Number(_) => self.clone(),
            Expression::Variable { name, .. } => {
                if let Some(&v) = bindings.get(name) {
                    Expression::Number(v)
                } else {
                    self.clone()
                }
            }
            Expression::Add(left, right) => Expression::Add(
                Box::new(left.bind(bindings)),
                Box::new(right.bind(bindings)),
            ),
            Expression::Subtract(left, right) => Expression::Subtract(
                Box::new(left.bind(bindings)),
                Box::new(right.bind(bindings)),
            ),
            Expression::Multiply(left, right) => Expression::Multiply(
                Box::new(left.bind(bindings)),
                Box::new(right.bind(bindings)),
            ),
            Expression::Divide(left, right) => Expression::Divide(
                Box::new(left.bind(bindings)),
                Box::new(right.bind(bindings)),
            ),
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
    // Shape テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_circle_area() {
        let circle = Shape::circle(Point::new(0.0, 0.0), 1.0);
        assert!((circle.area() - PI).abs() < 0.0001);
    }

    #[test]
    fn test_square_area() {
        let square = Shape::square(Point::new(0.0, 0.0), 2.0);
        assert_eq!(square.area(), 4.0);
    }

    #[test]
    fn test_rectangle_area() {
        let rect = Shape::rectangle(Point::new(0.0, 0.0), 3.0, 4.0);
        assert_eq!(rect.area(), 12.0);
    }

    #[test]
    fn test_composite_area() {
        let shapes = vec![
            Shape::square(Point::new(0.0, 0.0), 2.0),
            Shape::rectangle(Point::new(0.0, 0.0), 3.0, 4.0),
        ];
        let composite = Shape::composite(shapes);
        assert_eq!(composite.area(), 16.0); // 4 + 12
    }

    #[test]
    fn test_shape_translate() {
        let circle = Shape::circle(Point::new(0.0, 0.0), 1.0);
        let moved = circle.translate(5.0, 3.0);
        if let Shape::Circle { center, .. } = moved {
            assert_eq!(center.x, 5.0);
            assert_eq!(center.y, 3.0);
        }
    }

    #[test]
    fn test_shape_scale() {
        let square = Shape::square(Point::new(0.0, 0.0), 2.0);
        let scaled = square.scale(2.0);
        if let Shape::Square { side, .. } = scaled {
            assert_eq!(side, 4.0);
        }
    }

    #[test]
    fn test_composite_translate() {
        let shapes = vec![
            Shape::circle(Point::new(0.0, 0.0), 1.0),
            Shape::square(Point::new(0.0, 0.0), 2.0),
        ];
        let composite = Shape::composite(shapes);
        let moved = composite.translate(1.0, 1.0);

        if let Shape::Composite { shapes } = moved {
            if let Shape::Circle { center, .. } = &shapes[0] {
                assert_eq!(center.x, 1.0);
                assert_eq!(center.y, 1.0);
            }
        }
    }

    #[test]
    fn test_bounding_box() {
        let circle = Shape::circle(Point::new(5.0, 5.0), 2.0);
        let bb = circle.bounding_box();
        assert_eq!(bb.top_left.x, 3.0);
        assert_eq!(bb.top_left.y, 3.0);
        assert_eq!(bb.bottom_right.x, 7.0);
        assert_eq!(bb.bottom_right.y, 7.0);
    }

    #[test]
    fn test_composite_add() {
        let composite = Shape::composite(vec![]);
        let with_circle = composite.add(Shape::circle(Point::new(0.0, 0.0), 1.0));
        assert_eq!(with_circle.count(), 1);
    }

    #[test]
    fn test_composite_flatten() {
        let inner = Shape::composite(vec![
            Shape::circle(Point::new(0.0, 0.0), 1.0),
            Shape::square(Point::new(0.0, 0.0), 2.0),
        ]);
        let outer = Shape::composite(vec![inner, Shape::rectangle(Point::new(0.0, 0.0), 3.0, 4.0)]);
        let flattened = outer.flatten();
        assert_eq!(flattened.len(), 3);
    }

    // -------------------------------------------------------------------------
    // Switchable テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_light_turn_on_off() {
        let light = Switchable::light("リビング");
        assert!(!light.is_on());

        let light_on = light.turn_on();
        assert!(light_on.is_on());

        let light_off = light_on.turn_off();
        assert!(!light_off.is_on());
    }

    #[test]
    fn test_dimmable_light() {
        let light = Switchable::dimmable_light("寝室");
        let dimmed = light.set_intensity(50);
        if let Switchable::DimmableLight { intensity, .. } = dimmed {
            assert_eq!(intensity, 50);
        }
    }

    #[test]
    fn test_fan_speed() {
        let fan = Switchable::fan("リビング");
        let fast = fan.set_speed(5);
        if let Switchable::Fan { speed, .. } = fast {
            assert_eq!(speed, 5);
        }
    }

    #[test]
    fn test_group_turn_on() {
        let group = Switchable::group(
            "リビング",
            vec![Switchable::light("メイン"), Switchable::fan("扇風機")],
        );
        assert!(!group.is_on());

        let group_on = group.turn_on();
        assert!(group_on.is_on());
        assert!(group_on.all_on());
    }

    #[test]
    fn test_group_partial_on() {
        let light = Switchable::light("メイン").turn_on();
        let fan = Switchable::fan("扇風機");
        let group = Switchable::group("リビング", vec![light, fan]);

        assert!(group.is_on()); // 一つでも on なら true
        assert!(!group.all_on()); // 全て on ではない
    }

    // -------------------------------------------------------------------------
    // FileSystem テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_file_size() {
        let file = FileSystemEntry::file("test.txt", 100);
        assert_eq!(file.size(), 100);
    }

    #[test]
    fn test_directory_size() {
        let dir = FileSystemEntry::directory("docs")
            .add(FileSystemEntry::file("a.txt", 100))
            .add(FileSystemEntry::file("b.txt", 200));
        assert_eq!(dir.size(), 300);
    }

    #[test]
    fn test_nested_directory_size() {
        let subdir = FileSystemEntry::directory("sub")
            .add(FileSystemEntry::file("c.txt", 50));
        let dir = FileSystemEntry::directory("docs")
            .add(FileSystemEntry::file("a.txt", 100))
            .add(subdir);
        assert_eq!(dir.size(), 150);
    }

    #[test]
    fn test_file_path() {
        let dir = FileSystemEntry::directory("docs")
            .add(FileSystemEntry::file("test.txt", 100));
        if let FileSystemEntry::Directory { children, .. } = dir {
            assert_eq!(children[0].path(), "docs/test.txt");
        }
    }

    #[test]
    fn test_find_files() {
        let dir = FileSystemEntry::directory("docs")
            .add(FileSystemEntry::file("a.txt", 100))
            .add(FileSystemEntry::file("b.md", 200))
            .add(FileSystemEntry::file("c.txt", 150));

        let txt_files = dir.find(|e| e.name().ends_with(".txt"));
        assert_eq!(txt_files.len(), 2);
    }

    #[test]
    fn test_file_count() {
        let subdir = FileSystemEntry::directory("sub")
            .add(FileSystemEntry::file("c.txt", 50));
        let dir = FileSystemEntry::directory("docs")
            .add(FileSystemEntry::file("a.txt", 100))
            .add(FileSystemEntry::file("b.txt", 200))
            .add(subdir);
        assert_eq!(dir.file_count(), 3);
    }

    #[test]
    fn test_directory_count() {
        let subdir = FileSystemEntry::directory("sub");
        let dir = FileSystemEntry::directory("docs").add(subdir);
        assert_eq!(dir.directory_count(), 1);
    }

    // -------------------------------------------------------------------------
    // Menu テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_single_item_price() {
        let item = MenuItem::single("ハンバーガー", 500, false, "ビーフパティ");
        assert_eq!(item.price(), 500);
    }

    #[test]
    fn test_set_menu_price() {
        let items = vec![
            MenuItem::single("ハンバーガー", 500, false, ""),
            MenuItem::single("ポテト", 200, true, ""),
            MenuItem::single("ドリンク", 150, true, ""),
        ];
        let set = MenuItem::set("セットA", items, 100, "お得なセット");
        assert_eq!(set.price(), 750); // 850 - 100
    }

    #[test]
    fn test_vegetarian_set() {
        let items = vec![
            MenuItem::single("サラダ", 400, true, ""),
            MenuItem::single("ポテト", 200, true, ""),
        ];
        let set = MenuItem::set("ベジセット", items, 50, "");
        assert!(set.is_vegetarian());
    }

    #[test]
    fn test_non_vegetarian_set() {
        let items = vec![
            MenuItem::single("ハンバーガー", 500, false, ""),
            MenuItem::single("サラダ", 400, true, ""),
        ];
        let set = MenuItem::set("セット", items, 0, "");
        assert!(!set.is_vegetarian());
    }

    #[test]
    fn test_discount_rate() {
        let items = vec![
            MenuItem::single("A", 1000, false, ""),
        ];
        let set = MenuItem::set("セット", items, 100, "");
        assert!((set.discount_rate() - 10.0).abs() < 0.001);
    }

    // -------------------------------------------------------------------------
    // Expression テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_number_evaluate() {
        let expr = Expression::number(42.0);
        assert_eq!(expr.evaluate().unwrap(), 42.0);
    }

    #[test]
    fn test_add_evaluate() {
        let expr = Expression::add(Expression::number(1.0), Expression::number(2.0));
        assert_eq!(expr.evaluate().unwrap(), 3.0);
    }

    #[test]
    fn test_complex_expression() {
        // (2 + 3) * 4 = 20
        let expr = Expression::multiply(
            Expression::add(Expression::number(2.0), Expression::number(3.0)),
            Expression::number(4.0),
        );
        assert_eq!(expr.evaluate().unwrap(), 20.0);
    }

    #[test]
    fn test_variable_without_value() {
        let expr = Expression::variable("x");
        assert!(expr.evaluate().is_err());
    }

    #[test]
    fn test_variable_with_value() {
        let expr = Expression::variable_with_value("x", 5.0);
        assert_eq!(expr.evaluate().unwrap(), 5.0);
    }

    #[test]
    fn test_division_by_zero() {
        let expr = Expression::divide(Expression::number(1.0), Expression::number(0.0));
        assert!(expr.evaluate().is_err());
    }

    #[test]
    fn test_simplify_add_zero() {
        let expr = Expression::add(Expression::number(5.0), Expression::number(0.0));
        let simplified = expr.simplify();
        assert_eq!(simplified, Expression::Number(5.0));
    }

    #[test]
    fn test_simplify_multiply_zero() {
        let expr = Expression::multiply(Expression::number(5.0), Expression::number(0.0));
        let simplified = expr.simplify();
        assert_eq!(simplified, Expression::Number(0.0));
    }

    #[test]
    fn test_simplify_multiply_one() {
        let expr = Expression::multiply(Expression::number(5.0), Expression::number(1.0));
        let simplified = expr.simplify();
        assert_eq!(simplified, Expression::Number(5.0));
    }

    #[test]
    fn test_variables() {
        let expr = Expression::add(
            Expression::variable("x"),
            Expression::multiply(Expression::variable("y"), Expression::number(2.0)),
        );
        let vars = expr.variables();
        assert!(vars.contains("x"));
        assert!(vars.contains("y"));
        assert_eq!(vars.len(), 2);
    }

    #[test]
    fn test_bind() {
        let expr = Expression::add(Expression::variable("x"), Expression::number(1.0));
        let mut bindings = std::collections::HashMap::new();
        bindings.insert("x".to_string(), 5.0);
        let bound = expr.bind(&bindings);
        assert_eq!(bound.evaluate().unwrap(), 6.0);
    }
}
