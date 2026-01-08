//! 第17章: レンタルビデオシステム
//!
//! Martin Fowler の「リファクタリング」で有名なレンタルビデオシステム。
//! 関数型プログラミングによる料金計算ロジックの設計を学びます。

use rust_decimal::Decimal;
use rust_decimal_macros::dec;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};

// ============================================================
// 1. 基本型定義
// ============================================================

pub type Money = Decimal;
pub type Days = i32;
pub type Points = i32;

// ============================================================
// 2. 映画カテゴリ
// ============================================================

/// 映画カテゴリ
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum MovieCategory {
    /// 通常: 2日まで2.0、以降1日ごとに1.5追加
    Regular,
    /// 新作: 1日ごとに3.0
    NewRelease,
    /// 子供向け: 3日まで1.5、以降1日ごとに1.5追加
    Childrens,
}

// ============================================================
// 3. 映画
// ============================================================

/// 映画
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Movie {
    pub title: String,
    pub category: MovieCategory,
}

impl Movie {
    pub fn new(title: &str, category: MovieCategory) -> Self {
        Self {
            title: title.to_string(),
            category,
        }
    }

    pub fn regular(title: &str) -> Self {
        Self::new(title, MovieCategory::Regular)
    }

    pub fn new_release(title: &str) -> Self {
        Self::new(title, MovieCategory::NewRelease)
    }

    pub fn childrens(title: &str) -> Self {
        Self::new(title, MovieCategory::Childrens)
    }
}

// ============================================================
// 4. レンタル
// ============================================================

/// レンタル
#[derive(Debug, Clone)]
pub struct Rental {
    pub movie: Movie,
    pub days: Days,
}

impl Rental {
    pub fn new(movie: Movie, days: Days) -> Self {
        Self { movie, days }
    }
}

// ============================================================
// 5. 顧客
// ============================================================

/// 顧客
#[derive(Debug, Clone)]
pub struct Customer {
    pub name: String,
    pub rentals: Vec<Rental>,
}

impl Customer {
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            rentals: Vec::new(),
        }
    }

    pub fn add_rental(mut self, rental: Rental) -> Self {
        self.rentals.push(rental);
        self
    }

    pub fn add_rentals(mut self, rentals: &[Rental]) -> Self {
        self.rentals.extend(rentals.iter().cloned());
        self
    }
}

// ============================================================
// 6. 料金計算
// ============================================================

/// 料金計算の trait
pub trait PriceCalculator {
    fn calculate_amount(&self, days: Days) -> Money;
    fn calculate_points(&self, days: Days) -> Points;
}

/// 通常映画の料金計算
pub struct RegularPricing;

impl PriceCalculator for RegularPricing {
    fn calculate_amount(&self, days: Days) -> Money {
        if days > 2 {
            dec!(2.0) + Decimal::from(days - 2) * dec!(1.5)
        } else {
            dec!(2.0)
        }
    }

    fn calculate_points(&self, _days: Days) -> Points {
        1
    }
}

/// 新作映画の料金計算
pub struct NewReleasePricing;

impl PriceCalculator for NewReleasePricing {
    fn calculate_amount(&self, days: Days) -> Money {
        Decimal::from(days) * dec!(3.0)
    }

    fn calculate_points(&self, days: Days) -> Points {
        if days > 1 { 2 } else { 1 }
    }
}

/// 子供向け映画の料金計算
pub struct ChildrensPricing;

impl PriceCalculator for ChildrensPricing {
    fn calculate_amount(&self, days: Days) -> Money {
        if days > 3 {
            dec!(1.5) + Decimal::from(days - 3) * dec!(1.5)
        } else {
            dec!(1.5)
        }
    }

    fn calculate_points(&self, _days: Days) -> Points {
        1
    }
}

/// カテゴリに応じた料金計算器を取得
pub fn get_price_calculator(category: MovieCategory) -> Box<dyn PriceCalculator> {
    match category {
        MovieCategory::Regular => Box::new(RegularPricing),
        MovieCategory::NewRelease => Box::new(NewReleasePricing),
        MovieCategory::Childrens => Box::new(ChildrensPricing),
    }
}

/// レンタル料金を計算
pub fn calculate_rental_amount(rental: &Rental) -> Money {
    get_price_calculator(rental.movie.category).calculate_amount(rental.days)
}

/// レンタルポイントを計算
pub fn calculate_rental_points(rental: &Rental) -> Points {
    get_price_calculator(rental.movie.category).calculate_points(rental.days)
}

/// 合計料金を計算
pub fn total_amount(rentals: &[Rental]) -> Money {
    rentals.iter().map(calculate_rental_amount).sum()
}

/// 合計ポイントを計算
pub fn total_points(rentals: &[Rental]) -> Points {
    rentals.iter().map(calculate_rental_points).sum()
}

// ============================================================
// 7. 明細データ
// ============================================================

/// レンタル明細行
#[derive(Debug, Clone)]
pub struct RentalLine {
    pub title: String,
    pub days: Days,
    pub amount: Money,
    pub points: Points,
}

/// 明細データ
#[derive(Debug, Clone)]
pub struct StatementData {
    pub customer_name: String,
    pub rental_lines: Vec<RentalLine>,
    pub total_amount: Money,
    pub total_points: Points,
}

/// 明細データを生成
pub fn generate_statement_data(customer: &Customer) -> StatementData {
    let lines = customer
        .rentals
        .iter()
        .map(|rental| RentalLine {
            title: rental.movie.title.clone(),
            days: rental.days,
            amount: calculate_rental_amount(rental),
            points: calculate_rental_points(rental),
        })
        .collect();

    StatementData {
        customer_name: customer.name.clone(),
        rental_lines: lines,
        total_amount: total_amount(&customer.rentals),
        total_points: total_points(&customer.rentals),
    }
}

// ============================================================
// 8. 明細書フォーマッター
// ============================================================

/// フォーマット形式
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StatementFormat {
    Text,
    Html,
    Json,
}

/// 明細書フォーマッター trait
pub trait StatementFormatter {
    fn format(&self, data: &StatementData) -> String;
}

/// テキスト形式フォーマッター
pub struct TextFormatter;

impl StatementFormatter for TextFormatter {
    fn format(&self, data: &StatementData) -> String {
        let mut result = format!("Rental Record for {}\n", data.customer_name);
        for line in &data.rental_lines {
            result.push_str(&format!("\t{}\t{}\n", line.title, line.amount));
        }
        result.push_str(&format!("Amount owed is {}\n", data.total_amount));
        result.push_str(&format!(
            "You earned {} frequent renter points",
            data.total_points
        ));
        result
    }
}

/// HTML形式フォーマッター
pub struct HtmlFormatter;

impl StatementFormatter for HtmlFormatter {
    fn format(&self, data: &StatementData) -> String {
        let mut result = format!(
            "<h1>Rental Record for <em>{}</em></h1>\n<ul>\n",
            data.customer_name
        );
        for line in &data.rental_lines {
            result.push_str(&format!("  <li>{} - {}</li>\n", line.title, line.amount));
        }
        result.push_str("</ul>\n");
        result.push_str(&format!(
            "<p>Amount owed is <strong>{}</strong></p>\n",
            data.total_amount
        ));
        result.push_str(&format!(
            "<p>You earned <strong>{}</strong> frequent renter points</p>",
            data.total_points
        ));
        result
    }
}

/// JSON形式フォーマッター
pub struct JsonFormatter;

impl StatementFormatter for JsonFormatter {
    fn format(&self, data: &StatementData) -> String {
        let rentals_json: Vec<String> = data
            .rental_lines
            .iter()
            .map(|line| {
                format!(
                    r#"{{"title":"{}","days":{},"amount":{},"points":{}}}"#,
                    line.title, line.days, line.amount, line.points
                )
            })
            .collect();
        format!(
            r#"{{"customer":"{}","rentals":[{}],"totalAmount":{},"totalPoints":{}}}"#,
            data.customer_name,
            rentals_json.join(","),
            data.total_amount,
            data.total_points
        )
    }
}

/// フォーマット形式に応じたフォーマッターを取得
pub fn get_formatter(format: StatementFormat) -> Box<dyn StatementFormatter> {
    match format {
        StatementFormat::Text => Box::new(TextFormatter),
        StatementFormat::Html => Box::new(HtmlFormatter),
        StatementFormat::Json => Box::new(JsonFormatter),
    }
}

/// 明細書を生成
pub fn generate_statement(customer: &Customer, format: StatementFormat) -> String {
    let data = generate_statement_data(customer);
    get_formatter(format).format(&data)
}

/// デフォルトはテキスト形式で明細書を生成
pub fn generate_text_statement(customer: &Customer) -> String {
    generate_statement(customer, StatementFormat::Text)
}

// ============================================================
// 9. 拡張可能な料金ポリシー（関数型）
// ============================================================

/// 料金ポリシー（関数型）
#[derive(Clone)]
pub struct PricingPolicy {
    pub name: String,
    calculate_amount_fn: Arc<dyn Fn(Days) -> Money + Send + Sync>,
    calculate_points_fn: Arc<dyn Fn(Days) -> Points + Send + Sync>,
}

impl PricingPolicy {
    pub fn new<F1, F2>(name: &str, amount_fn: F1, points_fn: F2) -> Self
    where
        F1: Fn(Days) -> Money + Send + Sync + 'static,
        F2: Fn(Days) -> Points + Send + Sync + 'static,
    {
        Self {
            name: name.to_string(),
            calculate_amount_fn: Arc::new(amount_fn),
            calculate_points_fn: Arc::new(points_fn),
        }
    }

    pub fn calculate_amount(&self, days: Days) -> Money {
        (self.calculate_amount_fn)(days)
    }

    pub fn calculate_points(&self, days: Days) -> Points {
        (self.calculate_points_fn)(days)
    }
}

/// 定義済み料金ポリシー
pub mod pricing_policies {
    use super::*;

    pub fn regular() -> PricingPolicy {
        PricingPolicy::new(
            "Regular",
            |days| {
                if days > 2 {
                    dec!(2.0) + Decimal::from(days - 2) * dec!(1.5)
                } else {
                    dec!(2.0)
                }
            },
            |_| 1,
        )
    }

    pub fn new_release() -> PricingPolicy {
        PricingPolicy::new(
            "New Release",
            |days| Decimal::from(days) * dec!(3.0),
            |days| if days > 1 { 2 } else { 1 },
        )
    }

    pub fn childrens() -> PricingPolicy {
        PricingPolicy::new(
            "Children's",
            |days| {
                if days > 3 {
                    dec!(1.5) + Decimal::from(days - 3) * dec!(1.5)
                } else {
                    dec!(1.5)
                }
            },
            |_| 1,
        )
    }

    pub fn premium() -> PricingPolicy {
        PricingPolicy::new(
            "Premium",
            |days| Decimal::from(days) * dec!(5.0),
            |days| days, // 日数分のポイント
        )
    }
}

// ============================================================
// 10. ポリシーベースの映画
// ============================================================

/// ポリシーベースの映画
#[derive(Clone)]
pub struct PolicyMovie {
    pub title: String,
    pub policy: PricingPolicy,
}

impl PolicyMovie {
    pub fn new(title: &str, policy: PricingPolicy) -> Self {
        Self {
            title: title.to_string(),
            policy,
        }
    }
}

/// ポリシーベースのレンタル
#[derive(Clone)]
pub struct PolicyRental {
    pub movie: PolicyMovie,
    pub days: Days,
}

impl PolicyRental {
    pub fn new(movie: PolicyMovie, days: Days) -> Self {
        Self { movie, days }
    }

    pub fn amount(&self) -> Money {
        self.movie.policy.calculate_amount(self.days)
    }

    pub fn points(&self) -> Points {
        self.movie.policy.calculate_points(self.days)
    }
}

/// ポリシーベースの顧客
#[derive(Clone)]
pub struct PolicyCustomer {
    pub name: String,
    pub rentals: Vec<PolicyRental>,
}

impl PolicyCustomer {
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            rentals: Vec::new(),
        }
    }

    pub fn add_rental(mut self, rental: PolicyRental) -> Self {
        self.rentals.push(rental);
        self
    }

    pub fn total_amount(&self) -> Money {
        self.rentals.iter().map(|r| r.amount()).sum()
    }

    pub fn total_points(&self) -> Points {
        self.rentals.iter().map(|r| r.points()).sum()
    }
}

// ============================================================
// 11. レンタルショップ
// ============================================================

/// レンタルショップ
pub struct RentalShop {
    movies: HashMap<String, Movie>,
    customers: HashMap<String, Customer>,
}

impl RentalShop {
    pub fn new() -> Self {
        Self {
            movies: HashMap::new(),
            customers: HashMap::new(),
        }
    }

    pub fn add_movie(&mut self, movie: Movie) {
        self.movies.insert(movie.title.clone(), movie);
    }

    pub fn get_movie(&self, title: &str) -> Option<&Movie> {
        self.movies.get(title)
    }

    pub fn register_customer(&mut self, name: &str) -> Customer {
        let customer = Customer::new(name);
        self.customers.insert(name.to_string(), customer.clone());
        customer
    }

    pub fn get_customer(&self, name: &str) -> Option<&Customer> {
        self.customers.get(name)
    }

    pub fn rent_movie(&mut self, customer_name: &str, movie_title: &str, days: Days) -> Option<Rental> {
        let movie = self.movies.get(movie_title)?.clone();
        let customer = self.customers.get(customer_name)?.clone();
        let rental = Rental::new(movie, days);
        let updated_customer = customer.add_rental(rental.clone());
        self.customers.insert(customer_name.to_string(), updated_customer);
        Some(rental)
    }

    pub fn generate_customer_statement(&self, customer_name: &str, format: StatementFormat) -> Option<String> {
        self.customers
            .get(customer_name)
            .map(|c| generate_statement(c, format))
    }

    pub fn clear(&mut self) {
        self.movies.clear();
        self.customers.clear();
    }
}

impl Default for RentalShop {
    fn default() -> Self {
        Self::new()
    }
}

// ============================================================
// 12. レンタル履歴
// ============================================================

/// レンタルイベント
#[derive(Debug, Clone)]
pub enum RentalEvent {
    MovieRented {
        timestamp: i64,
        customer_name: String,
        movie_title: String,
        days: Days,
        amount: Money,
    },
    MovieReturned {
        timestamp: i64,
        customer_name: String,
        movie_title: String,
    },
    PointsRedeemed {
        timestamp: i64,
        customer_name: String,
        points: Points,
    },
}

impl RentalEvent {
    pub fn customer_name(&self) -> &str {
        match self {
            RentalEvent::MovieRented { customer_name, .. } => customer_name,
            RentalEvent::MovieReturned { customer_name, .. } => customer_name,
            RentalEvent::PointsRedeemed { customer_name, .. } => customer_name,
        }
    }
}

/// レンタル履歴
pub struct RentalHistory {
    events: Vec<RentalEvent>,
}

impl RentalHistory {
    pub fn new() -> Self {
        Self { events: Vec::new() }
    }

    pub fn record(&mut self, event: RentalEvent) {
        self.events.push(event);
    }

    pub fn get_events(&self) -> Vec<RentalEvent> {
        self.events.clone()
    }

    pub fn get_events_by_customer(&self, customer_name: &str) -> Vec<RentalEvent> {
        self.events
            .iter()
            .filter(|e| e.customer_name() == customer_name)
            .cloned()
            .collect()
    }

    pub fn clear(&mut self) {
        self.events.clear();
    }
}

impl Default for RentalHistory {
    fn default() -> Self {
        Self::new()
    }
}

// ============================================================
// 13. 割引計算
// ============================================================

/// 割引タイプ
pub trait Discount {
    fn apply(&self, amount: Money) -> Money;
}

/// パーセント割引
pub struct PercentageDiscount {
    percent: Decimal,
}

impl PercentageDiscount {
    pub fn new(percent: f64) -> Self {
        Self {
            percent: Decimal::try_from(percent).unwrap(),
        }
    }
}

impl Discount for PercentageDiscount {
    fn apply(&self, amount: Money) -> Money {
        amount * (Decimal::ONE - self.percent)
    }
}

/// 固定割引
pub struct FixedDiscount {
    value: Money,
}

impl FixedDiscount {
    pub fn new(value: Money) -> Self {
        Self { value }
    }
}

impl Discount for FixedDiscount {
    fn apply(&self, amount: Money) -> Money {
        (amount - self.value).max(Decimal::ZERO)
    }
}

/// ポイント割引
pub struct PointsDiscount {
    points_per_unit: Points,
    discount_per_unit: Money,
    available_points: Arc<Mutex<Points>>,
}

impl PointsDiscount {
    pub fn new(points_per_unit: Points, discount_per_unit: Money) -> Self {
        Self {
            points_per_unit,
            discount_per_unit,
            available_points: Arc::new(Mutex::new(0)),
        }
    }

    pub fn set_available_points(&self, points: Points) {
        *self.available_points.lock().unwrap() = points;
    }
}

impl Discount for PointsDiscount {
    fn apply(&self, amount: Money) -> Money {
        let points = *self.available_points.lock().unwrap();
        let max_discount = Decimal::from(points / self.points_per_unit) * self.discount_per_unit;
        (amount - max_discount).max(Decimal::ZERO)
    }
}

/// 割引を適用
pub fn apply_discounts(amount: Money, discounts: &[Box<dyn Discount>]) -> Money {
    discounts.iter().fold(amount, |acc, d| d.apply(acc))
}

// ============================================================
// 14. レポート生成
// ============================================================

/// 売上レポート
#[derive(Debug, Clone)]
pub struct SalesReport {
    pub period: String,
    pub total_rentals: usize,
    pub total_revenue: Money,
    pub rentals_by_category: HashMap<MovieCategory, usize>,
    pub revenue_by_category: HashMap<MovieCategory, Money>,
}

/// 売上レポートを生成
pub fn generate_sales_report(rentals: &[Rental], period: &str) -> SalesReport {
    let mut rentals_by_category: HashMap<MovieCategory, usize> = HashMap::new();
    let mut revenue_by_category: HashMap<MovieCategory, Money> = HashMap::new();

    for rental in rentals {
        *rentals_by_category.entry(rental.movie.category).or_insert(0) += 1;
        *revenue_by_category.entry(rental.movie.category).or_insert(Decimal::ZERO) +=
            calculate_rental_amount(rental);
    }

    SalesReport {
        period: period.to_string(),
        total_rentals: rentals.len(),
        total_revenue: total_amount(rentals),
        rentals_by_category,
        revenue_by_category,
    }
}

// ============================================================
// 15. DSL
// ============================================================

/// レンタル DSL
pub mod rental_dsl {
    use super::*;

    pub fn customer(name: &str) -> CustomerBuilder {
        CustomerBuilder::new(name)
    }

    pub struct CustomerBuilder {
        name: String,
        rentals: Vec<Rental>,
    }

    impl CustomerBuilder {
        pub fn new(name: &str) -> Self {
            Self {
                name: name.to_string(),
                rentals: Vec::new(),
            }
        }

        pub fn rents(mut self, movie: Movie, days: Days) -> Self {
            self.rentals.push(Rental::new(movie, days));
            self
        }

        pub fn build(self) -> Customer {
            Customer {
                name: self.name,
                rentals: self.rentals,
            }
        }

        pub fn statement(self) -> String {
            generate_text_statement(&self.build())
        }

        pub fn statement_as(self, format: StatementFormat) -> String {
            generate_statement(&self.build(), format)
        }
    }

    // 便利なメソッド
    pub fn regular(title: &str) -> Movie {
        Movie::regular(title)
    }

    pub fn new_release(title: &str) -> Movie {
        Movie::new_release(title)
    }

    pub fn childrens(title: &str) -> Movie {
        Movie::childrens(title)
    }
}

// ============================================================
// テスト
// ============================================================

#[cfg(test)]
mod tests {
    use super::*;

    mod movie_tests {
        use super::*;

        #[test]
        fn creates_regular_movie() {
            let movie = Movie::regular("Inception");
            assert_eq!(movie.title, "Inception");
            assert_eq!(movie.category, MovieCategory::Regular);
        }

        #[test]
        fn creates_new_release_movie() {
            let movie = Movie::new_release("New Movie");
            assert_eq!(movie.category, MovieCategory::NewRelease);
        }

        #[test]
        fn creates_childrens_movie() {
            let movie = Movie::childrens("Frozen");
            assert_eq!(movie.category, MovieCategory::Childrens);
        }
    }

    mod pricing_tests {
        use super::*;

        mod regular {
            use super::*;

            #[test]
            fn two_days_or_less_costs_2() {
                let rental = Rental::new(Movie::regular("Test"), 1);
                assert_eq!(calculate_rental_amount(&rental), dec!(2.0));
            }

            #[test]
            fn two_days_costs_2() {
                let rental = Rental::new(Movie::regular("Test"), 2);
                assert_eq!(calculate_rental_amount(&rental), dec!(2.0));
            }

            #[test]
            fn three_days_costs_3_5() {
                let rental = Rental::new(Movie::regular("Test"), 3);
                assert_eq!(calculate_rental_amount(&rental), dec!(3.5));
            }

            #[test]
            fn five_days_costs_6_5() {
                let rental = Rental::new(Movie::regular("Test"), 5);
                assert_eq!(calculate_rental_amount(&rental), dec!(6.5));
            }
        }

        mod new_release {
            use super::*;

            #[test]
            fn one_day_costs_3() {
                let rental = Rental::new(Movie::new_release("Test"), 1);
                assert_eq!(calculate_rental_amount(&rental), dec!(3.0));
            }

            #[test]
            fn three_days_costs_9() {
                let rental = Rental::new(Movie::new_release("Test"), 3);
                assert_eq!(calculate_rental_amount(&rental), dec!(9.0));
            }
        }

        mod childrens {
            use super::*;

            #[test]
            fn three_days_or_less_costs_1_5() {
                let rental = Rental::new(Movie::childrens("Test"), 2);
                assert_eq!(calculate_rental_amount(&rental), dec!(1.5));
            }

            #[test]
            fn three_days_costs_1_5() {
                let rental = Rental::new(Movie::childrens("Test"), 3);
                assert_eq!(calculate_rental_amount(&rental), dec!(1.5));
            }

            #[test]
            fn four_days_costs_3() {
                let rental = Rental::new(Movie::childrens("Test"), 4);
                assert_eq!(calculate_rental_amount(&rental), dec!(3.0));
            }

            #[test]
            fn six_days_costs_6() {
                let rental = Rental::new(Movie::childrens("Test"), 6);
                assert_eq!(calculate_rental_amount(&rental), dec!(6.0));
            }
        }
    }

    mod points_tests {
        use super::*;

        #[test]
        fn regular_gives_1_point() {
            let rental = Rental::new(Movie::regular("Test"), 5);
            assert_eq!(calculate_rental_points(&rental), 1);
        }

        #[test]
        fn childrens_gives_1_point() {
            let rental = Rental::new(Movie::childrens("Test"), 5);
            assert_eq!(calculate_rental_points(&rental), 1);
        }

        #[test]
        fn new_release_1_day_gives_1_point() {
            let rental = Rental::new(Movie::new_release("Test"), 1);
            assert_eq!(calculate_rental_points(&rental), 1);
        }

        #[test]
        fn new_release_2_days_gives_2_points() {
            let rental = Rental::new(Movie::new_release("Test"), 2);
            assert_eq!(calculate_rental_points(&rental), 2);
        }
    }

    mod total_tests {
        use super::*;

        #[test]
        fn calculates_total_amount() {
            let rentals = vec![
                Rental::new(Movie::regular("Inception"), 3),     // 3.5
                Rental::new(Movie::childrens("Frozen"), 4),      // 3.0
                Rental::new(Movie::new_release("New Movie"), 2), // 6.0
            ];
            assert_eq!(total_amount(&rentals), dec!(12.5));
        }

        #[test]
        fn calculates_total_points() {
            let rentals = vec![
                Rental::new(Movie::regular("Inception"), 3),     // 1
                Rental::new(Movie::childrens("Frozen"), 4),      // 1
                Rental::new(Movie::new_release("New Movie"), 2), // 2
            ];
            assert_eq!(total_points(&rentals), 4);
        }
    }

    mod customer_tests {
        use super::*;

        #[test]
        fn adds_rental() {
            let customer = Customer::new("John").add_rental(Rental::new(Movie::regular("Test"), 3));
            assert_eq!(customer.rentals.len(), 1);
        }

        #[test]
        fn adds_multiple_rentals() {
            let customer = Customer::new("John").add_rentals(&[
                Rental::new(Movie::regular("Test1"), 3),
                Rental::new(Movie::new_release("Test2"), 2),
            ]);
            assert_eq!(customer.rentals.len(), 2);
        }
    }

    mod statement_data_tests {
        use super::*;

        #[test]
        fn generates_statement_data() {
            let customer = Customer::new("John").add_rentals(&[
                Rental::new(Movie::regular("Inception"), 3),
                Rental::new(Movie::new_release("New Movie"), 2),
            ]);
            let data = generate_statement_data(&customer);

            assert_eq!(data.customer_name, "John");
            assert_eq!(data.rental_lines.len(), 2);
            assert_eq!(data.total_amount, dec!(9.5)); // 3.5 + 6.0
            assert_eq!(data.total_points, 3);         // 1 + 2
        }
    }

    mod formatter_tests {
        use super::*;

        fn test_customer() -> Customer {
            Customer::new("John").add_rentals(&[
                Rental::new(Movie::regular("Inception"), 3),
                Rental::new(Movie::new_release("New Movie"), 2),
            ])
        }

        #[test]
        fn text_format() {
            let statement = generate_statement(&test_customer(), StatementFormat::Text);

            assert!(statement.contains("Rental Record for John"));
            assert!(statement.contains("Inception"));
            assert!(statement.contains("3.5"));
            assert!(statement.contains("New Movie"));
            assert!(statement.contains("Amount owed is 9.5"));
            assert!(statement.contains("3 frequent renter points"));
        }

        #[test]
        fn html_format() {
            let statement = generate_statement(&test_customer(), StatementFormat::Html);

            assert!(statement.contains("<h1>Rental Record for <em>John</em></h1>"));
            assert!(statement.contains("<li>Inception - 3.5</li>"));
            assert!(statement.contains("New Movie"));
            assert!(statement.contains("<strong>9.5</strong>"));
            assert!(statement.contains("<strong>3</strong>"));
        }

        #[test]
        fn json_format() {
            let statement = generate_statement(&test_customer(), StatementFormat::Json);

            assert!(statement.contains(r#""customer":"John""#));
            assert!(statement.contains(r#""title":"Inception""#));
            assert!(statement.contains(r#""totalAmount":9.5"#));
            assert!(statement.contains(r#""totalPoints":3"#));
        }
    }

    mod pricing_policy_tests {
        use super::*;

        #[test]
        fn regular_policy_calculates_amount() {
            assert_eq!(pricing_policies::regular().calculate_amount(3), dec!(3.5));
        }

        #[test]
        fn new_release_policy_calculates_amount() {
            assert_eq!(pricing_policies::new_release().calculate_amount(3), dec!(9.0));
        }

        #[test]
        fn childrens_policy_calculates_amount() {
            assert_eq!(pricing_policies::childrens().calculate_amount(4), dec!(3.0));
        }

        #[test]
        fn premium_policy_calculates_amount() {
            assert_eq!(pricing_policies::premium().calculate_amount(3), dec!(15.0));
            assert_eq!(pricing_policies::premium().calculate_points(3), 3);
        }
    }

    mod policy_customer_tests {
        use super::*;

        #[test]
        fn calculates_total_with_policies() {
            let customer = PolicyCustomer::new("Alice")
                .add_rental(PolicyRental::new(
                    PolicyMovie::new("Movie1", pricing_policies::regular()),
                    3,
                ))
                .add_rental(PolicyRental::new(
                    PolicyMovie::new("Movie2", pricing_policies::premium()),
                    2,
                ));

            assert_eq!(customer.total_amount(), dec!(13.5)); // 3.5 + 10.0
            assert_eq!(customer.total_points(), 3);          // 1 + 2
        }
    }

    mod rental_shop_tests {
        use super::*;

        #[test]
        fn adds_and_gets_movie() {
            let mut shop = RentalShop::new();
            shop.add_movie(Movie::regular("Inception"));

            assert_eq!(shop.get_movie("Inception"), Some(&Movie::regular("Inception")));
        }

        #[test]
        fn registers_customer() {
            let mut shop = RentalShop::new();
            shop.register_customer("John");

            assert!(shop.get_customer("John").is_some());
        }

        #[test]
        fn rents_movie() {
            let mut shop = RentalShop::new();
            shop.add_movie(Movie::regular("Inception"));
            shop.register_customer("John");

            let rental = shop.rent_movie("John", "Inception", 3);

            assert!(rental.is_some());
            assert_eq!(shop.get_customer("John").unwrap().rentals.len(), 1);
        }

        #[test]
        fn generates_customer_statement() {
            let mut shop = RentalShop::new();
            shop.add_movie(Movie::regular("Inception"));
            shop.register_customer("John");
            shop.rent_movie("John", "Inception", 3);

            let statement = shop.generate_customer_statement("John", StatementFormat::Text);

            assert!(statement.is_some());
            assert!(statement.as_ref().unwrap().contains("John"));
            assert!(statement.as_ref().unwrap().contains("Inception"));
        }
    }

    mod rental_history_tests {
        use super::*;

        #[test]
        fn records_events() {
            let mut history = RentalHistory::new();
            history.record(RentalEvent::MovieRented {
                timestamp: 1000,
                customer_name: "John".to_string(),
                movie_title: "Inception".to_string(),
                days: 3,
                amount: dec!(3.5),
            });
            history.record(RentalEvent::MovieReturned {
                timestamp: 2000,
                customer_name: "John".to_string(),
                movie_title: "Inception".to_string(),
            });

            assert_eq!(history.get_events().len(), 2);
        }

        #[test]
        fn gets_events_by_customer() {
            let mut history = RentalHistory::new();
            history.record(RentalEvent::MovieRented {
                timestamp: 1000,
                customer_name: "John".to_string(),
                movie_title: "Inception".to_string(),
                days: 3,
                amount: dec!(3.5),
            });
            history.record(RentalEvent::MovieRented {
                timestamp: 1500,
                customer_name: "Alice".to_string(),
                movie_title: "Frozen".to_string(),
                days: 2,
                amount: dec!(1.5),
            });
            history.record(RentalEvent::MovieReturned {
                timestamp: 2000,
                customer_name: "John".to_string(),
                movie_title: "Inception".to_string(),
            });

            assert_eq!(history.get_events_by_customer("John").len(), 2);
        }
    }

    mod discount_tests {
        use super::*;

        #[test]
        fn percentage_discount_applies() {
            let discount = PercentageDiscount::new(0.1);
            assert_eq!(discount.apply(dec!(100)), dec!(90));
        }

        #[test]
        fn fixed_discount_applies() {
            let discount = FixedDiscount::new(dec!(20));
            assert_eq!(discount.apply(dec!(100)), dec!(80));
        }

        #[test]
        fn fixed_discount_does_not_go_negative() {
            let discount = FixedDiscount::new(dec!(200));
            assert_eq!(discount.apply(dec!(100)), dec!(0));
        }

        #[test]
        fn apply_multiple_discounts() {
            let discounts: Vec<Box<dyn Discount>> = vec![
                Box::new(PercentageDiscount::new(0.1)), // 100 -> 90
                Box::new(FixedDiscount::new(dec!(10))), // 90 -> 80
            ];
            assert_eq!(apply_discounts(dec!(100), &discounts), dec!(80));
        }
    }

    mod sales_report_tests {
        use super::*;

        #[test]
        fn generates_sales_report() {
            let rentals = vec![
                Rental::new(Movie::regular("Inception"), 3),
                Rental::new(Movie::regular("Matrix"), 2),
                Rental::new(Movie::new_release("New Movie"), 2),
                Rental::new(Movie::childrens("Frozen"), 4),
            ];

            let report = generate_sales_report(&rentals, "2024-01");

            assert_eq!(report.period, "2024-01");
            assert_eq!(report.total_rentals, 4);
            assert_eq!(report.total_revenue, dec!(14.5)); // 3.5 + 2.0 + 6.0 + 3.0
            assert_eq!(report.rentals_by_category[&MovieCategory::Regular], 2);
            assert_eq!(report.rentals_by_category[&MovieCategory::NewRelease], 1);
            assert_eq!(report.rentals_by_category[&MovieCategory::Childrens], 1);
        }
    }

    mod dsl_tests {
        use super::*;
        use rental_dsl::*;

        #[test]
        fn creates_customer_with_dsl() {
            let c = customer("John")
                .rents(regular("Inception"), 3)
                .rents(new_release("New Movie"), 2)
                .build();

            assert_eq!(c.name, "John");
            assert_eq!(c.rentals.len(), 2);
        }

        #[test]
        fn generates_statement_with_dsl() {
            let statement = customer("John")
                .rents(regular("Inception"), 3)
                .statement();

            assert!(statement.contains("John"));
            assert!(statement.contains("Inception"));
        }

        #[test]
        fn generates_html_statement_with_dsl() {
            let statement = customer("John")
                .rents(regular("Inception"), 3)
                .statement_as(StatementFormat::Html);

            assert!(statement.contains("<h1>"));
        }
    }
}
