//! 第14章: Abstract Server パターン
//!
//! Abstract Server パターンは依存関係逆転の原則（DIP）を実現するパターンです。
//! 高レベルモジュールが低レベルモジュールの詳細に依存するのではなく、
//! 両者が抽象に依存することで疎結合を実現します。

use std::collections::HashMap;
use std::sync::{Arc, Mutex};

// ============================================================
// 1. Switchable パターン - デバイス制御
// ============================================================

/// Abstract Server: スイッチ可能なデバイスのトレイト
pub trait Switchable: Clone {
    fn turn_on(&self) -> Self;
    fn turn_off(&self) -> Self;
    fn is_on(&self) -> bool;
    
    fn toggle(&self) -> Self {
        if self.is_on() {
            self.turn_off()
        } else {
            self.turn_on()
        }
    }
}

// --- Concrete Server: Light ---

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LightState {
    On,
    Off,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Light {
    pub state: LightState,
}

impl Default for Light {
    fn default() -> Self {
        Self { state: LightState::Off }
    }
}

impl Light {
    pub fn new() -> Self {
        Self::default()
    }
}

impl Switchable for Light {
    fn turn_on(&self) -> Self {
        Self { state: LightState::On }
    }

    fn turn_off(&self) -> Self {
        Self { state: LightState::Off }
    }

    fn is_on(&self) -> bool {
        self.state == LightState::On
    }
}

// --- Concrete Server: Fan ---

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FanSpeed {
    Low,
    Medium,
    High,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Fan {
    pub state: LightState,
    pub speed: Option<FanSpeed>,
}

impl Default for Fan {
    fn default() -> Self {
        Self {
            state: LightState::Off,
            speed: None,
        }
    }
}

impl Fan {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn set_speed(&self, speed: FanSpeed) -> Self {
        if self.is_on() {
            Self {
                speed: Some(speed),
                ..self.clone()
            }
        } else {
            self.clone()
        }
    }
}

impl Switchable for Fan {
    fn turn_on(&self) -> Self {
        Self {
            state: LightState::On,
            speed: Some(self.speed.unwrap_or(FanSpeed::Low)),
        }
    }

    fn turn_off(&self) -> Self {
        Self {
            state: LightState::Off,
            speed: None,
        }
    }

    fn is_on(&self) -> bool {
        self.state == LightState::On
    }
}

// --- Concrete Server: Motor ---

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MotorDirection {
    Forward,
    Reverse,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Motor {
    pub state: LightState,
    pub direction: Option<MotorDirection>,
}

impl Default for Motor {
    fn default() -> Self {
        Self {
            state: LightState::Off,
            direction: None,
        }
    }
}

impl Motor {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn reverse_direction(&self) -> Self {
        if self.is_on() {
            let new_direction = match self.direction {
                Some(MotorDirection::Forward) => MotorDirection::Reverse,
                Some(MotorDirection::Reverse) => MotorDirection::Forward,
                None => MotorDirection::Forward,
            };
            Self {
                direction: Some(new_direction),
                ..self.clone()
            }
        } else {
            self.clone()
        }
    }
}

impl Switchable for Motor {
    fn turn_on(&self) -> Self {
        Self {
            state: LightState::On,
            direction: Some(self.direction.unwrap_or(MotorDirection::Forward)),
        }
    }

    fn turn_off(&self) -> Self {
        Self {
            state: LightState::Off,
            ..self.clone()
        }
    }

    fn is_on(&self) -> bool {
        self.state == LightState::On
    }
}

// --- Client: Switch ---

/// Switch クライアント - Switchable プロトコルを通じてデバイスを操作
pub struct Switch;

impl Switch {
    pub fn engage<T: Switchable>(device: &T) -> T {
        device.turn_on()
    }

    pub fn disengage<T: Switchable>(device: &T) -> T {
        device.turn_off()
    }

    pub fn toggle<T: Switchable>(device: &T) -> T {
        device.toggle()
    }

    pub fn status<T: Switchable>(device: &T) -> &'static str {
        if device.is_on() { "on" } else { "off" }
    }
}

// ============================================================
// 2. Repository パターン - データアクセス
// ============================================================

/// シンプルなID型
pub type Id = String;

/// User エンティティ
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct User {
    pub id: Option<Id>,
    pub name: String,
    pub email: String,
    pub created_at: u64,
}

impl User {
    pub fn new(name: &str, email: &str) -> Self {
        Self {
            id: None,
            name: name.to_string(),
            email: email.to_string(),
            created_at: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis() as u64,
        }
    }

    pub fn with_id(mut self, id: Id) -> Self {
        self.id = Some(id);
        self
    }
}

/// Abstract Server: リポジトリインターフェース
pub trait Repository<E, ID> {
    fn find_by_id(&self, id: &ID) -> Option<E>;
    fn find_all(&self) -> Vec<E>;
    fn save(&self, entity: E) -> E;
    fn delete(&self, id: &ID) -> Option<E>;
}

/// Concrete Server: インメモリリポジトリ
pub struct MemoryRepository<E: Clone, ID: Clone + Eq + std::hash::Hash> {
    data: Arc<Mutex<HashMap<ID, E>>>,
    get_id: fn(&E) -> Option<ID>,
    set_id: fn(E, ID) -> E,
    generate_id: fn() -> ID,
}

impl<E: Clone, ID: Clone + Eq + std::hash::Hash> MemoryRepository<E, ID> {
    pub fn new(
        get_id: fn(&E) -> Option<ID>,
        set_id: fn(E, ID) -> E,
        generate_id: fn() -> ID,
    ) -> Self {
        Self {
            data: Arc::new(Mutex::new(HashMap::new())),
            get_id,
            set_id,
            generate_id,
        }
    }

    pub fn clear(&self) {
        self.data.lock().unwrap().clear();
    }
}

impl<E: Clone, ID: Clone + Eq + std::hash::Hash> Repository<E, ID> for MemoryRepository<E, ID> {
    fn find_by_id(&self, id: &ID) -> Option<E> {
        self.data.lock().unwrap().get(id).cloned()
    }

    fn find_all(&self) -> Vec<E> {
        self.data.lock().unwrap().values().cloned().collect()
    }

    fn save(&self, entity: E) -> E {
        let id = (self.get_id)(&entity).unwrap_or_else(|| (self.generate_id)());
        let entity_with_id = (self.set_id)(entity, id.clone());
        self.data.lock().unwrap().insert(id, entity_with_id.clone());
        entity_with_id
    }

    fn delete(&self, id: &ID) -> Option<E> {
        self.data.lock().unwrap().remove(id)
    }
}

/// UserRepository のファクトリー
pub fn create_user_repository() -> MemoryRepository<User, Id> {
    MemoryRepository::new(
        |user| user.id.clone(),
        |mut user, id| {
            user.id = Some(id);
            user
        },
        || uuid::Uuid::new_v4().to_string(),
    )
}

/// シンプルなUUID生成（外部crateなしの場合）
pub mod uuid {
    use std::sync::atomic::{AtomicU64, Ordering};
    
    static COUNTER: AtomicU64 = AtomicU64::new(0);
    
    pub struct Uuid;
    
    impl Uuid {
        pub fn new_v4() -> UuidResult {
            let count = COUNTER.fetch_add(1, Ordering::SeqCst);
            let time = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_nanos();
            UuidResult(format!("{:x}-{:x}", time, count))
        }
    }
    
    pub struct UuidResult(String);
    
    impl std::fmt::Display for UuidResult {
        fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
            write!(f, "{}", self.0)
        }
    }
}

/// Client: UserService
pub struct UserService;

impl UserService {
    pub fn create_user<R: Repository<User, Id>>(
        repository: &R,
        name: &str,
        email: &str,
    ) -> User {
        repository.save(User::new(name, email))
    }

    pub fn get_user<R: Repository<User, Id>>(
        repository: &R,
        id: &Id,
    ) -> Option<User> {
        repository.find_by_id(id)
    }

    pub fn get_all_users<R: Repository<User, Id>>(
        repository: &R,
    ) -> Vec<User> {
        repository.find_all()
    }

    pub fn delete_user<R: Repository<User, Id>>(
        repository: &R,
        id: &Id,
    ) -> Option<User> {
        repository.delete(id)
    }
}

// ============================================================
// 3. Logger パターン - ロギング抽象化
// ============================================================

/// Abstract Server: Logger インターフェース
pub trait Logger {
    fn debug(&self, message: &str);
    fn info(&self, message: &str);
    fn warn(&self, message: &str);
    fn error(&self, message: &str);
    fn error_with_cause(&self, message: &str, cause: &str);
}

/// Concrete Server: Console Logger
pub struct ConsoleLogger;

impl Logger for ConsoleLogger {
    fn debug(&self, message: &str) {
        println!("[DEBUG] {}", message);
    }

    fn info(&self, message: &str) {
        println!("[INFO] {}", message);
    }

    fn warn(&self, message: &str) {
        println!("[WARN] {}", message);
    }

    fn error(&self, message: &str) {
        println!("[ERROR] {}", message);
    }

    fn error_with_cause(&self, message: &str, cause: &str) {
        println!("[ERROR] {}: {}", message, cause);
    }
}

/// Concrete Server: Test Logger（テスト用にログを記録）
pub struct TestLogger {
    logs: Arc<Mutex<Vec<(String, String)>>>,
}

impl TestLogger {
    pub fn new() -> Self {
        Self {
            logs: Arc::new(Mutex::new(Vec::new())),
        }
    }

    pub fn get_logs(&self) -> Vec<(String, String)> {
        self.logs.lock().unwrap().clone()
    }

    pub fn clear(&self) {
        self.logs.lock().unwrap().clear();
    }
}

impl Default for TestLogger {
    fn default() -> Self {
        Self::new()
    }
}

impl Logger for TestLogger {
    fn debug(&self, message: &str) {
        self.logs.lock().unwrap().push(("DEBUG".to_string(), message.to_string()));
    }

    fn info(&self, message: &str) {
        self.logs.lock().unwrap().push(("INFO".to_string(), message.to_string()));
    }

    fn warn(&self, message: &str) {
        self.logs.lock().unwrap().push(("WARN".to_string(), message.to_string()));
    }

    fn error(&self, message: &str) {
        self.logs.lock().unwrap().push(("ERROR".to_string(), message.to_string()));
    }

    fn error_with_cause(&self, message: &str, cause: &str) {
        self.logs.lock().unwrap().push(("ERROR".to_string(), format!("{}: {}", message, cause)));
    }
}

/// Concrete Server: Silent Logger（何も出力しない）
pub struct SilentLogger;

impl Logger for SilentLogger {
    fn debug(&self, _message: &str) {}
    fn info(&self, _message: &str) {}
    fn warn(&self, _message: &str) {}
    fn error(&self, _message: &str) {}
    fn error_with_cause(&self, _message: &str, _cause: &str) {}
}

/// Client: Application Service
pub struct ApplicationService<'a, L: Logger> {
    logger: &'a L,
}

impl<'a, L: Logger> ApplicationService<'a, L> {
    pub fn new(logger: &'a L) -> Self {
        Self { logger }
    }

    pub fn process_request(&self, request: &str) -> Result<String, String> {
        self.logger.info(&format!("Processing request: {}", request));
        let result = format!("Processed: {}", request);
        self.logger.debug("Request completed successfully");
        Ok(result)
    }
}

// ============================================================
// 4. Notification パターン - 通知抽象化
// ============================================================

/// Abstract Server: Notification インターフェース
pub trait NotificationService {
    fn send(&self, recipient: &str, subject: &str, message: &str) -> bool;
}

/// Concrete Server: Email Notification
pub struct EmailNotification;

impl NotificationService for EmailNotification {
    fn send(&self, recipient: &str, subject: &str, message: &str) -> bool {
        println!("Email to {}: [{}] {}", recipient, subject, message);
        true
    }
}

/// Concrete Server: SMS Notification
pub struct SmsNotification;

impl NotificationService for SmsNotification {
    fn send(&self, recipient: &str, _subject: &str, message: &str) -> bool {
        println!("SMS to {}: {}", recipient, message);
        true
    }
}

/// Concrete Server: Push Notification
pub struct PushNotification;

impl NotificationService for PushNotification {
    fn send(&self, recipient: &str, subject: &str, message: &str) -> bool {
        println!("Push to {}: [{}] {}", recipient, subject, message);
        true
    }
}

/// Concrete Server: Mock Notification（テスト用）
pub struct MockNotification {
    sent: Arc<Mutex<Vec<(String, String, String)>>>,
}

impl MockNotification {
    pub fn new() -> Self {
        Self {
            sent: Arc::new(Mutex::new(Vec::new())),
        }
    }

    pub fn get_sent_notifications(&self) -> Vec<(String, String, String)> {
        self.sent.lock().unwrap().clone()
    }

    pub fn clear(&self) {
        self.sent.lock().unwrap().clear();
    }
}

impl Default for MockNotification {
    fn default() -> Self {
        Self::new()
    }
}

impl NotificationService for MockNotification {
    fn send(&self, recipient: &str, subject: &str, message: &str) -> bool {
        self.sent.lock().unwrap().push((
            recipient.to_string(),
            subject.to_string(),
            message.to_string(),
        ));
        true
    }
}

/// Concrete Server: Composite Notification（複数に送信）
pub struct CompositeNotification {
    services: Vec<Box<dyn NotificationService>>,
}

impl CompositeNotification {
    pub fn new(services: Vec<Box<dyn NotificationService>>) -> Self {
        Self { services }
    }
}

impl NotificationService for CompositeNotification {
    fn send(&self, recipient: &str, subject: &str, message: &str) -> bool {
        self.services.iter().all(|s| s.send(recipient, subject, message))
    }
}

/// Client: Order Service
pub struct OrderService<'a, N: NotificationService> {
    notification: &'a N,
}

impl<'a, N: NotificationService> OrderService<'a, N> {
    pub fn new(notification: &'a N) -> Self {
        Self { notification }
    }

    pub fn place_order(&self, user_id: &str, order_id: &str, amount: f64) -> bool {
        self.notification.send(
            user_id,
            &format!("Order Confirmation: {}", order_id),
            &format!("Your order for ${:.2} has been placed.", amount),
        )
    }
}

// ============================================================
// 5. Storage パターン - ストレージ抽象化
// ============================================================

/// Abstract Server: Storage インターフェース
pub trait Storage {
    fn read(&self, key: &str) -> Option<String>;
    fn write(&self, key: &str, value: &str);
    fn delete(&self, key: &str) -> bool;
    fn exists(&self, key: &str) -> bool;
}

/// Concrete Server: Memory Storage
pub struct MemoryStorage {
    data: Arc<Mutex<HashMap<String, String>>>,
}

impl MemoryStorage {
    pub fn new() -> Self {
        Self {
            data: Arc::new(Mutex::new(HashMap::new())),
        }
    }
}

impl Default for MemoryStorage {
    fn default() -> Self {
        Self::new()
    }
}

impl Storage for MemoryStorage {
    fn read(&self, key: &str) -> Option<String> {
        self.data.lock().unwrap().get(key).cloned()
    }

    fn write(&self, key: &str, value: &str) {
        self.data.lock().unwrap().insert(key.to_string(), value.to_string());
    }

    fn delete(&self, key: &str) -> bool {
        self.data.lock().unwrap().remove(key).is_some()
    }

    fn exists(&self, key: &str) -> bool {
        self.data.lock().unwrap().contains_key(key)
    }
}

/// Concrete Server: File Storage（シミュレーション）
pub struct FileStorage {
    base_path: String,
    files: Arc<Mutex<HashMap<String, String>>>,
}

impl FileStorage {
    pub fn new(base_path: &str) -> Self {
        Self {
            base_path: base_path.to_string(),
            files: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    fn full_path(&self, key: &str) -> String {
        format!("{}/{}", self.base_path, key)
    }
}

impl Storage for FileStorage {
    fn read(&self, key: &str) -> Option<String> {
        self.files.lock().unwrap().get(&self.full_path(key)).cloned()
    }

    fn write(&self, key: &str, value: &str) {
        self.files.lock().unwrap().insert(self.full_path(key), value.to_string());
    }

    fn delete(&self, key: &str) -> bool {
        self.files.lock().unwrap().remove(&self.full_path(key)).is_some()
    }

    fn exists(&self, key: &str) -> bool {
        self.files.lock().unwrap().contains_key(&self.full_path(key))
    }
}

/// Client: Cache Service
pub struct CacheService<'a, S: Storage> {
    storage: &'a S,
    ttl_ms: u64,
    timestamps: Arc<Mutex<HashMap<String, u64>>>,
}

impl<'a, S: Storage> CacheService<'a, S> {
    pub fn new(storage: &'a S, ttl_ms: u64) -> Self {
        Self {
            storage,
            ttl_ms,
            timestamps: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    fn current_time_ms() -> u64 {
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64
    }

    pub fn get(&self, key: &str) -> Option<String> {
        let timestamps = self.timestamps.lock().unwrap();
        match timestamps.get(key) {
            Some(&ts) if Self::current_time_ms() - ts < self.ttl_ms => {
                self.storage.read(key)
            }
            Some(_) => {
                drop(timestamps);
                self.storage.delete(key);
                self.timestamps.lock().unwrap().remove(key);
                None
            }
            None => None,
        }
    }

    pub fn set(&self, key: &str, value: &str) {
        self.storage.write(key, value);
        self.timestamps.lock().unwrap().insert(key.to_string(), Self::current_time_ms());
    }

    pub fn invalidate(&self, key: &str) {
        self.storage.delete(key);
        self.timestamps.lock().unwrap().remove(key);
    }
}

// ============================================================
// 6. 関数型アプローチ - 高階関数による抽象化
// ============================================================

pub mod functional {
    /// 関数型 Switchable - 状態変換関数のレコード
    #[derive(Clone)]
    pub struct SwitchableFn<A: Clone> {
        pub turn_on: fn(&A) -> A,
        pub turn_off: fn(&A) -> A,
        pub is_on: fn(&A) -> bool,
    }

    impl<A: Clone> SwitchableFn<A> {
        pub fn toggle(&self, device: &A) -> A {
            if (self.is_on)(device) {
                (self.turn_off)(device)
            } else {
                (self.turn_on)(device)
            }
        }
    }

    /// 関数型 Repository - CRUD操作関数のレコード
    pub struct RepositoryFn<E, ID> {
        pub find_by_id: Box<dyn Fn(&ID) -> Option<E>>,
        pub find_all: Box<dyn Fn() -> Vec<E>>,
        pub save: Box<dyn Fn(E) -> E>,
        pub delete: Box<dyn Fn(&ID) -> Option<E>>,
    }

    /// 関数型スイッチクライアント
    pub struct FunctionalSwitch<A: Clone> {
        switchable: SwitchableFn<A>,
    }

    impl<A: Clone> FunctionalSwitch<A> {
        pub fn new(switchable: SwitchableFn<A>) -> Self {
            Self { switchable }
        }

        pub fn engage(&self, device: &A) -> A {
            (self.switchable.turn_on)(device)
        }

        pub fn disengage(&self, device: &A) -> A {
            (self.switchable.turn_off)(device)
        }

        pub fn toggle(&self, device: &A) -> A {
            self.switchable.toggle(device)
        }

        pub fn status(&self, device: &A) -> &'static str {
            if (self.switchable.is_on)(device) { "on" } else { "off" }
        }
    }

    /// シンプルなデバイス型
    #[derive(Debug, Clone, PartialEq, Eq, Default)]
    pub struct SimpleDevice {
        pub on: bool,
    }

    impl SimpleDevice {
        pub fn new() -> Self {
            Self::default()
        }
    }

    pub fn simple_device_switchable() -> SwitchableFn<SimpleDevice> {
        SwitchableFn {
            turn_on: |_| SimpleDevice { on: true },
            turn_off: |_| SimpleDevice { on: false },
            is_on: |d| d.on,
        }
    }
}

// ============================================================
// 7. 依存性注入 - Constructor Injection
// ============================================================

/// 依存性を注入可能なサービス
pub struct UserManagementService<'a, R, N, L>
where
    R: Repository<User, Id>,
    N: NotificationService,
    L: Logger,
{
    repository: &'a R,
    notification: &'a N,
    logger: &'a L,
}

impl<'a, R, N, L> UserManagementService<'a, R, N, L>
where
    R: Repository<User, Id>,
    N: NotificationService,
    L: Logger,
{
    pub fn new(repository: &'a R, notification: &'a N, logger: &'a L) -> Self {
        Self {
            repository,
            notification,
            logger,
        }
    }

    pub fn register_user(&self, name: &str, email: &str) -> User {
        self.logger.info(&format!("Registering user: {}", name));
        let user = self.repository.save(User::new(name, email));
        self.notification.send(
            email,
            "Welcome!",
            &format!("Hello {}, your account has been created.", name),
        );
        self.logger.info(&format!("User registered: {}", user.id.as_deref().unwrap_or("unknown")));
        user
    }

    pub fn deactivate_user(&self, user_id: &Id) -> Option<User> {
        self.logger.info(&format!("Deactivating user: {}", user_id));
        match self.repository.find_by_id(user_id) {
            Some(user) => {
                self.repository.delete(user_id);
                self.notification.send(
                    &user.email,
                    "Account Deactivated",
                    &format!("Hello {}, your account has been deactivated.", user.name),
                );
                self.logger.info(&format!("User deactivated: {}", user_id));
                Some(user)
            }
            None => {
                self.logger.warn(&format!("User not found: {}", user_id));
                None
            }
        }
    }
}

// ============================================================
// 8. Payment Gateway パターン
// ============================================================

/// 支払い結果
#[derive(Debug, Clone, PartialEq)]
pub enum PaymentResult {
    Success { transaction_id: String, amount: f64 },
    Failure { reason: String },
}

impl PaymentResult {
    pub fn is_success(&self) -> bool {
        matches!(self, PaymentResult::Success { .. })
    }
}

/// Abstract Server: Payment Gateway
pub trait PaymentGateway {
    fn charge(&self, amount: f64, card_token: &str) -> PaymentResult;
    fn refund(&self, transaction_id: &str, amount: f64) -> PaymentResult;
}

/// Concrete Server: Stripe Gateway（シミュレーション）
pub struct StripeGateway;

impl PaymentGateway for StripeGateway {
    fn charge(&self, amount: f64, card_token: &str) -> PaymentResult {
        if card_token.starts_with("valid_") {
            PaymentResult::Success {
                transaction_id: format!("stripe_{}", Self::timestamp()),
                amount,
            }
        } else {
            PaymentResult::Failure {
                reason: "Invalid card token".to_string(),
            }
        }
    }

    fn refund(&self, transaction_id: &str, amount: f64) -> PaymentResult {
        if transaction_id.starts_with("stripe_") {
            PaymentResult::Success {
                transaction_id: format!("refund_{}", transaction_id),
                amount,
            }
        } else {
            PaymentResult::Failure {
                reason: "Invalid transaction ID".to_string(),
            }
        }
    }
}

impl StripeGateway {
    fn timestamp() -> u64 {
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64
    }
}

/// Concrete Server: PayPal Gateway（シミュレーション）
pub struct PayPalGateway;

impl PaymentGateway for PayPalGateway {
    fn charge(&self, amount: f64, card_token: &str) -> PaymentResult {
        if card_token.starts_with("valid_") {
            PaymentResult::Success {
                transaction_id: format!("paypal_{}", Self::timestamp()),
                amount,
            }
        } else {
            PaymentResult::Failure {
                reason: "Invalid card token".to_string(),
            }
        }
    }

    fn refund(&self, transaction_id: &str, amount: f64) -> PaymentResult {
        if transaction_id.starts_with("paypal_") {
            PaymentResult::Success {
                transaction_id: format!("refund_{}", transaction_id),
                amount,
            }
        } else {
            PaymentResult::Failure {
                reason: "Invalid transaction ID".to_string(),
            }
        }
    }
}

impl PayPalGateway {
    fn timestamp() -> u64 {
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64
    }
}

/// Concrete Server: Mock Gateway（テスト用）
pub struct MockPaymentGateway {
    charges: Arc<Mutex<Vec<(f64, String)>>>,
    refunds: Arc<Mutex<Vec<(String, f64)>>>,
    should_fail: Arc<Mutex<bool>>,
}

impl MockPaymentGateway {
    pub fn new() -> Self {
        Self {
            charges: Arc::new(Mutex::new(Vec::new())),
            refunds: Arc::new(Mutex::new(Vec::new())),
            should_fail: Arc::new(Mutex::new(false)),
        }
    }

    pub fn set_should_fail(&self, fail: bool) {
        *self.should_fail.lock().unwrap() = fail;
    }

    pub fn get_charges(&self) -> Vec<(f64, String)> {
        self.charges.lock().unwrap().clone()
    }

    pub fn get_refunds(&self) -> Vec<(String, f64)> {
        self.refunds.lock().unwrap().clone()
    }

    pub fn clear(&self) {
        self.charges.lock().unwrap().clear();
        self.refunds.lock().unwrap().clear();
    }
}

impl Default for MockPaymentGateway {
    fn default() -> Self {
        Self::new()
    }
}

impl PaymentGateway for MockPaymentGateway {
    fn charge(&self, amount: f64, card_token: &str) -> PaymentResult {
        if *self.should_fail.lock().unwrap() {
            return PaymentResult::Failure {
                reason: "Mock failure".to_string(),
            };
        }
        
        let mut charges = self.charges.lock().unwrap();
        charges.push((amount, card_token.to_string()));
        PaymentResult::Success {
            transaction_id: format!("mock_{}", charges.len()),
            amount,
        }
    }

    fn refund(&self, transaction_id: &str, amount: f64) -> PaymentResult {
        if *self.should_fail.lock().unwrap() {
            return PaymentResult::Failure {
                reason: "Mock failure".to_string(),
            };
        }
        
        self.refunds.lock().unwrap().push((transaction_id.to_string(), amount));
        PaymentResult::Success {
            transaction_id: format!("refund_{}", transaction_id),
            amount,
        }
    }
}

/// Client: Checkout Service
pub struct CheckoutService<'a, P: PaymentGateway> {
    payment_gateway: &'a P,
}

impl<'a, P: PaymentGateway> CheckoutService<'a, P> {
    pub fn new(payment_gateway: &'a P) -> Self {
        Self { payment_gateway }
    }

    pub fn process_payment(&self, amount: f64, card_token: &str) -> Result<String, String> {
        match self.payment_gateway.charge(amount, card_token) {
            PaymentResult::Success { transaction_id, .. } => Ok(transaction_id),
            PaymentResult::Failure { reason } => Err(reason),
        }
    }

    pub fn refund_payment(&self, transaction_id: &str, amount: f64) -> Result<String, String> {
        match self.payment_gateway.refund(transaction_id, amount) {
            PaymentResult::Success { transaction_id: refund_id, .. } => Ok(refund_id),
            PaymentResult::Failure { reason } => Err(reason),
        }
    }
}

// ============================================================
// テスト
// ============================================================

#[cfg(test)]
mod tests {
    use super::*;
    use super::functional::*;

    // ============================================================
    // 1. Switchable パターン
    // ============================================================

    mod switchable_tests {
        use super::*;

        #[test]
        fn light_initial_state_is_off() {
            let light = Light::new();
            assert!(!light.is_on());
        }

        #[test]
        fn light_can_turn_on() {
            let light = Light::new().turn_on();
            assert!(light.is_on());
            assert_eq!(light.state, LightState::On);
        }

        #[test]
        fn light_can_turn_off() {
            let light = Light::new().turn_on().turn_off();
            assert!(!light.is_on());
            assert_eq!(light.state, LightState::Off);
        }

        #[test]
        fn light_can_toggle() {
            let light = Light::new();
            assert!(light.toggle().is_on());
            assert!(!light.toggle().toggle().is_on());
        }

        #[test]
        fn fan_initial_state_is_off_with_no_speed() {
            let fan = Fan::new();
            assert!(!fan.is_on());
            assert_eq!(fan.speed, None);
        }

        #[test]
        fn fan_on_sets_default_speed() {
            let fan = Fan::new().turn_on();
            assert!(fan.is_on());
            assert_eq!(fan.speed, Some(FanSpeed::Low));
        }

        #[test]
        fn fan_can_change_speed() {
            let fan = Fan::new().turn_on();
            let high_fan = fan.set_speed(FanSpeed::High);
            assert_eq!(high_fan.speed, Some(FanSpeed::High));
        }

        #[test]
        fn fan_cannot_change_speed_when_off() {
            let fan = Fan::new();
            let result = fan.set_speed(FanSpeed::High);
            assert_eq!(result.speed, None);
        }

        #[test]
        fn fan_off_resets_speed() {
            let fan = Fan::new().turn_on().turn_off();
            assert_eq!(fan.speed, None);
        }

        #[test]
        fn motor_initial_state_is_off_with_no_direction() {
            let motor = Motor::new();
            assert!(!motor.is_on());
            assert_eq!(motor.direction, None);
        }

        #[test]
        fn motor_on_sets_default_direction() {
            let motor = Motor::new().turn_on();
            assert!(motor.is_on());
            assert_eq!(motor.direction, Some(MotorDirection::Forward));
        }

        #[test]
        fn motor_can_reverse_direction() {
            let motor = Motor::new().turn_on();
            let reversed = motor.reverse_direction();
            assert_eq!(reversed.direction, Some(MotorDirection::Reverse));
        }

        #[test]
        fn motor_can_reverse_direction_again() {
            let motor = Motor::new().turn_on();
            let reversed = motor.reverse_direction().reverse_direction();
            assert_eq!(reversed.direction, Some(MotorDirection::Forward));
        }

        #[test]
        fn motor_cannot_reverse_when_off() {
            let motor = Motor::new();
            let result = motor.reverse_direction();
            assert_eq!(result.direction, None);
        }

        #[test]
        fn switch_operates_different_devices() {
            let light = Switch::engage(&Light::new());
            let fan = Switch::engage(&Fan::new());
            let motor = Switch::engage(&Motor::new());

            assert_eq!(Switch::status(&light), "on");
            assert_eq!(Switch::status(&fan), "on");
            assert_eq!(Switch::status(&motor), "on");
        }

        #[test]
        fn switch_disengage_turns_off() {
            let light = Switch::disengage(&Switch::engage(&Light::new()));
            assert_eq!(Switch::status(&light), "off");
        }

        #[test]
        fn switch_toggle_switches_state() {
            let light = Light::new();
            assert_eq!(Switch::status(&light), "off");
            assert_eq!(Switch::status(&Switch::toggle(&light)), "on");
            assert_eq!(Switch::status(&Switch::toggle(&Switch::toggle(&light))), "off");
        }
    }

    // ============================================================
    // 2. Repository パターン
    // ============================================================

    mod repository_tests {
        use super::*;

        #[test]
        fn memory_repository_saves_entity() {
            let repo = create_user_repository();
            let user = repo.save(User::new("Alice", "alice@example.com"));

            assert!(user.id.is_some());
            assert_eq!(user.name, "Alice");
        }

        #[test]
        fn memory_repository_finds_by_id() {
            let repo = create_user_repository();
            let saved = repo.save(User::new("Bob", "bob@example.com"));

            let found = repo.find_by_id(&saved.id.clone().unwrap());
            assert!(found.is_some());
            assert_eq!(found.unwrap().name, "Bob");
        }

        #[test]
        fn memory_repository_finds_all() {
            let repo = create_user_repository();
            repo.save(User::new("Alice", "alice@example.com"));
            repo.save(User::new("Bob", "bob@example.com"));

            let users = repo.find_all();
            assert_eq!(users.len(), 2);
        }

        #[test]
        fn memory_repository_deletes_entity() {
            let repo = create_user_repository();
            let saved = repo.save(User::new("Charlie", "charlie@example.com"));

            let deleted = repo.delete(&saved.id.clone().unwrap());
            assert!(deleted.is_some());
            assert!(repo.find_by_id(&saved.id.unwrap()).is_none());
        }

        #[test]
        fn memory_repository_delete_nonexistent_returns_none() {
            let repo = create_user_repository();
            assert!(repo.delete(&"nonexistent".to_string()).is_none());
        }

        #[test]
        fn user_service_creates_user() {
            let repo = create_user_repository();
            let user = UserService::create_user(&repo, "Diana", "diana@example.com");

            assert_eq!(user.name, "Diana");
            assert_eq!(user.email, "diana@example.com");
            assert!(user.id.is_some());
        }

        #[test]
        fn user_service_gets_user() {
            let repo = create_user_repository();
            let created = UserService::create_user(&repo, "Eve", "eve@example.com");

            let found = UserService::get_user(&repo, &created.id.unwrap());
            assert!(found.is_some());
            assert_eq!(found.unwrap().name, "Eve");
        }

        #[test]
        fn user_service_gets_all_users() {
            let repo = create_user_repository();
            UserService::create_user(&repo, "Frank", "frank@example.com");
            UserService::create_user(&repo, "Grace", "grace@example.com");

            let users = UserService::get_all_users(&repo);
            assert_eq!(users.len(), 2);
        }

        #[test]
        fn user_service_deletes_user() {
            let repo = create_user_repository();
            let user = UserService::create_user(&repo, "Henry", "henry@example.com");

            let deleted = UserService::delete_user(&repo, &user.id.clone().unwrap());
            assert!(deleted.is_some());
            assert!(UserService::get_user(&repo, &user.id.unwrap()).is_none());
        }
    }

    // ============================================================
    // 3. Logger パターン
    // ============================================================

    mod logger_tests {
        use super::*;

        #[test]
        fn test_logger_records_logs() {
            let logger = TestLogger::new();
            logger.debug("Debug message");
            logger.info("Info message");
            logger.warn("Warn message");
            logger.error("Error message");

            let logs = logger.get_logs();
            assert_eq!(logs.len(), 4);
            assert_eq!(logs[0], ("DEBUG".to_string(), "Debug message".to_string()));
            assert_eq!(logs[1], ("INFO".to_string(), "Info message".to_string()));
            assert_eq!(logs[2], ("WARN".to_string(), "Warn message".to_string()));
            assert_eq!(logs[3], ("ERROR".to_string(), "Error message".to_string()));
        }

        #[test]
        fn test_logger_records_error_with_cause() {
            let logger = TestLogger::new();
            logger.error_with_cause("Failed", "Test error");

            let logs = logger.get_logs();
            assert_eq!(logs[0].0, "ERROR");
            assert!(logs[0].1.contains("Test error"));
        }

        #[test]
        fn test_logger_clears() {
            let logger = TestLogger::new();
            logger.info("Test");
            logger.clear();
            assert!(logger.get_logs().is_empty());
        }

        #[test]
        fn application_service_processes_request_and_logs() {
            let logger = TestLogger::new();
            let service = ApplicationService::new(&logger);

            let result = service.process_request("test-request");

            assert_eq!(result, Ok("Processed: test-request".to_string()));
            assert!(logger.get_logs().iter().any(|(_, msg)| msg.contains("test-request")));
        }

        #[test]
        fn application_service_works_with_silent_logger() {
            let service = ApplicationService::new(&SilentLogger);
            assert_eq!(
                service.process_request("silent-request"),
                Ok("Processed: silent-request".to_string())
            );
        }
    }

    // ============================================================
    // 4. Notification パターン
    // ============================================================

    mod notification_tests {
        use super::*;

        #[test]
        fn mock_notification_records_sent() {
            let notification = MockNotification::new();
            notification.send("user@example.com", "Subject", "Body");

            let sent = notification.get_sent_notifications();
            assert_eq!(sent.len(), 1);
            assert_eq!(sent[0], ("user@example.com".to_string(), "Subject".to_string(), "Body".to_string()));
        }

        #[test]
        fn mock_notification_records_multiple() {
            let notification = MockNotification::new();
            notification.send("a@example.com", "S1", "B1");
            notification.send("b@example.com", "S2", "B2");

            assert_eq!(notification.get_sent_notifications().len(), 2);
        }

        #[test]
        fn order_service_sends_notification() {
            let notification = MockNotification::new();
            let order_service = OrderService::new(&notification);

            order_service.place_order("user123", "ORD001", 99.99);

            let sent = notification.get_sent_notifications();
            assert_eq!(sent.len(), 1);
            assert_eq!(sent[0].0, "user123");
            assert!(sent[0].1.contains("ORD001"));
        }
    }

    // ============================================================
    // 5. Storage パターン
    // ============================================================

    mod storage_tests {
        use super::*;

        #[test]
        fn memory_storage_writes_and_reads() {
            let storage = MemoryStorage::new();
            storage.write("key1", "value1");

            assert_eq!(storage.read("key1"), Some("value1".to_string()));
        }

        #[test]
        fn memory_storage_checks_existence() {
            let storage = MemoryStorage::new();
            assert!(!storage.exists("key"));
            storage.write("key", "value");
            assert!(storage.exists("key"));
        }

        #[test]
        fn memory_storage_deletes() {
            let storage = MemoryStorage::new();
            storage.write("key", "value");
            assert!(storage.delete("key"));
            assert!(storage.read("key").is_none());
        }

        #[test]
        fn memory_storage_delete_nonexistent_returns_false() {
            let storage = MemoryStorage::new();
            assert!(!storage.delete("nonexistent"));
        }

        #[test]
        fn file_storage_uses_base_path() {
            let storage = FileStorage::new("/tmp/test");
            storage.write("config.json", "{}");

            assert_eq!(storage.read("config.json"), Some("{}".to_string()));
            assert!(storage.exists("config.json"));
        }

        #[test]
        fn cache_service_sets_and_gets() {
            let storage = MemoryStorage::new();
            let cache = CacheService::new(&storage, 60000);

            cache.set("user:1", "Alice");
            assert_eq!(cache.get("user:1"), Some("Alice".to_string()));
        }

        #[test]
        fn cache_service_invalidates() {
            let storage = MemoryStorage::new();
            let cache = CacheService::new(&storage, 60000);

            cache.set("user:1", "Alice");
            cache.invalidate("user:1");
            assert!(cache.get("user:1").is_none());
        }
    }

    // ============================================================
    // 6. 関数型アプローチ
    // ============================================================

    mod functional_tests {
        use super::*;

        #[test]
        fn functional_switch_operates_device() {
            let switch = FunctionalSwitch::new(simple_device_switchable());
            let device = SimpleDevice::new();

            assert_eq!(switch.status(&device), "off");
            assert_eq!(switch.status(&switch.engage(&device)), "on");
            assert_eq!(switch.status(&switch.disengage(&switch.engage(&device))), "off");
        }

        #[test]
        fn functional_switch_toggles() {
            let switch = FunctionalSwitch::new(simple_device_switchable());
            let device = SimpleDevice::new();

            assert_eq!(switch.status(&switch.toggle(&device)), "on");
            assert_eq!(switch.status(&switch.toggle(&switch.toggle(&device))), "off");
        }
    }

    // ============================================================
    // 7. 依存性注入
    // ============================================================

    mod dependency_injection_tests {
        use super::*;

        #[test]
        fn user_management_service_registers_user() {
            let repo = create_user_repository();
            let notification = MockNotification::new();
            let logger = TestLogger::new();
            let service = UserManagementService::new(&repo, &notification, &logger);

            let user = service.register_user("Alice", "alice@example.com");

            assert_eq!(user.name, "Alice");
            assert!(repo.find_by_id(&user.id.clone().unwrap()).is_some());
            assert_eq!(notification.get_sent_notifications().len(), 1);
            assert!(logger.get_logs().iter().any(|(_, msg)| msg.contains("Alice")));
        }

        #[test]
        fn user_management_service_deactivates_user() {
            let repo = create_user_repository();
            let notification = MockNotification::new();
            let logger = TestLogger::new();
            let service = UserManagementService::new(&repo, &notification, &logger);

            let user = service.register_user("Bob", "bob@example.com");
            notification.clear();
            logger.clear();

            let deleted = service.deactivate_user(&user.id.clone().unwrap());

            assert!(deleted.is_some());
            assert!(repo.find_by_id(&user.id.unwrap()).is_none());
            assert_eq!(notification.get_sent_notifications().len(), 1);
        }

        #[test]
        fn user_management_service_warns_on_nonexistent_user() {
            let repo = create_user_repository();
            let notification = MockNotification::new();
            let logger = TestLogger::new();
            let service = UserManagementService::new(&repo, &notification, &logger);

            let result = service.deactivate_user(&"nonexistent".to_string());

            assert!(result.is_none());
            assert!(logger.get_logs().iter().any(|(level, _)| level == "WARN"));
        }
    }

    // ============================================================
    // 8. Payment Gateway パターン
    // ============================================================

    mod payment_gateway_tests {
        use super::*;

        #[test]
        fn mock_gateway_records_charges() {
            let gateway = MockPaymentGateway::new();
            let result = gateway.charge(100.0, "valid_token");

            assert!(result.is_success());
            assert_eq!(gateway.get_charges().len(), 1);
            assert_eq!(gateway.get_charges()[0], (100.0, "valid_token".to_string()));
        }

        #[test]
        fn mock_gateway_simulates_failure() {
            let gateway = MockPaymentGateway::new();
            gateway.set_should_fail(true);

            assert!(!gateway.charge(100.0, "valid_token").is_success());
        }

        #[test]
        fn mock_gateway_records_refunds() {
            let gateway = MockPaymentGateway::new();
            if let PaymentResult::Success { transaction_id, .. } = gateway.charge(100.0, "valid_token") {
                let refund_result = gateway.refund(&transaction_id, 50.0);
                assert!(refund_result.is_success());
                assert_eq!(gateway.get_refunds().len(), 1);
            }
        }

        #[test]
        fn stripe_gateway_charges_with_valid_token() {
            let gateway = StripeGateway;
            let result = gateway.charge(100.0, "valid_token");

            assert!(result.is_success());
            if let PaymentResult::Success { transaction_id, .. } = result {
                assert!(transaction_id.starts_with("stripe_"));
            }
        }

        #[test]
        fn stripe_gateway_fails_with_invalid_token() {
            let gateway = StripeGateway;
            let result = gateway.charge(100.0, "invalid_token");

            assert!(!result.is_success());
        }

        #[test]
        fn paypal_gateway_charges_with_valid_token() {
            let gateway = PayPalGateway;
            let result = gateway.charge(100.0, "valid_token");

            assert!(result.is_success());
            if let PaymentResult::Success { transaction_id, .. } = result {
                assert!(transaction_id.starts_with("paypal_"));
            }
        }

        #[test]
        fn checkout_service_processes_payment() {
            let gateway = MockPaymentGateway::new();
            let service = CheckoutService::new(&gateway);

            let result = service.process_payment(100.0, "valid_token");

            assert!(result.is_ok());
        }

        #[test]
        fn checkout_service_returns_error_on_failure() {
            let gateway = MockPaymentGateway::new();
            gateway.set_should_fail(true);
            let service = CheckoutService::new(&gateway);

            let result = service.process_payment(100.0, "valid_token");

            assert!(result.is_err());
        }

        #[test]
        fn checkout_service_processes_refund() {
            let gateway = MockPaymentGateway::new();
            let service = CheckoutService::new(&gateway);

            let payment_result = service.process_payment(100.0, "valid_token");
            let transaction_id = payment_result.unwrap();
            let refund_result = service.refund_payment(&transaction_id, 50.0);

            assert!(refund_result.is_ok());
        }

        #[test]
        fn checkout_service_switches_gateways() {
            let stripe_service = CheckoutService::new(&StripeGateway);
            let paypal_service = CheckoutService::new(&PayPalGateway);

            let stripe_result = stripe_service.process_payment(100.0, "valid_token").unwrap();
            let paypal_result = paypal_service.process_payment(100.0, "valid_token").unwrap();

            assert!(stripe_result.starts_with("stripe_"));
            assert!(paypal_result.starts_with("paypal_"));
        }
    }
}
