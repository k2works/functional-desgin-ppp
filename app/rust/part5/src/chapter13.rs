//! 第13章: Abstract Factory パターン
//!
//! Abstract Factory パターンは、関連するオブジェクトのファミリーを、
//! その具体的なクラスを指定することなく生成するためのインターフェースを提供します。

// ============================================
// 1. 図形 - Product
// ============================================

/// 色
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Color {
    pub r: i32,
    pub g: i32,
    pub b: i32,
}

impl Color {
    pub const BLACK: Color = Color { r: 0, g: 0, b: 0 };
    pub const WHITE: Color = Color { r: 255, g: 255, b: 255 };
    pub const RED: Color = Color { r: 255, g: 0, b: 0 };
    pub const GREEN: Color = Color { r: 0, g: 255, b: 0 };
    pub const BLUE: Color = Color { r: 0, g: 0, b: 255 };
    pub const TRANSPARENT: Color = Color { r: -1, g: -1, b: -1 };

    pub fn new(r: i32, g: i32, b: i32) -> Self {
        Self { r, g, b }
    }

    pub fn to_hex(&self) -> String {
        format!("#{:02X}{:02X}{:02X}", self.r as u8, self.g as u8, self.b as u8)
    }
}

/// 点
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

impl Point {
    pub fn new(x: f64, y: f64) -> Self {
        Self { x, y }
    }
}

/// 図形スタイル
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct ShapeStyle {
    pub stroke_color: Color,
    pub stroke_width: f64,
    pub fill_color: Color,
}

impl Default for ShapeStyle {
    fn default() -> Self {
        Self {
            stroke_color: Color::BLACK,
            stroke_width: 1.0,
            fill_color: Color::TRANSPARENT,
        }
    }
}

impl ShapeStyle {
    pub fn new(stroke_color: Color, stroke_width: f64, fill_color: Color) -> Self {
        Self {
            stroke_color,
            stroke_width,
            fill_color,
        }
    }
}

/// 図形の基本トレイト
pub trait Shape: Clone {
    fn style(&self) -> ShapeStyle;
    fn translate(&self, dx: f64, dy: f64) -> Self;
    fn scale(&self, factor: f64) -> Self;
    fn with_style(&self, new_style: ShapeStyle) -> Self;
}

/// 円
#[derive(Debug, Clone, PartialEq)]
pub struct Circle {
    pub center: Point,
    pub radius: f64,
    pub style: ShapeStyle,
}

impl Circle {
    pub fn new(center: Point, radius: f64) -> Self {
        Self {
            center,
            radius,
            style: ShapeStyle::default(),
        }
    }

    pub fn with_style_new(center: Point, radius: f64, style: ShapeStyle) -> Self {
        Self { center, radius, style }
    }
}

impl Shape for Circle {
    fn style(&self) -> ShapeStyle {
        self.style
    }

    fn translate(&self, dx: f64, dy: f64) -> Self {
        Self {
            center: Point::new(self.center.x + dx, self.center.y + dy),
            ..self.clone()
        }
    }

    fn scale(&self, factor: f64) -> Self {
        Self {
            radius: self.radius * factor,
            ..self.clone()
        }
    }

    fn with_style(&self, new_style: ShapeStyle) -> Self {
        Self {
            style: new_style,
            ..self.clone()
        }
    }
}

/// 正方形
#[derive(Debug, Clone, PartialEq)]
pub struct Square {
    pub top_left: Point,
    pub side: f64,
    pub style: ShapeStyle,
}

impl Square {
    pub fn new(top_left: Point, side: f64) -> Self {
        Self {
            top_left,
            side,
            style: ShapeStyle::default(),
        }
    }

    pub fn with_style_new(top_left: Point, side: f64, style: ShapeStyle) -> Self {
        Self { top_left, side, style }
    }
}

impl Shape for Square {
    fn style(&self) -> ShapeStyle {
        self.style
    }

    fn translate(&self, dx: f64, dy: f64) -> Self {
        Self {
            top_left: Point::new(self.top_left.x + dx, self.top_left.y + dy),
            ..self.clone()
        }
    }

    fn scale(&self, factor: f64) -> Self {
        Self {
            side: self.side * factor,
            ..self.clone()
        }
    }

    fn with_style(&self, new_style: ShapeStyle) -> Self {
        Self {
            style: new_style,
            ..self.clone()
        }
    }
}

/// 長方形
#[derive(Debug, Clone, PartialEq)]
pub struct Rectangle {
    pub top_left: Point,
    pub width: f64,
    pub height: f64,
    pub style: ShapeStyle,
}

impl Rectangle {
    pub fn new(top_left: Point, width: f64, height: f64) -> Self {
        Self {
            top_left,
            width,
            height,
            style: ShapeStyle::default(),
        }
    }

    pub fn with_style_new(top_left: Point, width: f64, height: f64, style: ShapeStyle) -> Self {
        Self { top_left, width, height, style }
    }
}

impl Shape for Rectangle {
    fn style(&self) -> ShapeStyle {
        self.style
    }

    fn translate(&self, dx: f64, dy: f64) -> Self {
        Self {
            top_left: Point::new(self.top_left.x + dx, self.top_left.y + dy),
            ..self.clone()
        }
    }

    fn scale(&self, factor: f64) -> Self {
        Self {
            width: self.width * factor,
            height: self.height * factor,
            ..self.clone()
        }
    }

    fn with_style(&self, new_style: ShapeStyle) -> Self {
        Self {
            style: new_style,
            ..self.clone()
        }
    }
}

/// 三角形
#[derive(Debug, Clone, PartialEq)]
pub struct Triangle {
    pub p1: Point,
    pub p2: Point,
    pub p3: Point,
    pub style: ShapeStyle,
}

impl Triangle {
    pub fn new(p1: Point, p2: Point, p3: Point) -> Self {
        Self {
            p1,
            p2,
            p3,
            style: ShapeStyle::default(),
        }
    }

    pub fn with_style_new(p1: Point, p2: Point, p3: Point, style: ShapeStyle) -> Self {
        Self { p1, p2, p3, style }
    }
}

impl Shape for Triangle {
    fn style(&self) -> ShapeStyle {
        self.style
    }

    fn translate(&self, dx: f64, dy: f64) -> Self {
        Self {
            p1: Point::new(self.p1.x + dx, self.p1.y + dy),
            p2: Point::new(self.p2.x + dx, self.p2.y + dy),
            p3: Point::new(self.p3.x + dx, self.p3.y + dy),
            ..self.clone()
        }
    }

    fn scale(&self, factor: f64) -> Self {
        Self {
            p1: Point::new(self.p1.x * factor, self.p1.y * factor),
            p2: Point::new(self.p2.x * factor, self.p2.y * factor),
            p3: Point::new(self.p3.x * factor, self.p3.y * factor),
            ..self.clone()
        }
    }

    fn with_style(&self, new_style: ShapeStyle) -> Self {
        Self {
            style: new_style,
            ..self.clone()
        }
    }
}

// ============================================
// 2. ShapeFactory - Abstract Factory
// ============================================

/// 図形ファクトリの抽象インターフェース
pub trait ShapeFactory {
    fn create_circle(&self, center: Point, radius: f64) -> Circle;
    fn create_square(&self, top_left: Point, side: f64) -> Square;
    fn create_rectangle(&self, top_left: Point, width: f64, height: f64) -> Rectangle;
    fn create_triangle(&self, p1: Point, p2: Point, p3: Point) -> Triangle;
}

// ============================================
// 3. StandardShapeFactory - Concrete Factory
// ============================================

/// 標準図形ファクトリ
pub struct StandardShapeFactory;

impl ShapeFactory for StandardShapeFactory {
    fn create_circle(&self, center: Point, radius: f64) -> Circle {
        Circle::new(center, radius)
    }

    fn create_square(&self, top_left: Point, side: f64) -> Square {
        Square::new(top_left, side)
    }

    fn create_rectangle(&self, top_left: Point, width: f64, height: f64) -> Rectangle {
        Rectangle::new(top_left, width, height)
    }

    fn create_triangle(&self, p1: Point, p2: Point, p3: Point) -> Triangle {
        Triangle::new(p1, p2, p3)
    }
}

// ============================================
// 4. OutlinedShapeFactory - Concrete Factory
// ============================================

/// 輪郭線付き図形ファクトリ
pub struct OutlinedShapeFactory {
    style: ShapeStyle,
}

impl OutlinedShapeFactory {
    pub fn new(stroke_color: Color, stroke_width: f64) -> Self {
        Self {
            style: ShapeStyle::new(stroke_color, stroke_width, Color::TRANSPARENT),
        }
    }
}

impl ShapeFactory for OutlinedShapeFactory {
    fn create_circle(&self, center: Point, radius: f64) -> Circle {
        Circle::with_style_new(center, radius, self.style)
    }

    fn create_square(&self, top_left: Point, side: f64) -> Square {
        Square::with_style_new(top_left, side, self.style)
    }

    fn create_rectangle(&self, top_left: Point, width: f64, height: f64) -> Rectangle {
        Rectangle::with_style_new(top_left, width, height, self.style)
    }

    fn create_triangle(&self, p1: Point, p2: Point, p3: Point) -> Triangle {
        Triangle::with_style_new(p1, p2, p3, self.style)
    }
}

// ============================================
// 5. FilledShapeFactory - Concrete Factory
// ============================================

/// 塗りつぶし図形ファクトリ
pub struct FilledShapeFactory {
    style: ShapeStyle,
}

impl FilledShapeFactory {
    pub fn new(fill_color: Color) -> Self {
        Self {
            style: ShapeStyle::new(Color::BLACK, 1.0, fill_color),
        }
    }

    pub fn with_stroke(fill_color: Color, stroke_color: Color, stroke_width: f64) -> Self {
        Self {
            style: ShapeStyle::new(stroke_color, stroke_width, fill_color),
        }
    }
}

impl ShapeFactory for FilledShapeFactory {
    fn create_circle(&self, center: Point, radius: f64) -> Circle {
        Circle::with_style_new(center, radius, self.style)
    }

    fn create_square(&self, top_left: Point, side: f64) -> Square {
        Square::with_style_new(top_left, side, self.style)
    }

    fn create_rectangle(&self, top_left: Point, width: f64, height: f64) -> Rectangle {
        Rectangle::with_style_new(top_left, width, height, self.style)
    }

    fn create_triangle(&self, p1: Point, p2: Point, p3: Point) -> Triangle {
        Triangle::with_style_new(p1, p2, p3, self.style)
    }
}

// ============================================
// 6. UI コンポーネント - Product
// ============================================

/// UI テーマ
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Theme {
    Light,
    Dark,
}

/// ボタン
pub trait Button: Clone {
    fn label(&self) -> &str;
    fn theme(&self) -> Theme;
    fn render(&self) -> String;
}

/// テキストフィールド
pub trait TextField: Clone {
    fn placeholder(&self) -> &str;
    fn theme(&self) -> Theme;
    fn render(&self) -> String;
    fn value(&self) -> &str;
    fn set_value(&self, new_value: &str) -> Self;
}

/// チェックボックス
pub trait Checkbox: Clone {
    fn label(&self) -> &str;
    fn checked(&self) -> bool;
    fn theme(&self) -> Theme;
    fn render(&self) -> String;
    fn toggle(&self) -> Self;
}

// ============================================
// 7. Windows UI 実装
// ============================================

#[derive(Debug, Clone)]
pub struct WindowsButton {
    label: String,
    theme: Theme,
}

impl WindowsButton {
    pub fn new(label: &str, theme: Theme) -> Self {
        Self {
            label: label.to_string(),
            theme,
        }
    }
}

impl Button for WindowsButton {
    fn label(&self) -> &str {
        &self.label
    }

    fn theme(&self) -> Theme {
        self.theme
    }

    fn render(&self) -> String {
        let icon = if self.theme == Theme::Dark { "▓" } else { "░" };
        format!("[{} {}]", icon, self.label)
    }
}

#[derive(Debug, Clone)]
pub struct WindowsTextField {
    placeholder: String,
    theme: Theme,
    value: String,
}

impl WindowsTextField {
    pub fn new(placeholder: &str, theme: Theme) -> Self {
        Self {
            placeholder: placeholder.to_string(),
            theme,
            value: String::new(),
        }
    }
}

impl TextField for WindowsTextField {
    fn placeholder(&self) -> &str {
        &self.placeholder
    }

    fn theme(&self) -> Theme {
        self.theme
    }

    fn render(&self) -> String {
        let content = if self.value.is_empty() {
            &self.placeholder
        } else {
            &self.value
        };
        format!("|{}|", content)
    }

    fn value(&self) -> &str {
        &self.value
    }

    fn set_value(&self, new_value: &str) -> Self {
        Self {
            value: new_value.to_string(),
            ..self.clone()
        }
    }
}

#[derive(Debug, Clone)]
pub struct WindowsCheckbox {
    label: String,
    checked: bool,
    theme: Theme,
}

impl WindowsCheckbox {
    pub fn new(label: &str, checked: bool, theme: Theme) -> Self {
        Self {
            label: label.to_string(),
            checked,
            theme,
        }
    }
}

impl Checkbox for WindowsCheckbox {
    fn label(&self) -> &str {
        &self.label
    }

    fn checked(&self) -> bool {
        self.checked
    }

    fn theme(&self) -> Theme {
        self.theme
    }

    fn render(&self) -> String {
        let mark = if self.checked { "X" } else { " " };
        format!("[{}] {}", mark, self.label)
    }

    fn toggle(&self) -> Self {
        Self {
            checked: !self.checked,
            ..self.clone()
        }
    }
}

// ============================================
// 8. MacOS UI 実装
// ============================================

#[derive(Debug, Clone)]
pub struct MacOSButton {
    label: String,
    theme: Theme,
}

impl MacOSButton {
    pub fn new(label: &str, theme: Theme) -> Self {
        Self {
            label: label.to_string(),
            theme,
        }
    }
}

impl Button for MacOSButton {
    fn label(&self) -> &str {
        &self.label
    }

    fn theme(&self) -> Theme {
        self.theme
    }

    fn render(&self) -> String {
        let icon = if self.theme == Theme::Dark { "●" } else { "○" };
        format!("({} {})", icon, self.label)
    }
}

#[derive(Debug, Clone)]
pub struct MacOSTextField {
    placeholder: String,
    theme: Theme,
    value: String,
}

impl MacOSTextField {
    pub fn new(placeholder: &str, theme: Theme) -> Self {
        Self {
            placeholder: placeholder.to_string(),
            theme,
            value: String::new(),
        }
    }
}

impl TextField for MacOSTextField {
    fn placeholder(&self) -> &str {
        &self.placeholder
    }

    fn theme(&self) -> Theme {
        self.theme
    }

    fn render(&self) -> String {
        let content = if self.value.is_empty() {
            &self.placeholder
        } else {
            &self.value
        };
        format!("⌊{}⌋", content)
    }

    fn value(&self) -> &str {
        &self.value
    }

    fn set_value(&self, new_value: &str) -> Self {
        Self {
            value: new_value.to_string(),
            ..self.clone()
        }
    }
}

#[derive(Debug, Clone)]
pub struct MacOSCheckbox {
    label: String,
    checked: bool,
    theme: Theme,
}

impl MacOSCheckbox {
    pub fn new(label: &str, checked: bool, theme: Theme) -> Self {
        Self {
            label: label.to_string(),
            checked,
            theme,
        }
    }
}

impl Checkbox for MacOSCheckbox {
    fn label(&self) -> &str {
        &self.label
    }

    fn checked(&self) -> bool {
        self.checked
    }

    fn theme(&self) -> Theme {
        self.theme
    }

    fn render(&self) -> String {
        let mark = if self.checked { "✓" } else { " " };
        format!("({}) {}", mark, self.label)
    }

    fn toggle(&self) -> Self {
        Self {
            checked: !self.checked,
            ..self.clone()
        }
    }
}

// ============================================
// 9. Web UI 実装
// ============================================

#[derive(Debug, Clone)]
pub struct WebButton {
    label: String,
    theme: Theme,
}

impl WebButton {
    pub fn new(label: &str, theme: Theme) -> Self {
        Self {
            label: label.to_string(),
            theme,
        }
    }
}

impl Button for WebButton {
    fn label(&self) -> &str {
        &self.label
    }

    fn theme(&self) -> Theme {
        self.theme
    }

    fn render(&self) -> String {
        let bg_color = if self.theme == Theme::Dark { "#333" } else { "#fff" };
        format!(r#"<button style="background:{}">{}</button>"#, bg_color, self.label)
    }
}

#[derive(Debug, Clone)]
pub struct WebTextField {
    placeholder: String,
    theme: Theme,
    value: String,
}

impl WebTextField {
    pub fn new(placeholder: &str, theme: Theme) -> Self {
        Self {
            placeholder: placeholder.to_string(),
            theme,
            value: String::new(),
        }
    }
}

impl TextField for WebTextField {
    fn placeholder(&self) -> &str {
        &self.placeholder
    }

    fn theme(&self) -> Theme {
        self.theme
    }

    fn render(&self) -> String {
        format!(
            r#"<input type="text" placeholder="{}" value="{}"/>"#,
            self.placeholder, self.value
        )
    }

    fn value(&self) -> &str {
        &self.value
    }

    fn set_value(&self, new_value: &str) -> Self {
        Self {
            value: new_value.to_string(),
            ..self.clone()
        }
    }
}

#[derive(Debug, Clone)]
pub struct WebCheckbox {
    label: String,
    checked: bool,
    theme: Theme,
}

impl WebCheckbox {
    pub fn new(label: &str, checked: bool, theme: Theme) -> Self {
        Self {
            label: label.to_string(),
            checked,
            theme,
        }
    }
}

impl Checkbox for WebCheckbox {
    fn label(&self) -> &str {
        &self.label
    }

    fn checked(&self) -> bool {
        self.checked
    }

    fn theme(&self) -> Theme {
        self.theme
    }

    fn render(&self) -> String {
        let checked_attr = if self.checked { " checked" } else { "" };
        format!(
            r#"<label><input type="checkbox"{}/>{}</label>"#,
            checked_attr, self.label
        )
    }

    fn toggle(&self) -> Self {
        Self {
            checked: !self.checked,
            ..self.clone()
        }
    }
}

// ============================================
// 10. UIFactory - Abstract Factory
// ============================================

/// UI ファクトリの抽象インターフェース
pub trait UIFactory {
    type Btn: Button;
    type Fld: TextField;
    type Chk: Checkbox;

    fn theme(&self) -> Theme;
    fn create_button(&self, label: &str) -> Self::Btn;
    fn create_text_field(&self, placeholder: &str) -> Self::Fld;
    fn create_checkbox(&self, label: &str, checked: bool) -> Self::Chk;
}

// ============================================
// 11. Concrete UI Factories
// ============================================

/// Windows UI ファクトリ
pub struct WindowsUIFactory {
    theme: Theme,
}

impl WindowsUIFactory {
    pub fn new(theme: Theme) -> Self {
        Self { theme }
    }

    pub fn light() -> Self {
        Self::new(Theme::Light)
    }

    pub fn dark() -> Self {
        Self::new(Theme::Dark)
    }
}

impl UIFactory for WindowsUIFactory {
    type Btn = WindowsButton;
    type Fld = WindowsTextField;
    type Chk = WindowsCheckbox;

    fn theme(&self) -> Theme {
        self.theme
    }

    fn create_button(&self, label: &str) -> WindowsButton {
        WindowsButton::new(label, self.theme)
    }

    fn create_text_field(&self, placeholder: &str) -> WindowsTextField {
        WindowsTextField::new(placeholder, self.theme)
    }

    fn create_checkbox(&self, label: &str, checked: bool) -> WindowsCheckbox {
        WindowsCheckbox::new(label, checked, self.theme)
    }
}

/// MacOS UI ファクトリ
pub struct MacOSUIFactory {
    theme: Theme,
}

impl MacOSUIFactory {
    pub fn new(theme: Theme) -> Self {
        Self { theme }
    }

    pub fn light() -> Self {
        Self::new(Theme::Light)
    }

    pub fn dark() -> Self {
        Self::new(Theme::Dark)
    }
}

impl UIFactory for MacOSUIFactory {
    type Btn = MacOSButton;
    type Fld = MacOSTextField;
    type Chk = MacOSCheckbox;

    fn theme(&self) -> Theme {
        self.theme
    }

    fn create_button(&self, label: &str) -> MacOSButton {
        MacOSButton::new(label, self.theme)
    }

    fn create_text_field(&self, placeholder: &str) -> MacOSTextField {
        MacOSTextField::new(placeholder, self.theme)
    }

    fn create_checkbox(&self, label: &str, checked: bool) -> MacOSCheckbox {
        MacOSCheckbox::new(label, checked, self.theme)
    }
}

/// Web UI ファクトリ
pub struct WebUIFactory {
    theme: Theme,
}

impl WebUIFactory {
    pub fn new(theme: Theme) -> Self {
        Self { theme }
    }

    pub fn light() -> Self {
        Self::new(Theme::Light)
    }

    pub fn dark() -> Self {
        Self::new(Theme::Dark)
    }
}

impl UIFactory for WebUIFactory {
    type Btn = WebButton;
    type Fld = WebTextField;
    type Chk = WebCheckbox;

    fn theme(&self) -> Theme {
        self.theme
    }

    fn create_button(&self, label: &str) -> WebButton {
        WebButton::new(label, self.theme)
    }

    fn create_text_field(&self, placeholder: &str) -> WebTextField {
        WebTextField::new(placeholder, self.theme)
    }

    fn create_checkbox(&self, label: &str, checked: bool) -> WebCheckbox {
        WebCheckbox::new(label, checked, self.theme)
    }
}

// ============================================
// 12. Database コンポーネント - Product
// ============================================

/// クエリ結果
#[derive(Debug, Clone)]
pub struct QueryResult {
    pub columns: Vec<String>,
    pub rows: Vec<Vec<String>>,
    pub affected_rows: usize,
}

impl QueryResult {
    pub fn new(columns: Vec<String>, rows: Vec<Vec<String>>, affected_rows: usize) -> Self {
        Self {
            columns,
            rows,
            affected_rows,
        }
    }
}

/// データベース接続トレイト
pub trait Connection: Clone {
    fn database(&self) -> &str;
    fn is_connected(&self) -> bool;
    fn connect(&self) -> Self;
    fn disconnect(&self) -> Self;
    fn execute(&self, sql: &str) -> QueryResult;
}

/// クエリビルダートレイト
pub trait QueryBuilder {
    fn select(self, columns: &[&str]) -> Self;
    fn from(self, table: &str) -> Self;
    fn where_clause(self, condition: &str) -> Self;
    fn order_by(self, column: &str, ascending: bool) -> Self;
    fn limit(self, n: usize) -> Self;
    fn build(&self) -> String;
}

// ============================================
// 13. PostgreSQL 実装
// ============================================

#[derive(Debug, Clone)]
pub struct PostgreSQLConnection {
    database: String,
    connected: bool,
}

impl PostgreSQLConnection {
    pub fn new(database: &str) -> Self {
        Self {
            database: database.to_string(),
            connected: false,
        }
    }
}

impl Connection for PostgreSQLConnection {
    fn database(&self) -> &str {
        &self.database
    }

    fn is_connected(&self) -> bool {
        self.connected
    }

    fn connect(&self) -> Self {
        Self {
            connected: true,
            ..self.clone()
        }
    }

    fn disconnect(&self) -> Self {
        Self {
            connected: false,
            ..self.clone()
        }
    }

    fn execute(&self, sql: &str) -> QueryResult {
        QueryResult::new(
            vec!["result".to_string()],
            vec![vec![format!("PostgreSQL: {}", sql)]],
            1,
        )
    }
}

#[derive(Debug, Clone, Default)]
pub struct PostgreSQLQueryBuilder {
    select_cols: Vec<String>,
    from_table: String,
    where_clause: Option<String>,
    order_by_clause: Option<(String, bool)>,
    limit_clause: Option<usize>,
}

impl PostgreSQLQueryBuilder {
    pub fn new() -> Self {
        Self {
            select_cols: vec!["*".to_string()],
            ..Default::default()
        }
    }
}

impl QueryBuilder for PostgreSQLQueryBuilder {
    fn select(mut self, columns: &[&str]) -> Self {
        self.select_cols = columns.iter().map(|s| s.to_string()).collect();
        self
    }

    fn from(mut self, table: &str) -> Self {
        self.from_table = table.to_string();
        self
    }

    fn where_clause(mut self, condition: &str) -> Self {
        self.where_clause = Some(condition.to_string());
        self
    }

    fn order_by(mut self, column: &str, ascending: bool) -> Self {
        self.order_by_clause = Some((column.to_string(), ascending));
        self
    }

    fn limit(mut self, n: usize) -> Self {
        self.limit_clause = Some(n);
        self
    }

    fn build(&self) -> String {
        let mut query = format!(
            "SELECT {} FROM {}",
            self.select_cols.join(", "),
            self.from_table
        );

        if let Some(ref cond) = self.where_clause {
            query.push_str(&format!(" WHERE {}", cond));
        }

        if let Some((ref col, asc)) = self.order_by_clause {
            let order = if asc { "ASC" } else { "DESC" };
            query.push_str(&format!(" ORDER BY {} {}", col, order));
        }

        if let Some(n) = self.limit_clause {
            query.push_str(&format!(" LIMIT {}", n));
        }

        query
    }
}

// ============================================
// 14. MySQL 実装
// ============================================

#[derive(Debug, Clone)]
pub struct MySQLConnection {
    database: String,
    connected: bool,
}

impl MySQLConnection {
    pub fn new(database: &str) -> Self {
        Self {
            database: database.to_string(),
            connected: false,
        }
    }
}

impl Connection for MySQLConnection {
    fn database(&self) -> &str {
        &self.database
    }

    fn is_connected(&self) -> bool {
        self.connected
    }

    fn connect(&self) -> Self {
        Self {
            connected: true,
            ..self.clone()
        }
    }

    fn disconnect(&self) -> Self {
        Self {
            connected: false,
            ..self.clone()
        }
    }

    fn execute(&self, sql: &str) -> QueryResult {
        QueryResult::new(
            vec!["result".to_string()],
            vec![vec![format!("MySQL: {}", sql)]],
            1,
        )
    }
}

#[derive(Debug, Clone, Default)]
pub struct MySQLQueryBuilder {
    select_cols: Vec<String>,
    from_table: String,
    where_clause: Option<String>,
    order_by_clause: Option<(String, bool)>,
    limit_clause: Option<usize>,
}

impl MySQLQueryBuilder {
    pub fn new() -> Self {
        Self {
            select_cols: vec!["*".to_string()],
            ..Default::default()
        }
    }
}

impl QueryBuilder for MySQLQueryBuilder {
    fn select(mut self, columns: &[&str]) -> Self {
        self.select_cols = columns.iter().map(|s| s.to_string()).collect();
        self
    }

    fn from(mut self, table: &str) -> Self {
        // MySQL uses backticks
        self.from_table = format!("`{}`", table);
        self
    }

    fn where_clause(mut self, condition: &str) -> Self {
        self.where_clause = Some(condition.to_string());
        self
    }

    fn order_by(mut self, column: &str, ascending: bool) -> Self {
        self.order_by_clause = Some((column.to_string(), ascending));
        self
    }

    fn limit(mut self, n: usize) -> Self {
        self.limit_clause = Some(n);
        self
    }

    fn build(&self) -> String {
        let mut query = format!(
            "SELECT {} FROM {}",
            self.select_cols.join(", "),
            self.from_table
        );

        if let Some(ref cond) = self.where_clause {
            query.push_str(&format!(" WHERE {}", cond));
        }

        if let Some((ref col, asc)) = self.order_by_clause {
            let order = if asc { "ASC" } else { "DESC" };
            query.push_str(&format!(" ORDER BY {} {}", col, order));
        }

        if let Some(n) = self.limit_clause {
            query.push_str(&format!(" LIMIT {}", n));
        }

        query
    }
}

// ============================================
// 15. SQLite 実装
// ============================================

#[derive(Debug, Clone)]
pub struct SQLiteConnection {
    database: String,
    connected: bool,
}

impl SQLiteConnection {
    pub fn new(database: &str) -> Self {
        Self {
            database: database.to_string(),
            connected: false,
        }
    }
}

impl Connection for SQLiteConnection {
    fn database(&self) -> &str {
        &self.database
    }

    fn is_connected(&self) -> bool {
        self.connected
    }

    fn connect(&self) -> Self {
        Self {
            connected: true,
            ..self.clone()
        }
    }

    fn disconnect(&self) -> Self {
        Self {
            connected: false,
            ..self.clone()
        }
    }

    fn execute(&self, sql: &str) -> QueryResult {
        QueryResult::new(
            vec!["result".to_string()],
            vec![vec![format!("SQLite: {}", sql)]],
            1,
        )
    }
}

#[derive(Debug, Clone, Default)]
pub struct SQLiteQueryBuilder {
    select_cols: Vec<String>,
    from_table: String,
    where_clause: Option<String>,
    order_by_clause: Option<(String, bool)>,
    limit_clause: Option<usize>,
}

impl SQLiteQueryBuilder {
    pub fn new() -> Self {
        Self {
            select_cols: vec!["*".to_string()],
            ..Default::default()
        }
    }
}

impl QueryBuilder for SQLiteQueryBuilder {
    fn select(mut self, columns: &[&str]) -> Self {
        self.select_cols = columns.iter().map(|s| s.to_string()).collect();
        self
    }

    fn from(mut self, table: &str) -> Self {
        self.from_table = table.to_string();
        self
    }

    fn where_clause(mut self, condition: &str) -> Self {
        self.where_clause = Some(condition.to_string());
        self
    }

    fn order_by(mut self, column: &str, ascending: bool) -> Self {
        self.order_by_clause = Some((column.to_string(), ascending));
        self
    }

    fn limit(mut self, n: usize) -> Self {
        self.limit_clause = Some(n);
        self
    }

    fn build(&self) -> String {
        let mut query = format!(
            "SELECT {} FROM {}",
            self.select_cols.join(", "),
            self.from_table
        );

        if let Some(ref cond) = self.where_clause {
            query.push_str(&format!(" WHERE {}", cond));
        }

        if let Some((ref col, asc)) = self.order_by_clause {
            let order = if asc { "ASC" } else { "DESC" };
            query.push_str(&format!(" ORDER BY {} {}", col, order));
        }

        if let Some(n) = self.limit_clause {
            query.push_str(&format!(" LIMIT {}", n));
        }

        query
    }
}

// ============================================
// 16. DatabaseFactory - Abstract Factory
// ============================================

/// データベースファクトリの抽象インターフェース
pub trait DatabaseFactory {
    type Conn: Connection;
    type QB: QueryBuilder;

    fn create_connection(&self, database: &str) -> Self::Conn;
    fn create_query_builder(&self) -> Self::QB;
    fn database_type(&self) -> &'static str;
}

/// PostgreSQL ファクトリ
pub struct PostgreSQLFactory;

impl DatabaseFactory for PostgreSQLFactory {
    type Conn = PostgreSQLConnection;
    type QB = PostgreSQLQueryBuilder;

    fn create_connection(&self, database: &str) -> PostgreSQLConnection {
        PostgreSQLConnection::new(database)
    }

    fn create_query_builder(&self) -> PostgreSQLQueryBuilder {
        PostgreSQLQueryBuilder::new()
    }

    fn database_type(&self) -> &'static str {
        "PostgreSQL"
    }
}

/// MySQL ファクトリ
pub struct MySQLFactory;

impl DatabaseFactory for MySQLFactory {
    type Conn = MySQLConnection;
    type QB = MySQLQueryBuilder;

    fn create_connection(&self, database: &str) -> MySQLConnection {
        MySQLConnection::new(database)
    }

    fn create_query_builder(&self) -> MySQLQueryBuilder {
        MySQLQueryBuilder::new()
    }

    fn database_type(&self) -> &'static str {
        "MySQL"
    }
}

/// SQLite ファクトリ
pub struct SQLiteFactory;

impl DatabaseFactory for SQLiteFactory {
    type Conn = SQLiteConnection;
    type QB = SQLiteQueryBuilder;

    fn create_connection(&self, database: &str) -> SQLiteConnection {
        SQLiteConnection::new(database)
    }

    fn create_query_builder(&self) -> SQLiteQueryBuilder {
        SQLiteQueryBuilder::new()
    }

    fn database_type(&self) -> &'static str {
        "SQLite"
    }
}

// ============================================
// 17. 関数型アプローチ
// ============================================

pub mod functional {
    use super::*;

    /// ファクトリ設定
    #[derive(Debug, Clone, Copy)]
    pub struct FactoryConfig {
        pub stroke_color: Color,
        pub stroke_width: f64,
        pub fill_color: Color,
    }

    impl Default for FactoryConfig {
        fn default() -> Self {
            Self {
                stroke_color: Color::BLACK,
                stroke_width: 1.0,
                fill_color: Color::TRANSPARENT,
            }
        }
    }

    impl FactoryConfig {
        pub fn new() -> Self {
            Self::default()
        }

        pub fn style(&self) -> ShapeStyle {
            ShapeStyle::new(self.stroke_color, self.stroke_width, self.fill_color)
        }
    }

    /// 図形作成関数を生成
    pub fn circle_creator(config: &FactoryConfig) -> impl Fn(Point, f64) -> Circle + '_ {
        move |center, radius| Circle::with_style_new(center, radius, config.style())
    }

    pub fn square_creator(config: &FactoryConfig) -> impl Fn(Point, f64) -> Square + '_ {
        move |top_left, side| Square::with_style_new(top_left, side, config.style())
    }

    pub fn rectangle_creator(config: &FactoryConfig) -> impl Fn(Point, f64, f64) -> Rectangle + '_ {
        move |top_left, width, height| Rectangle::with_style_new(top_left, width, height, config.style())
    }

    /// ファクトリを合成
    pub fn compose_factory(
        base_config: FactoryConfig,
        modifiers: &[fn(FactoryConfig) -> FactoryConfig],
    ) -> FactoryConfig {
        modifiers
            .iter()
            .fold(base_config, |config, modifier| modifier(config))
    }

    /// 修飾子
    pub fn with_stroke(color: Color, width: f64) -> impl Fn(FactoryConfig) -> FactoryConfig {
        move |config| FactoryConfig {
            stroke_color: color,
            stroke_width: width,
            ..config
        }
    }

    pub fn with_fill(color: Color) -> impl Fn(FactoryConfig) -> FactoryConfig {
        move |config| FactoryConfig {
            fill_color: color,
            ..config
        }
    }
}

// ============================================
// テスト
// ============================================

#[cfg(test)]
mod tests {
    use super::*;
    use super::functional::*;

    // ============================================
    // 1. Shape 基本テスト
    // ============================================

    mod shape_tests {
        use super::*;

        #[test]
        fn circle_translate_moves_center() {
            let circle = Circle::new(Point::new(10.0, 20.0), 5.0);
            let moved = circle.translate(5.0, 10.0);
            assert_eq!(moved.center, Point::new(15.0, 30.0));
        }

        #[test]
        fn circle_scale_increases_radius() {
            let circle = Circle::new(Point::new(10.0, 20.0), 5.0);
            let scaled = circle.scale(2.0);
            assert_eq!(scaled.radius, 10.0);
        }

        #[test]
        fn circle_with_style_changes_style() {
            let circle = Circle::new(Point::new(10.0, 20.0), 5.0);
            let new_style = ShapeStyle::new(Color::RED, 2.0, Color::BLUE);
            let styled = circle.with_style(new_style);
            assert_eq!(styled.style, new_style);
        }

        #[test]
        fn square_translate_moves_top_left() {
            let square = Square::new(Point::new(0.0, 0.0), 10.0);
            let moved = square.translate(5.0, 5.0);
            assert_eq!(moved.top_left, Point::new(5.0, 5.0));
        }

        #[test]
        fn square_scale_increases_side() {
            let square = Square::new(Point::new(0.0, 0.0), 10.0);
            let scaled = square.scale(2.0);
            assert_eq!(scaled.side, 20.0);
        }

        #[test]
        fn rectangle_scale_increases_dimensions() {
            let rect = Rectangle::new(Point::new(0.0, 0.0), 10.0, 20.0);
            let scaled = rect.scale(2.0);
            assert_eq!(scaled.width, 20.0);
            assert_eq!(scaled.height, 40.0);
        }
    }

    // ============================================
    // 2. ShapeFactory テスト
    // ============================================

    mod shape_factory_tests {
        use super::*;

        #[test]
        fn standard_factory_creates_circle() {
            let factory = StandardShapeFactory;
            let circle = factory.create_circle(Point::new(10.0, 20.0), 5.0);
            assert_eq!(circle.center, Point::new(10.0, 20.0));
            assert_eq!(circle.radius, 5.0);
            assert_eq!(circle.style, ShapeStyle::default());
        }

        #[test]
        fn standard_factory_creates_square() {
            let factory = StandardShapeFactory;
            let square = factory.create_square(Point::new(0.0, 0.0), 10.0);
            assert_eq!(square.top_left, Point::new(0.0, 0.0));
            assert_eq!(square.side, 10.0);
        }

        #[test]
        fn standard_factory_creates_rectangle() {
            let factory = StandardShapeFactory;
            let rect = factory.create_rectangle(Point::new(0.0, 0.0), 10.0, 20.0);
            assert_eq!(rect.width, 10.0);
            assert_eq!(rect.height, 20.0);
        }

        #[test]
        fn standard_factory_creates_triangle() {
            let factory = StandardShapeFactory;
            let triangle = factory.create_triangle(
                Point::new(0.0, 0.0),
                Point::new(10.0, 0.0),
                Point::new(5.0, 10.0),
            );
            assert_eq!(triangle.p1, Point::new(0.0, 0.0));
        }

        #[test]
        fn outlined_factory_creates_circle_with_stroke() {
            let factory = OutlinedShapeFactory::new(Color::RED, 3.0);
            let circle = factory.create_circle(Point::new(10.0, 20.0), 5.0);
            assert_eq!(circle.style.stroke_color, Color::RED);
            assert_eq!(circle.style.stroke_width, 3.0);
        }

        #[test]
        fn outlined_factory_creates_square_with_stroke() {
            let factory = OutlinedShapeFactory::new(Color::RED, 3.0);
            let square = factory.create_square(Point::new(0.0, 0.0), 10.0);
            assert_eq!(square.style.stroke_color, Color::RED);
            assert_eq!(square.style.stroke_width, 3.0);
        }

        #[test]
        fn filled_factory_creates_circle_with_fill() {
            let factory = FilledShapeFactory::new(Color::BLUE);
            let circle = factory.create_circle(Point::new(10.0, 20.0), 5.0);
            assert_eq!(circle.style.fill_color, Color::BLUE);
        }

        #[test]
        fn filled_factory_creates_shape_with_stroke_and_fill() {
            let factory = FilledShapeFactory::with_stroke(Color::GREEN, Color::RED, 2.0);
            let rect = factory.create_rectangle(Point::new(0.0, 0.0), 10.0, 20.0);
            assert_eq!(rect.style.fill_color, Color::GREEN);
            assert_eq!(rect.style.stroke_color, Color::RED);
            assert_eq!(rect.style.stroke_width, 2.0);
        }

        #[test]
        fn factory_switching_standard() {
            fn create_shapes(factory: &dyn ShapeFactory) -> Vec<ShapeStyle> {
                vec![
                    factory.create_circle(Point::new(0.0, 0.0), 5.0).style,
                    factory.create_square(Point::new(10.0, 10.0), 10.0).style,
                    factory.create_rectangle(Point::new(20.0, 20.0), 10.0, 5.0).style,
                ]
            }

            let shapes = create_shapes(&StandardShapeFactory);
            assert_eq!(shapes.len(), 3);
            assert_eq!(shapes[0], ShapeStyle::default());
        }

        #[test]
        fn factory_switching_outlined() {
            fn create_shapes(factory: &dyn ShapeFactory) -> Vec<ShapeStyle> {
                vec![
                    factory.create_circle(Point::new(0.0, 0.0), 5.0).style,
                    factory.create_square(Point::new(10.0, 10.0), 10.0).style,
                    factory.create_rectangle(Point::new(20.0, 20.0), 10.0, 5.0).style,
                ]
            }

            let shapes = create_shapes(&OutlinedShapeFactory::new(Color::BLACK, 2.0));
            assert_eq!(shapes.len(), 3);
            assert_eq!(shapes[0].stroke_width, 2.0);
        }

        #[test]
        fn factory_switching_filled() {
            fn create_shapes(factory: &dyn ShapeFactory) -> Vec<ShapeStyle> {
                vec![
                    factory.create_circle(Point::new(0.0, 0.0), 5.0).style,
                    factory.create_square(Point::new(10.0, 10.0), 10.0).style,
                    factory.create_rectangle(Point::new(20.0, 20.0), 10.0, 5.0).style,
                ]
            }

            let shapes = create_shapes(&FilledShapeFactory::new(Color::RED));
            assert_eq!(shapes.len(), 3);
            assert_eq!(shapes[0].fill_color, Color::RED);
        }
    }

    // ============================================
    // 3. UIFactory テスト
    // ============================================

    mod ui_factory_tests {
        use super::*;

        #[test]
        fn windows_factory_creates_button() {
            let factory = WindowsUIFactory::light();
            let button = factory.create_button("OK");
            assert_eq!(button.label(), "OK");
            assert!(button.render().contains("OK"));
            assert!(button.render().contains("["));
        }

        #[test]
        fn windows_factory_creates_text_field() {
            let factory = WindowsUIFactory::light();
            let field = factory.create_text_field("Name");
            assert_eq!(field.placeholder(), "Name");
            assert!(field.render().contains("|"));
        }

        #[test]
        fn windows_factory_creates_checkbox() {
            let factory = WindowsUIFactory::light();
            let checkbox = factory.create_checkbox("Accept", false);
            assert_eq!(checkbox.label(), "Accept");
            assert!(!checkbox.checked());
            assert!(checkbox.render().contains("[ ]"));

            let toggled = checkbox.toggle();
            assert!(toggled.checked());
            assert!(toggled.render().contains("[X]"));
        }

        #[test]
        fn windows_factory_supports_dark_theme() {
            let factory = WindowsUIFactory::dark();
            let button = factory.create_button("Dark");
            assert_eq!(button.theme(), Theme::Dark);
        }

        #[test]
        fn macos_factory_creates_button() {
            let factory = MacOSUIFactory::light();
            let button = factory.create_button("OK");
            assert!(button.render().contains("("));
            assert!(button.render().contains(")"));
        }

        #[test]
        fn macos_factory_creates_checkbox() {
            let factory = MacOSUIFactory::light();
            let checkbox = factory.create_checkbox("Accept", true);
            assert!(checkbox.render().contains("(✓)"));
        }

        #[test]
        fn web_factory_creates_button() {
            let factory = WebUIFactory::light();
            let button = factory.create_button("Submit");
            assert!(button.render().contains("<button"));
            assert!(button.render().contains("Submit"));
            assert!(button.render().contains("</button>"));
        }

        #[test]
        fn web_factory_creates_text_field() {
            let factory = WebUIFactory::light();
            let field = factory.create_text_field("Email");
            assert!(field.render().contains("<input"));
            assert!(field.render().contains(r#"placeholder="Email""#));
        }

        #[test]
        fn web_factory_creates_checkbox() {
            let factory = WebUIFactory::light();
            let checkbox = factory.create_checkbox("Subscribe", false);
            assert!(checkbox.render().contains(r#"<input type="checkbox""#));
            assert!(checkbox.render().contains("<label>"));
        }

        #[test]
        fn web_text_field_can_set_value() {
            let factory = WebUIFactory::light();
            let field = factory.create_text_field("Name");
            let updated = field.set_value("John");
            assert_eq!(updated.value(), "John");
            assert!(updated.render().contains(r#"value="John""#));
        }
    }

    // ============================================
    // 4. DatabaseFactory テスト
    // ============================================

    mod database_factory_tests {
        use super::*;

        #[test]
        fn postgresql_factory_creates_connection() {
            let factory = PostgreSQLFactory;
            let conn = factory.create_connection("mydb");
            assert_eq!(conn.database(), "mydb");
            assert!(!conn.is_connected());

            let connected = conn.connect();
            assert!(connected.is_connected());
        }

        #[test]
        fn postgresql_factory_creates_query_builder() {
            let factory = PostgreSQLFactory;
            let query = factory
                .create_query_builder()
                .select(&["id", "name"])
                .from("users")
                .where_clause("active = true")
                .order_by("name", true)
                .limit(10)
                .build();

            assert_eq!(
                query,
                "SELECT id, name FROM users WHERE active = true ORDER BY name ASC LIMIT 10"
            );
        }

        #[test]
        fn postgresql_factory_returns_database_type() {
            let factory = PostgreSQLFactory;
            assert_eq!(factory.database_type(), "PostgreSQL");
        }

        #[test]
        fn mysql_factory_creates_query_builder_with_backticks() {
            let factory = MySQLFactory;
            let query = factory
                .create_query_builder()
                .select(&["id", "name"])
                .from("users")
                .build();

            assert!(query.contains("`users`"));
        }

        #[test]
        fn sqlite_factory_creates_connection() {
            let factory = SQLiteFactory;
            let conn = factory.create_connection("test.db");
            assert_eq!(conn.database(), "test.db");
        }

        #[test]
        fn sqlite_executes_query() {
            let factory = SQLiteFactory;
            let conn = factory.create_connection("test.db").connect();
            let result = conn.execute("SELECT 1");
            assert!(result.rows[0][0].contains("SQLite"));
        }

        #[test]
        fn database_factory_switching() {
            fn execute_query<F: DatabaseFactory>(factory: &F, db: &str) -> QueryResult {
                let conn = factory.create_connection(db).connect();
                let query = factory
                    .create_query_builder()
                    .select(&["*"])
                    .from("users")
                    .build();
                conn.execute(&query)
            }

            let pg_result = execute_query(&PostgreSQLFactory, "pg_db");
            let mysql_result = execute_query(&MySQLFactory, "mysql_db");
            let sqlite_result = execute_query(&SQLiteFactory, "sqlite.db");

            assert!(pg_result.rows[0][0].contains("PostgreSQL"));
            assert!(mysql_result.rows[0][0].contains("MySQL"));
            assert!(sqlite_result.rows[0][0].contains("SQLite"));
        }
    }

    // ============================================
    // 5. 関数型アプローチ
    // ============================================

    mod functional_factory_tests {
        use super::*;

        #[test]
        fn config_creates_style() {
            let config = FactoryConfig {
                stroke_color: Color::RED,
                stroke_width: 2.0,
                fill_color: Color::BLUE,
            };
            let style = config.style();
            assert_eq!(style.stroke_color, Color::RED);
            assert_eq!(style.stroke_width, 2.0);
            assert_eq!(style.fill_color, Color::BLUE);
        }

        #[test]
        fn circle_creator_creates_circle() {
            let config = FactoryConfig {
                fill_color: Color::GREEN,
                ..Default::default()
            };
            let create_circle = circle_creator(&config);

            let circle = create_circle(Point::new(10.0, 20.0), 5.0);
            assert_eq!(circle.center, Point::new(10.0, 20.0));
            assert_eq!(circle.style.fill_color, Color::GREEN);
        }

        #[test]
        fn compose_factory_applies_modifiers() {
            fn stroke_modifier(config: FactoryConfig) -> FactoryConfig {
                FactoryConfig {
                    stroke_color: Color::RED,
                    stroke_width: 2.0,
                    ..config
                }
            }

            fn fill_modifier(config: FactoryConfig) -> FactoryConfig {
                FactoryConfig {
                    fill_color: Color::BLUE,
                    ..config
                }
            }

            let config = compose_factory(FactoryConfig::default(), &[stroke_modifier, fill_modifier]);

            assert_eq!(config.stroke_color, Color::RED);
            assert_eq!(config.stroke_width, 2.0);
            assert_eq!(config.fill_color, Color::BLUE);
        }

        #[test]
        fn composed_factory_creates_shapes() {
            fn stroke_modifier(config: FactoryConfig) -> FactoryConfig {
                FactoryConfig {
                    stroke_color: Color::BLACK,
                    stroke_width: 3.0,
                    ..config
                }
            }

            fn fill_modifier(config: FactoryConfig) -> FactoryConfig {
                FactoryConfig {
                    fill_color: Color::GREEN,
                    ..config
                }
            }

            let config = compose_factory(FactoryConfig::default(), &[stroke_modifier, fill_modifier]);
            let create_square = square_creator(&config);

            let square = create_square(Point::new(0.0, 0.0), 10.0);
            assert_eq!(square.style.stroke_color, Color::BLACK);
            assert_eq!(square.style.stroke_width, 3.0);
            assert_eq!(square.style.fill_color, Color::GREEN);
        }
    }
}
