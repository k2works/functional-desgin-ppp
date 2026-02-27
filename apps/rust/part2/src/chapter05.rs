//! 第5章: プロパティベーステスト
//!
//! Rust の proptest クレートを使ったプロパティベーステストを学びます。
//! ランダムなテストデータ生成と、不変条件の検証を扱います。

use std::collections::HashSet;

// =============================================================================
// 1. 基本的な関数（テスト対象）
// =============================================================================

/// リストを反転する
pub fn reverse<T: Clone>(list: &[T]) -> Vec<T> {
    list.iter().rev().cloned().collect()
}

/// リストの長さを取得
pub fn length<T>(list: &[T]) -> usize {
    list.len()
}

/// 二つのリストを連結
pub fn concat<T: Clone>(list1: &[T], list2: &[T]) -> Vec<T> {
    let mut result = list1.to_vec();
    result.extend(list2.iter().cloned());
    result
}

/// リストの最小値を取得
pub fn minimum(list: &[i32]) -> Option<i32> {
    list.iter().copied().min()
}

/// リストの最大値を取得
pub fn maximum(list: &[i32]) -> Option<i32> {
    list.iter().copied().max()
}

/// リストの合計
pub fn sum(list: &[i32]) -> i64 {
    list.iter().map(|&x| x as i64).sum()
}

/// リストをソート
pub fn sort(list: &[i32]) -> Vec<i32> {
    let mut sorted = list.to_vec();
    sorted.sort();
    sorted
}

/// リストの重複を除去
pub fn distinct(list: &[i32]) -> Vec<i32> {
    let set: HashSet<_> = list.iter().cloned().collect();
    set.into_iter().collect()
}

// =============================================================================
// 2. 文字列操作関数
// =============================================================================

/// 文字列を大文字に変換
pub fn to_uppercase(s: &str) -> String {
    s.to_uppercase()
}

/// 文字列を小文字に変換
pub fn to_lowercase(s: &str) -> String {
    s.to_lowercase()
}

/// 文字列の長さを取得
pub fn string_length(s: &str) -> usize {
    s.chars().count()
}

/// 文字列を反転
pub fn reverse_string(s: &str) -> String {
    s.chars().rev().collect()
}

/// 文字列をトリム
pub fn trim(s: &str) -> String {
    s.trim().to_string()
}

// =============================================================================
// 3. 数学関数
// =============================================================================

/// 絶対値
pub fn abs(n: i32) -> i32 {
    n.abs()
}

/// 二つの数の最大値
pub fn max(a: i32, b: i32) -> i32 {
    std::cmp::max(a, b)
}

/// 二つの数の最小値
pub fn min(a: i32, b: i32) -> i32 {
    std::cmp::min(a, b)
}

/// 加算（結合法則と可換法則の検証用）
pub fn add(a: i64, b: i64) -> i64 {
    a + b
}

/// 乗算（結合法則と可換法則の検証用）
pub fn multiply(a: i64, b: i64) -> i64 {
    a * b
}

// =============================================================================
// 4. ドメインモデル（プロパティテスト用）
// =============================================================================

/// 金額
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Money {
    pub amount: i64,
    pub currency: Currency,
}

/// 通貨
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Currency {
    JPY,
    USD,
    EUR,
}

impl Money {
    pub fn new(amount: i64, currency: Currency) -> Money {
        Money { amount, currency }
    }

    /// 同じ通貨同士の加算
    pub fn add(&self, other: &Money) -> Option<Money> {
        if self.currency == other.currency {
            Some(Money::new(self.amount + other.amount, self.currency))
        } else {
            None
        }
    }

    /// 同じ通貨同士の減算
    pub fn subtract(&self, other: &Money) -> Option<Money> {
        if self.currency == other.currency {
            Some(Money::new(self.amount - other.amount, self.currency))
        } else {
            None
        }
    }

    /// スカラー倍
    pub fn multiply(&self, factor: i64) -> Money {
        Money::new(self.amount * factor, self.currency)
    }
}

/// 商品
#[derive(Debug, Clone, PartialEq)]
pub struct Product {
    pub name: String,
    pub price: Money,
    pub quantity: u32,
}

impl Product {
    pub fn new(name: &str, price: Money, quantity: u32) -> Product {
        Product {
            name: name.to_string(),
            price,
            quantity,
        }
    }

    /// 在庫の合計金額
    pub fn total_value(&self) -> Money {
        self.price.multiply(self.quantity as i64)
    }
}

/// 注文アイテム
#[derive(Debug, Clone, PartialEq)]
pub struct OrderItem {
    pub product_id: String,
    pub price: i64,
    pub quantity: u32,
}

impl OrderItem {
    pub fn new(product_id: &str, price: i64, quantity: u32) -> OrderItem {
        OrderItem {
            product_id: product_id.to_string(),
            price,
            quantity,
        }
    }

    /// アイテムの小計
    pub fn subtotal(&self) -> i64 {
        self.price * self.quantity as i64
    }
}

/// 注文
#[derive(Debug, Clone, PartialEq)]
pub struct Order {
    pub id: String,
    pub items: Vec<OrderItem>,
}

impl Order {
    pub fn new(id: &str, items: Vec<OrderItem>) -> Order {
        Order {
            id: id.to_string(),
            items,
        }
    }

    /// 注文の合計金額
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
}

// =============================================================================
// 5. 検証関数
// =============================================================================

/// 価格が正の数かどうか
pub fn is_valid_price(price: i64) -> bool {
    price > 0
}

/// 数量が正の数かどうか
pub fn is_valid_quantity(quantity: u32) -> bool {
    quantity > 0
}

/// メールアドレスの簡易検証
pub fn is_valid_email(email: &str) -> bool {
    email.contains('@') && email.contains('.')
}

/// 電話番号の簡易検証（日本形式）
pub fn is_valid_phone(phone: &str) -> bool {
    let digits: String = phone.chars().filter(|c| c.is_ascii_digit()).collect();
    digits.len() >= 10 && digits.len() <= 11
}

// =============================================================================
// 6. リスト操作のプロパティ
// =============================================================================

/// リストが空かどうか
pub fn is_empty<T>(list: &[T]) -> bool {
    list.is_empty()
}

/// リストの先頭要素
pub fn head<T: Clone>(list: &[T]) -> Option<T> {
    list.first().cloned()
}

/// リストの末尾（先頭以外）
pub fn tail<T: Clone>(list: &[T]) -> Vec<T> {
    if list.is_empty() {
        Vec::new()
    } else {
        list[1..].to_vec()
    }
}

/// リストの末尾要素
pub fn last<T: Clone>(list: &[T]) -> Option<T> {
    list.last().cloned()
}

/// リストの末尾以外
pub fn init<T: Clone>(list: &[T]) -> Vec<T> {
    if list.is_empty() {
        Vec::new()
    } else {
        list[..list.len() - 1].to_vec()
    }
}

/// 要素を先頭に追加
pub fn cons<T: Clone>(elem: T, list: &[T]) -> Vec<T> {
    let mut result = vec![elem];
    result.extend(list.iter().cloned());
    result
}

/// 要素を末尾に追加
pub fn snoc<T: Clone>(list: &[T], elem: T) -> Vec<T> {
    let mut result = list.to_vec();
    result.push(elem);
    result
}

// =============================================================================
// テスト
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;

    // -------------------------------------------------------------------------
    // リスト操作のプロパティテスト
    // -------------------------------------------------------------------------

    proptest! {
        /// reverse の自己逆元性: reverse(reverse(xs)) == xs
        #[test]
        fn prop_reverse_involutive(xs: Vec<i32>) {
            prop_assert_eq!(reverse(&reverse(&xs)), xs);
        }

        /// reverse は長さを保存する
        #[test]
        fn prop_reverse_preserves_length(xs: Vec<i32>) {
            prop_assert_eq!(length(&reverse(&xs)), length(&xs));
        }

        /// concat の長さは各リストの長さの和
        #[test]
        fn prop_concat_length(xs: Vec<i32>, ys: Vec<i32>) {
            prop_assert_eq!(length(&concat(&xs, &ys)), length(&xs) + length(&ys));
        }

        /// 空リストとの連結は恒等操作（右単位元）
        #[test]
        fn prop_concat_right_identity(xs: Vec<i32>) {
            prop_assert_eq!(concat(&xs, &[]), xs);
        }

        /// 空リストとの連結は恒等操作（左単位元）
        #[test]
        fn prop_concat_left_identity(xs: Vec<i32>) {
            prop_assert_eq!(concat(&[], &xs), xs);
        }

        /// sort は長さを保存する
        #[test]
        fn prop_sort_preserves_length(xs: Vec<i32>) {
            prop_assert_eq!(length(&sort(&xs)), length(&xs));
        }

        /// sort は冪等: sort(sort(xs)) == sort(xs)
        #[test]
        fn prop_sort_idempotent(xs: Vec<i32>) {
            prop_assert_eq!(sort(&sort(&xs)), sort(&xs));
        }

        /// sort 後の最小値は先頭
        #[test]
        fn prop_sort_minimum_is_first(xs: Vec<i32>) {
            let sorted = sort(&xs);
            if !sorted.is_empty() {
                prop_assert_eq!(Some(sorted[0]), minimum(&xs));
            }
        }

        /// sort 後の最大値は末尾
        #[test]
        fn prop_sort_maximum_is_last(xs: Vec<i32>) {
            let sorted = sort(&xs);
            if !sorted.is_empty() {
                prop_assert_eq!(Some(sorted[sorted.len() - 1]), maximum(&xs));
            }
        }
    }

    // -------------------------------------------------------------------------
    // 数学的プロパティ
    // -------------------------------------------------------------------------

    proptest! {
        /// 加算の可換法則: a + b == b + a
        #[test]
        fn prop_add_commutative(a: i32, b: i32) {
            let a = a as i64;
            let b = b as i64;
            prop_assert_eq!(add(a, b), add(b, a));
        }

        /// 乗算の可換法則: a * b == b * a
        #[test]
        fn prop_multiply_commutative(a: i16, b: i16) {
            let a = a as i64;
            let b = b as i64;
            prop_assert_eq!(multiply(a, b), multiply(b, a));
        }

        /// 加算の結合法則: (a + b) + c == a + (b + c)
        #[test]
        fn prop_add_associative(a: i16, b: i16, c: i16) {
            let a = a as i64;
            let b = b as i64;
            let c = c as i64;
            prop_assert_eq!(add(add(a, b), c), add(a, add(b, c)));
        }

        /// 加算の単位元: a + 0 == a
        #[test]
        fn prop_add_identity(a: i64) {
            prop_assert_eq!(add(a, 0), a);
        }

        /// 乗算の単位元: a * 1 == a
        #[test]
        fn prop_multiply_identity(a: i64) {
            prop_assert_eq!(multiply(a, 1), a);
        }

        /// max は可換
        #[test]
        fn prop_max_commutative(a: i32, b: i32) {
            prop_assert_eq!(max(a, b), max(b, a));
        }

        /// min は可換
        #[test]
        fn prop_min_commutative(a: i32, b: i32) {
            prop_assert_eq!(min(a, b), min(b, a));
        }

        /// max(a, b) >= a && max(a, b) >= b
        #[test]
        fn prop_max_is_greater(a: i32, b: i32) {
            let m = max(a, b);
            prop_assert!(m >= a && m >= b);
        }

        /// min(a, b) <= a && min(a, b) <= b
        #[test]
        fn prop_min_is_lesser(a: i32, b: i32) {
            let m = min(a, b);
            prop_assert!(m <= a && m <= b);
        }

        /// abs(n) >= 0
        #[test]
        fn prop_abs_non_negative(n: i32) {
            // i32::MIN の abs はオーバーフローするので除外
            prop_assume!(n != i32::MIN);
            prop_assert!(abs(n) >= 0);
        }
    }

    // -------------------------------------------------------------------------
    // 文字列操作のプロパティ
    // -------------------------------------------------------------------------

    proptest! {
        /// 反転の自己逆元性
        #[test]
        fn prop_string_reverse_involutive(s in "\\PC*") {
            prop_assert_eq!(reverse_string(&reverse_string(&s)), s);
        }

        /// 大文字変換後の長さは変わらない（ASCII）
        #[test]
        fn prop_uppercase_preserves_length(s in "[a-zA-Z]*") {
            prop_assert_eq!(string_length(&to_uppercase(&s)), string_length(&s));
        }

        /// 小文字変換後の長さは変わらない（ASCII）
        #[test]
        fn prop_lowercase_preserves_length(s in "[a-zA-Z]*") {
            prop_assert_eq!(string_length(&to_lowercase(&s)), string_length(&s));
        }

        /// trim は冪等
        #[test]
        fn prop_trim_idempotent(s in "\\PC*") {
            prop_assert_eq!(trim(&trim(&s)), trim(&s));
        }

        /// to_uppercase は冪等
        #[test]
        fn prop_uppercase_idempotent(s in "[a-zA-Z]*") {
            prop_assert_eq!(to_uppercase(&to_uppercase(&s)), to_uppercase(&s));
        }

        /// to_lowercase は冪等
        #[test]
        fn prop_lowercase_idempotent(s in "[a-zA-Z]*") {
            prop_assert_eq!(to_lowercase(&to_lowercase(&s)), to_lowercase(&s));
        }
    }

    // -------------------------------------------------------------------------
    // Money のプロパティ
    // -------------------------------------------------------------------------

    proptest! {
        /// Money の加算は可換
        #[test]
        fn prop_money_add_commutative(a: i32, b: i32) {
            let m1 = Money::new(a as i64, Currency::JPY);
            let m2 = Money::new(b as i64, Currency::JPY);
            prop_assert_eq!(m1.add(&m2), m2.add(&m1));
        }

        /// Money の加算は結合的
        #[test]
        fn prop_money_add_associative(a: i16, b: i16, c: i16) {
            let m1 = Money::new(a as i64, Currency::JPY);
            let m2 = Money::new(b as i64, Currency::JPY);
            let m3 = Money::new(c as i64, Currency::JPY);

            let left = m1.add(&m2).and_then(|r| r.add(&m3));
            let right = m2.add(&m3).and_then(|r| m1.add(&r));
            prop_assert_eq!(left, right);
        }

        /// Money のゼロは単位元
        #[test]
        fn prop_money_add_identity(a: i64) {
            let m = Money::new(a, Currency::JPY);
            let zero = Money::new(0, Currency::JPY);
            prop_assert_eq!(m.add(&zero), Some(m));
        }

        /// Money の加算と減算は逆操作
        #[test]
        fn prop_money_add_subtract_inverse(a: i32, b: i32) {
            let m1 = Money::new(a as i64, Currency::JPY);
            let m2 = Money::new(b as i64, Currency::JPY);

            let result = m1.add(&m2).and_then(|r| r.subtract(&m2));
            prop_assert_eq!(result, Some(m1));
        }

        /// 異なる通貨の加算は None
        #[test]
        fn prop_money_add_different_currency_fails(a: i64, b: i64) {
            let m1 = Money::new(a, Currency::JPY);
            let m2 = Money::new(b, Currency::USD);
            prop_assert!(m1.add(&m2).is_none());
        }
    }

    // -------------------------------------------------------------------------
    // Order のプロパティ
    // -------------------------------------------------------------------------

    proptest! {
        /// 注文の合計は各アイテムの小計の和
        #[test]
        fn prop_order_total_is_sum_of_subtotals(
            prices in prop::collection::vec(1i64..1000, 1..5),
            quantities in prop::collection::vec(1u32..100, 1..5)
        ) {
            let items: Vec<OrderItem> = prices.iter()
                .zip(quantities.iter())
                .enumerate()
                .map(|(i, (&p, &q))| OrderItem::new(&format!("PROD-{}", i), p, q))
                .collect();

            let order = Order::new("ORD-001", items.clone());

            let expected: i64 = items.iter().map(|i| i.subtotal()).sum();
            prop_assert_eq!(order.total(), expected);
        }

        /// アイテム数は items の長さと一致
        #[test]
        fn prop_order_item_count(
            n in 0usize..10
        ) {
            let items: Vec<OrderItem> = (0..n)
                .map(|i| OrderItem::new(&format!("PROD-{}", i), 100, 1))
                .collect();

            let order = Order::new("ORD-001", items);
            prop_assert_eq!(order.item_count(), n);
        }
    }

    // -------------------------------------------------------------------------
    // リスト操作（head, tail, last, init）
    // -------------------------------------------------------------------------

    proptest! {
        /// cons で追加した要素が head で取得できる
        #[test]
        fn prop_cons_head(x: i32, xs: Vec<i32>) {
            let result = cons(x, &xs);
            prop_assert_eq!(head(&result), Some(x));
        }

        /// cons で追加後の tail は元のリスト
        #[test]
        fn prop_cons_tail(x: i32, xs: Vec<i32>) {
            let result = cons(x, &xs);
            prop_assert_eq!(tail(&result), xs);
        }

        /// snoc で追加した要素が last で取得できる
        #[test]
        fn prop_snoc_last(xs: Vec<i32>, x: i32) {
            let result = snoc(&xs, x);
            prop_assert_eq!(last(&result), Some(x));
        }

        /// snoc で追加後の init は元のリスト
        #[test]
        fn prop_snoc_init(xs: Vec<i32>, x: i32) {
            let result = snoc(&xs, x);
            prop_assert_eq!(init(&result), xs);
        }

        /// head と tail で元のリストを再構築できる
        #[test]
        fn prop_head_tail_reconstruction(xs: Vec<i32>) {
            if !xs.is_empty() {
                let h = head(&xs).unwrap();
                let t = tail(&xs);
                prop_assert_eq!(cons(h, &t), xs);
            }
        }

        /// last と init で元のリストを再構築できる
        #[test]
        fn prop_last_init_reconstruction(xs: Vec<i32>) {
            if !xs.is_empty() {
                let l = last(&xs).unwrap();
                let i = init(&xs);
                prop_assert_eq!(snoc(&i, l), xs);
            }
        }
    }

    // -------------------------------------------------------------------------
    // 単体テスト（基本動作確認）
    // -------------------------------------------------------------------------

    #[test]
    fn test_reverse_basic() {
        assert_eq!(reverse(&[1, 2, 3]), vec![3, 2, 1]);
        assert_eq!(reverse::<i32>(&[]), Vec::<i32>::new());
    }

    #[test]
    fn test_sort_basic() {
        assert_eq!(sort(&[3, 1, 2]), vec![1, 2, 3]);
    }

    #[test]
    fn test_money_basic() {
        let m1 = Money::new(100, Currency::JPY);
        let m2 = Money::new(50, Currency::JPY);
        assert_eq!(m1.add(&m2), Some(Money::new(150, Currency::JPY)));
    }

    #[test]
    fn test_order_total_basic() {
        let items = vec![
            OrderItem::new("PROD-1", 100, 2),
            OrderItem::new("PROD-2", 200, 1),
        ];
        let order = Order::new("ORD-001", items);
        assert_eq!(order.total(), 400);
    }
}
