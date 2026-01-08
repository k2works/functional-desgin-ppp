# 第6章: TDD と関数型

## 概要

この章では、Rust における TDD（テスト駆動開発）と関数型プログラミングの実践を学びます。純粋関数、イミュータブルデータ、依存性注入など、テストしやすいコードを書くための技法を扱います。

## 学習目標

1. 純粋関数によるビジネスロジックの実装
2. イミュータブルデータ構造の設計
3. 依存性注入パターン
4. テストダブルの活用
5. ドメインモデルのテスト戦略

## 基本概念

### 純粋関数の特徴

純粋関数は以下の特性を持ちます：

1. **同じ入力に対して常に同じ出力**
2. **副作用がない**（外部状態の変更なし）
3. **参照透過性**（式をその結果で置き換え可能）

```rust
// 純粋関数：テストしやすい
pub fn calculate_tax(amount: i64, tax_type: TaxType) -> i64 {
    (amount as f64 * tax_type.rate()).round() as i64
}

// 非純粋関数：テストしにくい
pub fn save_to_database(data: &Data) -> Result<(), Error> {
    // 外部システムへの副作用
}
```

## 実装パターン

### 1. イミュータブルなショッピングカート

```rust
#[derive(Debug, Clone, PartialEq)]
pub struct Cart {
    pub items: Vec<CartItem>,
}

impl Cart {
    pub fn new() -> Cart {
        Cart { items: Vec::new() }
    }

    /// アイテムを追加（元のカートは変更しない）
    pub fn add_item(&self, item: CartItem) -> Cart {
        let mut new_items = self.items.clone();
        new_items.push(item);
        Cart { items: new_items }
    }

    /// 合計金額（純粋関数）
    pub fn total(&self) -> i64 {
        self.items.iter().map(|item| item.subtotal()).sum()
    }
}
```

### 2. ビジネスルールの分離

割引ルールを独立した純粋関数として実装：

```rust
#[derive(Debug, Clone)]
pub enum DiscountType {
    Percentage(f64),
    FixedAmount(i64),
}

#[derive(Debug, Clone)]
pub struct DiscountRule {
    pub name: String,
    pub discount_type: DiscountType,
    pub min_amount: Option<i64>,
}

impl DiscountRule {
    /// 適用可能かどうかを判定（純粋関数）
    pub fn is_applicable(&self, cart: &Cart) -> bool {
        self.min_amount.map_or(true, |min| cart.total() >= min)
    }

    /// 割引額を計算（純粋関数）
    pub fn calculate_discount(&self, cart: &Cart) -> i64 {
        if !self.is_applicable(cart) {
            return 0;
        }

        match &self.discount_type {
            DiscountType::Percentage(rate) => (cart.total() as f64 * rate) as i64,
            DiscountType::FixedAmount(amount) => *amount,
        }
    }
}
```

### 3. 依存性注入

外部依存（ID生成など）を関数として注入：

```rust
/// ID 生成関数の型
pub type IdGenerator = fn() -> String;

/// 注文を作成（ID生成を外部から注入）
pub fn create_order(
    cart: &Cart,
    discount_rules: &[DiscountRule],
    id_gen: IdGenerator,
) -> Order {
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

// 本番用
fn production_id_generator() -> String {
    uuid::Uuid::new_v4().to_string()
}

// テスト用
fn test_id_generator() -> String {
    "TEST-ORDER-001".to_string()
}
```

### 4. イミュータブルな在庫管理

```rust
#[derive(Debug, Clone)]
pub struct Inventory {
    pub stocks: HashMap<String, u32>,
}

impl Inventory {
    /// 在庫を追加（新しいインベントリを返す）
    pub fn add_stock(&self, product_id: &str, quantity: u32) -> Inventory {
        let mut new_stocks = self.stocks.clone();
        *new_stocks.entry(product_id.to_string()).or_insert(0) += quantity;
        Inventory { stocks: new_stocks }
    }

    /// 在庫を減らす（Result で失敗を表現）
    pub fn remove_stock(&self, product_id: &str, quantity: u32) -> Result<Inventory, String> {
        let current = self.stocks.get(product_id).copied().unwrap_or(0);
        if current < quantity {
            Err(format!("在庫不足: {}", product_id))
        } else {
            let mut new_stocks = self.stocks.clone();
            new_stocks.insert(product_id.to_string(), current - quantity);
            Ok(Inventory { stocks: new_stocks })
        }
    }
}
```

## テスト戦略

### 純粋関数のテスト

```rust
#[test]
fn test_calculate_tax() {
    assert_eq!(calculate_tax(1000, TaxType::Standard), 100);  // 10%
    assert_eq!(calculate_tax(1000, TaxType::Reduced), 80);    // 8%
    assert_eq!(calculate_tax(1000, TaxType::TaxFree), 0);     // 0%
}
```

### イミュータビリティの検証

```rust
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
```

### 依存性注入のテスト

```rust
#[test]
fn test_create_order_with_injected_id() {
    let cart = test_cart_with_items(vec![
        (test_product("P1", "商品1", 1000, "general"), 1),
    ]);

    // テスト用のID生成器を注入
    let order = create_order(&cart, &[], test_id_generator);

    assert_eq!(order.id, "TEST-ORDER-001");
}
```

### テストヘルパー関数

```rust
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
```

## TDD サイクルの例

### Red: 失敗するテストを書く

```rust
#[test]
fn test_percentage_discount() {
    let cart = test_cart_with_items(vec![
        (test_product("P1", "商品1", 1000, "general"), 10),
    ]);

    let rule = DiscountRule {
        name: "10%オフ".to_string(),
        discount_type: DiscountType::Percentage(0.1),
        min_amount: None,
    };

    assert_eq!(rule.calculate_discount(&cart), 1000);
}
```

### Green: テストを通す最小限の実装

```rust
pub fn calculate_discount(&self, cart: &Cart) -> i64 {
    match &self.discount_type {
        DiscountType::Percentage(rate) => (cart.total() as f64 * rate) as i64,
        DiscountType::FixedAmount(amount) => *amount,
    }
}
```

### Refactor: コードを改善

```rust
pub fn calculate_discount(&self, cart: &Cart) -> i64 {
    if !self.is_applicable(cart) {
        return 0;  // 適用条件を追加
    }

    match &self.discount_type {
        DiscountType::Percentage(rate) => (cart.total() as f64 * rate) as i64,
        DiscountType::FixedAmount(amount) => *amount,
    }
}
```

## 他言語との比較

| 概念 | Rust | Scala | F# |
|------|------|-------|-----|
| イミュータブル | デフォルト | `val` / case class | デフォルト |
| 依存性注入 | 関数型 / trait | 暗黙的パラメータ | 関数パラメータ |
| テストダブル | 関数 / mock crate | ScalaMock | 関数 |
| 副作用の分離 | `Result` / `Option` | `IO` / `Future` | `Async` / `Result` |

## まとめ

- **純粋関数**: 副作用なし、テスト容易、再利用性高
- **イミュータブル**: 状態変更なし、並行安全、履歴追跡可能
- **依存性注入**: 外部依存を抽象化、テスト用実装を注入可能
- **TDD**: Red-Green-Refactor サイクルで設計を導く
- **テストヘルパー**: 共通のセットアップコードを関数化

## 次の章

[第7章: FP アーキテクチャパターン](../part3/07-fp-architecture.md) では、関数型プログラミングを活用したアーキテクチャ設計を学びます。
