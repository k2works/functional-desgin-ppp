//! 第2章: 関数合成と高階関数
//!
//! 小さな関数を組み合わせて複雑な処理を構築する方法を学びます。
//! クロージャ、部分適用などの関数合成ツールと、
//! 高階関数を活用したデータ処理パターンを扱います。

// =============================================================================
// 1. 関数合成の基本
// =============================================================================

/// 税金を追加する
pub fn add_tax(rate: f64) -> impl Fn(f64) -> f64 {
    move |amount| amount * (1.0 + rate)
}

/// 割引を適用する
pub fn apply_discount_rate(rate: f64) -> impl Fn(f64) -> f64 {
    move |amount| amount * (1.0 - rate)
}

/// 円単位に丸める
pub fn round_to_yen(amount: f64) -> i64 {
    amount.round() as i64
}

/// 最終価格を計算する（関数合成）
pub fn calculate_final_price(amount: f64) -> i64 {
    // Rust ではクロージャを直接連鎖させる
    let discounted = apply_discount_rate(0.2)(amount);
    let with_tax = add_tax(0.1)(discounted);
    round_to_yen(with_tax)
}

/// 関数を合成するマクロ的なヘルパー
pub fn compose<A, B, C, F, G>(f: F, g: G) -> impl Fn(A) -> C
where
    F: Fn(A) -> B,
    G: Fn(B) -> C,
{
    move |x| g(f(x))
}

/// パイプライン形式で関数を適用するヘルパー
pub fn pipe<T, R, F: FnOnce(T) -> R>(value: T, f: F) -> R {
    f(value)
}

// =============================================================================
// 2. 部分適用とカリー化
// =============================================================================

/// 挨拶する（カリー化版）
pub fn greet_curried(greeting: &str) -> impl Fn(&str) -> String + '_ {
    move |name| format!("{}, {}!", greeting, name)
}

/// say_hello 関数
pub fn say_hello(name: &str) -> String {
    greet_curried("Hello")(name)
}

/// say_goodbye 関数
pub fn say_goodbye(name: &str) -> String {
    greet_curried("Goodbye")(name)
}

/// メールを表す構造体
#[derive(Debug, Clone, PartialEq)]
pub struct Email {
    pub from: String,
    pub to: String,
    pub subject: String,
    pub body: String,
}

impl Email {
    pub fn new(from: &str, to: &str, subject: &str, body: &str) -> Self {
        Email {
            from: from.to_string(),
            to: to.to_string(),
            subject: subject.to_string(),
            body: body.to_string(),
        }
    }
}

/// メール送信関数（カリー化）
pub fn send_email(from: &str) -> impl Fn(&str) -> Box<dyn Fn(&str) -> Box<dyn Fn(&str) -> Email>> + '_ {
    let from = from.to_string();
    move |to: &str| {
        let from = from.clone();
        let to = to.to_string();
        Box::new(move |subject: &str| {
            let from = from.clone();
            let to = to.clone();
            let subject = subject.to_string();
            Box::new(move |body: &str| Email::new(&from, &to, &subject, body))
        })
    }
}

// =============================================================================
// 3. 複数の関数を並列適用
// =============================================================================

/// 数値リストの統計情報を取得する
pub fn get_stats(numbers: &[i32]) -> (i32, i32, usize, i32, i32) {
    (
        *numbers.first().unwrap_or(&0),
        *numbers.last().unwrap_or(&0),
        numbers.len(),
        *numbers.iter().min().unwrap_or(&0),
        *numbers.iter().max().unwrap_or(&0),
    )
}

/// 人物分析結果
#[derive(Debug, Clone, PartialEq)]
pub struct PersonAnalysis {
    pub name: String,
    pub age: i32,
    pub category: String,
}

/// 人物情報を分析する
pub fn analyze_person(name: &str, age: i32) -> PersonAnalysis {
    let category = if age >= 18 { "adult" } else { "minor" };
    PersonAnalysis {
        name: name.to_string(),
        age,
        category: category.to_string(),
    }
}

// =============================================================================
// 4. 高階関数によるデータ処理
// =============================================================================

/// 処理をラップしてログを出力する高階関数
pub fn process_with_logging<A: std::fmt::Debug, B: std::fmt::Debug>(
    f: impl Fn(A) -> B,
) -> impl Fn(A) -> B {
    move |input| {
        println!("入力: {:?}", input);
        let result = f(input);
        println!("出力: {:?}", result);
        result
    }
}

/// 失敗時にリトライする高階関数
pub fn retry<A: Clone, B, E, F>(f: F, max_retries: u32) -> impl Fn(A) -> Result<B, E>
where
    F: Fn(A) -> Result<B, E>,
{
    move |input: A| {
        let mut attempts = 0;
        loop {
            match f(input.clone()) {
                Ok(result) => return Ok(result),
                Err(e) => {
                    if attempts < max_retries {
                        attempts += 1;
                    } else {
                        return Err(e);
                    }
                }
            }
        }
    }
}

/// TTL付きメモ化を行う高階関数
/// 注意: Rustでは状態を持つクロージャは RefCell などで内部可変性を使う
use std::cell::RefCell;
use std::collections::HashMap;
use std::hash::Hash;
use std::time::{Duration, Instant};

pub fn memoize_with_ttl<A, B, F>(f: F, ttl: Duration) -> impl Fn(A) -> B
where
    A: Eq + Hash + Clone,
    B: Clone,
    F: Fn(A) -> B,
{
    let cache: RefCell<HashMap<A, (B, Instant)>> = RefCell::new(HashMap::new());

    move |input: A| {
        let now = Instant::now();
        let mut cache_ref = cache.borrow_mut();

        if let Some((value, time)) = cache_ref.get(&input) {
            if now.duration_since(*time) < ttl {
                return value.clone();
            }
        }

        let result = f(input.clone());
        cache_ref.insert(input, (result.clone(), now));
        result
    }
}

// =============================================================================
// 5. パイプライン処理
// =============================================================================

/// 関数のリストを順次適用するパイプラインを作成する
pub fn pipeline<T>(fns: Vec<Box<dyn Fn(T) -> T>>) -> impl Fn(T) -> T {
    move |input| fns.iter().fold(input, |acc, f| f(acc))
}

/// 注文アイテム
#[derive(Debug, Clone, PartialEq)]
pub struct OrderItem {
    pub price: i32,
    pub quantity: i32,
}

impl OrderItem {
    pub fn new(price: i32, quantity: i32) -> Self {
        OrderItem { price, quantity }
    }
}

/// 顧客
#[derive(Debug, Clone, PartialEq)]
pub struct OrderCustomer {
    pub membership: String,
}

impl OrderCustomer {
    pub fn new(membership: &str) -> Self {
        OrderCustomer {
            membership: membership.to_string(),
        }
    }
}

/// 注文
#[derive(Debug, Clone, PartialEq)]
pub struct Order {
    pub items: Vec<OrderItem>,
    pub customer: OrderCustomer,
    pub total: f64,
    pub shipping: i32,
}

impl Order {
    pub fn new(items: Vec<OrderItem>, customer: OrderCustomer) -> Self {
        Order {
            items,
            customer,
            total: 0.0,
            shipping: 0,
        }
    }
}

/// 注文を検証する
pub fn validate_order(order: Order) -> Result<Order, String> {
    if order.items.is_empty() {
        Err("注文にアイテムがありません".to_string())
    } else {
        Ok(order)
    }
}

/// 注文合計を計算する
pub fn calculate_order_total(mut order: Order) -> Order {
    let total: i32 = order
        .items
        .iter()
        .map(|item| item.price * item.quantity)
        .sum();
    order.total = total as f64;
    order
}

/// 注文割引を適用する
pub fn apply_order_discount(mut order: Order) -> Order {
    let discount_rate = match order.customer.membership.as_str() {
        "gold" => 0.1,
        "silver" => 0.05,
        "bronze" => 0.02,
        _ => 0.0,
    };
    order.total *= 1.0 - discount_rate;
    order
}

/// 送料を追加する
pub fn add_shipping(mut order: Order) -> Order {
    let shipping = if order.total >= 5000.0 { 0 } else { 500 };
    order.shipping = shipping;
    order.total += shipping as f64;
    order
}

/// 注文処理パイプライン
pub fn process_order_pipeline(order: Order) -> Result<Order, String> {
    validate_order(order).map(|o| {
        let o = calculate_order_total(o);
        let o = apply_order_discount(o);
        add_shipping(o)
    })
}

// =============================================================================
// 6. 関数合成によるバリデーション
// =============================================================================

/// バリデーション結果
#[derive(Debug, Clone, PartialEq)]
pub struct ValidationResult<T> {
    pub valid: bool,
    pub value: T,
    pub error: Option<String>,
}

impl<T> ValidationResult<T> {
    pub fn ok(value: T) -> Self {
        ValidationResult {
            valid: true,
            value,
            error: None,
        }
    }

    pub fn err(value: T, error: &str) -> Self {
        ValidationResult {
            valid: false,
            value,
            error: Some(error.to_string()),
        }
    }
}

/// バリデータを作成する高階関数
pub fn validator<T: Clone>(
    pred: impl Fn(&T) -> bool + 'static,
    error_msg: &str,
) -> Box<dyn Fn(T) -> ValidationResult<T>> {
    let error_msg = error_msg.to_string();
    Box::new(move |value: T| {
        if pred(&value) {
            ValidationResult::ok(value)
        } else {
            ValidationResult::err(value, &error_msg)
        }
    })
}

/// 複数のバリデータを合成する
pub fn combine_validators<T: Clone + 'static>(
    validators: Vec<Box<dyn Fn(T) -> ValidationResult<T>>>,
) -> Box<dyn Fn(T) -> ValidationResult<T>> {
    Box::new(move |value: T| {
        validators
            .iter()
            .fold(ValidationResult::ok(value), |result, v| {
                if result.valid {
                    v(result.value)
                } else {
                    result
                }
            })
    })
}

/// 正の数かどうかをチェックするバリデータ
pub fn validate_positive() -> Box<dyn Fn(i32) -> ValidationResult<i32>> {
    validator(|&x| x > 0, "値は正の数である必要があります")
}

/// 100未満かどうかをチェックするバリデータ
pub fn validate_under_100() -> Box<dyn Fn(i32) -> ValidationResult<i32>> {
    validator(|&x| x < 100, "値は100未満である必要があります")
}

/// 数量バリデータ
pub fn validate_quantity(value: i32) -> ValidationResult<i32> {
    let validators: Vec<Box<dyn Fn(i32) -> ValidationResult<i32>>> =
        vec![validate_positive(), validate_under_100()];
    combine_validators(validators)(value)
}

// =============================================================================
// 7. 関数の変換
// =============================================================================

/// 引数の順序を反転する
pub fn flip<A, B, C, F>(f: F) -> impl Fn(B, A) -> C
where
    F: Fn(A, B) -> C,
{
    move |b, a| f(a, b)
}

/// 述語の結果を反転する
pub fn complement<A, F>(pred: F) -> impl Fn(A) -> bool
where
    F: Fn(A) -> bool,
{
    move |a| !pred(a)
}

/// 常に同じ値を返す関数を作成する
pub fn constantly<A, B: Clone>(value: B) -> impl Fn(A) -> B {
    move |_| value.clone()
}

/// 2引数関数をカリー化する
pub fn curry<A: Clone + 'static, B: 'static, C: 'static, F: Fn(A, B) -> C + Clone + 'static>(
    f: F,
) -> impl Fn(A) -> Box<dyn Fn(B) -> C> {
    move |a: A| {
        let f = f.clone();
        let a = a.clone();
        Box::new(move |b: B| f(a.clone(), b))
    }
}

/// カリー化された関数を元に戻す
pub fn uncurry<A, B, C, F, G>(f: F) -> impl Fn(A, B) -> C
where
    F: Fn(A) -> G,
    G: Fn(B) -> C,
{
    move |a, b| f(a)(b)
}

// =============================================================================
// 8. 関数合成のパターン
// =============================================================================

/// 複数の述語を AND で合成する
pub fn compose_predicates<T: Clone>(preds: Vec<Box<dyn Fn(&T) -> bool>>) -> impl Fn(&T) -> bool {
    move |x| preds.iter().all(|p| p(x))
}

/// 複数の述語を OR で合成する
pub fn compose_predicates_or<T: Clone>(preds: Vec<Box<dyn Fn(&T) -> bool>>) -> impl Fn(&T) -> bool {
    move |x| preds.iter().any(|p| p(x))
}

/// 有効な年齢かチェックする
pub fn valid_age(age: &i32) -> bool {
    let preds: Vec<Box<dyn Fn(&i32) -> bool>> =
        vec![Box::new(|&x| x > 0), Box::new(|&x| x <= 150)];
    compose_predicates(preds)(age)
}

/// 顧客情報
#[derive(Debug, Clone, PartialEq)]
pub struct CustomerInfo {
    pub membership: String,
    pub purchase_count: i32,
    pub total_spent: i32,
}

impl CustomerInfo {
    pub fn new(membership: &str, purchase_count: i32, total_spent: i32) -> Self {
        CustomerInfo {
            membership: membership.to_string(),
            purchase_count,
            total_spent,
        }
    }
}

/// プレミアム顧客かチェックする
pub fn premium_customer(customer: &CustomerInfo) -> bool {
    let preds: Vec<Box<dyn Fn(&CustomerInfo) -> bool>> = vec![
        Box::new(|c| c.membership == "gold"),
        Box::new(|c| c.purchase_count >= 100),
        Box::new(|c| c.total_spent >= 100000),
    ];
    compose_predicates_or(preds)(customer)
}

// =============================================================================
// テスト
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    // -------------------------------------------------------------------------
    // 関数合成の基本
    // -------------------------------------------------------------------------

    #[test]
    fn test_add_tax() {
        let add_10_percent = add_tax(0.1);
        assert_eq!(add_10_percent(1000.0), 1100.0);
    }

    #[test]
    fn test_apply_discount_rate() {
        let discount_20_percent = apply_discount_rate(0.2);
        assert_eq!(discount_20_percent(1000.0), 800.0);
    }

    #[test]
    fn test_round_to_yen() {
        assert_eq!(round_to_yen(999.4), 999);
        assert_eq!(round_to_yen(999.5), 1000);
    }

    #[test]
    fn test_calculate_final_price() {
        // 1000 → 20%割引(800) → 10%税込(880) → 丸め(880)
        assert_eq!(calculate_final_price(1000.0), 880);
    }

    // -------------------------------------------------------------------------
    // 部分適用とカリー化
    // -------------------------------------------------------------------------

    #[test]
    fn test_greet_curried() {
        assert_eq!(say_hello("田中"), "Hello, 田中!");
        assert_eq!(say_goodbye("鈴木"), "Goodbye, 鈴木!");
    }

    #[test]
    fn test_send_email() {
        let send_from_system = send_email("system@example.com");
        let send_to_user = send_from_system("user@example.com");
        let send_notification = send_to_user("通知");
        let email = send_notification("メッセージ本文");

        assert_eq!(email.from, "system@example.com");
        assert_eq!(email.to, "user@example.com");
        assert_eq!(email.subject, "通知");
        assert_eq!(email.body, "メッセージ本文");
    }

    // -------------------------------------------------------------------------
    // 複数の関数を並列適用
    // -------------------------------------------------------------------------

    #[test]
    fn test_get_stats() {
        let numbers = vec![3, 1, 4, 1, 5, 9, 2, 6];
        let stats = get_stats(&numbers);
        assert_eq!(stats, (3, 6, 8, 1, 9));
    }

    #[test]
    fn test_analyze_person() {
        let adult = analyze_person("田中", 25);
        assert_eq!(adult.name, "田中");
        assert_eq!(adult.age, 25);
        assert_eq!(adult.category, "adult");

        let minor = analyze_person("鈴木", 15);
        assert_eq!(minor.category, "minor");
    }

    // -------------------------------------------------------------------------
    // パイプライン処理
    // -------------------------------------------------------------------------

    #[test]
    fn test_validate_order_empty() {
        let order = Order::new(vec![], OrderCustomer::new("gold"));
        let result = validate_order(order);
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_order_non_empty() {
        let order = Order::new(vec![OrderItem::new(1000, 1)], OrderCustomer::new("gold"));
        let result = validate_order(order);
        assert!(result.is_ok());
    }

    #[test]
    fn test_calculate_order_total() {
        let order = Order::new(
            vec![OrderItem::new(1000, 2), OrderItem::new(500, 3)],
            OrderCustomer::new("regular"),
        );
        let result = calculate_order_total(order);
        assert_eq!(result.total, 3500.0);
    }

    #[test]
    fn test_apply_order_discount() {
        let mut order = Order::new(vec![], OrderCustomer::new("gold"));
        order.total = 1000.0;
        let result = apply_order_discount(order);
        assert_eq!(result.total, 900.0);
    }

    #[test]
    fn test_add_shipping_free() {
        let mut order = Order::new(vec![], OrderCustomer::new("regular"));
        order.total = 5000.0;
        let result = add_shipping(order);
        assert_eq!(result.shipping, 0);
        assert_eq!(result.total, 5000.0);
    }

    #[test]
    fn test_add_shipping_paid() {
        let mut order = Order::new(vec![], OrderCustomer::new("regular"));
        order.total = 4999.0;
        let result = add_shipping(order);
        assert_eq!(result.shipping, 500);
        assert_eq!(result.total, 5499.0);
    }

    #[test]
    fn test_process_order_pipeline() {
        let order = Order::new(
            vec![OrderItem::new(1000, 2), OrderItem::new(500, 3)],
            OrderCustomer::new("gold"),
        );
        let result = process_order_pipeline(order).unwrap();
        // 3500 * 0.9 = 3150 + 500 = 3650
        assert_eq!(result.total, 3650.0);
        assert_eq!(result.shipping, 500);
    }

    // -------------------------------------------------------------------------
    // バリデーション
    // -------------------------------------------------------------------------

    #[test]
    fn test_validate_quantity_valid() {
        let result = validate_quantity(50);
        assert!(result.valid);
        assert_eq!(result.value, 50);
    }

    #[test]
    fn test_validate_quantity_negative() {
        let result = validate_quantity(-1);
        assert!(!result.valid);
        assert_eq!(result.error, Some("値は正の数である必要があります".to_string()));
    }

    #[test]
    fn test_validate_quantity_too_large() {
        let result = validate_quantity(100);
        assert!(!result.valid);
        assert_eq!(result.error, Some("値は100未満である必要があります".to_string()));
    }

    // -------------------------------------------------------------------------
    // 関数の変換
    // -------------------------------------------------------------------------

    #[test]
    fn test_flip() {
        let subtract = |a: i32, b: i32| a - b;
        let flipped = flip(subtract);
        assert_eq!(flipped(3, 5), 2); // 5 - 3 = 2
    }

    #[test]
    fn test_complement() {
        let is_even = |x: i32| x % 2 == 0;
        let is_odd = complement(is_even);
        assert!(is_odd(3));
        assert!(!is_odd(4));
    }

    #[test]
    fn test_constantly() {
        let always_42 = constantly::<i32, i32>(42);
        assert_eq!(always_42(0), 42);
        assert_eq!(always_42(100), 42);
    }

    #[test]
    fn test_curry() {
        let add = |a: i32, b: i32| a + b;
        let curried_add = curry(add);
        let add_5 = curried_add(5);
        assert_eq!(add_5(3), 8);
    }

    // -------------------------------------------------------------------------
    // 述語の合成
    // -------------------------------------------------------------------------

    #[test]
    fn test_valid_age() {
        assert!(valid_age(&25));
        assert!(!valid_age(&-1));
        assert!(!valid_age(&200));
    }

    #[test]
    fn test_premium_customer() {
        assert!(premium_customer(&CustomerInfo::new("gold", 0, 0)));
        assert!(premium_customer(&CustomerInfo::new("bronze", 100, 0)));
        assert!(premium_customer(&CustomerInfo::new("bronze", 0, 100000)));
        assert!(!premium_customer(&CustomerInfo::new("bronze", 10, 1000)));
    }
}
