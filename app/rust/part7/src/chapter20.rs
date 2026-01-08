//! 第20章: パターン間の相互作用
//!
//! 複数のデザインパターンを組み合わせた実装例。
//! Composite + Decorator、Command + Observer などの相互作用を示す。

use std::f64::consts::PI;
use std::sync::{Arc, Mutex};

// ============================================================
// 1. 基本図形インターフェース
// ============================================================

/// 図形の基底 trait
pub trait Shape: std::fmt::Debug + Send + Sync {
    fn move_by(&self, dx: f64, dy: f64) -> Box<dyn Shape>;
    fn scale(&self, factor: f64) -> Box<dyn Shape>;
    fn area(&self) -> f64;
    fn draw(&self) -> String;
    fn clone_box(&self) -> Box<dyn Shape>;
}

// ============================================================
// 2. 基本図形の実装
// ============================================================

/// 円
#[derive(Debug, Clone)]
pub struct Circle {
    pub x: f64,
    pub y: f64,
    pub radius: f64,
}

impl Circle {
    pub fn new(x: f64, y: f64, radius: f64) -> Self {
        Self { x, y, radius }
    }
}

impl Shape for Circle {
    fn move_by(&self, dx: f64, dy: f64) -> Box<dyn Shape> {
        Box::new(Circle::new(self.x + dx, self.y + dy, self.radius))
    }

    fn scale(&self, factor: f64) -> Box<dyn Shape> {
        Box::new(Circle::new(self.x, self.y, self.radius * factor))
    }

    fn area(&self) -> f64 {
        PI * self.radius * self.radius
    }

    fn draw(&self) -> String {
        format!("Circle(x={}, y={}, r={})", self.x, self.y, self.radius)
    }

    fn clone_box(&self) -> Box<dyn Shape> {
        Box::new(self.clone())
    }
}

/// 矩形
#[derive(Debug, Clone)]
pub struct Rectangle {
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
}

impl Rectangle {
    pub fn new(x: f64, y: f64, width: f64, height: f64) -> Self {
        Self { x, y, width, height }
    }
}

impl Shape for Rectangle {
    fn move_by(&self, dx: f64, dy: f64) -> Box<dyn Shape> {
        Box::new(Rectangle::new(self.x + dx, self.y + dy, self.width, self.height))
    }

    fn scale(&self, factor: f64) -> Box<dyn Shape> {
        Box::new(Rectangle::new(self.x, self.y, self.width * factor, self.height * factor))
    }

    fn area(&self) -> f64 {
        self.width * self.height
    }

    fn draw(&self) -> String {
        format!(
            "Rectangle(x={}, y={}, w={}, h={})",
            self.x, self.y, self.width, self.height
        )
    }

    fn clone_box(&self) -> Box<dyn Shape> {
        Box::new(self.clone())
    }
}

/// 三角形
#[derive(Debug, Clone)]
pub struct Triangle {
    pub x1: f64,
    pub y1: f64,
    pub x2: f64,
    pub y2: f64,
    pub x3: f64,
    pub y3: f64,
}

impl Triangle {
    pub fn new(x1: f64, y1: f64, x2: f64, y2: f64, x3: f64, y3: f64) -> Self {
        Self { x1, y1, x2, y2, x3, y3 }
    }
}

impl Shape for Triangle {
    fn move_by(&self, dx: f64, dy: f64) -> Box<dyn Shape> {
        Box::new(Triangle::new(
            self.x1 + dx,
            self.y1 + dy,
            self.x2 + dx,
            self.y2 + dy,
            self.x3 + dx,
            self.y3 + dy,
        ))
    }

    fn scale(&self, factor: f64) -> Box<dyn Shape> {
        let cx = (self.x1 + self.x2 + self.x3) / 3.0;
        let cy = (self.y1 + self.y2 + self.y3) / 3.0;
        Box::new(Triangle::new(
            cx + (self.x1 - cx) * factor,
            cy + (self.y1 - cy) * factor,
            cx + (self.x2 - cx) * factor,
            cy + (self.y2 - cy) * factor,
            cx + (self.x3 - cx) * factor,
            cy + (self.y3 - cy) * factor,
        ))
    }

    fn area(&self) -> f64 {
        ((self.x1 * (self.y2 - self.y3) + self.x2 * (self.y3 - self.y1) + self.x3 * (self.y1 - self.y2)) / 2.0).abs()
    }

    fn draw(&self) -> String {
        format!(
            "Triangle(({},{}), ({},{}), ({},{}))",
            self.x1, self.y1, self.x2, self.y2, self.x3, self.y3
        )
    }

    fn clone_box(&self) -> Box<dyn Shape> {
        Box::new(self.clone())
    }
}

// ============================================================
// 3. Composite パターン
// ============================================================

/// 複合図形 - 複数の図形をまとめて扱う
#[derive(Debug)]
pub struct CompositeShape {
    shapes: Vec<Box<dyn Shape>>,
}

impl CompositeShape {
    pub fn new() -> Self {
        Self { shapes: Vec::new() }
    }

    pub fn from_shapes(shapes: Vec<Box<dyn Shape>>) -> Self {
        Self { shapes }
    }

    pub fn add(mut self, shape: Box<dyn Shape>) -> Self {
        self.shapes.push(shape);
        self
    }

    pub fn shapes(&self) -> &[Box<dyn Shape>] {
        &self.shapes
    }

    pub fn get(&self, index: usize) -> Option<&Box<dyn Shape>> {
        self.shapes.get(index)
    }
}

impl Default for CompositeShape {
    fn default() -> Self {
        Self::new()
    }
}

impl Shape for CompositeShape {
    fn move_by(&self, dx: f64, dy: f64) -> Box<dyn Shape> {
        let shapes = self.shapes.iter().map(|s| s.move_by(dx, dy)).collect();
        Box::new(CompositeShape::from_shapes(shapes))
    }

    fn scale(&self, factor: f64) -> Box<dyn Shape> {
        let shapes = self.shapes.iter().map(|s| s.scale(factor)).collect();
        Box::new(CompositeShape::from_shapes(shapes))
    }

    fn area(&self) -> f64 {
        self.shapes.iter().map(|s| s.area()).sum()
    }

    fn draw(&self) -> String {
        let shapes_str: Vec<_> = self.shapes.iter().map(|s| s.draw()).collect();
        format!("Composite[\n  {}\n]", shapes_str.join("\n  "))
    }

    fn clone_box(&self) -> Box<dyn Shape> {
        let shapes = self.shapes.iter().map(|s| s.clone_box()).collect();
        Box::new(CompositeShape::from_shapes(shapes))
    }
}

// ============================================================
// 4. Decorator パターン
// ============================================================

/// ジャーナルエントリ
#[derive(Debug, Clone)]
pub struct JournalEntry {
    pub operation: String,
    pub timestamp: i64,
}

impl JournalEntry {
    pub fn new(operation: &str) -> Self {
        Self {
            operation: operation.to_string(),
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis() as i64,
        }
    }
}

/// ジャーナル付き図形 - 操作履歴を記録
#[derive(Debug)]
pub struct JournaledShape {
    shape: Box<dyn Shape>,
    journal: Vec<JournalEntry>,
}

impl JournaledShape {
    pub fn new(shape: Box<dyn Shape>) -> Self {
        Self {
            shape,
            journal: Vec::new(),
        }
    }

    pub fn get_journal(&self) -> &[JournalEntry] {
        &self.journal
    }
}

impl Shape for JournaledShape {
    fn move_by(&self, dx: f64, dy: f64) -> Box<dyn Shape> {
        let mut journal = self.journal.clone();
        journal.push(JournalEntry::new(&format!("move({}, {})", dx, dy)));
        Box::new(JournaledShape {
            shape: self.shape.move_by(dx, dy),
            journal,
        })
    }

    fn scale(&self, factor: f64) -> Box<dyn Shape> {
        let mut journal = self.journal.clone();
        journal.push(JournalEntry::new(&format!("scale({})", factor)));
        Box::new(JournaledShape {
            shape: self.shape.scale(factor),
            journal,
        })
    }

    fn area(&self) -> f64 {
        self.shape.area()
    }

    fn draw(&self) -> String {
        format!("[Journaled: {} ops] {}", self.journal.len(), self.shape.draw())
    }

    fn clone_box(&self) -> Box<dyn Shape> {
        Box::new(JournaledShape {
            shape: self.shape.clone_box(),
            journal: self.journal.clone(),
        })
    }
}

/// 色付き図形
#[derive(Debug)]
pub struct ColoredShape {
    shape: Box<dyn Shape>,
    pub color: String,
}

impl ColoredShape {
    pub fn new(shape: Box<dyn Shape>, color: &str) -> Self {
        Self {
            shape,
            color: color.to_string(),
        }
    }

    pub fn with_color(self, new_color: &str) -> Self {
        Self {
            shape: self.shape,
            color: new_color.to_string(),
        }
    }
}

impl Shape for ColoredShape {
    fn move_by(&self, dx: f64, dy: f64) -> Box<dyn Shape> {
        Box::new(ColoredShape::new(self.shape.move_by(dx, dy), &self.color))
    }

    fn scale(&self, factor: f64) -> Box<dyn Shape> {
        Box::new(ColoredShape::new(self.shape.scale(factor), &self.color))
    }

    fn area(&self) -> f64 {
        self.shape.area()
    }

    fn draw(&self) -> String {
        format!("[{}] {}", self.color, self.shape.draw())
    }

    fn clone_box(&self) -> Box<dyn Shape> {
        Box::new(ColoredShape::new(self.shape.clone_box(), &self.color))
    }
}

/// 枠付き図形
#[derive(Debug)]
pub struct BorderedShape {
    shape: Box<dyn Shape>,
    pub border_width: i32,
}

impl BorderedShape {
    pub fn new(shape: Box<dyn Shape>, border_width: i32) -> Self {
        Self { shape, border_width }
    }
}

impl Shape for BorderedShape {
    fn move_by(&self, dx: f64, dy: f64) -> Box<dyn Shape> {
        Box::new(BorderedShape::new(self.shape.move_by(dx, dy), self.border_width))
    }

    fn scale(&self, factor: f64) -> Box<dyn Shape> {
        Box::new(BorderedShape::new(self.shape.scale(factor), self.border_width))
    }

    fn area(&self) -> f64 {
        self.shape.area()
    }

    fn draw(&self) -> String {
        format!("[Border: {}px] {}", self.border_width, self.shape.draw())
    }

    fn clone_box(&self) -> Box<dyn Shape> {
        Box::new(BorderedShape::new(self.shape.clone_box(), self.border_width))
    }
}

// ============================================================
// 5. Observer パターン
// ============================================================

/// イベント
#[derive(Debug, Clone)]
pub enum Event {
    CommandExecuted { description: String },
    CommandUndone { description: String },
    CommandRedone { description: String },
    StateChanged { new_state: String },
}

/// オブザーバー型
pub type Observer = Arc<dyn Fn(&Event) + Send + Sync>;

/// サブジェクト - オブザーバーを管理
pub struct Subject {
    observers: Vec<Observer>,
}

impl Subject {
    pub fn new() -> Self {
        Self { observers: Vec::new() }
    }

    pub fn add_observer(&mut self, observer: Observer) {
        self.observers.push(observer);
    }

    pub fn notify_observers(&self, event: &Event) {
        for observer in &self.observers {
            observer(event);
        }
    }

    pub fn observer_count(&self) -> usize {
        self.observers.len()
    }
}

impl Default for Subject {
    fn default() -> Self {
        Self::new()
    }
}

// ============================================================
// 6. Command パターン
// ============================================================

/// キャンバス - 図形を管理する
#[derive(Debug)]
pub struct Canvas {
    shapes: Vec<Box<dyn Shape>>,
}

impl Canvas {
    pub fn new() -> Self {
        Self { shapes: Vec::new() }
    }

    pub fn add_shape(mut self, shape: Box<dyn Shape>) -> Self {
        self.shapes.push(shape);
        self
    }

    pub fn remove_shape(mut self, index: usize) -> Self {
        if index < self.shapes.len() {
            self.shapes.remove(index);
        }
        self
    }

    pub fn update_shape(mut self, index: usize, shape: Box<dyn Shape>) -> Self {
        if index < self.shapes.len() {
            self.shapes[index] = shape;
        }
        self
    }

    pub fn get_shape(&self, index: usize) -> Option<&Box<dyn Shape>> {
        self.shapes.get(index)
    }

    pub fn shapes(&self) -> &[Box<dyn Shape>] {
        &self.shapes
    }

    pub fn clone_canvas(&self) -> Self {
        let shapes = self.shapes.iter().map(|s| s.clone_box()).collect();
        Self { shapes }
    }
}

impl Default for Canvas {
    fn default() -> Self {
        Self::new()
    }
}

/// コマンドの基底 trait
pub trait Command: Send + Sync {
    fn execute(&self, canvas: Canvas) -> Canvas;
    fn undo(&self, canvas: Canvas) -> Canvas;
    fn describe(&self) -> String;
}

/// 図形追加コマンド
pub struct AddShapeCommand {
    shape: Box<dyn Shape>,
}

impl AddShapeCommand {
    pub fn new(shape: Box<dyn Shape>) -> Self {
        Self { shape }
    }
}

impl Command for AddShapeCommand {
    fn execute(&self, canvas: Canvas) -> Canvas {
        canvas.add_shape(self.shape.clone_box())
    }

    fn undo(&self, canvas: Canvas) -> Canvas {
        let len = canvas.shapes.len();
        if len > 0 {
            canvas.remove_shape(len - 1)
        } else {
            canvas
        }
    }

    fn describe(&self) -> String {
        format!("Add shape: {}", self.shape.draw())
    }
}

/// 図形移動コマンド
pub struct MoveShapeCommand {
    index: usize,
    dx: f64,
    dy: f64,
}

impl MoveShapeCommand {
    pub fn new(index: usize, dx: f64, dy: f64) -> Self {
        Self { index, dx, dy }
    }
}

impl Command for MoveShapeCommand {
    fn execute(&self, canvas: Canvas) -> Canvas {
        match canvas.get_shape(self.index) {
            Some(shape) => {
                let moved = shape.move_by(self.dx, self.dy);
                canvas.update_shape(self.index, moved)
            }
            None => canvas,
        }
    }

    fn undo(&self, canvas: Canvas) -> Canvas {
        match canvas.get_shape(self.index) {
            Some(shape) => {
                let moved = shape.move_by(-self.dx, -self.dy);
                canvas.update_shape(self.index, moved)
            }
            None => canvas,
        }
    }

    fn describe(&self) -> String {
        format!("Move shape[{}] by ({}, {})", self.index, self.dx, self.dy)
    }
}

/// 図形拡大縮小コマンド
pub struct ScaleShapeCommand {
    index: usize,
    factor: f64,
}

impl ScaleShapeCommand {
    pub fn new(index: usize, factor: f64) -> Self {
        Self { index, factor }
    }
}

impl Command for ScaleShapeCommand {
    fn execute(&self, canvas: Canvas) -> Canvas {
        match canvas.get_shape(self.index) {
            Some(shape) => {
                let scaled = shape.scale(self.factor);
                canvas.update_shape(self.index, scaled)
            }
            None => canvas,
        }
    }

    fn undo(&self, canvas: Canvas) -> Canvas {
        match canvas.get_shape(self.index) {
            Some(shape) => {
                let scaled = shape.scale(1.0 / self.factor);
                canvas.update_shape(self.index, scaled)
            }
            None => canvas,
        }
    }

    fn describe(&self) -> String {
        format!("Scale shape[{}] by {}", self.index, self.factor)
    }
}

/// マクロコマンド - 複数のコマンドをまとめる
pub struct MacroCommand {
    commands: Vec<Box<dyn Command>>,
}

impl MacroCommand {
    pub fn new(commands: Vec<Box<dyn Command>>) -> Self {
        Self { commands }
    }
}

impl Command for MacroCommand {
    fn execute(&self, canvas: Canvas) -> Canvas {
        self.commands.iter().fold(canvas, |c, cmd| cmd.execute(c))
    }

    fn undo(&self, canvas: Canvas) -> Canvas {
        self.commands.iter().rev().fold(canvas, |c, cmd| cmd.undo(c))
    }

    fn describe(&self) -> String {
        let descs: Vec<_> = self.commands.iter().map(|c| c.describe()).collect();
        format!("Macro[{}]", descs.join(", "))
    }
}

// ============================================================
// 7. Command + Observer 統合
// ============================================================

/// オブザーバブルキャンバス
pub struct ObservableCanvas {
    canvas: Canvas,
    history: Vec<Box<dyn Command>>,
    redo_stack: Vec<Box<dyn Command>>,
    subject: Subject,
}

impl ObservableCanvas {
    pub fn new() -> Self {
        Self {
            canvas: Canvas::new(),
            history: Vec::new(),
            redo_stack: Vec::new(),
            subject: Subject::new(),
        }
    }

    pub fn get_canvas(&self) -> &Canvas {
        &self.canvas
    }

    pub fn get_history(&self) -> &[Box<dyn Command>] {
        &self.history
    }

    pub fn add_observer(&mut self, observer: Observer) {
        self.subject.add_observer(observer);
    }

    pub fn execute_command(&mut self, command: Box<dyn Command>) {
        let desc = command.describe();
        self.canvas = command.execute(self.canvas.clone_canvas());
        self.history.push(command);
        self.redo_stack.clear();
        self.subject.notify_observers(&Event::CommandExecuted { description: desc });
    }

    pub fn undo_last(&mut self) -> bool {
        if self.history.is_empty() {
            return false;
        }
        let command = self.history.pop().unwrap();
        let desc = command.describe();
        self.canvas = command.undo(self.canvas.clone_canvas());
        self.redo_stack.push(command);
        self.subject.notify_observers(&Event::CommandUndone { description: desc });
        true
    }

    pub fn redo_last(&mut self) -> bool {
        if self.redo_stack.is_empty() {
            return false;
        }
        let command = self.redo_stack.pop().unwrap();
        let desc = command.describe();
        self.canvas = command.execute(self.canvas.clone_canvas());
        self.history.push(command);
        self.subject.notify_observers(&Event::CommandRedone { description: desc });
        true
    }

    pub fn can_undo(&self) -> bool {
        !self.history.is_empty()
    }

    pub fn can_redo(&self) -> bool {
        !self.redo_stack.is_empty()
    }
}

impl Default for ObservableCanvas {
    fn default() -> Self {
        Self::new()
    }
}

// ============================================================
// 8. Strategy パターン
// ============================================================

/// レンダリング戦略
pub trait RenderStrategy {
    fn render(&self, canvas: &Canvas) -> String;
}

/// テキストレンダリング
pub struct TextRenderStrategy;

impl RenderStrategy for TextRenderStrategy {
    fn render(&self, canvas: &Canvas) -> String {
        canvas
            .shapes()
            .iter()
            .enumerate()
            .map(|(i, shape)| format!("[{}] {}", i, shape.draw()))
            .collect::<Vec<_>>()
            .join("\n")
    }
}

/// JSONレンダリング
pub struct JsonRenderStrategy;

impl RenderStrategy for JsonRenderStrategy {
    fn render(&self, canvas: &Canvas) -> String {
        let shapes_json: Vec<_> = canvas
            .shapes()
            .iter()
            .map(|shape| format!("    {}", shape_to_json(shape)))
            .collect();
        format!("{{\n  \"shapes\": [\n{}\n  ]\n}}", shapes_json.join(",\n"))
    }
}

fn shape_to_json(shape: &Box<dyn Shape>) -> String {
    let draw = shape.draw();
    if draw.starts_with("Circle") {
        format!("{{\"type\":\"circle\",\"draw\":\"{}\"}}", draw)
    } else if draw.starts_with("Rectangle") {
        format!("{{\"type\":\"rectangle\",\"draw\":\"{}\"}}", draw)
    } else if draw.starts_with("Triangle") {
        format!("{{\"type\":\"triangle\",\"draw\":\"{}\"}}", draw)
    } else {
        format!("{{\"type\":\"unknown\",\"draw\":\"{}\"}}", draw)
    }
}

/// SVGレンダリング
pub struct SvgRenderStrategy;

impl RenderStrategy for SvgRenderStrategy {
    fn render(&self, canvas: &Canvas) -> String {
        let shapes_svg: Vec<_> = canvas
            .shapes()
            .iter()
            .map(|shape| format!("  {}", shape_to_svg(shape)))
            .collect();
        format!(
            "<svg xmlns=\"http://www.w3.org/2000/svg\">\n{}\n</svg>",
            shapes_svg.join("\n")
        )
    }
}

fn shape_to_svg(shape: &Box<dyn Shape>) -> String {
    let draw = shape.draw();
    if draw.starts_with("Circle") {
        // Simple SVG circle placeholder
        "<circle />".to_string()
    } else if draw.starts_with("Rectangle") {
        "<rect />".to_string()
    } else if draw.starts_with("Triangle") {
        "<polygon />".to_string()
    } else {
        "<!-- unknown shape -->".to_string()
    }
}

// ============================================================
// 9. Factory パターン
// ============================================================

/// 図形ファクトリ
pub trait ShapeFactory {
    fn create_circle(&self, x: f64, y: f64, radius: f64) -> Box<dyn Shape>;
    fn create_rectangle(&self, x: f64, y: f64, width: f64, height: f64) -> Box<dyn Shape>;
}

/// シンプル図形ファクトリ
pub struct SimpleShapeFactory;

impl ShapeFactory for SimpleShapeFactory {
    fn create_circle(&self, x: f64, y: f64, radius: f64) -> Box<dyn Shape> {
        Box::new(Circle::new(x, y, radius))
    }

    fn create_rectangle(&self, x: f64, y: f64, width: f64, height: f64) -> Box<dyn Shape> {
        Box::new(Rectangle::new(x, y, width, height))
    }
}

/// 色付き図形ファクトリ
pub struct ColoredShapeFactory {
    color: String,
}

impl ColoredShapeFactory {
    pub fn new(color: &str) -> Self {
        Self { color: color.to_string() }
    }
}

impl ShapeFactory for ColoredShapeFactory {
    fn create_circle(&self, x: f64, y: f64, radius: f64) -> Box<dyn Shape> {
        Box::new(ColoredShape::new(Box::new(Circle::new(x, y, radius)), &self.color))
    }

    fn create_rectangle(&self, x: f64, y: f64, width: f64, height: f64) -> Box<dyn Shape> {
        Box::new(ColoredShape::new(Box::new(Rectangle::new(x, y, width, height)), &self.color))
    }
}

/// ジャーナル付き図形ファクトリ
pub struct JournaledShapeFactory;

impl ShapeFactory for JournaledShapeFactory {
    fn create_circle(&self, x: f64, y: f64, radius: f64) -> Box<dyn Shape> {
        Box::new(JournaledShape::new(Box::new(Circle::new(x, y, radius))))
    }

    fn create_rectangle(&self, x: f64, y: f64, width: f64, height: f64) -> Box<dyn Shape> {
        Box::new(JournaledShape::new(Box::new(Rectangle::new(x, y, width, height))))
    }
}

// ============================================================
// 10. BoundingBox
// ============================================================

/// 境界ボックス
#[derive(Debug, Clone, PartialEq)]
pub struct BoundingBox {
    pub min_x: f64,
    pub min_y: f64,
    pub max_x: f64,
    pub max_y: f64,
}

impl BoundingBox {
    pub fn new(min_x: f64, min_y: f64, max_x: f64, max_y: f64) -> Self {
        Self { min_x, min_y, max_x, max_y }
    }

    pub fn width(&self) -> f64 {
        self.max_x - self.min_x
    }

    pub fn height(&self) -> f64 {
        self.max_y - self.min_y
    }

    pub fn merge(&self, other: &BoundingBox) -> BoundingBox {
        BoundingBox::new(
            self.min_x.min(other.min_x),
            self.min_y.min(other.min_y),
            self.max_x.max(other.max_x),
            self.max_y.max(other.max_y),
        )
    }
}

/// 円の境界ボックスを取得
pub fn circle_bounding_box(circle: &Circle) -> BoundingBox {
    BoundingBox::new(
        circle.x - circle.radius,
        circle.y - circle.radius,
        circle.x + circle.radius,
        circle.y + circle.radius,
    )
}

/// 矩形の境界ボックスを取得
pub fn rectangle_bounding_box(rect: &Rectangle) -> BoundingBox {
    BoundingBox::new(rect.x, rect.y, rect.x + rect.width, rect.y + rect.height)
}

// ============================================================
// 11. DSL
// ============================================================

pub mod dsl {
    use super::*;

    pub fn circle(x: f64, y: f64, radius: f64) -> Circle {
        Circle::new(x, y, radius)
    }

    pub fn rectangle(x: f64, y: f64, width: f64, height: f64) -> Rectangle {
        Rectangle::new(x, y, width, height)
    }

    pub fn triangle(x1: f64, y1: f64, x2: f64, y2: f64, x3: f64, y3: f64) -> Triangle {
        Triangle::new(x1, y1, x2, y2, x3, y3)
    }

    pub fn composite(shapes: Vec<Box<dyn Shape>>) -> CompositeShape {
        CompositeShape::from_shapes(shapes)
    }

    /// Shape を色付きにする
    pub fn with_color(shape: Box<dyn Shape>, color: &str) -> ColoredShape {
        ColoredShape::new(shape, color)
    }

    /// Shape に枠を付ける
    pub fn with_border(shape: Box<dyn Shape>, width: i32) -> BorderedShape {
        BorderedShape::new(shape, width)
    }

    /// Shape にジャーナルを付ける
    pub fn with_journal(shape: Box<dyn Shape>) -> JournaledShape {
        JournaledShape::new(shape)
    }
}

// ============================================================
// 12. ログオブザーバー
// ============================================================

/// ログオブザーバー
pub struct LogObserver {
    logs: Arc<Mutex<Vec<String>>>,
}

impl LogObserver {
    pub fn new() -> Self {
        Self {
            logs: Arc::new(Mutex::new(Vec::new())),
        }
    }

    pub fn observer(&self) -> Observer {
        let logs = Arc::clone(&self.logs);
        Arc::new(move |event| {
            let message = match event {
                Event::CommandExecuted { description } => format!("Executed: {}", description),
                Event::CommandUndone { description } => format!("Undone: {}", description),
                Event::CommandRedone { description } => format!("Redone: {}", description),
                Event::StateChanged { new_state } => format!("State changed: {}", new_state),
            };
            logs.lock().unwrap().push(message);
        })
    }

    pub fn get_logs(&self) -> Vec<String> {
        self.logs.lock().unwrap().clone()
    }

    pub fn clear(&self) {
        self.logs.lock().unwrap().clear();
    }
}

impl Default for LogObserver {
    fn default() -> Self {
        Self::new()
    }
}

// ============================================================
// テスト
// ============================================================

#[cfg(test)]
mod tests {
    use super::*;

    mod shape_tests {
        use super::*;

        mod circle_tests {
            use super::*;

            #[test]
            fn creates_circle() {
                let circle = Circle::new(0.0, 0.0, 10.0);
                assert_eq!(circle.x, 0.0);
                assert_eq!(circle.y, 0.0);
                assert_eq!(circle.radius, 10.0);
            }

            #[test]
            fn moves_circle() {
                let circle = Circle::new(0.0, 0.0, 10.0);
                let moved = circle.move_by(5.0, 3.0);
                assert!(moved.draw().contains("x=5"));
                assert!(moved.draw().contains("y=3"));
            }

            #[test]
            fn scales_circle() {
                let circle = Circle::new(0.0, 0.0, 10.0);
                let scaled = circle.scale(2.0);
                assert!(scaled.draw().contains("r=20"));
            }

            #[test]
            fn calculates_area() {
                let circle = Circle::new(0.0, 0.0, 10.0);
                let expected = PI * 100.0;
                assert!((circle.area() - expected).abs() < 0.001);
            }

            #[test]
            fn draws_circle() {
                let circle = Circle::new(0.0, 0.0, 10.0);
                assert!(circle.draw().contains("Circle"));
            }
        }

        mod rectangle_tests {
            use super::*;

            #[test]
            fn creates_rectangle() {
                let rect = Rectangle::new(0.0, 0.0, 10.0, 20.0);
                assert_eq!(rect.width, 10.0);
                assert_eq!(rect.height, 20.0);
            }

            #[test]
            fn moves_rectangle() {
                let rect = Rectangle::new(0.0, 0.0, 10.0, 20.0);
                let moved = rect.move_by(5.0, 3.0);
                assert!(moved.draw().contains("x=5"));
                assert!(moved.draw().contains("y=3"));
            }

            #[test]
            fn scales_rectangle() {
                let rect = Rectangle::new(0.0, 0.0, 10.0, 20.0);
                let scaled = rect.scale(2.0);
                assert!(scaled.draw().contains("w=20"));
                assert!(scaled.draw().contains("h=40"));
            }

            #[test]
            fn calculates_area() {
                let rect = Rectangle::new(0.0, 0.0, 10.0, 20.0);
                assert_eq!(rect.area(), 200.0);
            }
        }

        mod triangle_tests {
            use super::*;

            #[test]
            fn creates_triangle() {
                let tri = Triangle::new(0.0, 0.0, 10.0, 0.0, 5.0, 10.0);
                assert_eq!(tri.area(), 50.0);
            }

            #[test]
            fn moves_triangle() {
                let tri = Triangle::new(0.0, 0.0, 10.0, 0.0, 5.0, 10.0);
                let moved = tri.move_by(5.0, 5.0);
                assert!(moved.draw().contains("(5,5)"));
            }
        }
    }

    mod composite_tests {
        use super::*;

        #[test]
        fn creates_empty_composite() {
            let composite = CompositeShape::new();
            assert!(composite.shapes().is_empty());
        }

        #[test]
        fn adds_shapes() {
            let composite = CompositeShape::new()
                .add(Box::new(Circle::new(0.0, 0.0, 10.0)))
                .add(Box::new(Rectangle::new(0.0, 0.0, 10.0, 20.0)));
            assert_eq!(composite.shapes().len(), 2);
        }

        #[test]
        fn moves_composite() {
            let composite = CompositeShape::new()
                .add(Box::new(Circle::new(0.0, 0.0, 10.0)))
                .add(Box::new(Rectangle::new(0.0, 0.0, 10.0, 20.0)));
            let moved = composite.move_by(5.0, 3.0);
            assert!(moved.draw().contains("x=5"));
        }

        #[test]
        fn calculates_composite_area() {
            let composite = CompositeShape::new()
                .add(Box::new(Circle::new(0.0, 0.0, 10.0)))
                .add(Box::new(Rectangle::new(0.0, 0.0, 10.0, 20.0)));
            let expected = PI * 100.0 + 200.0;
            assert!((composite.area() - expected).abs() < 0.001);
        }
    }

    mod decorator_tests {
        use super::*;

        mod journaled_shape_tests {
            use super::*;

            #[test]
            fn records_operations() {
                let shape = JournaledShape::new(Box::new(Circle::new(0.0, 0.0, 10.0)));
                let moved = shape.move_by(5.0, 3.0);
                let scaled = moved.scale(2.0);
                // Check via draw output
                assert!(scaled.draw().contains("2 ops"));
            }

            #[test]
            fn includes_ops_count_in_draw() {
                let shape = JournaledShape::new(Box::new(Circle::new(0.0, 0.0, 10.0)));
                let moved = shape.move_by(5.0, 3.0);
                assert!(moved.draw().contains("1 ops"));
            }
        }

        mod colored_shape_tests {
            use super::*;

            #[test]
            fn sets_color() {
                let colored = ColoredShape::new(Box::new(Circle::new(0.0, 0.0, 10.0)), "red");
                assert_eq!(colored.color, "red");
            }

            #[test]
            fn includes_color_in_draw() {
                let colored = ColoredShape::new(Box::new(Circle::new(0.0, 0.0, 10.0)), "red");
                assert!(colored.draw().contains("[red]"));
            }

            #[test]
            fn changes_color() {
                let colored = ColoredShape::new(Box::new(Circle::new(0.0, 0.0, 10.0)), "red")
                    .with_color("blue");
                assert_eq!(colored.color, "blue");
            }
        }

        mod bordered_shape_tests {
            use super::*;

            #[test]
            fn sets_border_width() {
                let bordered = BorderedShape::new(Box::new(Circle::new(0.0, 0.0, 10.0)), 3);
                assert_eq!(bordered.border_width, 3);
            }

            #[test]
            fn includes_border_in_draw() {
                let bordered = BorderedShape::new(Box::new(Circle::new(0.0, 0.0, 10.0)), 3);
                assert!(bordered.draw().contains("3px"));
            }
        }
    }

    mod observer_tests {
        use super::*;

        #[test]
        fn registers_observer() {
            let mut subject = Subject::new();
            let notified = Arc::new(Mutex::new(false));
            let notified_clone = Arc::clone(&notified);

            subject.add_observer(Arc::new(move |_| {
                *notified_clone.lock().unwrap() = true;
            }));

            subject.notify_observers(&Event::StateChanged {
                new_state: "test".to_string(),
            });

            assert!(*notified.lock().unwrap());
        }

        #[test]
        fn notifies_multiple_observers() {
            let mut subject = Subject::new();
            let count = Arc::new(Mutex::new(0));
            let count1 = Arc::clone(&count);
            let count2 = Arc::clone(&count);

            subject.add_observer(Arc::new(move |_| {
                *count1.lock().unwrap() += 1;
            }));
            subject.add_observer(Arc::new(move |_| {
                *count2.lock().unwrap() += 1;
            }));

            subject.notify_observers(&Event::StateChanged {
                new_state: "test".to_string(),
            });

            assert_eq!(*count.lock().unwrap(), 2);
        }
    }

    mod command_tests {
        use super::*;

        mod canvas_tests {
            use super::*;

            #[test]
            fn adds_shape() {
                let canvas = Canvas::new().add_shape(Box::new(Circle::new(0.0, 0.0, 10.0)));
                assert_eq!(canvas.shapes().len(), 1);
            }

            #[test]
            fn removes_shape() {
                let canvas = Canvas::new()
                    .add_shape(Box::new(Circle::new(0.0, 0.0, 10.0)))
                    .add_shape(Box::new(Rectangle::new(0.0, 0.0, 10.0, 20.0)))
                    .remove_shape(0);
                assert_eq!(canvas.shapes().len(), 1);
            }

            #[test]
            fn updates_shape() {
                let canvas = Canvas::new()
                    .add_shape(Box::new(Circle::new(0.0, 0.0, 10.0)))
                    .update_shape(0, Box::new(Circle::new(5.0, 5.0, 20.0)));
                assert!(canvas.shapes()[0].draw().contains("r=20"));
            }
        }

        mod add_shape_command_tests {
            use super::*;

            #[test]
            fn executes_add() {
                let cmd = AddShapeCommand::new(Box::new(Circle::new(0.0, 0.0, 10.0)));
                let canvas = cmd.execute(Canvas::new());
                assert_eq!(canvas.shapes().len(), 1);
            }

            #[test]
            fn undoes_add() {
                let cmd = AddShapeCommand::new(Box::new(Circle::new(0.0, 0.0, 10.0)));
                let canvas = cmd.execute(Canvas::new());
                let undone = cmd.undo(canvas);
                assert_eq!(undone.shapes().len(), 0);
            }
        }

        mod move_shape_command_tests {
            use super::*;

            #[test]
            fn executes_move() {
                let canvas = Canvas::new().add_shape(Box::new(Circle::new(0.0, 0.0, 10.0)));
                let cmd = MoveShapeCommand::new(0, 5.0, 3.0);
                let moved = cmd.execute(canvas);
                assert!(moved.shapes()[0].draw().contains("x=5"));
            }

            #[test]
            fn undoes_move() {
                let canvas = Canvas::new().add_shape(Box::new(Circle::new(0.0, 0.0, 10.0)));
                let cmd = MoveShapeCommand::new(0, 5.0, 3.0);
                let moved = cmd.execute(canvas);
                let undone = cmd.undo(moved);
                assert!(undone.shapes()[0].draw().contains("x=0"));
            }
        }

        mod scale_shape_command_tests {
            use super::*;

            #[test]
            fn executes_scale() {
                let canvas = Canvas::new().add_shape(Box::new(Circle::new(0.0, 0.0, 10.0)));
                let cmd = ScaleShapeCommand::new(0, 2.0);
                let scaled = cmd.execute(canvas);
                assert!(scaled.shapes()[0].draw().contains("r=20"));
            }

            #[test]
            fn undoes_scale() {
                let canvas = Canvas::new().add_shape(Box::new(Circle::new(0.0, 0.0, 10.0)));
                let cmd = ScaleShapeCommand::new(0, 2.0);
                let scaled = cmd.execute(canvas);
                let undone = cmd.undo(scaled);
                assert!(undone.shapes()[0].draw().contains("r=10"));
            }
        }

        mod macro_command_tests {
            use super::*;

            #[test]
            fn executes_multiple_commands() {
                let canvas = Canvas::new();
                let commands: Vec<Box<dyn Command>> = vec![
                    Box::new(AddShapeCommand::new(Box::new(Circle::new(0.0, 0.0, 10.0)))),
                    Box::new(AddShapeCommand::new(Box::new(Rectangle::new(
                        0.0, 0.0, 10.0, 20.0,
                    )))),
                ];
                let macro_cmd = MacroCommand::new(commands);
                let executed = macro_cmd.execute(canvas);
                assert_eq!(executed.shapes().len(), 2);
            }

            #[test]
            fn undoes_all_commands() {
                let canvas = Canvas::new();
                let commands: Vec<Box<dyn Command>> = vec![
                    Box::new(AddShapeCommand::new(Box::new(Circle::new(0.0, 0.0, 10.0)))),
                    Box::new(AddShapeCommand::new(Box::new(Rectangle::new(
                        0.0, 0.0, 10.0, 20.0,
                    )))),
                ];
                let macro_cmd = MacroCommand::new(commands);
                let executed = macro_cmd.execute(canvas);
                let undone = macro_cmd.undo(executed);
                assert_eq!(undone.shapes().len(), 0);
            }
        }
    }

    mod observable_canvas_tests {
        use super::*;

        #[test]
        fn notifies_on_execute() {
            let mut obs_canvas = ObservableCanvas::new();
            let notified = Arc::new(Mutex::new(false));
            let notified_clone = Arc::clone(&notified);

            obs_canvas.add_observer(Arc::new(move |event| {
                if matches!(event, Event::CommandExecuted { .. }) {
                    *notified_clone.lock().unwrap() = true;
                }
            }));

            obs_canvas.execute_command(Box::new(AddShapeCommand::new(Box::new(Circle::new(
                0.0, 0.0, 10.0,
            )))));

            assert!(*notified.lock().unwrap());
        }

        #[test]
        fn notifies_on_undo() {
            let mut obs_canvas = ObservableCanvas::new();
            let undo_notified = Arc::new(Mutex::new(false));
            let undo_notified_clone = Arc::clone(&undo_notified);

            obs_canvas.add_observer(Arc::new(move |event| {
                if matches!(event, Event::CommandUndone { .. }) {
                    *undo_notified_clone.lock().unwrap() = true;
                }
            }));

            obs_canvas.execute_command(Box::new(AddShapeCommand::new(Box::new(Circle::new(
                0.0, 0.0, 10.0,
            )))));
            obs_canvas.undo_last();

            assert!(*undo_notified.lock().unwrap());
        }

        #[test]
        fn notifies_on_redo() {
            let mut obs_canvas = ObservableCanvas::new();
            let redo_notified = Arc::new(Mutex::new(false));
            let redo_notified_clone = Arc::clone(&redo_notified);

            obs_canvas.add_observer(Arc::new(move |event| {
                if matches!(event, Event::CommandRedone { .. }) {
                    *redo_notified_clone.lock().unwrap() = true;
                }
            }));

            obs_canvas.execute_command(Box::new(AddShapeCommand::new(Box::new(Circle::new(
                0.0, 0.0, 10.0,
            )))));
            obs_canvas.undo_last();
            obs_canvas.redo_last();

            assert!(*redo_notified.lock().unwrap());
        }

        #[test]
        fn manages_history() {
            let mut obs_canvas = ObservableCanvas::new();
            obs_canvas.execute_command(Box::new(AddShapeCommand::new(Box::new(Circle::new(
                0.0, 0.0, 10.0,
            )))));
            obs_canvas.execute_command(Box::new(MoveShapeCommand::new(0, 5.0, 3.0)));

            assert_eq!(obs_canvas.get_history().len(), 2);
            assert!(obs_canvas.can_undo());
        }

        #[test]
        fn undo_redo_works_correctly() {
            let mut obs_canvas = ObservableCanvas::new();
            obs_canvas.execute_command(Box::new(AddShapeCommand::new(Box::new(Circle::new(
                0.0, 0.0, 10.0,
            )))));
            obs_canvas.execute_command(Box::new(MoveShapeCommand::new(0, 5.0, 3.0)));

            assert!(obs_canvas.get_canvas().shapes()[0].draw().contains("x=5"));

            obs_canvas.undo_last();
            assert!(obs_canvas.get_canvas().shapes()[0].draw().contains("x=0"));

            obs_canvas.redo_last();
            assert!(obs_canvas.get_canvas().shapes()[0].draw().contains("x=5"));
        }
    }

    mod strategy_tests {
        use super::*;

        fn test_canvas() -> Canvas {
            Canvas::new()
                .add_shape(Box::new(Circle::new(0.0, 0.0, 10.0)))
                .add_shape(Box::new(Rectangle::new(0.0, 0.0, 10.0, 20.0)))
        }

        #[test]
        fn text_render() {
            let canvas = test_canvas();
            let text = TextRenderStrategy.render(&canvas);
            assert!(text.contains("[0]"));
            assert!(text.contains("Circle"));
        }

        #[test]
        fn json_render() {
            let canvas = test_canvas();
            let json = JsonRenderStrategy.render(&canvas);
            assert!(json.contains("\"shapes\""));
            assert!(json.contains("\"type\":\"circle\""));
        }

        #[test]
        fn svg_render() {
            let canvas = test_canvas();
            let svg = SvgRenderStrategy.render(&canvas);
            assert!(svg.contains("<svg"));
            assert!(svg.contains("<circle"));
            assert!(svg.contains("<rect"));
        }
    }

    mod factory_tests {
        use super::*;

        #[test]
        fn simple_factory_creates_shapes() {
            let factory = SimpleShapeFactory;
            let circle = factory.create_circle(0.0, 0.0, 10.0);
            assert!(circle.draw().contains("Circle"));
        }

        #[test]
        fn colored_factory_creates_colored_shapes() {
            let factory = ColoredShapeFactory::new("red");
            let circle = factory.create_circle(0.0, 0.0, 10.0);
            assert!(circle.draw().contains("[red]"));
        }

        #[test]
        fn journaled_factory_creates_journaled_shapes() {
            let factory = JournaledShapeFactory;
            let circle = factory.create_circle(0.0, 0.0, 10.0);
            assert!(circle.draw().contains("Journaled"));
        }
    }

    mod bounding_box_tests {
        use super::*;

        #[test]
        fn calculates_circle_bounding_box() {
            let circle = Circle::new(0.0, 0.0, 10.0);
            let bb = circle_bounding_box(&circle);
            assert_eq!(bb.min_x, -10.0);
            assert_eq!(bb.max_x, 10.0);
        }

        #[test]
        fn merges_bounding_boxes() {
            let bb1 = BoundingBox::new(0.0, 0.0, 10.0, 10.0);
            let bb2 = BoundingBox::new(5.0, 5.0, 20.0, 20.0);
            let merged = bb1.merge(&bb2);
            assert_eq!(merged.min_x, 0.0);
            assert_eq!(merged.max_x, 20.0);
        }
    }

    mod dsl_tests {
        use super::*;
        use dsl::*;

        #[test]
        fn creates_shapes_with_dsl() {
            let c = circle(0.0, 0.0, 10.0);
            assert!(c.draw().contains("Circle"));
        }

        #[test]
        fn applies_decorators_with_dsl() {
            let decorated = with_border(
                Box::new(with_color(Box::new(circle(0.0, 0.0, 10.0)), "red")),
                3,
            );
            assert!(decorated.draw().contains("[red]"));
            assert!(decorated.draw().contains("3px"));
        }

        #[test]
        fn creates_composite_with_dsl() {
            let comp = composite(vec![
                Box::new(circle(0.0, 0.0, 10.0)),
                Box::new(rectangle(0.0, 0.0, 10.0, 20.0)),
            ]);
            assert_eq!(comp.shapes().len(), 2);
        }
    }

    mod log_observer_tests {
        use super::*;

        #[test]
        fn records_logs() {
            let mut obs_canvas = ObservableCanvas::new();
            let log_observer = LogObserver::new();
            obs_canvas.add_observer(log_observer.observer());

            obs_canvas.execute_command(Box::new(AddShapeCommand::new(Box::new(Circle::new(
                0.0, 0.0, 10.0,
            )))));
            obs_canvas.execute_command(Box::new(MoveShapeCommand::new(0, 5.0, 3.0)));
            obs_canvas.undo_last();

            let logs = log_observer.get_logs();
            assert_eq!(logs.len(), 3);
            assert!(logs[0].contains("Executed"));
            assert!(logs[2].contains("Undone"));
        }
    }
}


