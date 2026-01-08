//! 第3章: 多態性の実現方法
//!
//! 同じインターフェースで異なる振る舞いを実現する多態性について学びます。
//! Rust では enum、trait、ジェネリクスで多態性を実現します。

// =============================================================================
// 1. Enum による多態性（代数的データ型）
// =============================================================================

/// 図形を表す enum
#[derive(Debug, Clone, PartialEq)]
pub enum Shape {
    Rectangle { width: f64, height: f64 },
    Circle { radius: f64 },
    Triangle { base: f64, height: f64 },
}

impl Shape {
    /// 図形の面積を計算する
    pub fn area(&self) -> f64 {
        match self {
            Shape::Rectangle { width, height } => width * height,
            Shape::Circle { radius } => std::f64::consts::PI * radius * radius,
            Shape::Triangle { base, height } => base * height / 2.0,
        }
    }

    /// 図形の名前を取得する
    pub fn name(&self) -> &str {
        match self {
            Shape::Rectangle { .. } => "rectangle",
            Shape::Circle { .. } => "circle",
            Shape::Triangle { .. } => "triangle",
        }
    }
}

// =============================================================================
// 2. 複合ディスパッチ
// =============================================================================

/// 支払い方法
#[derive(Debug, Clone, PartialEq)]
pub enum PaymentMethod {
    CreditCard,
    BankTransfer,
    Cash,
}

/// 通貨
#[derive(Debug, Clone, PartialEq)]
pub enum Currency {
    JPY,
    USD,
    EUR,
}

/// 支払い
#[derive(Debug, Clone, PartialEq)]
pub struct Payment {
    pub method: PaymentMethod,
    pub currency: Currency,
    pub amount: i32,
}

/// 支払い結果
#[derive(Debug, Clone, PartialEq)]
pub struct PaymentResult {
    pub status: String,
    pub message: String,
    pub amount: i32,
    pub converted: Option<i32>,
}

impl Payment {
    pub fn new(method: PaymentMethod, currency: Currency, amount: i32) -> Self {
        Payment {
            method,
            currency,
            amount,
        }
    }

    /// 支払いを処理する（複合ディスパッチ）
    pub fn process(&self) -> PaymentResult {
        match (&self.method, &self.currency) {
            (PaymentMethod::CreditCard, Currency::JPY) => PaymentResult {
                status: "processed".to_string(),
                message: "クレジットカード（円）で処理しました".to_string(),
                amount: self.amount,
                converted: None,
            },
            (PaymentMethod::CreditCard, Currency::USD) => PaymentResult {
                status: "processed".to_string(),
                message: "Credit card (USD) processed".to_string(),
                amount: self.amount,
                converted: Some(self.amount * 150),
            },
            (PaymentMethod::BankTransfer, Currency::JPY) => PaymentResult {
                status: "pending".to_string(),
                message: "銀行振込を受け付けました".to_string(),
                amount: self.amount,
                converted: None,
            },
            _ => PaymentResult {
                status: "error".to_string(),
                message: "サポートされていない支払い方法です".to_string(),
                amount: self.amount,
                converted: None,
            },
        }
    }
}

// =============================================================================
// 3. 階層的ディスパッチ（Trait による）
// =============================================================================

/// 口座の共通トレイト
pub trait Account {
    fn balance(&self) -> i32;
    fn interest_rate(&self) -> f64;

    fn calculate_interest(&self) -> f64 {
        self.balance() as f64 * self.interest_rate()
    }
}

/// 普通預金口座
#[derive(Debug, Clone, PartialEq)]
pub struct SavingsAccount {
    pub balance: i32,
}

impl Account for SavingsAccount {
    fn balance(&self) -> i32 {
        self.balance
    }

    fn interest_rate(&self) -> f64 {
        0.02
    }
}

/// プレミアム普通預金口座
#[derive(Debug, Clone, PartialEq)]
pub struct PremiumSavingsAccount {
    pub balance: i32,
}

impl Account for PremiumSavingsAccount {
    fn balance(&self) -> i32 {
        self.balance
    }

    fn interest_rate(&self) -> f64 {
        0.05
    }
}

/// 当座預金口座
#[derive(Debug, Clone, PartialEq)]
pub struct CheckingAccount {
    pub balance: i32,
}

impl Account for CheckingAccount {
    fn balance(&self) -> i32 {
        self.balance
    }

    fn interest_rate(&self) -> f64 {
        0.001
    }
}

// =============================================================================
// 4. Trait（Protocol に相当）
// =============================================================================

/// バウンディングボックス
#[derive(Debug, Clone, PartialEq)]
pub struct BoundingBox {
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
}

/// 描画可能なオブジェクトのトレイト
pub trait Drawable {
    fn draw(&self) -> String;
    fn bounding_box(&self) -> BoundingBox;
}

/// 変換可能なオブジェクトのトレイト
pub trait Transformable: Sized {
    fn translate(&self, dx: f64, dy: f64) -> Self;
    fn scale(&self, factor: f64) -> Self;
    fn rotate(&self, angle: f64) -> Self;
}

// =============================================================================
// 5. Trait を実装する構造体
// =============================================================================

/// 描画可能な長方形
#[derive(Debug, Clone, PartialEq)]
pub struct DrawableRectangle {
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
}

impl DrawableRectangle {
    pub fn new(x: f64, y: f64, width: f64, height: f64) -> Self {
        DrawableRectangle {
            x,
            y,
            width,
            height,
        }
    }
}

impl Drawable for DrawableRectangle {
    fn draw(&self) -> String {
        format!(
            "Rectangle at ({},{}) with size {}x{}",
            self.x, self.y, self.width, self.height
        )
    }

    fn bounding_box(&self) -> BoundingBox {
        BoundingBox {
            x: self.x,
            y: self.y,
            width: self.width,
            height: self.height,
        }
    }
}

impl Transformable for DrawableRectangle {
    fn translate(&self, dx: f64, dy: f64) -> Self {
        DrawableRectangle {
            x: self.x + dx,
            y: self.y + dy,
            ..*self
        }
    }

    fn scale(&self, factor: f64) -> Self {
        DrawableRectangle {
            width: self.width * factor,
            height: self.height * factor,
            ..*self
        }
    }

    fn rotate(&self, _angle: f64) -> Self {
        self.clone()
    }
}

/// 描画可能な円
#[derive(Debug, Clone, PartialEq)]
pub struct DrawableCircle {
    pub x: f64,
    pub y: f64,
    pub radius: f64,
}

impl DrawableCircle {
    pub fn new(x: f64, y: f64, radius: f64) -> Self {
        DrawableCircle { x, y, radius }
    }
}

impl Drawable for DrawableCircle {
    fn draw(&self) -> String {
        format!("Circle at ({},{}) with radius {}", self.x, self.y, self.radius)
    }

    fn bounding_box(&self) -> BoundingBox {
        BoundingBox {
            x: self.x - self.radius,
            y: self.y - self.radius,
            width: self.radius * 2.0,
            height: self.radius * 2.0,
        }
    }
}

impl Transformable for DrawableCircle {
    fn translate(&self, dx: f64, dy: f64) -> Self {
        DrawableCircle {
            x: self.x + dx,
            y: self.y + dy,
            ..*self
        }
    }

    fn scale(&self, factor: f64) -> Self {
        DrawableCircle {
            radius: self.radius * factor,
            ..*self
        }
    }

    fn rotate(&self, _angle: f64) -> Self {
        self.clone()
    }
}

// =============================================================================
// 6. 既存型への拡張（Extension Trait）
// =============================================================================

/// 文字列に変換可能なトレイト
pub trait Stringable {
    fn to_custom_string(&self) -> String;
}

impl Stringable for std::collections::HashMap<String, String> {
    fn to_custom_string(&self) -> String {
        let parts: Vec<String> = self.iter().map(|(k, v)| format!("{}: {}", k, v)).collect();
        format!("{{{}}}", parts.join(", "))
    }
}

impl<T: std::fmt::Display> Stringable for Vec<T> {
    fn to_custom_string(&self) -> String {
        let parts: Vec<String> = self.iter().map(|x| x.to_string()).collect();
        format!("[{}]", parts.join(", "))
    }
}

impl Stringable for String {
    fn to_custom_string(&self) -> String {
        self.clone()
    }
}

impl Stringable for i32 {
    fn to_custom_string(&self) -> String {
        self.to_string()
    }
}

impl<T: Stringable> Stringable for Option<T> {
    fn to_custom_string(&self) -> String {
        match self {
            Some(v) => v.to_custom_string(),
            None => "nil".to_string(),
        }
    }
}

// =============================================================================
// 7. コンポーネントパターン
// =============================================================================

/// ライフサイクル管理トレイト
pub trait Lifecycle: Sized {
    fn start(self) -> Self;
    fn stop(self) -> Self;
}

/// データベース接続
#[derive(Debug, Clone, PartialEq)]
pub struct DatabaseConnection {
    pub host: String,
    pub port: u16,
    pub connected: bool,
}

impl DatabaseConnection {
    pub fn new(host: &str, port: u16) -> Self {
        DatabaseConnection {
            host: host.to_string(),
            port,
            connected: false,
        }
    }
}

impl Lifecycle for DatabaseConnection {
    fn start(mut self) -> Self {
        println!("データベースに接続中: {} : {}", self.host, self.port);
        self.connected = true;
        self
    }

    fn stop(mut self) -> Self {
        println!("データベース接続を切断中");
        self.connected = false;
        self
    }
}

/// Web サーバー
#[derive(Debug, Clone, PartialEq)]
pub struct WebServer {
    pub port: u16,
    pub db: DatabaseConnection,
    pub running: bool,
}

impl WebServer {
    pub fn new(port: u16, db: DatabaseConnection) -> Self {
        WebServer {
            port,
            db,
            running: false,
        }
    }
}

impl Lifecycle for WebServer {
    fn start(mut self) -> Self {
        println!("Webサーバーを起動中 ポート: {}", self.port);
        self.db = self.db.start();
        self.running = true;
        self
    }

    fn stop(mut self) -> Self {
        println!("Webサーバーを停止中");
        self.db = self.db.stop();
        self.running = false;
        self
    }
}

// =============================================================================
// 8. 条件分岐の置き換え（Strategy パターン）
// =============================================================================

/// 通知結果
#[derive(Debug, Clone, PartialEq)]
pub struct NotificationResult {
    pub notification_type: String,
    pub to: String,
    pub body: String,
    pub status: String,
    pub subject: Option<String>,
}

/// 通知送信トレイト
pub trait NotificationSender {
    fn send_notification(&self, message: &str) -> NotificationResult;
    fn delivery_time(&self) -> &str;
}

/// メール通知
#[derive(Debug, Clone, PartialEq)]
pub struct EmailNotification {
    pub to: String,
    pub subject: String,
}

impl EmailNotification {
    pub fn new(to: &str, subject: &str) -> Self {
        EmailNotification {
            to: to.to_string(),
            subject: subject.to_string(),
        }
    }
}

impl NotificationSender for EmailNotification {
    fn send_notification(&self, message: &str) -> NotificationResult {
        NotificationResult {
            notification_type: "email".to_string(),
            to: self.to.clone(),
            body: message.to_string(),
            status: "sent".to_string(),
            subject: Some(self.subject.clone()),
        }
    }

    fn delivery_time(&self) -> &str {
        "1-2分"
    }
}

/// SMS 通知
#[derive(Debug, Clone, PartialEq)]
pub struct SMSNotification {
    pub phone_number: String,
}

impl SMSNotification {
    pub fn new(phone_number: &str) -> Self {
        SMSNotification {
            phone_number: phone_number.to_string(),
        }
    }
}

impl NotificationSender for SMSNotification {
    fn send_notification(&self, message: &str) -> NotificationResult {
        let truncated = if message.len() > 160 {
            &message[..157]
        } else {
            message
        };
        NotificationResult {
            notification_type: "sms".to_string(),
            to: self.phone_number.clone(),
            body: truncated.to_string(),
            status: "sent".to_string(),
            subject: None,
        }
    }

    fn delivery_time(&self) -> &str {
        "数秒"
    }
}

/// プッシュ通知
#[derive(Debug, Clone, PartialEq)]
pub struct PushNotification {
    pub device_token: String,
}

impl PushNotification {
    pub fn new(device_token: &str) -> Self {
        PushNotification {
            device_token: device_token.to_string(),
        }
    }
}

impl NotificationSender for PushNotification {
    fn send_notification(&self, message: &str) -> NotificationResult {
        NotificationResult {
            notification_type: "push".to_string(),
            to: self.device_token.clone(),
            body: message.to_string(),
            status: "sent".to_string(),
            subject: None,
        }
    }

    fn delivery_time(&self) -> &str {
        "即時"
    }
}

/// 通知タイプから通知オブジェクトを作成するファクトリ
pub fn create_notification(
    notification_type: &str,
    to: &str,
    subject: Option<&str>,
) -> Result<Box<dyn NotificationSender>, String> {
    match notification_type {
        "email" => Ok(Box::new(EmailNotification::new(
            to,
            subject.unwrap_or("通知"),
        ))),
        "sms" => Ok(Box::new(SMSNotification::new(to))),
        "push" => Ok(Box::new(PushNotification::new(to))),
        _ => Err(format!("未知の通知タイプ: {}", notification_type)),
    }
}

// =============================================================================
// テスト
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    // -------------------------------------------------------------------------
    // Enum による多態性
    // -------------------------------------------------------------------------

    #[test]
    fn test_shape_area_rectangle() {
        let shape = Shape::Rectangle {
            width: 4.0,
            height: 5.0,
        };
        assert_eq!(shape.area(), 20.0);
    }

    #[test]
    fn test_shape_area_circle() {
        let shape = Shape::Circle { radius: 3.0 };
        let expected = std::f64::consts::PI * 9.0;
        assert!((shape.area() - expected).abs() < 0.0001);
    }

    #[test]
    fn test_shape_area_triangle() {
        let shape = Shape::Triangle {
            base: 6.0,
            height: 5.0,
        };
        assert_eq!(shape.area(), 15.0);
    }

    #[test]
    fn test_shape_name() {
        assert_eq!(
            Shape::Rectangle {
                width: 1.0,
                height: 1.0
            }
            .name(),
            "rectangle"
        );
        assert_eq!(Shape::Circle { radius: 1.0 }.name(), "circle");
        assert_eq!(
            Shape::Triangle {
                base: 1.0,
                height: 1.0
            }
            .name(),
            "triangle"
        );
    }

    // -------------------------------------------------------------------------
    // 複合ディスパッチ
    // -------------------------------------------------------------------------

    #[test]
    fn test_payment_credit_card_jpy() {
        let payment = Payment::new(PaymentMethod::CreditCard, Currency::JPY, 1000);
        let result = payment.process();
        assert_eq!(result.status, "processed");
        assert!(result.message.contains("クレジットカード"));
    }

    #[test]
    fn test_payment_credit_card_usd() {
        let payment = Payment::new(PaymentMethod::CreditCard, Currency::USD, 100);
        let result = payment.process();
        assert_eq!(result.status, "processed");
        assert_eq!(result.converted, Some(15000));
    }

    #[test]
    fn test_payment_bank_transfer_jpy() {
        let payment = Payment::new(PaymentMethod::BankTransfer, Currency::JPY, 5000);
        let result = payment.process();
        assert_eq!(result.status, "pending");
    }

    #[test]
    fn test_payment_unsupported() {
        let payment = Payment::new(PaymentMethod::Cash, Currency::EUR, 100);
        let result = payment.process();
        assert_eq!(result.status, "error");
    }

    // -------------------------------------------------------------------------
    // 階層的ディスパッチ
    // -------------------------------------------------------------------------

    #[test]
    fn test_savings_account_interest() {
        let account = SavingsAccount { balance: 10000 };
        assert_eq!(account.calculate_interest(), 200.0);
    }

    #[test]
    fn test_premium_savings_account_interest() {
        let account = PremiumSavingsAccount { balance: 10000 };
        assert_eq!(account.calculate_interest(), 500.0);
    }

    #[test]
    fn test_checking_account_interest() {
        let account = CheckingAccount { balance: 10000 };
        assert_eq!(account.calculate_interest(), 10.0);
    }

    // -------------------------------------------------------------------------
    // Trait を実装する構造体
    // -------------------------------------------------------------------------

    #[test]
    fn test_drawable_rectangle_draw() {
        let rect = DrawableRectangle::new(10.0, 20.0, 100.0, 50.0);
        assert_eq!(rect.draw(), "Rectangle at (10,20) with size 100x50");
    }

    #[test]
    fn test_drawable_rectangle_translate() {
        let rect = DrawableRectangle::new(10.0, 20.0, 100.0, 50.0);
        let moved = rect.translate(5.0, 10.0);
        assert_eq!(moved.x, 15.0);
        assert_eq!(moved.y, 30.0);
    }

    #[test]
    fn test_drawable_circle_bounding_box() {
        let circle = DrawableCircle::new(50.0, 50.0, 25.0);
        let bb = circle.bounding_box();
        assert_eq!(bb.x, 25.0);
        assert_eq!(bb.y, 25.0);
        assert_eq!(bb.width, 50.0);
        assert_eq!(bb.height, 50.0);
    }

    #[test]
    fn test_drawable_circle_scale() {
        let circle = DrawableCircle::new(50.0, 50.0, 25.0);
        let scaled = circle.scale(2.0);
        assert_eq!(scaled.radius, 50.0);
    }

    // -------------------------------------------------------------------------
    // 既存型への拡張
    // -------------------------------------------------------------------------

    #[test]
    fn test_stringable_vec() {
        let v = vec![1, 2, 3];
        assert_eq!(v.to_custom_string(), "[1, 2, 3]");
    }

    #[test]
    fn test_stringable_option_some() {
        let opt: Option<i32> = Some(42);
        assert_eq!(opt.to_custom_string(), "42");
    }

    #[test]
    fn test_stringable_option_none() {
        let opt: Option<i32> = None;
        assert_eq!(opt.to_custom_string(), "nil");
    }

    // -------------------------------------------------------------------------
    // コンポーネントパターン
    // -------------------------------------------------------------------------

    #[test]
    fn test_database_connection_lifecycle() {
        let db = DatabaseConnection::new("localhost", 5432);
        assert!(!db.connected);

        let db = db.start();
        assert!(db.connected);

        let db = db.stop();
        assert!(!db.connected);
    }

    #[test]
    fn test_web_server_lifecycle() {
        let db = DatabaseConnection::new("localhost", 5432);
        let server = WebServer::new(8080, db);
        assert!(!server.running);
        assert!(!server.db.connected);

        let server = server.start();
        assert!(server.running);
        assert!(server.db.connected);

        let server = server.stop();
        assert!(!server.running);
        assert!(!server.db.connected);
    }

    // -------------------------------------------------------------------------
    // 通知送信（Strategy パターン）
    // -------------------------------------------------------------------------

    #[test]
    fn test_email_notification() {
        let email = EmailNotification::new("user@example.com", "お知らせ");
        let result = email.send_notification("重要なお知らせ");
        assert_eq!(result.notification_type, "email");
        assert_eq!(result.to, "user@example.com");
        assert_eq!(result.subject, Some("お知らせ".to_string()));
    }

    #[test]
    fn test_sms_notification_truncation() {
        let sms = SMSNotification::new("090-1234-5678");
        let long_message = "a".repeat(200);
        let result = sms.send_notification(&long_message);
        assert_eq!(result.body.len(), 157);
    }

    #[test]
    fn test_push_notification() {
        let push = PushNotification::new("device_token_123");
        let result = push.send_notification("新着通知");
        assert_eq!(result.notification_type, "push");
        assert_eq!(result.to, "device_token_123");
    }

    #[test]
    fn test_create_notification_factory() {
        let email = create_notification("email", "user@example.com", Some("件名")).unwrap();
        let result = email.send_notification("テスト");
        assert_eq!(result.notification_type, "email");

        let sms = create_notification("sms", "090-1234-5678", None).unwrap();
        let result = sms.send_notification("テスト");
        assert_eq!(result.notification_type, "sms");

        let error = create_notification("unknown", "", None);
        assert!(error.is_err());
    }
}
