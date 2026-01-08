//! 第1章: 不変性とデータ変換
//!
//! 関数型プログラミングにおける不変データ構造の基本から、
//! データ変換パイプライン、副作用の分離までを扱います。

// =============================================================================
// 1. 不変データ構造の基本
// =============================================================================

/// 人物を表す構造体（デフォルトで不変）
#[derive(Debug, Clone, PartialEq)]
pub struct Person {
    pub name: String,
    pub age: u32,
}

impl Person {
    pub fn new(name: &str, age: u32) -> Self {
        Person {
            name: name.to_string(),
            age,
        }
    }

    /// 年齢を更新した新しい Person を返す（元のデータは変更しない）
    pub fn with_age(&self, new_age: u32) -> Self {
        Person {
            name: self.name.clone(),
            age: new_age,
        }
    }
}

// =============================================================================
// 2. 構造共有（Structural Sharing）
// =============================================================================

/// チームメンバーを表す構造体
#[derive(Debug, Clone, PartialEq)]
pub struct Member {
    pub name: String,
    pub role: String,
}

impl Member {
    pub fn new(name: &str, role: &str) -> Self {
        Member {
            name: name.to_string(),
            role: role.to_string(),
        }
    }
}

/// チームを表す構造体
#[derive(Debug, Clone, PartialEq)]
pub struct Team {
    pub name: String,
    pub members: Vec<Member>,
}

impl Team {
    pub fn new(name: &str, members: Vec<Member>) -> Self {
        Team {
            name: name.to_string(),
            members,
        }
    }

    /// 新しいメンバーを追加した新しい Team を返す
    pub fn add_member(&self, member: Member) -> Self {
        let mut new_members = self.members.clone();
        new_members.push(member);
        Team {
            name: self.name.clone(),
            members: new_members,
        }
    }
}

// =============================================================================
// 3. データ変換パイプライン
// =============================================================================

/// 商品アイテムを表す構造体
#[derive(Debug, Clone, PartialEq)]
pub struct Item {
    pub name: String,
    pub price: i32,
    pub quantity: i32,
}

impl Item {
    pub fn new(name: &str, price: i32, quantity: i32) -> Self {
        Item {
            name: name.to_string(),
            price,
            quantity,
        }
    }

    /// 小計を計算する
    pub fn subtotal(&self) -> i32 {
        self.price * self.quantity
    }
}

/// 顧客を表す構造体
#[derive(Debug, Clone, PartialEq)]
pub struct Customer {
    pub name: String,
    pub membership: String,
}

impl Customer {
    pub fn new(name: &str, membership: &str) -> Self {
        Customer {
            name: name.to_string(),
            membership: membership.to_string(),
        }
    }
}

/// 注文を表す構造体
#[derive(Debug, Clone, PartialEq)]
pub struct Order {
    pub items: Vec<Item>,
    pub customer: Customer,
}

impl Order {
    pub fn new(items: Vec<Item>, customer: Customer) -> Self {
        Order { items, customer }
    }

    /// 注文の合計金額を計算する
    pub fn calculate_total(&self) -> i32 {
        self.items.iter().map(|item| item.subtotal()).sum()
    }

    /// 割引後の金額を計算する
    pub fn apply_discount(&self, total: i32) -> f64 {
        let discount_rate = membership_discount(&self.customer.membership);
        total as f64 * (1.0 - discount_rate)
    }

    /// 注文を処理し、割引後の合計金額を返す
    pub fn process(&self) -> f64 {
        let total = self.calculate_total();
        self.apply_discount(total)
    }
}

/// 会員種別に応じた割引率を取得する
pub fn membership_discount(membership: &str) -> f64 {
    match membership {
        "gold" => 0.1,
        "silver" => 0.05,
        "bronze" => 0.02,
        _ => 0.0,
    }
}

// =============================================================================
// 4. 副作用の分離
// =============================================================================

/// 請求書を表す構造体
#[derive(Debug, Clone, PartialEq)]
pub struct Invoice {
    pub subtotal: i32,
    pub tax: f64,
    pub total: f64,
}

impl Invoice {
    pub fn new(subtotal: i32, tax: f64, total: f64) -> Self {
        Invoice {
            subtotal,
            tax,
            total,
        }
    }
}

/// 純粋関数：税額を計算する
pub fn pure_calculate_tax(amount: i32, tax_rate: f64) -> f64 {
    amount as f64 * tax_rate
}

/// ビジネスロジック（純粋関数）：請求書を計算する
pub fn calculate_invoice(items: &[Item], tax_rate: f64) -> Invoice {
    let subtotal: i32 = items.iter().map(|item| item.subtotal()).sum();
    let tax = pure_calculate_tax(subtotal, tax_rate);
    let total = subtotal as f64 + tax;
    Invoice::new(subtotal, tax, total)
}

/// データベースへの保存（副作用）
/// Rust では副作用を持つ関数に特別なサフィックスは付けないが、
/// 戻り値の型や名前で明示することが推奨される
pub fn save_invoice(invoice: Invoice) -> Invoice {
    println!("Saving invoice: {:?}", invoice);
    invoice
}

/// メール送信（副作用）
pub fn send_notification(invoice: Invoice, customer_email: &str) -> Invoice {
    println!("Sending notification to: {}", customer_email);
    invoice
}

/// 処理全体のオーケストレーション
pub fn process_and_save_invoice(items: &[Item], tax_rate: f64, customer_email: &str) -> Invoice {
    let invoice = calculate_invoice(items, tax_rate);
    let saved = save_invoice(invoice);
    send_notification(saved, customer_email)
}

// =============================================================================
// 5. 永続的データ構造の活用：Undo/Redo の実装
// =============================================================================

/// 履歴を保持するデータ構造
#[derive(Debug, Clone, PartialEq)]
pub struct History<T: Clone> {
    pub current: Option<T>,
    pub past: Vec<T>,
    pub future: Vec<T>,
}

impl<T: Clone> History<T> {
    /// 空の履歴を作成する
    pub fn new() -> Self {
        History {
            current: None,
            past: Vec::new(),
            future: Vec::new(),
        }
    }

    /// 新しい状態を履歴にプッシュする
    pub fn push_state(&self, new_state: T) -> Self {
        let mut new_past = Vec::new();
        if let Some(ref current) = self.current {
            new_past.push(current.clone());
        }
        new_past.extend(self.past.clone());

        History {
            current: Some(new_state),
            past: new_past,
            future: Vec::new(),
        }
    }

    /// 直前の状態に戻す
    pub fn undo(&self) -> Self {
        match self.past.first() {
            None => self.clone(),
            Some(previous) => {
                let mut new_future = Vec::new();
                if let Some(ref current) = self.current {
                    new_future.push(current.clone());
                }
                new_future.extend(self.future.clone());

                History {
                    current: Some(previous.clone()),
                    past: self.past[1..].to_vec(),
                    future: new_future,
                }
            }
        }
    }

    /// やり直し操作
    pub fn redo(&self) -> Self {
        match self.future.first() {
            None => self.clone(),
            Some(next_state) => {
                let mut new_past = Vec::new();
                if let Some(ref current) = self.current {
                    new_past.push(current.clone());
                }
                new_past.extend(self.past.clone());

                History {
                    current: Some(next_state.clone()),
                    past: new_past,
                    future: self.future[1..].to_vec(),
                }
            }
        }
    }
}

impl<T: Clone> Default for History<T> {
    fn default() -> Self {
        Self::new()
    }
}

// =============================================================================
// 6. Iterator による効率的な変換
// =============================================================================

/// 処理済みアイテムを表す構造体
#[derive(Debug, Clone, PartialEq)]
pub struct ProcessedItem {
    pub name: String,
    pub price: i32,
    pub quantity: i32,
    pub subtotal: i32,
}

impl ProcessedItem {
    pub fn from_item(item: &Item) -> Self {
        ProcessedItem {
            name: item.name.clone(),
            price: item.price,
            quantity: item.quantity,
            subtotal: item.subtotal(),
        }
    }
}

/// 複数の変換を合成した処理
pub fn process_items_efficiently(items: &[Item]) -> Vec<ProcessedItem> {
    items
        .iter()
        .filter(|item| item.quantity > 0)
        .map(ProcessedItem::from_item)
        .filter(|item| item.subtotal > 100)
        .collect()
}

/// Iterator を使用したより効率的な処理（Rust では同じ実装になる）
/// Rust のイテレータは遅延評価されるため、明示的に Iterator を使う必要はない
pub fn process_items_with_iterator(items: &[Item]) -> Vec<ProcessedItem> {
    items
        .iter()
        .filter(|item| item.quantity > 0)
        .map(ProcessedItem::from_item)
        .filter(|item| item.subtotal > 100)
        .collect()
}

// =============================================================================
// テスト
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;

    // -------------------------------------------------------------------------
    // 不変データ構造の基本
    // -------------------------------------------------------------------------

    #[test]
    fn test_update_age_does_not_modify_original() {
        let original = Person::new("田中", 30);
        let updated = original.with_age(31);

        assert_eq!(original.age, 30);
        assert_eq!(updated.age, 31);
        assert_eq!(updated.name, "田中");
    }

    // -------------------------------------------------------------------------
    // 構造共有
    // -------------------------------------------------------------------------

    #[test]
    fn test_add_member_returns_new_team() {
        let team = Team::new("開発チーム", vec![Member::new("田中", "developer")]);
        let new_team = team.add_member(Member::new("鈴木", "designer"));

        assert_eq!(team.members.len(), 1);
        assert_eq!(new_team.members.len(), 2);
        assert_eq!(new_team.name, "開発チーム");
    }

    // -------------------------------------------------------------------------
    // データ変換パイプライン
    // -------------------------------------------------------------------------

    #[test]
    fn test_calculate_subtotal() {
        assert_eq!(Item::new("A", 1000, 2).subtotal(), 2000);
        assert_eq!(Item::new("B", 500, 3).subtotal(), 1500);
    }

    #[test]
    fn test_membership_discount() {
        assert_eq!(membership_discount("gold"), 0.1);
        assert_eq!(membership_discount("silver"), 0.05);
        assert_eq!(membership_discount("bronze"), 0.02);
        assert_eq!(membership_discount("regular"), 0.0);
    }

    #[test]
    fn test_calculate_total() {
        let order = Order::new(
            vec![Item::new("A", 1000, 2), Item::new("B", 500, 3)],
            Customer::new("山田", "regular"),
        );
        assert_eq!(order.calculate_total(), 3500);
    }

    #[test]
    fn test_apply_discount() {
        let order = Order::new(vec![], Customer::new("山田", "gold"));
        assert_eq!(order.apply_discount(1000), 900.0);
    }

    #[test]
    fn test_process_order() {
        let order = Order::new(
            vec![Item::new("A", 1000, 2), Item::new("B", 500, 3)],
            Customer::new("山田", "gold"),
        );
        assert_eq!(order.process(), 3150.0);
    }

    // -------------------------------------------------------------------------
    // 副作用の分離
    // -------------------------------------------------------------------------

    #[test]
    fn test_pure_calculate_tax() {
        assert_eq!(pure_calculate_tax(1000, 0.1), 100.0);
        assert_eq!(pure_calculate_tax(1000, 0.08), 80.0);
    }

    #[test]
    fn test_calculate_invoice() {
        let items = vec![Item::new("A", 1000, 2), Item::new("B", 500, 1)];
        let invoice = calculate_invoice(&items, 0.1);

        assert_eq!(invoice.subtotal, 2500);
        assert_eq!(invoice.tax, 250.0);
        assert_eq!(invoice.total, 2750.0);
    }

    // -------------------------------------------------------------------------
    // Undo/Redo の実装
    // -------------------------------------------------------------------------

    #[test]
    fn test_create_history() {
        let history: History<HashMap<String, String>> = History::new();

        assert_eq!(history.current, None);
        assert!(history.past.is_empty());
        assert!(history.future.is_empty());
    }

    #[test]
    fn test_push_state() {
        let mut state = HashMap::new();
        state.insert("text".to_string(), "Hello".to_string());

        let history: History<HashMap<String, String>> = History::new();
        let history = history.push_state(state.clone());

        assert_eq!(history.current, Some(state));
    }

    #[test]
    fn test_undo() {
        let mut state1 = HashMap::new();
        state1.insert("text".to_string(), "Hello".to_string());
        let mut state2 = HashMap::new();
        state2.insert("text".to_string(), "Hello World".to_string());

        let history: History<HashMap<String, String>> = History::new();
        let history = history.push_state(state1.clone());
        let history = history.push_state(state2.clone());
        let after_undo = history.undo();

        assert_eq!(after_undo.current, Some(state1));
        assert_eq!(after_undo.future, vec![state2]);
    }

    #[test]
    fn test_redo() {
        let mut state1 = HashMap::new();
        state1.insert("text".to_string(), "Hello".to_string());
        let mut state2 = HashMap::new();
        state2.insert("text".to_string(), "Hello World".to_string());

        let history: History<HashMap<String, String>> = History::new();
        let history = history.push_state(state1.clone());
        let history = history.push_state(state2.clone());
        let history = history.undo().redo();

        assert_eq!(history.current, Some(state2));
        assert!(history.future.is_empty());
    }

    #[test]
    fn test_undo_on_empty_history() {
        let history: History<HashMap<String, String>> = History::new();
        let after_undo = history.undo();

        assert_eq!(after_undo.current, None);
    }

    #[test]
    fn test_redo_with_empty_future() {
        let mut state = HashMap::new();
        state.insert("text".to_string(), "Hello".to_string());

        let history: History<HashMap<String, String>> = History::new();
        let history = history.push_state(state.clone());
        let after_redo = history.redo();

        assert_eq!(after_redo.current, Some(state));
    }

    // -------------------------------------------------------------------------
    // Iterator による効率的な変換
    // -------------------------------------------------------------------------

    #[test]
    fn test_process_items_efficiently() {
        let items = vec![
            Item::new("A", 100, 2), // subtotal 200 > 100 ✓
            Item::new("B", 50, 1),  // subtotal 50 <= 100 ✗
            Item::new("C", 200, 0), // quantity 0 ✗
            Item::new("D", 300, 1), // subtotal 300 > 100 ✓
        ];
        assert_eq!(process_items_efficiently(&items).len(), 2);
    }

    #[test]
    fn test_process_items_with_iterator() {
        let items = vec![
            Item::new("A", 100, 2),
            Item::new("B", 50, 1),
            Item::new("C", 200, 0),
            Item::new("D", 300, 1),
        ];
        assert_eq!(process_items_with_iterator(&items).len(), 2);
    }
}
