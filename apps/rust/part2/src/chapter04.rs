//! 第4章: データ検証
//!
//! Rust の型システムと Result/Option を使ったデータバリデーションを学びます。
//! Newtype パターン、スマートコンストラクタ、エラー蓄積パターンを扱います。

use std::fmt;

// =============================================================================
// 1. 基本的なバリデーション（Result を使用）
// =============================================================================

/// バリデーションエラー
#[derive(Debug, Clone, PartialEq)]
pub struct ValidationError {
    pub message: String,
}

impl ValidationError {
    pub fn new(message: &str) -> Self {
        ValidationError {
            message: message.to_string(),
        }
    }
}

impl fmt::Display for ValidationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.message)
    }
}

impl std::error::Error for ValidationError {}

/// バリデーション結果型
pub type ValidationResult<T> = Result<T, Vec<String>>;

/// 名前のバリデーション
pub fn validate_name(name: &str) -> ValidationResult<String> {
    if name.is_empty() {
        Err(vec!["名前は空にできません".to_string()])
    } else if name.len() > 100 {
        Err(vec!["名前は100文字以内である必要があります".to_string()])
    } else {
        Ok(name.to_string())
    }
}

/// 年齢のバリデーション
pub fn validate_age(age: i32) -> ValidationResult<i32> {
    if age < 0 {
        Err(vec!["年齢は0以上である必要があります".to_string()])
    } else if age > 150 {
        Err(vec!["年齢は150以下である必要があります".to_string()])
    } else {
        Ok(age)
    }
}

/// メールアドレスのバリデーション
pub fn validate_email(email: &str) -> ValidationResult<String> {
    if email.contains('@') && email.contains('.') {
        Ok(email.to_string())
    } else {
        Err(vec!["無効なメールアドレス形式です".to_string()])
    }
}

// =============================================================================
// 2. 列挙型とスマートコンストラクタ
// =============================================================================

/// 会員種別
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Membership {
    Bronze,
    Silver,
    Gold,
    Platinum,
}

impl Membership {
    pub fn parse(s: &str) -> ValidationResult<Membership> {
        match s.to_lowercase().as_str() {
            "bronze" => Ok(Membership::Bronze),
            "silver" => Ok(Membership::Silver),
            "gold" => Ok(Membership::Gold),
            "platinum" => Ok(Membership::Platinum),
            _ => Err(vec![format!("無効な会員種別: {}", s)]),
        }
    }
}

/// ステータス
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Status {
    Active,
    Inactive,
    Suspended,
}

// =============================================================================
// 3. Validated パターン（エラー蓄積）
// =============================================================================

/// Validated 型（エラー蓄積をサポート）
#[derive(Debug, Clone, PartialEq)]
pub enum Validated<E, A> {
    Valid(A),
    Invalid(Vec<E>),
}

impl<E, A> Validated<E, A> {
    pub fn valid(value: A) -> Self {
        Validated::Valid(value)
    }

    pub fn invalid(errors: Vec<E>) -> Self {
        Validated::Invalid(errors)
    }

    pub fn is_valid(&self) -> bool {
        matches!(self, Validated::Valid(_))
    }

    pub fn map<B, F: FnOnce(A) -> B>(self, f: F) -> Validated<E, B> {
        match self {
            Validated::Valid(a) => Validated::Valid(f(a)),
            Validated::Invalid(e) => Validated::Invalid(e),
        }
    }

    pub fn to_result(self) -> Result<A, Vec<E>> {
        match self {
            Validated::Valid(a) => Ok(a),
            Validated::Invalid(e) => Err(e),
        }
    }
}

impl<E: Clone, A> Validated<E, A> {
    /// 2つの Validated を結合（エラー蓄積）
    pub fn combine<B, C, F>(self, other: Validated<E, B>, f: F) -> Validated<E, C>
    where
        F: FnOnce(A, B) -> C,
    {
        match (self, other) {
            (Validated::Valid(a), Validated::Valid(b)) => Validated::Valid(f(a, b)),
            (Validated::Invalid(e1), Validated::Invalid(e2)) => {
                let mut errors = e1;
                errors.extend(e2);
                Validated::Invalid(errors)
            }
            (Validated::Invalid(e), _) => Validated::Invalid(e),
            (_, Validated::Invalid(e)) => Validated::Invalid(e),
        }
    }

    /// 3つの Validated を結合
    pub fn combine3<B, C, D, F>(
        self,
        vb: Validated<E, B>,
        vc: Validated<E, C>,
        f: F,
    ) -> Validated<E, D>
    where
        F: FnOnce(A, B, C) -> D,
        B: Clone,
        C: Clone,
    {
        let ab = self.combine(vb, |a, b| (a, b));
        ab.combine(vc, |(a, b), c| f(a, b, c))
    }
}

// =============================================================================
// 4. Newtype パターンによるドメインモデル
// =============================================================================

/// 商品ID（バリデーション済み）
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProductId(String);

impl ProductId {
    pub fn new(id: &str) -> Validated<String, ProductId> {
        let pattern = regex::Regex::new(r"^PROD-\d{5}$").unwrap();
        if pattern.is_match(id) {
            Validated::valid(ProductId(id.to_string()))
        } else {
            Validated::invalid(vec![format!(
                "無効な商品ID形式: {} (PROD-XXXXXの形式が必要)",
                id
            )])
        }
    }

    pub fn value(&self) -> &str {
        &self.0
    }

    /// テスト用の unsafe コンストラクタ
    #[cfg(test)]
    pub fn unsafe_new(id: &str) -> ProductId {
        ProductId(id.to_string())
    }
}

/// 商品名（バリデーション済み）
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProductName(String);

impl ProductName {
    pub fn new(name: &str) -> Validated<String, ProductName> {
        if name.is_empty() {
            Validated::invalid(vec!["商品名は空にできません".to_string()])
        } else if name.len() > 200 {
            Validated::invalid(vec!["商品名は200文字以内である必要があります".to_string()])
        } else {
            Validated::valid(ProductName(name.to_string()))
        }
    }

    pub fn value(&self) -> &str {
        &self.0
    }
}

/// 価格（正の数）
#[derive(Debug, Clone, PartialEq)]
pub struct Price(f64);

impl Price {
    pub fn new(amount: f64) -> Validated<String, Price> {
        if amount <= 0.0 {
            Validated::invalid(vec!["価格は正の数である必要があります".to_string()])
        } else {
            Validated::valid(Price(amount))
        }
    }

    pub fn value(&self) -> f64 {
        self.0
    }

    #[cfg(test)]
    pub fn unsafe_new(amount: f64) -> Price {
        Price(amount)
    }
}

/// 数量（正の整数）
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Quantity(i32);

impl Quantity {
    pub fn new(qty: i32) -> Validated<String, Quantity> {
        if qty <= 0 {
            Validated::invalid(vec!["数量は正の整数である必要があります".to_string()])
        } else {
            Validated::valid(Quantity(qty))
        }
    }

    pub fn value(&self) -> i32 {
        self.0
    }

    #[cfg(test)]
    pub fn unsafe_new(qty: i32) -> Quantity {
        Quantity(qty)
    }
}

// =============================================================================
// 5. 商品モデル
// =============================================================================

/// 商品
#[derive(Debug, Clone, PartialEq)]
pub struct Product {
    pub id: ProductId,
    pub name: ProductName,
    pub price: Price,
    pub description: Option<String>,
    pub category: Option<String>,
}

impl Product {
    pub fn create(
        id: &str,
        name: &str,
        price: f64,
        description: Option<String>,
        category: Option<String>,
    ) -> Validated<String, Product> {
        ProductId::new(id).combine3(ProductName::new(name), Price::new(price), |pid, pname, pprice| {
            Product {
                id: pid,
                name: pname,
                price: pprice,
                description,
                category,
            }
        })
    }
}

// =============================================================================
// 6. 注文ドメインモデル
// =============================================================================

/// 注文ID
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OrderId(String);

impl OrderId {
    pub fn new(id: &str) -> Validated<String, OrderId> {
        let pattern = regex::Regex::new(r"^ORD-\d{8}$").unwrap();
        if pattern.is_match(id) {
            Validated::valid(OrderId(id.to_string()))
        } else {
            Validated::invalid(vec![format!("無効な注文ID形式: {}", id)])
        }
    }

    pub fn value(&self) -> &str {
        &self.0
    }
}

/// 顧客ID
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CustomerId(String);

impl CustomerId {
    pub fn new(id: &str) -> Validated<String, CustomerId> {
        let pattern = regex::Regex::new(r"^CUST-\d{6}$").unwrap();
        if pattern.is_match(id) {
            Validated::valid(CustomerId(id.to_string()))
        } else {
            Validated::invalid(vec![format!("無効な顧客ID形式: {}", id)])
        }
    }

    pub fn value(&self) -> &str {
        &self.0
    }
}

/// 注文アイテム
#[derive(Debug, Clone, PartialEq)]
pub struct OrderItem {
    pub product_id: ProductId,
    pub quantity: Quantity,
    pub price: Price,
}

impl OrderItem {
    pub fn create(product_id: &str, quantity: i32, price: f64) -> Validated<String, OrderItem> {
        ProductId::new(product_id).combine3(
            Quantity::new(quantity),
            Price::new(price),
            |pid, qty, p| OrderItem {
                product_id: pid,
                quantity: qty,
                price: p,
            },
        )
    }

    pub fn total(&self) -> f64 {
        self.price.value() * self.quantity.value() as f64
    }
}

// =============================================================================
// 7. 条件付きバリデーション（ADT）
// =============================================================================

/// 通知タイプ
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum NotificationType {
    Email,
    SMS,
    Push,
}

/// 通知
#[derive(Debug, Clone, PartialEq)]
pub enum Notification {
    Email {
        to: String,
        subject: String,
        body: String,
    },
    SMS {
        phone_number: String,
        body: String,
    },
    Push {
        device_token: String,
        body: String,
    },
}

impl Notification {
    pub fn create_email(to: &str, subject: &str, body: &str) -> Validated<String, Notification> {
        let mut errors = Vec::new();

        if !to.contains('@') || !to.contains('.') {
            errors.push("無効なメールアドレス形式です".to_string());
        }
        if subject.is_empty() {
            errors.push("件名は空にできません".to_string());
        }
        if body.is_empty() {
            errors.push("本文は空にできません".to_string());
        }

        if errors.is_empty() {
            Validated::valid(Notification::Email {
                to: to.to_string(),
                subject: subject.to_string(),
                body: body.to_string(),
            })
        } else {
            Validated::invalid(errors)
        }
    }

    pub fn create_sms(phone_number: &str, body: &str) -> Validated<String, Notification> {
        let mut errors = Vec::new();

        // 簡易的な電話番号チェック
        let phone_pattern = regex::Regex::new(r"^\d{2,4}-\d{2,4}-\d{4}$").unwrap();
        if !phone_pattern.is_match(phone_number) {
            errors.push("無効な電話番号形式です".to_string());
        }
        if body.is_empty() {
            errors.push("本文は空にできません".to_string());
        }

        if errors.is_empty() {
            Validated::valid(Notification::SMS {
                phone_number: phone_number.to_string(),
                body: body.to_string(),
            })
        } else {
            Validated::invalid(errors)
        }
    }

    pub fn create_push(device_token: &str, body: &str) -> Validated<String, Notification> {
        let mut errors = Vec::new();

        if device_token.is_empty() {
            errors.push("デバイストークンは空にできません".to_string());
        }
        if body.is_empty() {
            errors.push("本文は空にできません".to_string());
        }

        if errors.is_empty() {
            Validated::valid(Notification::Push {
                device_token: device_token.to_string(),
                body: body.to_string(),
            })
        } else {
            Validated::invalid(errors)
        }
    }
}

// =============================================================================
// 8. バリデーションユーティリティ
// =============================================================================

/// バリデーション結果レスポンス
#[derive(Debug, Clone, PartialEq)]
pub struct ValidationResponse<A> {
    pub valid: bool,
    pub data: Option<A>,
    pub errors: Vec<String>,
}

impl<A> ValidationResponse<A> {
    pub fn from_validated(validated: Validated<String, A>) -> Self {
        match validated {
            Validated::Valid(a) => ValidationResponse {
                valid: true,
                data: Some(a),
                errors: Vec::new(),
            },
            Validated::Invalid(errors) => ValidationResponse {
                valid: false,
                data: None,
                errors,
            },
        }
    }
}

/// Person（バリデーション例用）
#[derive(Debug, Clone, PartialEq)]
pub struct Person {
    pub name: String,
    pub age: i32,
}

/// Person のバリデーション
pub fn validate_person(name: &str, age: i32) -> ValidationResponse<Person> {
    let name_v = if name.is_empty() {
        Validated::invalid(vec!["名前は空にできません".to_string()])
    } else {
        Validated::valid(name.to_string())
    };

    let age_v = if age < 0 {
        Validated::invalid(vec!["年齢は0以上である必要があります".to_string()])
    } else {
        Validated::valid(age)
    };

    let validated = name_v.combine(age_v, |n, a| Person { name: n, age: a });
    ValidationResponse::from_validated(validated)
}

/// バリデーション失敗時に panic する
pub fn conform_or_panic<A>(validated: Validated<String, A>) -> A {
    match validated {
        Validated::Valid(a) => a,
        Validated::Invalid(errors) => {
            panic!("Validation failed: {}", errors.join(", "))
        }
    }
}

// =============================================================================
// 9. 計算関数
// =============================================================================

/// 注文アイテムの合計を計算
pub fn calculate_item_total(item: &OrderItem) -> f64 {
    item.price.value() * item.quantity.value() as f64
}

/// 割引を適用
pub fn apply_discount(total: f64, discount_rate: f64) -> Result<f64, String> {
    if !(0.0..=1.0).contains(&discount_rate) {
        Err("割引率は0から1の間である必要があります".to_string())
    } else {
        Ok(total * (1.0 - discount_rate))
    }
}

/// 複数の価格を合計
pub fn sum_prices(prices: &[f64]) -> f64 {
    prices.iter().sum()
}

// =============================================================================
// テスト
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    // -------------------------------------------------------------------------
    // 基本的なバリデーション
    // -------------------------------------------------------------------------

    #[test]
    fn test_validate_name_valid() {
        let result = validate_name("田中太郎");
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "田中太郎");
    }

    #[test]
    fn test_validate_name_empty() {
        let result = validate_name("");
        assert!(result.is_err());
        assert!(result.unwrap_err()[0].contains("空にできません"));
    }

    #[test]
    fn test_validate_age_valid() {
        let result = validate_age(25);
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), 25);
    }

    #[test]
    fn test_validate_age_negative() {
        let result = validate_age(-1);
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_email_valid() {
        let result = validate_email("test@example.com");
        assert!(result.is_ok());
    }

    #[test]
    fn test_validate_email_invalid() {
        let result = validate_email("invalid");
        assert!(result.is_err());
    }

    // -------------------------------------------------------------------------
    // 列挙型とスマートコンストラクタ
    // -------------------------------------------------------------------------

    #[test]
    fn test_membership_parse_valid() {
        assert_eq!(Membership::parse("gold"), Ok(Membership::Gold));
        assert_eq!(Membership::parse("SILVER"), Ok(Membership::Silver));
    }

    #[test]
    fn test_membership_parse_invalid() {
        let result = Membership::parse("unknown");
        assert!(result.is_err());
    }

    // -------------------------------------------------------------------------
    // Validated パターン
    // -------------------------------------------------------------------------

    #[test]
    fn test_validated_valid() {
        let v: Validated<String, i32> = Validated::valid(42);
        assert!(v.is_valid());
    }

    #[test]
    fn test_validated_invalid() {
        let v: Validated<String, i32> = Validated::invalid(vec!["error".to_string()]);
        assert!(!v.is_valid());
    }

    #[test]
    fn test_validated_combine_both_valid() {
        let v1: Validated<String, i32> = Validated::valid(1);
        let v2: Validated<String, i32> = Validated::valid(2);
        let result = v1.combine(v2, |a, b| a + b);
        assert_eq!(result, Validated::Valid(3));
    }

    #[test]
    fn test_validated_combine_both_invalid() {
        let v1: Validated<String, i32> = Validated::invalid(vec!["error1".to_string()]);
        let v2: Validated<String, i32> = Validated::invalid(vec!["error2".to_string()]);
        let result = v1.combine(v2, |a, b| a + b);
        match result {
            Validated::Invalid(errors) => {
                assert_eq!(errors.len(), 2);
                assert!(errors.contains(&"error1".to_string()));
                assert!(errors.contains(&"error2".to_string()));
            }
            _ => panic!("Expected Invalid"),
        }
    }

    // -------------------------------------------------------------------------
    // Newtype パターン
    // -------------------------------------------------------------------------

    #[test]
    fn test_product_id_valid() {
        let result = ProductId::new("PROD-00001");
        assert!(result.is_valid());
    }

    #[test]
    fn test_product_id_invalid() {
        let result = ProductId::new("INVALID");
        assert!(!result.is_valid());
    }

    #[test]
    fn test_price_valid() {
        let result = Price::new(100.0);
        assert!(result.is_valid());
    }

    #[test]
    fn test_price_invalid() {
        let result = Price::new(-100.0);
        assert!(!result.is_valid());
    }

    #[test]
    fn test_quantity_valid() {
        let result = Quantity::new(5);
        assert!(result.is_valid());
    }

    #[test]
    fn test_quantity_invalid() {
        let result = Quantity::new(0);
        assert!(!result.is_valid());
    }

    // -------------------------------------------------------------------------
    // 商品モデル
    // -------------------------------------------------------------------------

    #[test]
    fn test_product_create_valid() {
        let result = Product::create("PROD-00001", "テスト商品", 1000.0, None, None);
        assert!(result.is_valid());
    }

    #[test]
    fn test_product_create_all_invalid() {
        let result = Product::create("INVALID", "", -100.0, None, None);
        match result {
            Validated::Invalid(errors) => {
                assert_eq!(errors.len(), 3);
            }
            _ => panic!("Expected Invalid"),
        }
    }

    // -------------------------------------------------------------------------
    // 注文ドメインモデル
    // -------------------------------------------------------------------------

    #[test]
    fn test_order_id_valid() {
        let result = OrderId::new("ORD-12345678");
        assert!(result.is_valid());
    }

    #[test]
    fn test_customer_id_valid() {
        let result = CustomerId::new("CUST-123456");
        assert!(result.is_valid());
    }

    #[test]
    fn test_order_item_create_valid() {
        let result = OrderItem::create("PROD-00001", 2, 1000.0);
        assert!(result.is_valid());
    }

    #[test]
    fn test_order_item_total() {
        let item = OrderItem {
            product_id: ProductId::unsafe_new("PROD-00001"),
            quantity: Quantity::unsafe_new(3),
            price: Price::unsafe_new(500.0),
        };
        assert_eq!(item.total(), 1500.0);
    }

    // -------------------------------------------------------------------------
    // 条件付きバリデーション
    // -------------------------------------------------------------------------

    #[test]
    fn test_notification_email_valid() {
        let result = Notification::create_email("test@example.com", "テスト", "本文");
        assert!(result.is_valid());
    }

    #[test]
    fn test_notification_email_invalid() {
        let result = Notification::create_email("invalid", "", "");
        match result {
            Validated::Invalid(errors) => {
                assert_eq!(errors.len(), 3);
            }
            _ => panic!("Expected Invalid"),
        }
    }

    #[test]
    fn test_notification_sms_valid() {
        let result = Notification::create_sms("090-1234-5678", "本文");
        assert!(result.is_valid());
    }

    #[test]
    fn test_notification_push_valid() {
        let result = Notification::create_push("device_token_123", "本文");
        assert!(result.is_valid());
    }

    // -------------------------------------------------------------------------
    // バリデーションユーティリティ
    // -------------------------------------------------------------------------

    #[test]
    fn test_validate_person_valid() {
        let result = validate_person("田中", 30);
        assert!(result.valid);
        assert!(result.data.is_some());
        assert!(result.errors.is_empty());
    }

    #[test]
    fn test_validate_person_invalid() {
        let result = validate_person("", -1);
        assert!(!result.valid);
        assert!(result.data.is_none());
        assert_eq!(result.errors.len(), 2);
    }

    // -------------------------------------------------------------------------
    // 計算関数
    // -------------------------------------------------------------------------

    #[test]
    fn test_apply_discount_valid() {
        let result = apply_discount(1000.0, 0.1);
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), 900.0);
    }

    #[test]
    fn test_apply_discount_invalid() {
        let result = apply_discount(1000.0, 1.5);
        assert!(result.is_err());
    }

    #[test]
    fn test_sum_prices() {
        let prices = vec![100.0, 200.0, 300.0];
        assert_eq!(sum_prices(&prices), 600.0);
    }
}
