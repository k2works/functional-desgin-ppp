//! 第10章: Strategy パターン
//!
//! Strategy パターンは、アルゴリズムをカプセル化し、
//! それらを交換可能にするパターンです。
//! Rust では trait とクロージャの両方で実装できます。

// =============================================================================
// 1. 料金計算戦略（trait ベース）
// =============================================================================

/// 料金計算戦略の trait
pub trait PricingStrategy {
    fn calculate_price(&self, amount: f64) -> f64;
}

/// 通常料金戦略
#[derive(Debug, Clone, Copy)]
pub struct RegularPricing;

impl PricingStrategy for RegularPricing {
    fn calculate_price(&self, amount: f64) -> f64 {
        amount
    }
}

/// 割引料金戦略
#[derive(Debug, Clone, Copy)]
pub struct DiscountPricing {
    pub discount_rate: f64,
}

impl DiscountPricing {
    pub fn new(discount_rate: f64) -> Self {
        assert!(
            (0.0..=1.0).contains(&discount_rate),
            "Discount rate must be 0-1"
        );
        DiscountPricing { discount_rate }
    }
}

impl PricingStrategy for DiscountPricing {
    fn calculate_price(&self, amount: f64) -> f64 {
        amount * (1.0 - self.discount_rate)
    }
}

/// 会員レベル
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum MemberLevel {
    Gold,
    Silver,
    Bronze,
}

impl MemberLevel {
    pub fn discount_rate(&self) -> f64 {
        match self {
            MemberLevel::Gold => 0.20,
            MemberLevel::Silver => 0.15,
            MemberLevel::Bronze => 0.10,
        }
    }
}

/// 会員料金戦略
#[derive(Debug, Clone, Copy)]
pub struct MemberPricing {
    pub level: MemberLevel,
}

impl MemberPricing {
    pub fn new(level: MemberLevel) -> Self {
        MemberPricing { level }
    }
}

impl PricingStrategy for MemberPricing {
    fn calculate_price(&self, amount: f64) -> f64 {
        amount * (1.0 - self.level.discount_rate())
    }
}

/// 大量購入割引戦略
#[derive(Debug, Clone, Copy)]
pub struct BulkPricing {
    pub threshold: u32,
    pub bulk_discount: f64,
}

impl BulkPricing {
    pub fn new(threshold: u32, bulk_discount: f64) -> Self {
        assert!(
            (0.0..=1.0).contains(&bulk_discount),
            "Bulk discount must be 0-1"
        );
        BulkPricing {
            threshold,
            bulk_discount,
        }
    }

    pub fn calculate_with_quantity(&self, amount: f64, quantity: u32) -> f64 {
        if quantity >= self.threshold {
            amount * (1.0 - self.bulk_discount)
        } else {
            amount
        }
    }
}

impl PricingStrategy for BulkPricing {
    fn calculate_price(&self, amount: f64) -> f64 {
        amount
    }
}

// =============================================================================
// 2. ショッピングカート（Context）
// =============================================================================

/// カート内の商品
#[derive(Debug, Clone, PartialEq)]
pub struct CartItem {
    pub name: String,
    pub price: f64,
    pub quantity: u32,
}

impl CartItem {
    pub fn new(name: &str, price: f64, quantity: u32) -> Self {
        CartItem {
            name: name.to_string(),
            price,
            quantity,
        }
    }

    pub fn subtotal(&self) -> f64 {
        self.price * self.quantity as f64
    }
}

/// ショッピングカート
#[derive(Debug, Clone)]
pub struct ShoppingCart<S: PricingStrategy> {
    pub items: Vec<CartItem>,
    pub strategy: S,
}

impl<S: PricingStrategy> ShoppingCart<S> {
    pub fn new(strategy: S) -> Self {
        ShoppingCart {
            items: Vec::new(),
            strategy,
        }
    }

    pub fn add_item(&self, item: CartItem) -> ShoppingCart<S>
    where
        S: Clone,
    {
        let mut new_items = self.items.clone();
        new_items.push(item);
        ShoppingCart {
            items: new_items,
            strategy: self.strategy.clone(),
        }
    }

    pub fn remove_item(&self, name: &str) -> ShoppingCart<S>
    where
        S: Clone,
    {
        let new_items = self
            .items
            .iter()
            .filter(|i| i.name != name)
            .cloned()
            .collect();
        ShoppingCart {
            items: new_items,
            strategy: self.strategy.clone(),
        }
    }

    pub fn subtotal(&self) -> f64 {
        self.items.iter().map(|item| item.subtotal()).sum()
    }

    pub fn total(&self) -> f64 {
        self.strategy.calculate_price(self.subtotal())
    }

    pub fn item_count(&self) -> u32 {
        self.items.iter().map(|i| i.quantity).sum()
    }
}

impl ShoppingCart<RegularPricing> {
    pub fn empty() -> Self {
        ShoppingCart::new(RegularPricing)
    }
}

/// 戦略を変更
pub fn change_strategy<S1, S2>(cart: ShoppingCart<S1>, new_strategy: S2) -> ShoppingCart<S2>
where
    S1: PricingStrategy,
    S2: PricingStrategy,
{
    ShoppingCart {
        items: cart.items,
        strategy: new_strategy,
    }
}

// =============================================================================
// 3. 関数型アプローチ（クロージャベース）
// =============================================================================

/// 料金戦略の関数型
pub type PricingFn = fn(f64) -> f64;

/// 通常料金戦略（関数）
pub fn regular_pricing(amount: f64) -> f64 {
    amount
}

/// 割引料金戦略を返す関数
pub fn discount_pricing(discount_rate: f64) -> impl Fn(f64) -> f64 {
    move |amount: f64| amount * (1.0 - discount_rate)
}

/// 会員料金戦略を返す関数
pub fn member_pricing(level: MemberLevel) -> impl Fn(f64) -> f64 {
    move |amount: f64| amount * (1.0 - level.discount_rate())
}

/// 大量購入割引戦略を返す関数
pub fn bulk_pricing(threshold: u32, bulk_discount: f64) -> impl Fn(f64, u32) -> f64 {
    move |amount: f64, quantity: u32| {
        if quantity >= threshold {
            amount * (1.0 - bulk_discount)
        } else {
            amount
        }
    }
}

/// 戦略を合成
pub fn compose_strategies<F1, F2>(
    first: F1,
    second: F2,
) -> impl Fn(f64) -> f64
where
    F1: Fn(f64) -> f64,
    F2: Fn(f64) -> f64,
{
    move |amount: f64| second(first(amount))
}

// =============================================================================
// 4. ソート戦略
// =============================================================================

/// ソート戦略
pub trait SortStrategy<T> {
    fn sort(&self, items: &[T]) -> Vec<T>;
}

/// 昇順ソート
pub struct AscendingSort;

impl<T: Ord + Clone> SortStrategy<T> for AscendingSort {
    fn sort(&self, items: &[T]) -> Vec<T> {
        let mut sorted = items.to_vec();
        sorted.sort();
        sorted
    }
}

/// 降順ソート
pub struct DescendingSort;

impl<T: Ord + Clone> SortStrategy<T> for DescendingSort {
    fn sort(&self, items: &[T]) -> Vec<T> {
        let mut sorted = items.to_vec();
        sorted.sort();
        sorted.reverse();
        sorted
    }
}

/// カスタムソート
pub struct CustomSort<F> {
    pub compare: F,
}

impl<T: Clone, F: Fn(&T, &T) -> std::cmp::Ordering> SortStrategy<T> for CustomSort<F> {
    fn sort(&self, items: &[T]) -> Vec<T> {
        let mut sorted = items.to_vec();
        sorted.sort_by(&self.compare);
        sorted
    }
}

// =============================================================================
// 5. バリデーション戦略
// =============================================================================

/// バリデーション戦略
pub trait ValidationStrategy<T> {
    fn validate(&self, value: &T) -> Result<(), String>;
}

/// 必須バリデーション
pub struct RequiredValidation;

impl ValidationStrategy<String> for RequiredValidation {
    fn validate(&self, value: &String) -> Result<(), String> {
        if value.is_empty() {
            Err("Value is required".to_string())
        } else {
            Ok(())
        }
    }
}

/// 長さバリデーション
pub struct LengthValidation {
    pub min: Option<usize>,
    pub max: Option<usize>,
}

impl ValidationStrategy<String> for LengthValidation {
    fn validate(&self, value: &String) -> Result<(), String> {
        let len = value.len();
        if let Some(min) = self.min {
            if len < min {
                return Err(format!("Length must be at least {}", min));
            }
        }
        if let Some(max) = self.max {
            if len > max {
                return Err(format!("Length must be at most {}", max));
            }
        }
        Ok(())
    }
}

/// 範囲バリデーション
pub struct RangeValidation {
    pub min: Option<i64>,
    pub max: Option<i64>,
}

impl ValidationStrategy<i64> for RangeValidation {
    fn validate(&self, value: &i64) -> Result<(), String> {
        if let Some(min) = self.min {
            if *value < min {
                return Err(format!("Value must be at least {}", min));
            }
        }
        if let Some(max) = self.max {
            if *value > max {
                return Err(format!("Value must be at most {}", max));
            }
        }
        Ok(())
    }
}

/// 複合バリデーション
pub struct CompositeValidation<T> {
    pub validators: Vec<Box<dyn ValidationStrategy<T>>>,
}

impl<T> CompositeValidation<T> {
    pub fn new() -> Self {
        CompositeValidation {
            validators: Vec::new(),
        }
    }

    pub fn add<V: ValidationStrategy<T> + 'static>(mut self, validator: V) -> Self {
        self.validators.push(Box::new(validator));
        self
    }
}

impl<T> Default for CompositeValidation<T> {
    fn default() -> Self {
        Self::new()
    }
}

impl<T> ValidationStrategy<T> for CompositeValidation<T> {
    fn validate(&self, value: &T) -> Result<(), String> {
        for validator in &self.validators {
            validator.validate(value)?;
        }
        Ok(())
    }
}

// =============================================================================
// 6. 支払い戦略
// =============================================================================

/// 支払い結果
#[derive(Debug, Clone, PartialEq)]
pub struct PaymentResult {
    pub success: bool,
    pub transaction_id: String,
    pub message: String,
}

/// 支払い戦略
pub trait PaymentStrategy {
    fn pay(&self, amount: f64) -> PaymentResult;
}

/// クレジットカード支払い
pub struct CreditCardPayment {
    pub card_number: String,
    pub expiry: String,
}

impl PaymentStrategy for CreditCardPayment {
    fn pay(&self, amount: f64) -> PaymentResult {
        // シミュレーション
        PaymentResult {
            success: true,
            transaction_id: format!("CC-{}", self.card_number.chars().rev().take(4).collect::<String>()),
            message: format!("Credit card payment of ${:.2} successful", amount),
        }
    }
}

/// PayPal 支払い
pub struct PayPalPayment {
    pub email: String,
}

impl PaymentStrategy for PayPalPayment {
    fn pay(&self, amount: f64) -> PaymentResult {
        PaymentResult {
            success: true,
            transaction_id: format!("PP-{}", uuid_simple()),
            message: format!("PayPal payment of ${:.2} successful", amount),
        }
    }
}

/// 銀行振込支払い
pub struct BankTransferPayment {
    pub account_number: String,
}

impl PaymentStrategy for BankTransferPayment {
    fn pay(&self, amount: f64) -> PaymentResult {
        PaymentResult {
            success: true,
            transaction_id: format!("BT-{}", uuid_simple()),
            message: format!("Bank transfer of ${:.2} initiated", amount),
        }
    }
}

fn uuid_simple() -> String {
    format!("{:08X}", std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_nanos() as u32)
}

// =============================================================================
// 7. 通知戦略
// =============================================================================

/// 通知戦略
pub trait NotificationStrategy {
    fn send(&self, message: &str) -> Result<(), String>;
}

/// メール通知
pub struct EmailNotification {
    pub to: String,
}

impl NotificationStrategy for EmailNotification {
    fn send(&self, message: &str) -> Result<(), String> {
        // シミュレーション
        println!("Email to {}: {}", self.to, message);
        Ok(())
    }
}

/// SMS 通知
pub struct SmsNotification {
    pub phone: String,
}

impl NotificationStrategy for SmsNotification {
    fn send(&self, message: &str) -> Result<(), String> {
        println!("SMS to {}: {}", self.phone, message);
        Ok(())
    }
}

/// プッシュ通知
pub struct PushNotification {
    pub device_token: String,
}

impl NotificationStrategy for PushNotification {
    fn send(&self, message: &str) -> Result<(), String> {
        println!("Push to {}: {}", self.device_token, message);
        Ok(())
    }
}

/// マルチ通知（複数チャネルへ送信）
pub struct MultiNotification {
    pub strategies: Vec<Box<dyn NotificationStrategy>>,
}

impl NotificationStrategy for MultiNotification {
    fn send(&self, message: &str) -> Result<(), String> {
        for strategy in &self.strategies {
            strategy.send(message)?;
        }
        Ok(())
    }
}

// =============================================================================
// テスト
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    // -------------------------------------------------------------------------
    // 料金計算戦略テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_regular_pricing() {
        let strategy = RegularPricing;
        assert_eq!(strategy.calculate_price(100.0), 100.0);
    }

    #[test]
    fn test_discount_pricing() {
        let strategy = DiscountPricing::new(0.1);
        assert!((strategy.calculate_price(100.0) - 90.0).abs() < 0.001);
    }

    #[test]
    fn test_member_pricing_gold() {
        let strategy = MemberPricing::new(MemberLevel::Gold);
        assert!((strategy.calculate_price(100.0) - 80.0).abs() < 0.001);
    }

    #[test]
    fn test_member_pricing_silver() {
        let strategy = MemberPricing::new(MemberLevel::Silver);
        assert!((strategy.calculate_price(100.0) - 85.0).abs() < 0.001);
    }

    #[test]
    fn test_bulk_pricing() {
        let strategy = BulkPricing::new(10, 0.2);
        assert_eq!(strategy.calculate_with_quantity(100.0, 5), 100.0);
        assert!((strategy.calculate_with_quantity(100.0, 15) - 80.0).abs() < 0.001);
    }

    // -------------------------------------------------------------------------
    // ショッピングカートテスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_shopping_cart_empty() {
        let cart = ShoppingCart::empty();
        assert_eq!(cart.subtotal(), 0.0);
        assert_eq!(cart.total(), 0.0);
    }

    #[test]
    fn test_shopping_cart_add_items() {
        let cart = ShoppingCart::empty()
            .add_item(CartItem::new("Apple", 1.0, 3))
            .add_item(CartItem::new("Banana", 0.5, 2));

        assert_eq!(cart.item_count(), 5);
        assert!((cart.subtotal() - 4.0).abs() < 0.001);
    }

    #[test]
    fn test_shopping_cart_with_discount() {
        let cart = ShoppingCart::new(DiscountPricing::new(0.1))
            .add_item(CartItem::new("Apple", 10.0, 1));

        assert!((cart.subtotal() - 10.0).abs() < 0.001);
        assert!((cart.total() - 9.0).abs() < 0.001);
    }

    #[test]
    fn test_shopping_cart_change_strategy() {
        let cart = ShoppingCart::empty()
            .add_item(CartItem::new("Apple", 100.0, 1));

        let discounted_cart = change_strategy(cart, DiscountPricing::new(0.2));
        assert!((discounted_cart.total() - 80.0).abs() < 0.001);
    }

    // -------------------------------------------------------------------------
    // 関数型戦略テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_functional_regular_pricing() {
        assert_eq!(regular_pricing(100.0), 100.0);
    }

    #[test]
    fn test_functional_discount_pricing() {
        let strategy = discount_pricing(0.15);
        assert!((strategy(100.0) - 85.0).abs() < 0.001);
    }

    #[test]
    fn test_functional_member_pricing() {
        let strategy = member_pricing(MemberLevel::Bronze);
        assert!((strategy(100.0) - 90.0).abs() < 0.001);
    }

    #[test]
    fn test_compose_strategies() {
        let first = discount_pricing(0.1);  // 10% off
        let second = discount_pricing(0.05); // additional 5% off
        let combined = compose_strategies(first, second);
        // 100 * 0.9 * 0.95 = 85.5
        assert!((combined(100.0) - 85.5).abs() < 0.001);
    }

    // -------------------------------------------------------------------------
    // ソート戦略テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_ascending_sort() {
        let items = vec![3, 1, 4, 1, 5, 9, 2, 6];
        let sorted = AscendingSort.sort(&items);
        assert_eq!(sorted, vec![1, 1, 2, 3, 4, 5, 6, 9]);
    }

    #[test]
    fn test_descending_sort() {
        let items = vec![3, 1, 4, 1, 5, 9, 2, 6];
        let sorted = DescendingSort.sort(&items);
        assert_eq!(sorted, vec![9, 6, 5, 4, 3, 2, 1, 1]);
    }

    #[test]
    fn test_custom_sort() {
        let items = vec!["banana", "apple", "cherry"];
        let strategy = CustomSort {
            compare: |a: &&str, b: &&str| a.len().cmp(&b.len()),
        };
        let sorted = strategy.sort(&items);
        assert_eq!(sorted, vec!["apple", "banana", "cherry"]);
    }

    // -------------------------------------------------------------------------
    // バリデーション戦略テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_required_validation() {
        let validator = RequiredValidation;
        assert!(validator.validate(&"test".to_string()).is_ok());
        assert!(validator.validate(&"".to_string()).is_err());
    }

    #[test]
    fn test_length_validation() {
        let validator = LengthValidation {
            min: Some(3),
            max: Some(10),
        };
        assert!(validator.validate(&"hello".to_string()).is_ok());
        assert!(validator.validate(&"hi".to_string()).is_err());
        assert!(validator.validate(&"hello world!".to_string()).is_err());
    }

    #[test]
    fn test_range_validation() {
        let validator = RangeValidation {
            min: Some(0),
            max: Some(100),
        };
        assert!(validator.validate(&50).is_ok());
        assert!(validator.validate(&-1).is_err());
        assert!(validator.validate(&101).is_err());
    }

    #[test]
    fn test_composite_validation() {
        let validator = CompositeValidation::new()
            .add(RequiredValidation)
            .add(LengthValidation {
                min: Some(3),
                max: None,
            });

        assert!(validator.validate(&"hello".to_string()).is_ok());
        assert!(validator.validate(&"".to_string()).is_err());
        assert!(validator.validate(&"hi".to_string()).is_err());
    }

    // -------------------------------------------------------------------------
    // 支払い戦略テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_credit_card_payment() {
        let payment = CreditCardPayment {
            card_number: "1234567890123456".to_string(),
            expiry: "12/25".to_string(),
        };
        let result = payment.pay(100.0);
        assert!(result.success);
        assert!(result.transaction_id.starts_with("CC-"));
    }

    #[test]
    fn test_paypal_payment() {
        let payment = PayPalPayment {
            email: "test@example.com".to_string(),
        };
        let result = payment.pay(50.0);
        assert!(result.success);
        assert!(result.transaction_id.starts_with("PP-"));
    }

    #[test]
    fn test_bank_transfer_payment() {
        let payment = BankTransferPayment {
            account_number: "123456789".to_string(),
        };
        let result = payment.pay(200.0);
        assert!(result.success);
        assert!(result.transaction_id.starts_with("BT-"));
    }
}
