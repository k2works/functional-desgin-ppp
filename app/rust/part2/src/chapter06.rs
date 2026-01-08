//! 第6章: TDD と関数型
//!
//! Rust における TDD と関数型プログラミングの実践を解説します。
//! 純粋関数、テスト容易性、依存性注入などのパターンを扱います。

use std::collections::HashMap;

// =============================================================================
// 1. 純粋関数によるビジネスロジック
// =============================================================================

/// 商品情報
#[derive(Debug, Clone, PartialEq)]
pub struct Product {
    pub id: String,
    pub name: String,
    pub price: i64,
    pub category: String,
}

/// カート内アイテム
#[derive(Debug, Clone, PartialEq)]
pub struct CartItem {
    pub product: Product,
    pub quantity: u32,
}

impl CartItem {
    pub fn new(product: Product, quantity: u32) -> CartItem {
        CartItem { product, quantity }
    }

    /// アイテムの小計（純粋関数）
    pub fn subtotal(&self) -> i64 {
        self.product.price * self.quantity as i64
    }
}

/// ショッピングカート
#[derive(Debug, Clone, PartialEq)]
pub struct Cart {
    pub items: Vec<CartItem>,
}

impl Cart {
    pub fn new() -> Cart {
        Cart { items: Vec::new() }
    }

    /// アイテムを追加（イミュータブル操作）
    pub fn add_item(&self, item: CartItem) -> Cart {
        let mut new_items = self.items.clone();
        new_items.push(item);
        Cart { items: new_items }
    }

    /// アイテムを削除
    pub fn remove_item(&self, product_id: &str) -> Cart {
        let new_items = self
            .items
            .iter()
            .filter(|item| item.product.id != product_id)
            .cloned()
            .collect();
        Cart { items: new_items }
    }

    /// 合計金額（純粋関数）
    pub fn total(&self) -> i64 {
        self.items.iter().map(|item| item.subtotal()).sum()
    }

    /// アイテム数
    pub fn item_count(&self) -> usize {
        self.items.len()
    }

    /// 総数量
    pub fn total_quantity(&self) -> u32 {
        self.items.iter().map(|item| item.quantity).sum()
    }

    /// カテゴリごとの小計
    pub fn subtotals_by_category(&self) -> HashMap<String, i64> {
        let mut subtotals = HashMap::new();
        for item in &self.items {
            *subtotals.entry(item.product.category.clone()).or_insert(0) += item.subtotal();
        }
        subtotals
    }
}

impl Default for Cart {
    fn default() -> Self {
        Self::new()
    }
}

// =============================================================================
// 2. 割引計算（純粋関数によるビジネスルール）
// =============================================================================

/// 割引タイプ
#[derive(Debug, Clone, PartialEq)]
pub enum DiscountType {
    Percentage(f64),     // パーセント割引
    FixedAmount(i64),    // 固定金額割引
    BuyNGetM(u32, u32),  // N個買うとM個無料
}

/// 割引条件
#[derive(Debug, Clone, PartialEq)]
pub struct DiscountRule {
    pub name: String,
    pub discount_type: DiscountType,
    pub min_amount: Option<i64>,
    pub min_quantity: Option<u32>,
    pub category: Option<String>,
}

impl DiscountRule {
    /// 割引が適用可能かどうか（純粋関数）
    pub fn is_applicable(&self, cart: &Cart) -> bool {
        let amount_ok = self.min_amount.is_none_or(|min| cart.total() >= min);
        let quantity_ok = self.min_quantity.is_none_or(|min| cart.total_quantity() >= min);
        let category_ok = self.category.as_ref().is_none_or(|cat| {
            cart.items.iter().any(|item| &item.product.category == cat)
        });

        amount_ok && quantity_ok && category_ok
    }

    /// 割引額を計算（純粋関数）
    pub fn calculate_discount(&self, cart: &Cart) -> i64 {
        if !self.is_applicable(cart) {
            return 0;
        }

        match &self.discount_type {
            DiscountType::Percentage(rate) => (cart.total() as f64 * rate) as i64,
            DiscountType::FixedAmount(amount) => *amount,
            DiscountType::BuyNGetM(n, m) => {
                // 簡略化: 全アイテムに対して N+M 個ごとに M 個分の割引
                let total_qty = cart.total_quantity();
                let avg_price = if total_qty > 0 {
                    cart.total() / total_qty as i64
                } else {
                    0
                };
                let free_items = total_qty / (n + m) * m;
                avg_price * free_items as i64
            }
        }
    }
}

/// 複数の割引ルールを適用
pub fn apply_discounts(cart: &Cart, rules: &[DiscountRule]) -> i64 {
    let total = cart.total();
    let discount = rules
        .iter()
        .map(|rule| rule.calculate_discount(cart))
        .max()
        .unwrap_or(0);
    total - discount
}

// =============================================================================
// 3. 税金計算（純粋関数）
// =============================================================================

/// 税率タイプ
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum TaxType {
    Standard,     // 標準税率 (10%)
    Reduced,      // 軽減税率 (8%)
    TaxFree,      // 非課税
}

impl TaxType {
    pub fn rate(&self) -> f64 {
        match self {
            TaxType::Standard => 0.10,
            TaxType::Reduced => 0.08,
            TaxType::TaxFree => 0.0,
        }
    }
}

/// 税金を計算
pub fn calculate_tax(amount: i64, tax_type: TaxType) -> i64 {
    (amount as f64 * tax_type.rate()).round() as i64
}

/// カテゴリから税タイプを決定
pub fn tax_type_for_category(category: &str) -> TaxType {
    match category {
        "food" | "beverage" => TaxType::Reduced,
        "book" | "newspaper" => TaxType::Reduced,
        "medical" => TaxType::TaxFree,
        _ => TaxType::Standard,
    }
}

/// カートの税金を計算
pub fn calculate_cart_tax(cart: &Cart) -> i64 {
    cart.items
        .iter()
        .map(|item| {
            let tax_type = tax_type_for_category(&item.product.category);
            calculate_tax(item.subtotal(), tax_type)
        })
        .sum()
}

// =============================================================================
// 4. 注文処理（依存性注入パターン）
// =============================================================================

/// 注文
#[derive(Debug, Clone, PartialEq)]
pub struct Order {
    pub id: String,
    pub cart: Cart,
    pub subtotal: i64,
    pub tax: i64,
    pub discount: i64,
    pub total: i64,
}

/// 注文サマリー
#[derive(Debug, Clone, PartialEq)]
pub struct OrderSummary {
    pub item_count: usize,
    pub subtotal: i64,
    pub tax: i64,
    pub discount: i64,
    pub total: i64,
}

/// 注文サマリーを計算（純粋関数）
pub fn calculate_order_summary(cart: &Cart, discount_rules: &[DiscountRule]) -> OrderSummary {
    let subtotal = cart.total();
    let tax = calculate_cart_tax(cart);
    let discount = discount_rules
        .iter()
        .map(|rule| rule.calculate_discount(cart))
        .max()
        .unwrap_or(0);
    let total = subtotal + tax - discount;

    OrderSummary {
        item_count: cart.item_count(),
        subtotal,
        tax,
        discount,
        total: total.max(0), // 負にならないように
    }
}

/// ID 生成関数の型（依存性注入用）
pub type IdGenerator = fn() -> String;

/// 注文を作成（ID生成を外部から注入）
pub fn create_order(cart: &Cart, discount_rules: &[DiscountRule], id_gen: IdGenerator) -> Order {
    let summary = calculate_order_summary(cart, discount_rules);

    Order {
        id: id_gen(),
        cart: cart.clone(),
        subtotal: summary.subtotal,
        tax: summary.tax,
        discount: summary.discount,
        total: summary.total,
    }
}

// =============================================================================
// 5. 在庫管理（イミュータブルデータ構造）
// =============================================================================

/// 在庫情報
#[derive(Debug, Clone, PartialEq)]
pub struct Inventory {
    pub stocks: HashMap<String, u32>,
}

impl Inventory {
    pub fn new() -> Inventory {
        Inventory {
            stocks: HashMap::new(),
        }
    }

    /// 在庫を追加
    pub fn add_stock(&self, product_id: &str, quantity: u32) -> Inventory {
        let mut new_stocks = self.stocks.clone();
        *new_stocks.entry(product_id.to_string()).or_insert(0) += quantity;
        Inventory { stocks: new_stocks }
    }

    /// 在庫を減らす
    pub fn remove_stock(&self, product_id: &str, quantity: u32) -> Result<Inventory, String> {
        let current = self.stocks.get(product_id).copied().unwrap_or(0);
        if current < quantity {
            Err(format!(
                "在庫不足: {} (現在: {}, 要求: {})",
                product_id, current, quantity
            ))
        } else {
            let mut new_stocks = self.stocks.clone();
            new_stocks.insert(product_id.to_string(), current - quantity);
            Ok(Inventory { stocks: new_stocks })
        }
    }

    /// 在庫を確認
    pub fn get_stock(&self, product_id: &str) -> u32 {
        self.stocks.get(product_id).copied().unwrap_or(0)
    }

    /// カートの在庫を確保できるか確認
    pub fn can_fulfill(&self, cart: &Cart) -> bool {
        cart.items.iter().all(|item| {
            self.get_stock(&item.product.id) >= item.quantity
        })
    }

    /// カートの在庫を確保
    pub fn reserve_for_cart(&self, cart: &Cart) -> Result<Inventory, Vec<String>> {
        let mut errors = Vec::new();
        let mut inventory = self.clone();

        for item in &cart.items {
            match inventory.remove_stock(&item.product.id, item.quantity) {
                Ok(new_inv) => inventory = new_inv,
                Err(e) => errors.push(e),
            }
        }

        if errors.is_empty() {
            Ok(inventory)
        } else {
            Err(errors)
        }
    }
}

impl Default for Inventory {
    fn default() -> Self {
        Self::new()
    }
}

// =============================================================================
// 6. ポイント計算（ビジネスルールの分離）
// =============================================================================

/// ポイント計算ルール
#[derive(Debug, Clone)]
pub struct PointRule {
    pub name: String,
    pub rate: f64,           // ポイント付与率
    pub category: Option<String>,
    pub multiplier: f64,     // キャンペーン倍率
}

impl PointRule {
    pub fn new(name: &str, rate: f64) -> PointRule {
        PointRule {
            name: name.to_string(),
            rate,
            category: None,
            multiplier: 1.0,
        }
    }

    pub fn with_category(mut self, category: &str) -> PointRule {
        self.category = Some(category.to_string());
        self
    }

    pub fn with_multiplier(mut self, multiplier: f64) -> PointRule {
        self.multiplier = multiplier;
        self
    }
}

/// ポイントを計算（純粋関数）
pub fn calculate_points(cart: &Cart, rules: &[PointRule]) -> i64 {
    cart.items
        .iter()
        .map(|item| {
            let applicable_rules: Vec<_> = rules
                .iter()
                .filter(|rule| {
                    rule.category
                        .as_ref()
                        .is_none_or(|cat| cat == &item.product.category)
                })
                .collect();

            let best_rule = applicable_rules
                .iter()
                .max_by(|a, b| {
                    (a.rate * a.multiplier)
                        .partial_cmp(&(b.rate * b.multiplier))
                        .unwrap()
                });

            if let Some(rule) = best_rule {
                (item.subtotal() as f64 * rule.rate * rule.multiplier).round() as i64
            } else {
                0
            }
        })
        .sum()
}

// =============================================================================
// 7. テスト用ヘルパー（テストダブル）
// =============================================================================

/// テスト用の固定IDジェネレータ
pub fn test_id_generator() -> String {
    "TEST-ORDER-001".to_string()
}

/// テスト用の商品を作成
pub fn test_product(id: &str, name: &str, price: i64, category: &str) -> Product {
    Product {
        id: id.to_string(),
        name: name.to_string(),
        price,
        category: category.to_string(),
    }
}

/// テスト用のカートを作成
pub fn test_cart_with_items(items: Vec<(Product, u32)>) -> Cart {
    let cart_items: Vec<CartItem> = items
        .into_iter()
        .map(|(product, quantity)| CartItem::new(product, quantity))
        .collect();
    Cart { items: cart_items }
}

// =============================================================================
// テスト
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    // -------------------------------------------------------------------------
    // Cart のテスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_cart_new_is_empty() {
        let cart = Cart::new();
        assert_eq!(cart.item_count(), 0);
        assert_eq!(cart.total(), 0);
    }

    #[test]
    fn test_cart_add_item() {
        let cart = Cart::new();
        let product = test_product("P1", "商品1", 1000, "general");
        let item = CartItem::new(product, 2);

        let new_cart = cart.add_item(item);
        assert_eq!(new_cart.item_count(), 1);
        assert_eq!(new_cart.total(), 2000);
    }

    #[test]
    fn test_cart_add_multiple_items() {
        let cart = Cart::new();
        let p1 = test_product("P1", "商品1", 1000, "general");
        let p2 = test_product("P2", "商品2", 500, "food");

        let new_cart = cart
            .add_item(CartItem::new(p1, 2))
            .add_item(CartItem::new(p2, 3));

        assert_eq!(new_cart.item_count(), 2);
        assert_eq!(new_cart.total(), 3500);
    }

    #[test]
    fn test_cart_remove_item() {
        let cart = test_cart_with_items(vec![
            (test_product("P1", "商品1", 1000, "general"), 2),
            (test_product("P2", "商品2", 500, "food"), 3),
        ]);

        let new_cart = cart.remove_item("P1");
        assert_eq!(new_cart.item_count(), 1);
        assert_eq!(new_cart.total(), 1500);
    }

    #[test]
    fn test_cart_subtotals_by_category() {
        let cart = test_cart_with_items(vec![
            (test_product("P1", "商品1", 1000, "general"), 2),
            (test_product("P2", "商品2", 500, "food"), 3),
            (test_product("P3", "商品3", 800, "general"), 1),
        ]);

        let subtotals = cart.subtotals_by_category();
        assert_eq!(subtotals.get("general"), Some(&2800));
        assert_eq!(subtotals.get("food"), Some(&1500));
    }

    // -------------------------------------------------------------------------
    // 割引計算のテスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_percentage_discount() {
        let cart = test_cart_with_items(vec![
            (test_product("P1", "商品1", 1000, "general"), 10),
        ]);

        let rule = DiscountRule {
            name: "10%オフ".to_string(),
            discount_type: DiscountType::Percentage(0.1),
            min_amount: None,
            min_quantity: None,
            category: None,
        };

        assert_eq!(rule.calculate_discount(&cart), 1000);
    }

    #[test]
    fn test_fixed_amount_discount() {
        let cart = test_cart_with_items(vec![
            (test_product("P1", "商品1", 1000, "general"), 5),
        ]);

        let rule = DiscountRule {
            name: "500円引き".to_string(),
            discount_type: DiscountType::FixedAmount(500),
            min_amount: Some(3000),
            min_quantity: None,
            category: None,
        };

        assert!(rule.is_applicable(&cart));
        assert_eq!(rule.calculate_discount(&cart), 500);
    }

    #[test]
    fn test_discount_not_applicable() {
        let cart = test_cart_with_items(vec![
            (test_product("P1", "商品1", 100, "general"), 1),
        ]);

        let rule = DiscountRule {
            name: "500円引き".to_string(),
            discount_type: DiscountType::FixedAmount(500),
            min_amount: Some(3000),
            min_quantity: None,
            category: None,
        };

        assert!(!rule.is_applicable(&cart));
        assert_eq!(rule.calculate_discount(&cart), 0);
    }

    #[test]
    fn test_apply_best_discount() {
        let cart = test_cart_with_items(vec![
            (test_product("P1", "商品1", 1000, "general"), 10),
        ]);

        let rules = vec![
            DiscountRule {
                name: "5%オフ".to_string(),
                discount_type: DiscountType::Percentage(0.05),
                min_amount: None,
                min_quantity: None,
                category: None,
            },
            DiscountRule {
                name: "1000円引き".to_string(),
                discount_type: DiscountType::FixedAmount(1000),
                min_amount: Some(5000),
                min_quantity: None,
                category: None,
            },
        ];

        // 10000円のカート、5%=500円、1000円引きが最大
        assert_eq!(apply_discounts(&cart, &rules), 9000);
    }

    // -------------------------------------------------------------------------
    // 税金計算のテスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_calculate_standard_tax() {
        assert_eq!(calculate_tax(1000, TaxType::Standard), 100);
    }

    #[test]
    fn test_calculate_reduced_tax() {
        assert_eq!(calculate_tax(1000, TaxType::Reduced), 80);
    }

    #[test]
    fn test_calculate_tax_free() {
        assert_eq!(calculate_tax(1000, TaxType::TaxFree), 0);
    }

    #[test]
    fn test_tax_type_for_category() {
        assert_eq!(tax_type_for_category("food"), TaxType::Reduced);
        assert_eq!(tax_type_for_category("electronics"), TaxType::Standard);
        assert_eq!(tax_type_for_category("medical"), TaxType::TaxFree);
    }

    #[test]
    fn test_calculate_cart_tax() {
        let cart = test_cart_with_items(vec![
            (test_product("P1", "食品", 1000, "food"), 1),       // 軽減税率 8% = 80
            (test_product("P2", "家電", 2000, "electronics"), 1), // 標準税率 10% = 200
        ]);

        assert_eq!(calculate_cart_tax(&cart), 280);
    }

    // -------------------------------------------------------------------------
    // 注文処理のテスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_calculate_order_summary() {
        let cart = test_cart_with_items(vec![
            (test_product("P1", "商品1", 1000, "general"), 2),
        ]);
        let rules = vec![];

        let summary = calculate_order_summary(&cart, &rules);

        assert_eq!(summary.item_count, 1);
        assert_eq!(summary.subtotal, 2000);
        assert_eq!(summary.tax, 200);
        assert_eq!(summary.discount, 0);
        assert_eq!(summary.total, 2200);
    }

    #[test]
    fn test_create_order_with_injected_id() {
        let cart = test_cart_with_items(vec![
            (test_product("P1", "商品1", 1000, "general"), 1),
        ]);
        let rules = vec![];

        let order = create_order(&cart, &rules, test_id_generator);

        assert_eq!(order.id, "TEST-ORDER-001");
        assert_eq!(order.total, 1100);
    }

    // -------------------------------------------------------------------------
    // 在庫管理のテスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_inventory_add_stock() {
        let inventory = Inventory::new();
        let new_inventory = inventory.add_stock("P1", 10);

        assert_eq!(new_inventory.get_stock("P1"), 10);
        assert_eq!(inventory.get_stock("P1"), 0); // 元は変わらない
    }

    #[test]
    fn test_inventory_remove_stock() {
        let inventory = Inventory::new().add_stock("P1", 10);
        let result = inventory.remove_stock("P1", 3);

        assert!(result.is_ok());
        assert_eq!(result.unwrap().get_stock("P1"), 7);
    }

    #[test]
    fn test_inventory_remove_stock_insufficient() {
        let inventory = Inventory::new().add_stock("P1", 5);
        let result = inventory.remove_stock("P1", 10);

        assert!(result.is_err());
    }

    #[test]
    fn test_inventory_can_fulfill() {
        let inventory = Inventory::new()
            .add_stock("P1", 10)
            .add_stock("P2", 5);

        let cart = test_cart_with_items(vec![
            (test_product("P1", "商品1", 1000, "general"), 5),
            (test_product("P2", "商品2", 500, "food"), 3),
        ]);

        assert!(inventory.can_fulfill(&cart));
    }

    #[test]
    fn test_inventory_cannot_fulfill() {
        let inventory = Inventory::new()
            .add_stock("P1", 2);

        let cart = test_cart_with_items(vec![
            (test_product("P1", "商品1", 1000, "general"), 5),
        ]);

        assert!(!inventory.can_fulfill(&cart));
    }

    #[test]
    fn test_inventory_reserve_for_cart() {
        let inventory = Inventory::new()
            .add_stock("P1", 10)
            .add_stock("P2", 5);

        let cart = test_cart_with_items(vec![
            (test_product("P1", "商品1", 1000, "general"), 3),
            (test_product("P2", "商品2", 500, "food"), 2),
        ]);

        let result = inventory.reserve_for_cart(&cart);
        assert!(result.is_ok());
        let new_inventory = result.unwrap();
        assert_eq!(new_inventory.get_stock("P1"), 7);
        assert_eq!(new_inventory.get_stock("P2"), 3);
    }

    // -------------------------------------------------------------------------
    // ポイント計算のテスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_calculate_points_basic() {
        let cart = test_cart_with_items(vec![
            (test_product("P1", "商品1", 1000, "general"), 1),
        ]);

        let rules = vec![PointRule::new("基本", 0.01)];

        assert_eq!(calculate_points(&cart, &rules), 10);
    }

    #[test]
    fn test_calculate_points_with_multiplier() {
        let cart = test_cart_with_items(vec![
            (test_product("P1", "商品1", 1000, "general"), 1),
        ]);

        let rules = vec![PointRule::new("キャンペーン", 0.01).with_multiplier(3.0)];

        assert_eq!(calculate_points(&cart, &rules), 30);
    }

    #[test]
    fn test_calculate_points_category_specific() {
        let cart = test_cart_with_items(vec![
            (test_product("P1", "食品", 1000, "food"), 1),
            (test_product("P2", "家電", 2000, "electronics"), 1),
        ]);

        let rules = vec![
            PointRule::new("基本", 0.01),
            PointRule::new("食品ポイント", 0.05).with_category("food"),
        ];

        // food: 1000 * 0.05 = 50
        // electronics: 2000 * 0.01 = 20
        assert_eq!(calculate_points(&cart, &rules), 70);
    }

    // -------------------------------------------------------------------------
    // イミュータビリティのテスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_cart_immutability() {
        let cart1 = Cart::new();
        let product = test_product("P1", "商品1", 1000, "general");

        let cart2 = cart1.add_item(CartItem::new(product, 1));

        // cart1 は変更されていない
        assert_eq!(cart1.item_count(), 0);
        assert_eq!(cart2.item_count(), 1);
    }

    #[test]
    fn test_inventory_immutability() {
        let inv1 = Inventory::new();
        let inv2 = inv1.add_stock("P1", 10);
        let inv3 = inv2.remove_stock("P1", 3).unwrap();

        // 各バージョンは独立
        assert_eq!(inv1.get_stock("P1"), 0);
        assert_eq!(inv2.get_stock("P1"), 10);
        assert_eq!(inv3.get_stock("P1"), 7);
    }
}
