//! 第21章: ベストプラクティス
//!
//! データ中心設計、純粋関数と副作用の分離、テスト可能な設計パターンの実装例。

use rust_decimal::Decimal;
use rust_decimal_macros::dec;

// ============================================================
// 1. データ中心設計
// ============================================================

/// シンプルなデータ構造を使用
#[derive(Debug, Clone, PartialEq)]
pub struct User {
    pub id: String,
    pub name: String,
    pub email: String,
    pub created_at: i64,
}

impl User {
    pub fn new(id: &str, name: &str, email: &str) -> Self {
        Self {
            id: id.to_string(),
            name: name.to_string(),
            email: email.to_string(),
            created_at: 0,
        }
    }

    pub fn with_created_at(mut self, created_at: i64) -> Self {
        self.created_at = created_at;
        self
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct OrderItem {
    pub product_id: String,
    pub quantity: i32,
    pub price: Decimal,
}

impl OrderItem {
    pub fn new(product_id: &str, quantity: i32, price: Decimal) -> Self {
        Self {
            product_id: product_id.to_string(),
            quantity,
            price,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Default)]
pub enum OrderStatus {
    #[default]
    Pending,
    Processing,
    Completed,
    Cancelled,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Order {
    pub id: String,
    pub user_id: String,
    pub items: Vec<OrderItem>,
    pub status: OrderStatus,
    pub created_at: i64,
}

impl Order {
    pub fn new(id: &str, user_id: &str, items: Vec<OrderItem>) -> Self {
        Self {
            id: id.to_string(),
            user_id: user_id.to_string(),
            items,
            status: OrderStatus::Pending,
            created_at: 0,
        }
    }

    pub fn with_status(mut self, status: OrderStatus) -> Self {
        self.status = status;
        self
    }

    pub fn with_created_at(mut self, created_at: i64) -> Self {
        self.created_at = created_at;
        self
    }
}

// ============================================================
// 2. 小さな純粋関数
// ============================================================

pub mod order_calculations {
    use super::*;

    /// 各関数は単一の責任を持つ
    pub fn calculate_item_total(item: &OrderItem) -> Decimal {
        item.price * Decimal::from(item.quantity)
    }

    pub fn calculate_order_total(order: &Order) -> Decimal {
        order.items.iter().map(calculate_item_total).sum()
    }

    pub fn apply_discount(total: Decimal, discount_rate: Decimal) -> Decimal {
        total * (Decimal::ONE - discount_rate)
    }

    pub fn apply_tax(total: Decimal, tax_rate: Decimal) -> Decimal {
        total * (Decimal::ONE + tax_rate)
    }
}

// ============================================================
// 3. データ変換パイプライン
// ============================================================

#[derive(Debug, Clone, PartialEq)]
pub struct ProcessedOrder {
    pub order: Order,
    pub subtotal: Decimal,
    pub discount: Decimal,
    pub tax: Decimal,
    pub total: Decimal,
}

pub mod order_processing {
    use super::*;
    use super::order_calculations::*;

    pub fn process_order(
        order: Order,
        discount_rate: Decimal,
        tax_rate: Decimal,
    ) -> ProcessedOrder {
        let subtotal = calculate_order_total(&order);
        let discounted_subtotal = apply_discount(subtotal, discount_rate);
        let discount = subtotal - discounted_subtotal;
        let tax = discounted_subtotal * tax_rate;
        let total = discounted_subtotal + tax;

        ProcessedOrder {
            order: order.with_status(OrderStatus::Processing),
            subtotal,
            discount,
            tax,
            total,
        }
    }
}

// ============================================================
// 4. データ検証
// ============================================================

#[derive(Debug, Clone)]
pub enum ValidationResult<T> {
    Valid(T),
    Invalid(Vec<String>),
}

impl<T> ValidationResult<T> {
    pub fn is_valid(&self) -> bool {
        matches!(self, ValidationResult::Valid(_))
    }

    pub fn map<U, F: FnOnce(T) -> U>(self, f: F) -> ValidationResult<U> {
        match self {
            ValidationResult::Valid(v) => ValidationResult::Valid(f(v)),
            ValidationResult::Invalid(errs) => ValidationResult::Invalid(errs),
        }
    }

    pub fn flat_map<U, F: FnOnce(T) -> ValidationResult<U>>(self, f: F) -> ValidationResult<U> {
        match self {
            ValidationResult::Valid(v) => f(v),
            ValidationResult::Invalid(errs) => ValidationResult::Invalid(errs),
        }
    }
}

pub mod validation {
    use super::*;
    use regex::Regex;

    pub fn valid_email(email: &str) -> bool {
        let re = Regex::new(r"^[^@]+@[^@]+\.[^@]+$").unwrap();
        re.is_match(email)
    }

    pub fn non_empty(s: &str) -> bool {
        !s.trim().is_empty()
    }

    pub fn positive(n: Decimal) -> bool {
        n > Decimal::ZERO
    }

    pub fn validate_user(user: User) -> ValidationResult<User> {
        let mut errors = Vec::new();

        if !non_empty(&user.name) {
            errors.push("Name is required".to_string());
        }
        if !valid_email(&user.email) {
            errors.push("Invalid email format".to_string());
        }

        if errors.is_empty() {
            ValidationResult::Valid(user)
        } else {
            ValidationResult::Invalid(errors)
        }
    }

    pub fn validate_order_item(item: OrderItem) -> ValidationResult<OrderItem> {
        let mut errors = Vec::new();

        if item.quantity <= 0 {
            errors.push("Quantity must be positive".to_string());
        }
        if !positive(item.price) {
            errors.push("Price must be positive".to_string());
        }

        if errors.is_empty() {
            ValidationResult::Valid(item)
        } else {
            ValidationResult::Invalid(errors)
        }
    }

    pub fn validate_order(order: Order) -> ValidationResult<Order> {
        let mut errors = Vec::new();

        if order.items.is_empty() {
            errors.push("Order must have at least one item".to_string());
        }

        for item in &order.items {
            match validate_order_item(item.clone()) {
                ValidationResult::Invalid(errs) => errors.extend(errs),
                _ => {}
            }
        }

        if errors.is_empty() {
            ValidationResult::Valid(order)
        } else {
            ValidationResult::Invalid(errors)
        }
    }
}

// ============================================================
// 5. イミュータブルな更新
// ============================================================

pub mod immutable_updates {
    use super::*;
    use super::validation::*;

    pub fn update_user_email(user: User, new_email: &str) -> Result<User, String> {
        if valid_email(new_email) {
            Ok(User {
                email: new_email.to_string(),
                ..user
            })
        } else {
            Err("Invalid email format".to_string())
        }
    }

    pub fn add_order_item(order: Order, item: OrderItem) -> Result<Order, String> {
        match validate_order_item(item.clone()) {
            ValidationResult::Valid(_) => {
                let mut items = order.items;
                items.push(item);
                Ok(Order { items, ..order })
            }
            ValidationResult::Invalid(errs) => Err(errs.join(", ")),
        }
    }

    pub fn cancel_order(order: Order) -> Result<Order, String> {
        if order.status == OrderStatus::Pending {
            Ok(order.with_status(OrderStatus::Cancelled))
        } else {
            Err("Only pending orders can be cancelled".to_string())
        }
    }
}

// ============================================================
// 6. 純粋関数と副作用の分離
// ============================================================

/// 副作用を表現する型
pub enum IO<T> {
    Pure(T),
    Suspend(Box<dyn FnOnce() -> T>),
    Map(Box<dyn FnOnce() -> T>),
    FlatMap(Box<dyn FnOnce() -> T>),
}

impl<T: 'static> IO<T> {
    pub fn pure(value: T) -> Self {
        IO::Pure(value)
    }

    pub fn suspend<F: FnOnce() -> T + 'static>(thunk: F) -> Self {
        IO::Suspend(Box::new(thunk))
    }

    pub fn run(self) -> T {
        match self {
            IO::Pure(v) => v,
            IO::Suspend(thunk) => thunk(),
            IO::Map(thunk) => thunk(),
            IO::FlatMap(thunk) => thunk(),
        }
    }

    pub fn map<U: 'static, F: FnOnce(T) -> U + 'static>(self, f: F) -> IO<U> {
        IO::Map(Box::new(move || f(self.run())))
    }

    pub fn flat_map<U: 'static, F: FnOnce(T) -> IO<U> + 'static>(self, f: F) -> IO<U> {
        IO::FlatMap(Box::new(move || f(self.run()).run()))
    }
}

// ============================================================
// 7. 高階関数によるデコレーション
// ============================================================

pub mod function_decorators {
    use std::collections::HashMap;
    use std::hash::Hash;
    use std::sync::{Arc, Mutex};
    use std::time::Instant;

    /// ロギングデコレータ
    pub fn with_logging<A: Clone + std::fmt::Debug, B: std::fmt::Debug>(
        f: impl Fn(A) -> B,
        mut logger: impl FnMut(String),
    ) -> impl FnMut(A) -> B {
        move |a: A| {
            logger(format!("Input: {:?}", a));
            let result = f(a);
            logger(format!("Output: {:?}", result));
            result
        }
    }

    /// 計測デコレータ
    pub fn with_timing<A, B>(
        f: impl Fn(A) -> B,
        mut reporter: impl FnMut(u128),
    ) -> impl FnMut(A) -> B {
        move |a: A| {
            let start = Instant::now();
            let result = f(a);
            let elapsed = start.elapsed().as_nanos();
            reporter(elapsed);
            result
        }
    }

    /// リトライデコレータ
    pub fn with_retry<A: Clone, B, E>(
        f: impl Fn(A) -> Result<B, E>,
        max_retries: usize,
    ) -> impl Fn(A) -> Result<B, E> {
        move |a: A| {
            let mut remaining = max_retries;
            loop {
                match f(a.clone()) {
                    Ok(b) => return Ok(b),
                    Err(e) if remaining > 0 => {
                        remaining -= 1;
                    }
                    Err(e) => return Err(e),
                }
            }
        }
    }

    /// キャッシュデコレータ
    pub fn with_cache<A: Clone + Eq + Hash + 'static, B: Clone + 'static>(
        f: impl Fn(A) -> B + 'static,
    ) -> impl FnMut(A) -> B {
        let cache: Arc<Mutex<HashMap<A, B>>> = Arc::new(Mutex::new(HashMap::new()));
        move |a: A| {
            let mut cache = cache.lock().unwrap();
            if let Some(v) = cache.get(&a) {
                v.clone()
            } else {
                let result = f(a.clone());
                cache.insert(a, result.clone());
                result
            }
        }
    }
}

// ============================================================
// 8. 関数合成
// ============================================================

pub mod function_composition {
    /// パイプライン形式の関数合成
    pub fn pipeline<T: Clone>(fns: Vec<Box<dyn Fn(T) -> T>>) -> impl Fn(T) -> T {
        move |x: T| {
            let mut result = x;
            for f in &fns {
                result = f(result);
            }
            result
        }
    }

    /// 条件付き関数適用
    pub fn when<T>(condition: bool, f: impl Fn(T) -> T + 'static) -> Box<dyn Fn(T) -> T> {
        if condition {
            Box::new(f)
        } else {
            Box::new(|x| x)
        }
    }

    /// 繰り返し適用
    pub fn repeat<T: Clone>(n: usize, f: impl Fn(T) -> T + Clone + 'static) -> impl Fn(T) -> T {
        move |x: T| {
            let mut result = x;
            for _ in 0..n {
                result = f(result);
            }
            result
        }
    }
}

// ============================================================
// 9. テスト可能な設計 - 依存性注入
// ============================================================

/// リポジトリインターフェース
pub trait Repository<T: Clone, ID> {
    fn find_by_id(&self, id: &ID) -> Option<T>;
    fn find_all(&self) -> Vec<T>;
    fn save(&mut self, entity: T) -> T;
    fn delete(&mut self, id: &ID) -> bool;
}

/// インメモリリポジトリ（テスト用）
pub struct InMemoryRepository<T, ID, F>
where
    F: Fn(&T) -> ID,
{
    data: Vec<T>,
    id_extractor: F,
}

impl<T: Clone, ID: PartialEq, F: Fn(&T) -> ID> InMemoryRepository<T, ID, F> {
    pub fn new(id_extractor: F) -> Self {
        Self {
            data: Vec::new(),
            id_extractor,
        }
    }
}

impl<T: Clone, ID: PartialEq, F: Fn(&T) -> ID> Repository<T, ID>
    for InMemoryRepository<T, ID, F>
{
    fn find_by_id(&self, id: &ID) -> Option<T> {
        self.data
            .iter()
            .find(|e| (self.id_extractor)(e) == *id)
            .cloned()
    }

    fn find_all(&self) -> Vec<T> {
        self.data.clone()
    }

    fn save(&mut self, entity: T) -> T {
        let id = (self.id_extractor)(&entity);
        self.data.retain(|e| (self.id_extractor)(e) != id);
        self.data.push(entity.clone());
        entity
    }

    fn delete(&mut self, id: &ID) -> bool {
        let size_before = self.data.len();
        self.data.retain(|e| (self.id_extractor)(e) != *id);
        self.data.len() < size_before
    }
}

// ============================================================
// 10. テスト可能な設計 - 時間の抽象化
// ============================================================

/// 時間プロバイダー
pub trait Clock {
    fn now(&self) -> i64;
}

pub struct SystemClock;

impl Clock for SystemClock {
    fn now(&self) -> i64 {
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis() as i64
    }
}

pub struct FixedClock {
    time: i64,
}

impl FixedClock {
    pub fn new(time: i64) -> Self {
        Self { time }
    }
}

impl Clock for FixedClock {
    fn now(&self) -> i64 {
        self.time
    }
}

/// ID生成器
pub trait IdGenerator {
    fn generate(&mut self) -> String;
}

pub struct UuidGenerator;

impl IdGenerator for UuidGenerator {
    fn generate(&mut self) -> String {
        uuid::Uuid::new_v4().to_string()
    }
}

pub struct SequentialIdGenerator {
    prefix: String,
    counter: usize,
}

impl SequentialIdGenerator {
    pub fn new(prefix: &str) -> Self {
        Self {
            prefix: prefix.to_string(),
            counter: 0,
        }
    }
}

impl IdGenerator for SequentialIdGenerator {
    fn generate(&mut self) -> String {
        self.counter += 1;
        format!("{}-{}", self.prefix, self.counter)
    }
}

// ============================================================
// 11. テスト可能な設計 - 設定の分離
// ============================================================

#[derive(Clone)]
pub struct PricingConfig {
    pub tax_rate: Decimal,
    pub discount_rate: Decimal,
    pub currency: String,
}

impl Default for PricingConfig {
    fn default() -> Self {
        Self {
            tax_rate: dec!(0.1),
            discount_rate: dec!(0.0),
            currency: "JPY".to_string(),
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct PriceBreakdown {
    pub base_price: Decimal,
    pub discounted_price: Decimal,
    pub tax: Decimal,
    pub total: Decimal,
    pub currency: String,
}

pub mod pricing {
    use super::*;

    pub fn calculate_price(config: &PricingConfig, base_price: Decimal) -> PriceBreakdown {
        let discounted = base_price * (Decimal::ONE - config.discount_rate);
        let tax = discounted * config.tax_rate;
        let total = discounted + tax;

        PriceBreakdown {
            base_price,
            discounted_price: discounted,
            tax,
            total,
            currency: config.currency.clone(),
        }
    }
}

// ============================================================
// 12. テスト可能な設計 - 検証の分離
// ============================================================

pub type Validator<T> = Box<dyn Fn(&T) -> Vec<String>>;

pub mod validators {
    use super::*;
    use super::validation::valid_email;

    pub fn required(field_name: &str) -> Validator<Option<String>> {
        let field_name = field_name.to_string();
        Box::new(move |value: &Option<String>| {
            if value.is_none() {
                vec![format!("{} is required", field_name)]
            } else {
                vec![]
            }
        })
    }

    pub fn non_empty_string(field_name: &str) -> Validator<String> {
        let field_name = field_name.to_string();
        Box::new(move |value: &String| {
            if value.trim().is_empty() {
                vec![format!("{} must not be empty", field_name)]
            } else {
                vec![]
            }
        })
    }

    pub fn email(field_name: &str) -> Validator<String> {
        let field_name = field_name.to_string();
        Box::new(move |value: &String| {
            if !valid_email(value) {
                vec![format!("{} must be a valid email", field_name)]
            } else {
                vec![]
            }
        })
    }

    pub fn positive(field_name: &str) -> Validator<Decimal> {
        let field_name = field_name.to_string();
        Box::new(move |value: &Decimal| {
            if *value <= Decimal::ZERO {
                vec![format!("{} must be positive", field_name)]
            } else {
                vec![]
            }
        })
    }

    pub fn min_length(field_name: &str, min: usize) -> Validator<String> {
        let field_name = field_name.to_string();
        Box::new(move |value: &String| {
            if value.len() < min {
                vec![format!(
                    "{} must be at least {} characters",
                    field_name, min
                )]
            } else {
                vec![]
            }
        })
    }

    pub fn combine<T: 'static>(validators: Vec<Validator<T>>) -> Validator<T> {
        Box::new(move |value: &T| {
            validators
                .iter()
                .flat_map(|v| v(value))
                .collect::<Vec<_>>()
        })
    }
}

// ============================================================
// 13. サービス層の設計
// ============================================================

pub struct UserService<R, C, I>
where
    R: Repository<User, String>,
    C: Clock,
    I: IdGenerator,
{
    repository: R,
    clock: C,
    id_generator: I,
}

impl<R, C, I> UserService<R, C, I>
where
    R: Repository<User, String>,
    C: Clock,
    I: IdGenerator,
{
    pub fn new(repository: R, clock: C, id_generator: I) -> Self {
        Self {
            repository,
            clock,
            id_generator,
        }
    }

    pub fn create_user(&mut self, name: &str, email: &str) -> Result<User, Vec<String>> {
        let user = User {
            id: self.id_generator.generate(),
            name: name.to_string(),
            email: email.to_string(),
            created_at: self.clock.now(),
        };

        match validation::validate_user(user) {
            ValidationResult::Valid(u) => Ok(self.repository.save(u)),
            ValidationResult::Invalid(errors) => Err(errors),
        }
    }

    pub fn get_user(&self, id: &str) -> Option<User> {
        self.repository.find_by_id(&id.to_string())
    }

    pub fn update_email(&mut self, id: &str, new_email: &str) -> Result<User, String> {
        match self.repository.find_by_id(&id.to_string()) {
            Some(user) => {
                immutable_updates::update_user_email(user, new_email).map(|u| self.repository.save(u))
            }
            None => Err(format!("User not found: {}", id)),
        }
    }

    pub fn get_all_users(&self) -> Vec<User> {
        self.repository.find_all()
    }
}

// ============================================================
// 14. DSL
// ============================================================

pub mod dsl {
    use super::*;

    pub fn user(
        clock: &dyn Clock,
        id_gen: &mut dyn IdGenerator,
        name: &str,
        email: &str,
    ) -> User {
        User {
            id: id_gen.generate(),
            name: name.to_string(),
            email: email.to_string(),
            created_at: clock.now(),
        }
    }

    pub fn order(
        clock: &dyn Clock,
        id_gen: &mut dyn IdGenerator,
        user_id: &str,
        items: Vec<OrderItem>,
    ) -> Order {
        Order {
            id: id_gen.generate(),
            user_id: user_id.to_string(),
            items,
            status: OrderStatus::Pending,
            created_at: clock.now(),
        }
    }

    pub fn item(product_id: &str, quantity: i32, price: Decimal) -> OrderItem {
        OrderItem::new(product_id, quantity, price)
    }

    pub trait OrderExt {
        fn with_item(self, item: OrderItem) -> Order;
        fn process(self, discount_rate: Decimal, tax_rate: Decimal) -> ProcessedOrder;
    }

    impl OrderExt for Order {
        fn with_item(mut self, item: OrderItem) -> Order {
            self.items.push(item);
            self
        }

        fn process(self, discount_rate: Decimal, tax_rate: Decimal) -> ProcessedOrder {
            order_processing::process_order(self, discount_rate, tax_rate)
        }
    }
}

// ============================================================
// 15. 結果型
// ============================================================

#[derive(Debug, Clone)]
pub enum Result2<E, A> {
    Success(A),
    Failure(E),
}

impl<E, A> Result2<E, A> {
    pub fn success(value: A) -> Self {
        Result2::Success(value)
    }

    pub fn failure(error: E) -> Self {
        Result2::Failure(error)
    }

    pub fn is_success(&self) -> bool {
        matches!(self, Result2::Success(_))
    }

    pub fn get_or_else(self, default: A) -> A {
        match self {
            Result2::Success(a) => a,
            Result2::Failure(_) => default,
        }
    }

    pub fn map<B, F: FnOnce(A) -> B>(self, f: F) -> Result2<E, B> {
        match self {
            Result2::Success(a) => Result2::Success(f(a)),
            Result2::Failure(e) => Result2::Failure(e),
        }
    }

    pub fn flat_map<B, F: FnOnce(A) -> Result2<E, B>>(self, f: F) -> Result2<E, B> {
        match self {
            Result2::Success(a) => f(a),
            Result2::Failure(e) => Result2::Failure(e),
        }
    }
}

impl<A> Result2<String, A> {
    pub fn from_option(opt: Option<A>, if_none: &str) -> Self {
        match opt {
            Some(a) => Result2::Success(a),
            None => Result2::Failure(if_none.to_string()),
        }
    }
}

impl<E, A> Result2<E, A> {
    pub fn from_either(either: Result<A, E>) -> Self {
        match either {
            Ok(a) => Result2::Success(a),
            Err(e) => Result2::Failure(e),
        }
    }
}

// ============================================================
// テスト
// ============================================================

#[cfg(test)]
mod tests {
    use super::*;
    use rust_decimal_macros::dec;

    mod data_centric_design_tests {
        use super::*;

        mod user_tests {
            use super::*;

            #[test]
            fn creates_user() {
                let user = User::new("u1", "John", "john@example.com");
                assert_eq!(user.id, "u1");
                assert_eq!(user.name, "John");
                assert_eq!(user.email, "john@example.com");
            }
        }

        mod order_tests {
            use super::*;

            #[test]
            fn creates_order() {
                let items = vec![OrderItem::new("p1", 2, dec!(100))];
                let order = Order::new("o1", "u1", items);
                assert_eq!(order.items.len(), 1);
                assert_eq!(order.status, OrderStatus::Pending);
            }
        }
    }

    mod pure_function_tests {
        use super::*;
        use super::order_calculations::*;

        #[test]
        fn calculates_item_total() {
            let item = OrderItem::new("p1", 2, dec!(100));
            assert_eq!(calculate_item_total(&item), dec!(200));
        }

        #[test]
        fn calculates_order_total() {
            let items = vec![
                OrderItem::new("p1", 2, dec!(100)),
                OrderItem::new("p2", 1, dec!(200)),
            ];
            let order = Order::new("o1", "u1", items);
            assert_eq!(calculate_order_total(&order), dec!(400));
        }

        #[test]
        fn applies_discount() {
            assert_eq!(apply_discount(dec!(100), dec!(0.1)), dec!(90));
        }

        #[test]
        fn applies_tax() {
            assert_eq!(apply_tax(dec!(100), dec!(0.1)), dec!(110));
        }
    }

    mod data_transformation_tests {
        use super::*;
        use super::order_processing::*;

        #[test]
        fn processes_order() {
            let items = vec![OrderItem::new("p1", 2, dec!(100))];
            let order = Order::new("o1", "u1", items);
            let processed = process_order(order, dec!(0.1), dec!(0.08));

            assert_eq!(processed.subtotal, dec!(200));
            assert_eq!(processed.discount, dec!(20));
            assert_eq!(processed.order.status, OrderStatus::Processing);
        }
    }

    mod validation_tests {
        use super::*;
        use super::validation::*;

        #[test]
        fn validates_email() {
            assert!(valid_email("test@example.com"));
            assert!(!valid_email("invalid"));
            assert!(!valid_email(""));
        }

        #[test]
        fn validates_valid_user() {
            let user = User::new("u1", "John", "john@example.com");
            assert!(validate_user(user).is_valid());
        }

        #[test]
        fn detects_invalid_user() {
            let user = User::new("u1", "", "invalid");
            match validate_user(user) {
                ValidationResult::Invalid(errors) => {
                    assert_eq!(errors.len(), 2);
                }
                _ => panic!("Should be invalid"),
            }
        }

        #[test]
        fn validates_valid_order() {
            let items = vec![OrderItem::new("p1", 2, dec!(100))];
            let order = Order::new("o1", "u1", items);
            assert!(validate_order(order).is_valid());
        }

        #[test]
        fn detects_empty_order() {
            let order = Order::new("o1", "u1", vec![]);
            match validate_order(order) {
                ValidationResult::Invalid(errors) => {
                    assert!(errors.contains(&"Order must have at least one item".to_string()));
                }
                _ => panic!("Should be invalid"),
            }
        }

        #[test]
        fn detects_invalid_item() {
            let items = vec![OrderItem::new("p1", -1, dec!(100))];
            let order = Order::new("o1", "u1", items);
            match validate_order(order) {
                ValidationResult::Invalid(errors) => {
                    assert!(errors.contains(&"Quantity must be positive".to_string()));
                }
                _ => panic!("Should be invalid"),
            }
        }
    }

    mod immutable_updates_tests {
        use super::*;
        use super::immutable_updates::*;

        #[test]
        fn updates_user_email() {
            let user = User::new("u1", "John", "john@example.com");
            match update_user_email(user, "new@example.com") {
                Ok(updated) => assert_eq!(updated.email, "new@example.com"),
                Err(_) => panic!("Should succeed"),
            }
        }

        #[test]
        fn fails_with_invalid_email() {
            let user = User::new("u1", "John", "john@example.com");
            assert!(update_user_email(user, "invalid").is_err());
        }

        #[test]
        fn adds_order_item() {
            let order = Order::new("o1", "u1", vec![]);
            let item = OrderItem::new("p1", 2, dec!(100));
            match add_order_item(order, item) {
                Ok(updated) => assert_eq!(updated.items.len(), 1),
                Err(_) => panic!("Should succeed"),
            }
        }

        #[test]
        fn cancels_pending_order() {
            let order = Order::new("o1", "u1", vec![]);
            match cancel_order(order) {
                Ok(cancelled) => assert_eq!(cancelled.status, OrderStatus::Cancelled),
                Err(_) => panic!("Should succeed"),
            }
        }

        #[test]
        fn cannot_cancel_processing_order() {
            let order = Order::new("o1", "u1", vec![]).with_status(OrderStatus::Processing);
            assert!(cancel_order(order).is_err());
        }
    }

    mod io_tests {
        use super::*;

        #[test]
        fn wraps_pure_value() {
            let io = IO::pure(42);
            assert_eq!(io.run(), 42);
        }

        #[test]
        fn delays_evaluation() {
            use std::sync::atomic::{AtomicBool, Ordering};
            use std::sync::Arc;

            let side_effect = Arc::new(AtomicBool::new(false));
            let side_effect_clone = side_effect.clone();

            let io = IO::suspend(move || {
                side_effect_clone.store(true, Ordering::SeqCst);
                42
            });

            assert!(!side_effect.load(Ordering::SeqCst));
            assert_eq!(io.run(), 42);
            assert!(side_effect.load(Ordering::SeqCst));
        }

        #[test]
        fn maps_value() {
            let io = IO::pure(21).map(|x| x * 2);
            assert_eq!(io.run(), 42);
        }

        #[test]
        fn flat_maps_value() {
            let io = IO::pure(10).flat_map(|x| IO::pure(x + 5));
            assert_eq!(io.run(), 15);
        }
    }

    mod function_decorator_tests {
        use super::function_decorators::*;
        use std::sync::{Arc, Mutex};

        #[test]
        fn with_logging_adds_logging() {
            let logs = Arc::new(Mutex::new(Vec::new()));
            let logs_clone = logs.clone();

            let add = |x: i32| x + 1;
            let mut logged = with_logging(add, move |s| {
                logs_clone.lock().unwrap().push(s);
            });

            assert_eq!(logged(5), 6);
            assert_eq!(logs.lock().unwrap().len(), 2);
        }

        #[test]
        fn with_timing_adds_timing() {
            let elapsed = Arc::new(Mutex::new(0u128));
            let elapsed_clone = elapsed.clone();

            let slow = |_: i32| {
                std::thread::sleep(std::time::Duration::from_millis(10));
            };
            let mut timed = with_timing(slow, move |e| {
                *elapsed_clone.lock().unwrap() = e;
            });

            timed(1);
            assert!(*elapsed.lock().unwrap() > 0);
        }

        #[test]
        fn with_retry_retries_on_failure() {
            let attempts = Arc::new(Mutex::new(0));
            let attempts_clone = attempts.clone();

            let flaky = move |_: i32| -> Result<i32, &'static str> {
                let mut count = attempts_clone.lock().unwrap();
                *count += 1;
                if *count < 3 {
                    Err("fail")
                } else {
                    Ok(42)
                }
            };
            let retried = with_retry(flaky, 5);

            assert_eq!(retried(1).unwrap(), 42);
            assert_eq!(*attempts.lock().unwrap(), 3);
        }

        #[test]
        fn with_cache_caches_results() {
            let computations = Arc::new(Mutex::new(0));
            let computations_clone = computations.clone();

            let expensive = move |x: i32| {
                *computations_clone.lock().unwrap() += 1;
                x * 2
            };
            let mut cached = with_cache(expensive);

            assert_eq!(cached(5), 10);
            assert_eq!(cached(5), 10);
            assert_eq!(cached(3), 6);
            assert_eq!(*computations.lock().unwrap(), 2);
        }
    }

    mod function_composition_tests {
        use super::function_composition::*;

        #[test]
        fn pipeline_composes_functions() {
            let process = pipeline::<i32>(vec![
                Box::new(|x| x + 1),
                Box::new(|x| x * 2),
                Box::new(|x| x - 3),
            ]);
            assert_eq!(process(5), 9); // (5+1)*2-3 = 9
        }

        #[test]
        fn when_conditionally_applies() {
            let maybe_double = when(true, |x: i32| x * 2);
            assert_eq!(maybe_double(5), 10);

            let noop = when(false, |x: i32| x * 2);
            assert_eq!(noop(5), 5);
        }

        #[test]
        fn repeat_applies_multiple_times() {
            let add_three = repeat(3, |x: i32| x + 1);
            assert_eq!(add_three(0), 3);
        }
    }

    mod repository_tests {
        use super::*;

        #[test]
        fn in_memory_repository_works() {
            let mut repo: InMemoryRepository<User, String, _> =
                InMemoryRepository::new(|u: &User| u.id.clone());

            let user = User::new("u1", "John", "john@example.com");
            repo.save(user.clone());

            assert_eq!(repo.find_by_id(&"u1".to_string()), Some(user.clone()));
            assert_eq!(repo.find_all().len(), 1);
        }

        #[test]
        fn deletes_entity() {
            let mut repo: InMemoryRepository<User, String, _> =
                InMemoryRepository::new(|u: &User| u.id.clone());

            let user = User::new("u1", "John", "john@example.com");
            repo.save(user);

            assert!(repo.delete(&"u1".to_string()));
            assert_eq!(repo.find_by_id(&"u1".to_string()), None);
        }
    }

    mod time_abstraction_tests {
        use super::*;

        #[test]
        fn fixed_clock_returns_fixed_time() {
            let clock = FixedClock::new(1000);
            assert_eq!(clock.now(), 1000);
        }

        #[test]
        fn sequential_id_generator_generates_ids() {
            let mut id_gen = SequentialIdGenerator::new("test");
            assert_eq!(id_gen.generate(), "test-1");
            assert_eq!(id_gen.generate(), "test-2");
        }
    }

    mod pricing_config_tests {
        use super::*;
        use super::pricing::*;

        #[test]
        fn calculates_with_default_config() {
            let config = PricingConfig::default();
            let result = calculate_price(&config, dec!(1000));

            assert_eq!(result.discounted_price, dec!(1000));
            assert_eq!(result.tax, dec!(100));
            assert_eq!(result.total, dec!(1100));
        }

        #[test]
        fn calculates_with_custom_config() {
            let config = PricingConfig {
                tax_rate: dec!(0.08),
                discount_rate: dec!(0.1),
                currency: "JPY".to_string(),
            };
            let result = calculate_price(&config, dec!(1000));

            assert_eq!(result.discounted_price, dec!(900));
            assert_eq!(result.tax, dec!(72));
            assert_eq!(result.total, dec!(972));
        }
    }

    mod validators_tests {
        use super::validators::*;

        #[test]
        fn combines_validators() {
            let validate_name = combine(vec![
                non_empty_string("name"),
                min_length("name", 2),
            ]);

            assert!(!validate_name(&"".to_string()).is_empty());
            assert!(!validate_name(&"A".to_string()).is_empty());
            assert!(validate_name(&"John".to_string()).is_empty());
        }

        #[test]
        fn email_validator_works() {
            assert!(email("email")(&"test@example.com".to_string()).is_empty());
            assert!(!email("email")(&"invalid".to_string()).is_empty());
        }
    }

    mod service_tests {
        use super::*;

        #[test]
        fn creates_user() {
            let repo = InMemoryRepository::new(|u: &User| u.id.clone());
            let clock = FixedClock::new(1000);
            let id_gen = SequentialIdGenerator::new("user");
            let mut service = UserService::new(repo, clock, id_gen);

            match service.create_user("John", "john@example.com") {
                Ok(user) => {
                    assert_eq!(user.id, "user-1");
                    assert_eq!(user.created_at, 1000);
                }
                Err(_) => panic!("Should succeed"),
            }
        }

        #[test]
        fn returns_error_for_invalid_user() {
            let repo = InMemoryRepository::new(|u: &User| u.id.clone());
            let clock = FixedClock::new(1000);
            let id_gen = SequentialIdGenerator::new("user");
            let mut service = UserService::new(repo, clock, id_gen);

            match service.create_user("", "invalid") {
                Err(errors) => assert!(!errors.is_empty()),
                Ok(_) => panic!("Should fail"),
            }
        }

        #[test]
        fn updates_email() {
            let repo = InMemoryRepository::new(|u: &User| u.id.clone());
            let clock = FixedClock::new(1000);
            let id_gen = SequentialIdGenerator::new("user");
            let mut service = UserService::new(repo, clock, id_gen);

            service.create_user("John", "john@example.com").unwrap();
            match service.update_email("user-1", "new@example.com") {
                Ok(user) => assert_eq!(user.email, "new@example.com"),
                Err(_) => panic!("Should succeed"),
            }
        }
    }

    mod dsl_tests {
        use super::*;
        use super::dsl::*;

        #[test]
        fn creates_user_with_dsl() {
            let clock = FixedClock::new(1000);
            let mut id_gen = SequentialIdGenerator::new("u");

            let u = user(&clock, &mut id_gen, "John", "john@example.com");
            assert_eq!(u.name, "John");
            assert_eq!(u.id, "u-1");
        }

        #[test]
        fn creates_order_with_dsl() {
            let clock = FixedClock::new(1000);
            let mut id_gen = SequentialIdGenerator::new("o");

            let o = order(&clock, &mut id_gen, "u1", vec![item("p1", 2, dec!(100))]);
            assert_eq!(o.items.len(), 1);
        }

        #[test]
        fn processes_order_with_dsl() {
            let clock = FixedClock::new(1000);
            let mut id_gen = SequentialIdGenerator::new("o");

            let processed = order(&clock, &mut id_gen, "u1", vec![item("p1", 2, dec!(100))])
                .process(dec!(0.1), dec!(0.08));
            assert_eq!(processed.subtotal, dec!(200));
        }
    }

    mod result_type_tests {
        use super::*;

        #[test]
        fn represents_success() {
            let result: Result2<String, i32> = Result2::success(42);
            assert!(result.is_success());
            assert_eq!(result.get_or_else(0), 42);
        }

        #[test]
        fn represents_failure() {
            let result: Result2<String, i32> = Result2::failure("error".to_string());
            assert!(!result.is_success());
            assert_eq!(result.get_or_else(0), 0);
        }

        #[test]
        fn maps_value() {
            let result: Result2<String, i32> = Result2::success(21).map(|x| x * 2);
            assert_eq!(result.get_or_else(0), 42);
        }

        #[test]
        fn flat_maps_value() {
            let result: Result2<String, i32> = Result2::<String, i32>::success(10).flat_map(|x| Result2::success(x + 5));
            assert_eq!(result.get_or_else(0), 15);
        }

        #[test]
        fn converts_from_option() {
            assert_eq!(
                Result2::from_option(Some(42), "error").get_or_else(0),
                42
            );
            match Result2::<String, i32>::from_option(None, "error") {
                Result2::Failure(e) => assert_eq!(e, "error"),
                _ => panic!("Should be failure"),
            }
        }

        #[test]
        fn converts_from_either() {
            assert_eq!(
                Result2::from_either(Ok::<i32, String>(42)).get_or_else(0),
                42
            );
            match Result2::from_either(Err::<i32, String>("error".to_string())) {
                Result2::Failure(e) => assert_eq!(e, "error"),
                _ => panic!("Should be failure"),
            }
        }
    }
}
