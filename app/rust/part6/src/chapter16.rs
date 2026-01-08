//! 第16章: 給与計算システム
//!
//! 関数型プログラミングにおけるドメインモデリングと
//! 多態性の実現を学びます。

use std::collections::HashMap;
use rust_decimal::Decimal;
use rust_decimal_macros::dec;

// ============================================================
// 1. 基本型定義
// ============================================================

pub type EmployeeId = String;
pub type Money = Decimal;
pub type Hours = f64;
pub type Rate = f64;

// ============================================================
// 2. 給与分類（PayClass）
// ============================================================

/// 給与分類
#[derive(Debug, Clone, PartialEq)]
pub enum PayClass {
    /// 月給制
    Salaried { salary: Money },
    /// 時給制
    Hourly { hourly_rate: Money },
    /// 歩合制
    Commissioned { base_pay: Money, commission_rate: Rate },
}

impl PayClass {
    pub fn pay_type(&self) -> &'static str {
        match self {
            PayClass::Salaried { .. } => "salaried",
            PayClass::Hourly { .. } => "hourly",
            PayClass::Commissioned { .. } => "commissioned",
        }
    }
}

// ============================================================
// 3. 支払いスケジュール
// ============================================================

/// 支払いスケジュール
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Schedule {
    Monthly,   // 月次（月末）
    Weekly,    // 週次（毎週金曜日）
    Biweekly,  // 隔週（隔週金曜日）
}

// ============================================================
// 4. 支払い方法
// ============================================================

/// 支払い方法
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PaymentMethod {
    Hold,                              // 保留
    DirectDeposit { account: String }, // 口座振込
    Mail { address: String },          // 小切手郵送
}

// ============================================================
// 5. 従業員（Employee）
// ============================================================

/// 従業員
#[derive(Debug, Clone, PartialEq)]
pub struct Employee {
    pub id: EmployeeId,
    pub name: String,
    pub pay_class: PayClass,
    pub schedule: Schedule,
    pub payment_method: PaymentMethod,
    pub address: Option<String>,
}

impl Employee {
    /// 月給制従業員を作成
    pub fn salaried(id: &str, name: &str, salary: Money) -> Self {
        Self {
            id: id.to_string(),
            name: name.to_string(),
            pay_class: PayClass::Salaried { salary },
            schedule: Schedule::Monthly,
            payment_method: PaymentMethod::Hold,
            address: None,
        }
    }

    /// 時給制従業員を作成
    pub fn hourly(id: &str, name: &str, hourly_rate: Money) -> Self {
        Self {
            id: id.to_string(),
            name: name.to_string(),
            pay_class: PayClass::Hourly { hourly_rate },
            schedule: Schedule::Weekly,
            payment_method: PaymentMethod::Hold,
            address: None,
        }
    }

    /// 歩合制従業員を作成
    pub fn commissioned(id: &str, name: &str, base_pay: Money, commission_rate: Rate) -> Self {
        Self {
            id: id.to_string(),
            name: name.to_string(),
            pay_class: PayClass::Commissioned { base_pay, commission_rate },
            schedule: Schedule::Biweekly,
            payment_method: PaymentMethod::Hold,
            address: None,
        }
    }
}

// ============================================================
// 6. コンテキスト（タイムカード、売上）
// ============================================================

/// タイムカード
#[derive(Debug, Clone, PartialEq)]
pub struct TimeCard {
    pub employee_id: EmployeeId,
    pub date: String,
    pub hours: Hours,
}

impl TimeCard {
    pub fn new(employee_id: &str, date: &str, hours: Hours) -> Self {
        Self {
            employee_id: employee_id.to_string(),
            date: date.to_string(),
            hours,
        }
    }
}

/// 売上伝票
#[derive(Debug, Clone, PartialEq)]
pub struct SalesReceipt {
    pub employee_id: EmployeeId,
    pub date: String,
    pub amount: Money,
}

impl SalesReceipt {
    pub fn new(employee_id: &str, date: &str, amount: Money) -> Self {
        Self {
            employee_id: employee_id.to_string(),
            date: date.to_string(),
            amount,
        }
    }
}

/// 給与計算コンテキスト
#[derive(Debug, Clone, Default)]
pub struct PayrollContext {
    pub time_cards: HashMap<EmployeeId, Vec<TimeCard>>,
    pub sales_receipts: HashMap<EmployeeId, Vec<SalesReceipt>>,
}

impl PayrollContext {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn add_time_card(mut self, tc: TimeCard) -> Self {
        self.time_cards
            .entry(tc.employee_id.clone())
            .or_default()
            .push(tc);
        self
    }

    pub fn add_sales_receipt(mut self, sr: SalesReceipt) -> Self {
        self.sales_receipts
            .entry(sr.employee_id.clone())
            .or_default()
            .push(sr);
        self
    }

    pub fn get_time_cards(&self, employee_id: &str) -> &[TimeCard] {
        self.time_cards
            .get(employee_id)
            .map(|v| v.as_slice())
            .unwrap_or(&[])
    }

    pub fn get_sales_receipts(&self, employee_id: &str) -> &[SalesReceipt] {
        self.sales_receipts
            .get(employee_id)
            .map(|v| v.as_slice())
            .unwrap_or(&[])
    }
}

// ============================================================
// 7. 給与計算
// ============================================================

/// 従業員の給与を計算
pub fn calculate_pay(employee: &Employee, context: &PayrollContext) -> Money {
    match &employee.pay_class {
        PayClass::Salaried { salary } => *salary,
        PayClass::Hourly { hourly_rate } => {
            let time_cards = context.get_time_cards(&employee.id);
            let total_hours: Hours = time_cards.iter().map(|tc| tc.hours).sum();
            let regular_hours = total_hours.min(40.0);
            let overtime_hours = (total_hours - 40.0).max(0.0);
            
            *hourly_rate * Decimal::try_from(regular_hours).unwrap()
                + *hourly_rate * Decimal::try_from(overtime_hours).unwrap() * dec!(1.5)
        }
        PayClass::Commissioned { base_pay, commission_rate } => {
            let sales_receipts = context.get_sales_receipts(&employee.id);
            let total_sales: Money = sales_receipts.iter().map(|sr| sr.amount).sum();
            *base_pay + total_sales * Decimal::try_from(*commission_rate).unwrap()
        }
    }
}

// ============================================================
// 8. 支払いスケジュール判定
// ============================================================

/// 曜日
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DayOfWeek {
    Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday,
}

/// 日付情報
#[derive(Debug, Clone)]
pub struct PayDate {
    pub year: i32,
    pub month: u32,
    pub day: u32,
    pub day_of_week: DayOfWeek,
    pub is_last_day_of_month: bool,
    pub is_pay_week: bool,
}

impl PayDate {
    pub fn new(year: i32, month: u32, day: u32, day_of_week: DayOfWeek, is_last_day: bool) -> Self {
        Self {
            year,
            month,
            day,
            day_of_week,
            is_last_day_of_month: is_last_day,
            is_pay_week: true,
        }
    }

    pub fn with_pay_week(mut self, is_pay_week: bool) -> Self {
        self.is_pay_week = is_pay_week;
        self
    }
}

/// 支払日判定
pub fn is_pay_day(employee: &Employee, date: &PayDate) -> bool {
    match employee.schedule {
        Schedule::Monthly => date.is_last_day_of_month,
        Schedule::Weekly => date.day_of_week == DayOfWeek::Friday,
        Schedule::Biweekly => date.day_of_week == DayOfWeek::Friday && date.is_pay_week,
    }
}

// ============================================================
// 9. 支払い処理
// ============================================================

/// 支払い結果
#[derive(Debug, Clone, PartialEq)]
pub enum PaymentResult {
    Held { employee_id: EmployeeId, amount: Money },
    DirectDeposit { employee_id: EmployeeId, amount: Money, account: String },
    Mailed { employee_id: EmployeeId, amount: Money, address: String },
}

impl PaymentResult {
    pub fn employee_id(&self) -> &str {
        match self {
            PaymentResult::Held { employee_id, .. } => employee_id,
            PaymentResult::DirectDeposit { employee_id, .. } => employee_id,
            PaymentResult::Mailed { employee_id, .. } => employee_id,
        }
    }

    pub fn amount(&self) -> Money {
        match self {
            PaymentResult::Held { amount, .. } => *amount,
            PaymentResult::DirectDeposit { amount, .. } => *amount,
            PaymentResult::Mailed { amount, .. } => *amount,
        }
    }
}

/// 支払いを処理
pub fn process_payment(employee: &Employee, amount: Money) -> PaymentResult {
    match &employee.payment_method {
        PaymentMethod::Hold => PaymentResult::Held {
            employee_id: employee.id.clone(),
            amount,
        },
        PaymentMethod::DirectDeposit { account } => PaymentResult::DirectDeposit {
            employee_id: employee.id.clone(),
            amount,
            account: account.clone(),
        },
        PaymentMethod::Mail { address } => PaymentResult::Mailed {
            employee_id: employee.id.clone(),
            amount,
            address: address.clone(),
        },
    }
}

// ============================================================
// 10. 給与支払い実行
// ============================================================

/// 給与支払いを実行
pub fn run_payroll(employees: &[Employee], context: &PayrollContext, date: &PayDate) -> Vec<PaymentResult> {
    employees
        .iter()
        .filter(|emp| is_pay_day(emp, date))
        .map(|emp| {
            let pay = calculate_pay(emp, context);
            process_payment(emp, pay)
        })
        .collect()
}

// ============================================================
// 11. 従業員変更操作
// ============================================================

pub mod employee_operations {
    use super::*;

    pub fn change_payment_method(employee: &Employee, method: PaymentMethod) -> Employee {
        Employee {
            payment_method: method,
            ..employee.clone()
        }
    }

    pub fn change_address(employee: &Employee, address: &str) -> Employee {
        Employee {
            address: Some(address.to_string()),
            ..employee.clone()
        }
    }

    pub fn change_name(employee: &Employee, name: &str) -> Employee {
        Employee {
            name: name.to_string(),
            ..employee.clone()
        }
    }

    pub fn change_to_salaried(employee: &Employee, salary: Money) -> Employee {
        Employee {
            pay_class: PayClass::Salaried { salary },
            schedule: Schedule::Monthly,
            ..employee.clone()
        }
    }

    pub fn change_to_hourly(employee: &Employee, hourly_rate: Money) -> Employee {
        Employee {
            pay_class: PayClass::Hourly { hourly_rate },
            schedule: Schedule::Weekly,
            ..employee.clone()
        }
    }

    pub fn change_to_commissioned(employee: &Employee, base_pay: Money, commission_rate: Rate) -> Employee {
        Employee {
            pay_class: PayClass::Commissioned { base_pay, commission_rate },
            schedule: Schedule::Biweekly,
            ..employee.clone()
        }
    }
}

// ============================================================
// 12. 従業員リポジトリ
// ============================================================

/// 従業員リポジトリ
pub trait EmployeeRepository {
    fn find_by_id(&self, id: &str) -> Option<Employee>;
    fn find_all(&self) -> Vec<Employee>;
    fn save(&mut self, employee: Employee) -> Employee;
    fn delete(&mut self, id: &str) -> Option<Employee>;
}

/// インメモリ従業員リポジトリ
#[derive(Default)]
pub struct InMemoryEmployeeRepository {
    employees: HashMap<EmployeeId, Employee>,
}

impl InMemoryEmployeeRepository {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn clear(&mut self) {
        self.employees.clear();
    }
}

impl EmployeeRepository for InMemoryEmployeeRepository {
    fn find_by_id(&self, id: &str) -> Option<Employee> {
        self.employees.get(id).cloned()
    }

    fn find_all(&self) -> Vec<Employee> {
        self.employees.values().cloned().collect()
    }

    fn save(&mut self, employee: Employee) -> Employee {
        self.employees.insert(employee.id.clone(), employee.clone());
        employee
    }

    fn delete(&mut self, id: &str) -> Option<Employee> {
        self.employees.remove(id)
    }
}

// ============================================================
// 13. 給与明細
// ============================================================

/// 給与明細
#[derive(Debug, Clone)]
pub struct Payslip {
    pub employee_id: EmployeeId,
    pub employee_name: String,
    pub pay_period: String,
    pub gross_pay: Money,
    pub deductions: HashMap<String, Money>,
    pub net_pay: Money,
}

impl Payslip {
    pub fn create(employee: &Employee, pay_period: &str, gross_pay: Money) -> Self {
        Self {
            employee_id: employee.id.clone(),
            employee_name: employee.name.clone(),
            pay_period: pay_period.to_string(),
            gross_pay,
            deductions: HashMap::new(),
            net_pay: gross_pay,
        }
    }

    pub fn add_deduction(mut self, name: &str, amount: Money) -> Self {
        self.deductions.insert(name.to_string(), amount);
        self.net_pay = self.gross_pay - self.deductions.values().sum::<Money>();
        self
    }
}

// ============================================================
// 14. 控除計算
// ============================================================

/// 控除タイプ
#[derive(Debug, Clone)]
pub enum Deduction {
    Fixed { name: String, amount: Money },
    Percentage { name: String, rate: Rate },
    Tiered { name: String, tiers: Vec<(Money, Rate)> },
}

impl Deduction {
    pub fn name(&self) -> &str {
        match self {
            Deduction::Fixed { name, .. } => name,
            Deduction::Percentage { name, .. } => name,
            Deduction::Tiered { name, .. } => name,
        }
    }

    pub fn calculate(&self, gross_pay: Money) -> Money {
        match self {
            Deduction::Fixed { amount, .. } => *amount,
            Deduction::Percentage { rate, .. } => gross_pay * Decimal::try_from(*rate).unwrap(),
            Deduction::Tiered { tiers, .. } => {
                let mut remaining = gross_pay;
                let mut total = dec!(0);
                let mut prev_threshold = dec!(0);
                
                let mut sorted_tiers = tiers.clone();
                sorted_tiers.sort_by(|a, b| a.0.cmp(&b.0));
                
                for (threshold, rate) in sorted_tiers {
                    let taxable = (remaining.min(threshold - prev_threshold)).max(dec!(0));
                    total += taxable * Decimal::try_from(rate).unwrap();
                    remaining -= taxable;
                    prev_threshold = threshold;
                }
                total
            }
        }
    }
}

/// 控除を適用
pub fn apply_deductions(payslip: Payslip, deductions: &[Deduction]) -> Payslip {
    deductions.iter().fold(payslip, |ps, ded| {
        let gross = ps.gross_pay;
        ps.add_deduction(ded.name(), ded.calculate(gross))
    })
}

// ============================================================
// 15. 給与計算サービス
// ============================================================

/// 給与計算サービス
pub struct PayrollService<R: EmployeeRepository> {
    repository: R,
    deductions: Vec<Deduction>,
}

impl<R: EmployeeRepository> PayrollService<R> {
    pub fn new(repository: R, deductions: Vec<Deduction>) -> Self {
        Self { repository, deductions }
    }

    pub fn add_employee(&mut self, employee: Employee) -> Employee {
        self.repository.save(employee)
    }

    pub fn remove_employee(&mut self, id: &str) -> Option<Employee> {
        self.repository.delete(id)
    }

    pub fn get_employee(&self, id: &str) -> Option<Employee> {
        self.repository.find_by_id(id)
    }

    pub fn update_employee<F>(&mut self, id: &str, f: F) -> Option<Employee>
    where
        F: FnOnce(Employee) -> Employee,
    {
        self.repository.find_by_id(id).map(|emp| {
            self.repository.save(f(emp))
        })
    }

    pub fn run_payroll(&self, context: &PayrollContext, date: &PayDate, pay_period: &str) -> Vec<Payslip> {
        self.repository
            .find_all()
            .iter()
            .filter(|emp| is_pay_day(emp, date))
            .map(|emp| {
                let gross_pay = calculate_pay(emp, context);
                let payslip = Payslip::create(emp, pay_period, gross_pay);
                apply_deductions(payslip, &self.deductions)
            })
            .collect()
    }
}

// ============================================================
// 16. イベントソーシング風の操作履歴
// ============================================================

/// 給与計算イベント
#[derive(Debug, Clone)]
pub enum PayrollEvent {
    EmployeeAdded { timestamp: u64, employee_id: EmployeeId, employee: Employee },
    EmployeeRemoved { timestamp: u64, employee_id: EmployeeId },
    EmployeeUpdated { timestamp: u64, employee_id: EmployeeId, employee: Employee },
    TimeCardAdded { timestamp: u64, employee_id: EmployeeId, time_card: TimeCard },
    SalesReceiptAdded { timestamp: u64, employee_id: EmployeeId, sales_receipt: SalesReceipt },
    PayrollRun { timestamp: u64, employee_id: EmployeeId, amount: Money },
}

impl PayrollEvent {
    pub fn timestamp(&self) -> u64 {
        match self {
            PayrollEvent::EmployeeAdded { timestamp, .. } => *timestamp,
            PayrollEvent::EmployeeRemoved { timestamp, .. } => *timestamp,
            PayrollEvent::EmployeeUpdated { timestamp, .. } => *timestamp,
            PayrollEvent::TimeCardAdded { timestamp, .. } => *timestamp,
            PayrollEvent::SalesReceiptAdded { timestamp, .. } => *timestamp,
            PayrollEvent::PayrollRun { timestamp, .. } => *timestamp,
        }
    }

    pub fn employee_id(&self) -> &str {
        match self {
            PayrollEvent::EmployeeAdded { employee_id, .. } => employee_id,
            PayrollEvent::EmployeeRemoved { employee_id, .. } => employee_id,
            PayrollEvent::EmployeeUpdated { employee_id, .. } => employee_id,
            PayrollEvent::TimeCardAdded { employee_id, .. } => employee_id,
            PayrollEvent::SalesReceiptAdded { employee_id, .. } => employee_id,
            PayrollEvent::PayrollRun { employee_id, .. } => employee_id,
        }
    }
}

/// イベントストア
#[derive(Default)]
pub struct EventStore {
    events: Vec<PayrollEvent>,
}

impl EventStore {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn append(&mut self, event: PayrollEvent) {
        self.events.push(event);
    }

    pub fn get_events(&self) -> &[PayrollEvent] {
        &self.events
    }

    pub fn get_events_by_employee(&self, employee_id: &str) -> Vec<&PayrollEvent> {
        self.events
            .iter()
            .filter(|e| e.employee_id() == employee_id)
            .collect()
    }

    pub fn clear(&mut self) {
        self.events.clear();
    }
}

// ============================================================
// 17. レポート生成
// ============================================================

/// 給与レポート
#[derive(Debug, Clone)]
pub struct PayrollReport {
    pub pay_period: String,
    pub total_gross_pay: Money,
    pub total_deductions: Money,
    pub total_net_pay: Money,
    pub employee_count: usize,
    pub payslips: Vec<Payslip>,
}

impl PayrollReport {
    pub fn generate(pay_period: &str, payslips: Vec<Payslip>) -> Self {
        let total_gross: Money = payslips.iter().map(|p| p.gross_pay).sum();
        let total_deductions: Money = payslips
            .iter()
            .flat_map(|p| p.deductions.values())
            .sum();
        let total_net: Money = payslips.iter().map(|p| p.net_pay).sum();
        
        Self {
            pay_period: pay_period.to_string(),
            total_gross_pay: total_gross,
            total_deductions,
            total_net_pay: total_net,
            employee_count: payslips.len(),
            payslips,
        }
    }
}

// ============================================================
// 18. DSL for payroll configuration
// ============================================================

pub mod payroll_dsl {
    use super::*;

    pub fn employee(id: &str) -> EmployeeBuilder {
        EmployeeBuilder {
            id: id.to_string(),
            name: String::new(),
            pay_class: None,
            schedule: None,
            payment_method: PaymentMethod::Hold,
        }
    }

    pub struct EmployeeBuilder {
        id: String,
        name: String,
        pay_class: Option<PayClass>,
        schedule: Option<Schedule>,
        payment_method: PaymentMethod,
    }

    impl EmployeeBuilder {
        pub fn named(mut self, name: &str) -> Self {
            self.name = name.to_string();
            self
        }

        pub fn salaried(mut self, salary: Money) -> Self {
            self.pay_class = Some(PayClass::Salaried { salary });
            self.schedule = Some(Schedule::Monthly);
            self
        }

        pub fn hourly(mut self, rate: Money) -> Self {
            self.pay_class = Some(PayClass::Hourly { hourly_rate: rate });
            self.schedule = Some(Schedule::Weekly);
            self
        }

        pub fn commissioned(mut self, base_pay: Money, commission_rate: Rate) -> Self {
            self.pay_class = Some(PayClass::Commissioned { base_pay, commission_rate });
            self.schedule = Some(Schedule::Biweekly);
            self
        }

        pub fn with_direct_deposit(mut self, account: &str) -> Self {
            self.payment_method = PaymentMethod::DirectDeposit { account: account.to_string() };
            self
        }

        pub fn with_mail_payment(mut self, address: &str) -> Self {
            self.payment_method = PaymentMethod::Mail { address: address.to_string() };
            self
        }

        pub fn build(self) -> Employee {
            Employee {
                id: self.id,
                name: self.name,
                pay_class: self.pay_class.expect("PayClass not set"),
                schedule: self.schedule.unwrap_or(Schedule::Monthly),
                payment_method: self.payment_method,
                address: None,
            }
        }
    }
}

// ============================================================
// テスト
// ============================================================

#[cfg(test)]
mod tests {
    use super::*;

    // ============================================================
    // 1. 従業員作成
    // ============================================================

    mod employee_tests {
        use super::*;

        #[test]
        fn creates_salaried_employee() {
            let emp = Employee::salaried("E001", "田中太郎", dec!(500000));
            assert_eq!(emp.id, "E001");
            assert_eq!(emp.name, "田中太郎");
            assert_eq!(emp.pay_class, PayClass::Salaried { salary: dec!(500000) });
            assert_eq!(emp.schedule, Schedule::Monthly);
            assert_eq!(emp.payment_method, PaymentMethod::Hold);
        }

        #[test]
        fn creates_hourly_employee() {
            let emp = Employee::hourly("E002", "佐藤花子", dec!(1500));
            assert_eq!(emp.pay_class, PayClass::Hourly { hourly_rate: dec!(1500) });
            assert_eq!(emp.schedule, Schedule::Weekly);
        }

        #[test]
        fn creates_commissioned_employee() {
            let emp = Employee::commissioned("E003", "鈴木一郎", dec!(200000), 0.1);
            assert_eq!(emp.pay_class, PayClass::Commissioned { base_pay: dec!(200000), commission_rate: 0.1 });
            assert_eq!(emp.schedule, Schedule::Biweekly);
        }
    }

    // ============================================================
    // 2. 給与計算
    // ============================================================

    mod pay_calculation_tests {
        use super::*;

        #[test]
        fn salaried_returns_fixed_salary() {
            let emp = Employee::salaried("E001", "田中", dec!(500000));
            let ctx = PayrollContext::new();
            assert_eq!(calculate_pay(&emp, &ctx), dec!(500000));
        }

        #[test]
        fn hourly_calculates_based_on_hours() {
            let emp = Employee::hourly("E002", "佐藤", dec!(1500));
            let ctx = PayrollContext::new()
                .add_time_card(TimeCard::new("E002", "2024-01-15", 8.0))
                .add_time_card(TimeCard::new("E002", "2024-01-16", 8.0));
            assert_eq!(calculate_pay(&emp, &ctx), dec!(24000)); // 16 * 1500
        }

        #[test]
        fn hourly_overtime_at_1_5x() {
            let emp = Employee::hourly("E002", "佐藤", dec!(1000));
            let ctx = PayrollContext::new()
                .add_time_card(TimeCard::new("E002", "2024-01-15", 45.0));
            // 40 * 1000 + 5 * 1000 * 1.5 = 47500
            assert_eq!(calculate_pay(&emp, &ctx), dec!(47500));
        }

        #[test]
        fn hourly_no_timecards_returns_zero() {
            let emp = Employee::hourly("E002", "佐藤", dec!(1500));
            let ctx = PayrollContext::new();
            assert_eq!(calculate_pay(&emp, &ctx), dec!(0));
        }

        #[test]
        fn commissioned_calculates_base_plus_commission() {
            let emp = Employee::commissioned("E003", "鈴木", dec!(200000), 0.1);
            let ctx = PayrollContext::new()
                .add_sales_receipt(SalesReceipt::new("E003", "2024-01-15", dec!(100000)))
                .add_sales_receipt(SalesReceipt::new("E003", "2024-01-16", dec!(50000)));
            // 200000 + 150000 * 0.1 = 215000
            assert_eq!(calculate_pay(&emp, &ctx), dec!(215000));
        }

        #[test]
        fn commissioned_no_sales_returns_base() {
            let emp = Employee::commissioned("E003", "鈴木", dec!(200000), 0.1);
            let ctx = PayrollContext::new();
            assert_eq!(calculate_pay(&emp, &ctx), dec!(200000));
        }
    }

    // ============================================================
    // 3. 支払いスケジュール
    // ============================================================

    mod schedule_tests {
        use super::*;

        #[test]
        fn monthly_pays_on_last_day() {
            let emp = Employee::salaried("E001", "田中", dec!(500000));
            let date = PayDate::new(2024, 1, 31, DayOfWeek::Wednesday, true);
            assert!(is_pay_day(&emp, &date));
        }

        #[test]
        fn monthly_does_not_pay_mid_month() {
            let emp = Employee::salaried("E001", "田中", dec!(500000));
            let date = PayDate::new(2024, 1, 15, DayOfWeek::Monday, false);
            assert!(!is_pay_day(&emp, &date));
        }

        #[test]
        fn weekly_pays_on_friday() {
            let emp = Employee::hourly("E002", "佐藤", dec!(1500));
            let date = PayDate::new(2024, 1, 19, DayOfWeek::Friday, false);
            assert!(is_pay_day(&emp, &date));
        }

        #[test]
        fn weekly_does_not_pay_on_thursday() {
            let emp = Employee::hourly("E002", "佐藤", dec!(1500));
            let date = PayDate::new(2024, 1, 18, DayOfWeek::Thursday, false);
            assert!(!is_pay_day(&emp, &date));
        }

        #[test]
        fn biweekly_pays_on_pay_week_friday() {
            let emp = Employee::commissioned("E003", "鈴木", dec!(200000), 0.1);
            let date = PayDate::new(2024, 1, 19, DayOfWeek::Friday, false).with_pay_week(true);
            assert!(is_pay_day(&emp, &date));
        }

        #[test]
        fn biweekly_does_not_pay_on_non_pay_week() {
            let emp = Employee::commissioned("E003", "鈴木", dec!(200000), 0.1);
            let date = PayDate::new(2024, 1, 26, DayOfWeek::Friday, false).with_pay_week(false);
            assert!(!is_pay_day(&emp, &date));
        }
    }

    // ============================================================
    // 4. 支払い処理
    // ============================================================

    mod payment_tests {
        use super::*;

        #[test]
        fn hold_returns_held_payment() {
            let emp = Employee::salaried("E001", "田中", dec!(500000));
            let result = process_payment(&emp, dec!(500000));
            assert_eq!(result, PaymentResult::Held { employee_id: "E001".to_string(), amount: dec!(500000) });
        }

        #[test]
        fn direct_deposit_returns_deposit_payment() {
            let mut emp = Employee::salaried("E001", "田中", dec!(500000));
            emp.payment_method = PaymentMethod::DirectDeposit { account: "1234567890".to_string() };
            let result = process_payment(&emp, dec!(500000));
            assert_eq!(result, PaymentResult::DirectDeposit { employee_id: "E001".to_string(), amount: dec!(500000), account: "1234567890".to_string() });
        }

        #[test]
        fn mail_returns_mailed_payment() {
            let mut emp = Employee::salaried("E001", "田中", dec!(500000));
            emp.payment_method = PaymentMethod::Mail { address: "東京都渋谷区1-1-1".to_string() };
            let result = process_payment(&emp, dec!(500000));
            assert_eq!(result, PaymentResult::Mailed { employee_id: "E001".to_string(), amount: dec!(500000), address: "東京都渋谷区1-1-1".to_string() });
        }
    }

    // ============================================================
    // 5. 給与支払い実行
    // ============================================================

    mod run_payroll_tests {
        use super::*;

        #[test]
        fn pays_only_employees_on_pay_day() {
            let salaried = Employee::salaried("E001", "田中", dec!(500000));
            let hourly = Employee::hourly("E002", "佐藤", dec!(1500));

            let ctx = PayrollContext::new()
                .add_time_card(TimeCard::new("E002", "2024-01-15", 40.0));

            let month_end = PayDate::new(2024, 1, 31, DayOfWeek::Wednesday, true);
            let results = run_payroll(&[salaried, hourly], &ctx, &month_end);

            assert_eq!(results.len(), 1);
            assert_eq!(results[0].employee_id(), "E001");
        }

        #[test]
        fn pays_hourly_on_friday() {
            let salaried = Employee::salaried("E001", "田中", dec!(500000));
            let hourly = Employee::hourly("E002", "佐藤", dec!(1500));

            let ctx = PayrollContext::new()
                .add_time_card(TimeCard::new("E002", "2024-01-15", 40.0));

            let friday = PayDate::new(2024, 1, 19, DayOfWeek::Friday, false);
            let results = run_payroll(&[salaried, hourly], &ctx, &friday);

            assert_eq!(results.len(), 1);
            assert_eq!(results[0].employee_id(), "E002");
            assert_eq!(results[0].amount(), dec!(60000)); // 40 * 1500
        }
    }

    // ============================================================
    // 6. 従業員操作
    // ============================================================

    mod employee_operations_tests {
        use super::*;
        use employee_operations::*;

        #[test]
        fn changes_payment_method() {
            let emp = Employee::salaried("E001", "田中", dec!(500000));
            let updated = change_payment_method(&emp, PaymentMethod::DirectDeposit { account: "123456".to_string() });
            assert_eq!(updated.payment_method, PaymentMethod::DirectDeposit { account: "123456".to_string() });
        }

        #[test]
        fn changes_address() {
            let emp = Employee::salaried("E001", "田中", dec!(500000));
            let updated = change_address(&emp, "東京都");
            assert_eq!(updated.address, Some("東京都".to_string()));
        }

        #[test]
        fn changes_to_salaried() {
            let emp = Employee::hourly("E001", "田中", dec!(1500));
            let updated = change_to_salaried(&emp, dec!(500000));
            assert_eq!(updated.pay_class, PayClass::Salaried { salary: dec!(500000) });
            assert_eq!(updated.schedule, Schedule::Monthly);
        }

        #[test]
        fn changes_to_hourly() {
            let emp = Employee::salaried("E001", "田中", dec!(500000));
            let updated = change_to_hourly(&emp, dec!(1500));
            assert_eq!(updated.pay_class, PayClass::Hourly { hourly_rate: dec!(1500) });
            assert_eq!(updated.schedule, Schedule::Weekly);
        }
    }

    // ============================================================
    // 7. 従業員リポジトリ
    // ============================================================

    mod repository_tests {
        use super::*;

        #[test]
        fn saves_and_finds_employee() {
            let mut repo = InMemoryEmployeeRepository::new();
            let emp = Employee::salaried("E001", "田中", dec!(500000));

            repo.save(emp.clone());
            assert_eq!(repo.find_by_id("E001"), Some(emp));
        }

        #[test]
        fn finds_all_employees() {
            let mut repo = InMemoryEmployeeRepository::new();
            repo.save(Employee::salaried("E001", "田中", dec!(500000)));
            repo.save(Employee::hourly("E002", "佐藤", dec!(1500)));

            assert_eq!(repo.find_all().len(), 2);
        }

        #[test]
        fn deletes_employee() {
            let mut repo = InMemoryEmployeeRepository::new();
            let emp = Employee::salaried("E001", "田中", dec!(500000));

            repo.save(emp.clone());
            assert_eq!(repo.delete("E001"), Some(emp));
            assert_eq!(repo.find_by_id("E001"), None);
        }
    }

    // ============================================================
    // 8. 給与明細
    // ============================================================

    mod payslip_tests {
        use super::*;

        #[test]
        fn creates_payslip() {
            let emp = Employee::salaried("E001", "田中", dec!(500000));
            let payslip = Payslip::create(&emp, "2024-01", dec!(500000));

            assert_eq!(payslip.employee_id, "E001");
            assert_eq!(payslip.gross_pay, dec!(500000));
            assert_eq!(payslip.net_pay, dec!(500000));
        }

        #[test]
        fn adds_deductions() {
            let emp = Employee::salaried("E001", "田中", dec!(500000));
            let payslip = Payslip::create(&emp, "2024-01", dec!(500000))
                .add_deduction("所得税", dec!(50000))
                .add_deduction("社会保険", dec!(30000));

            assert_eq!(payslip.deductions.len(), 2);
            assert_eq!(payslip.net_pay, dec!(420000));
        }
    }

    // ============================================================
    // 9. 控除計算
    // ============================================================

    mod deduction_tests {
        use super::*;

        #[test]
        fn fixed_deduction_returns_amount() {
            let ded = Deduction::Fixed { name: "健康保険".to_string(), amount: dec!(10000) };
            assert_eq!(ded.calculate(dec!(500000)), dec!(10000));
        }

        #[test]
        fn percentage_deduction_calculates_rate() {
            let ded = Deduction::Percentage { name: "所得税".to_string(), rate: 0.1 };
            assert_eq!(ded.calculate(dec!(500000)), dec!(50000));
        }

        #[test]
        fn apply_deductions_applies_multiple() {
            let emp = Employee::salaried("E001", "田中", dec!(500000));
            let payslip = Payslip::create(&emp, "2024-01", dec!(500000));
            let deductions = vec![
                Deduction::Fixed { name: "健康保険".to_string(), amount: dec!(10000) },
                Deduction::Percentage { name: "所得税".to_string(), rate: 0.1 },
            ];
            let result = apply_deductions(payslip, &deductions);

            assert_eq!(result.deductions.len(), 2);
            assert_eq!(result.net_pay, dec!(440000)); // 500000 - 10000 - 50000
        }
    }

    // ============================================================
    // 10. 給与計算サービス
    // ============================================================

    mod payroll_service_tests {
        use super::*;

        #[test]
        fn adds_and_gets_employee() {
            let repo = InMemoryEmployeeRepository::new();
            let mut service = PayrollService::new(repo, vec![]);
            let emp = Employee::salaried("E001", "田中", dec!(500000));

            service.add_employee(emp.clone());
            assert_eq!(service.get_employee("E001"), Some(emp));
        }

        #[test]
        fn updates_employee() {
            let repo = InMemoryEmployeeRepository::new();
            let mut service = PayrollService::new(repo, vec![]);
            let emp = Employee::salaried("E001", "田中", dec!(500000));

            service.add_employee(emp);
            service.update_employee("E001", |e| Employee { name: "田中太郎".to_string(), ..e });

            assert_eq!(service.get_employee("E001").unwrap().name, "田中太郎");
        }

        #[test]
        fn runs_payroll_with_deductions() {
            let repo = InMemoryEmployeeRepository::new();
            let deductions = vec![Deduction::Percentage { name: "所得税".to_string(), rate: 0.1 }];
            let mut service = PayrollService::new(repo, deductions);

            service.add_employee(Employee::salaried("E001", "田中", dec!(500000)));

            let ctx = PayrollContext::new();
            let date = PayDate::new(2024, 1, 31, DayOfWeek::Wednesday, true);
            let payslips = service.run_payroll(&ctx, &date, "2024-01");

            assert_eq!(payslips.len(), 1);
            assert_eq!(payslips[0].gross_pay, dec!(500000));
            assert_eq!(payslips[0].net_pay, dec!(450000)); // 500000 - 50000
        }
    }

    // ============================================================
    // 11. イベントストア
    // ============================================================

    mod event_store_tests {
        use super::*;

        #[test]
        fn appends_and_gets_events() {
            let mut store = EventStore::new();
            let emp = Employee::salaried("E001", "田中", dec!(500000));

            store.append(PayrollEvent::EmployeeAdded { timestamp: 1000, employee_id: "E001".to_string(), employee: emp });
            store.append(PayrollEvent::TimeCardAdded { timestamp: 2000, employee_id: "E001".to_string(), time_card: TimeCard::new("E001", "2024-01-15", 8.0) });

            assert_eq!(store.get_events().len(), 2);
        }

        #[test]
        fn gets_events_by_employee() {
            let mut store = EventStore::new();
            let emp1 = Employee::salaried("E001", "田中", dec!(500000));
            let emp2 = Employee::hourly("E002", "佐藤", dec!(1500));

            store.append(PayrollEvent::EmployeeAdded { timestamp: 1000, employee_id: "E001".to_string(), employee: emp1 });
            store.append(PayrollEvent::EmployeeAdded { timestamp: 2000, employee_id: "E002".to_string(), employee: emp2 });
            store.append(PayrollEvent::TimeCardAdded { timestamp: 3000, employee_id: "E001".to_string(), time_card: TimeCard::new("E001", "2024-01-15", 8.0) });

            assert_eq!(store.get_events_by_employee("E001").len(), 2);
        }
    }

    // ============================================================
    // 12. レポート生成
    // ============================================================

    mod report_tests {
        use super::*;

        #[test]
        fn generates_report() {
            let emp1 = Employee::salaried("E001", "田中", dec!(500000));
            let emp2 = Employee::salaried("E002", "佐藤", dec!(400000));

            let payslip1 = Payslip::create(&emp1, "2024-01", dec!(500000))
                .add_deduction("所得税", dec!(50000));
            let payslip2 = Payslip::create(&emp2, "2024-01", dec!(400000))
                .add_deduction("所得税", dec!(40000));

            let report = PayrollReport::generate("2024-01", vec![payslip1, payslip2]);

            assert_eq!(report.total_gross_pay, dec!(900000));
            assert_eq!(report.total_deductions, dec!(90000));
            assert_eq!(report.total_net_pay, dec!(810000));
            assert_eq!(report.employee_count, 2);
        }
    }

    // ============================================================
    // 13. DSL
    // ============================================================

    mod dsl_tests {
        use super::*;
        use payroll_dsl::*;

        #[test]
        fn creates_employee_with_dsl() {
            let emp = employee("E001")
                .named("田中太郎")
                .salaried(dec!(500000))
                .with_direct_deposit("1234567890")
                .build();

            assert_eq!(emp.id, "E001");
            assert_eq!(emp.name, "田中太郎");
            assert_eq!(emp.pay_class, PayClass::Salaried { salary: dec!(500000) });
            assert_eq!(emp.payment_method, PaymentMethod::DirectDeposit { account: "1234567890".to_string() });
        }

        #[test]
        fn creates_hourly_with_dsl() {
            let emp = employee("E002")
                .named("佐藤花子")
                .hourly(dec!(1500))
                .build();

            assert_eq!(emp.pay_class, PayClass::Hourly { hourly_rate: dec!(1500) });
            assert_eq!(emp.schedule, Schedule::Weekly);
        }

        #[test]
        fn creates_commissioned_with_dsl() {
            let emp = employee("E003")
                .named("鈴木一郎")
                .commissioned(dec!(200000), 0.1)
                .with_mail_payment("東京都渋谷区")
                .build();

            assert_eq!(emp.pay_class, PayClass::Commissioned { base_pay: dec!(200000), commission_rate: 0.1 });
            assert_eq!(emp.payment_method, PaymentMethod::Mail { address: "東京都渋谷区".to_string() });
        }
    }
}
