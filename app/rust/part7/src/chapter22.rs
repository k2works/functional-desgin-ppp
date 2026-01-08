//! 第22章: OO から FP への移行
//!
//! オブジェクト指向から関数型への移行ガイドを解説します。

// ============================================================
// 1. OOスタイル（問題のあるアプローチ）
// ============================================================

pub mod oo_style {
    /// トランザクションの種類
    #[derive(Debug, Clone, PartialEq)]
    pub enum TransactionType {
        Deposit,
        Withdrawal,
    }

    /// トランザクション記録
    #[derive(Debug, Clone)]
    pub struct Transaction {
        pub transaction_type: TransactionType,
        pub amount: f64,
    }

    /// OOスタイル: 内部状態を持つオブジェクト（可変）
    pub struct Account {
        pub id: String,
        balance: f64,
        transactions: Vec<Transaction>,
    }

    impl Account {
        pub fn new(id: &str, initial_balance: f64) -> Account {
            Account {
                id: id.to_string(),
                balance: initial_balance,
                transactions: Vec::new(),
            }
        }

        pub fn balance(&self) -> f64 {
            self.balance
        }

        pub fn transactions(&self) -> &[Transaction] {
            &self.transactions
        }

        pub fn deposit(&mut self, amount: f64) -> f64 {
            if amount > 0.0 {
                self.balance += amount;
                self.transactions.push(Transaction {
                    transaction_type: TransactionType::Deposit,
                    amount,
                });
            }
            self.balance
        }

        pub fn withdraw(&mut self, amount: f64) -> f64 {
            if amount > 0.0 && self.balance >= amount {
                self.balance -= amount;
                self.transactions.push(Transaction {
                    transaction_type: TransactionType::Withdrawal,
                    amount,
                });
            }
            self.balance
        }
    }
}

// ============================================================
// 2. FPスタイル（推奨アプローチ）
// ============================================================

pub mod fp_style {
    /// トランザクションの種類
    #[derive(Debug, Clone, PartialEq)]
    pub enum TransactionType {
        Deposit,
        Withdrawal,
    }

    /// トランザクション記録
    #[derive(Debug, Clone)]
    pub struct Transaction {
        pub transaction_type: TransactionType,
        pub amount: f64,
    }

    /// 口座（不変データ）
    #[derive(Debug, Clone)]
    pub struct Account {
        pub id: String,
        pub balance: f64,
        pub transactions: Vec<Transaction>,
    }

    /// 口座を作成
    pub fn make_account(id: &str, initial_balance: f64) -> Account {
        Account {
            id: id.to_string(),
            balance: initial_balance,
            transactions: Vec::new(),
        }
    }

    /// 残高を取得
    pub fn get_balance(account: &Account) -> f64 {
        account.balance
    }

    /// 入金（新しい口座を返す）
    pub fn deposit(account: Account, amount: f64) -> Account {
        if amount > 0.0 {
            let mut transactions = account.transactions;
            transactions.push(Transaction {
                transaction_type: TransactionType::Deposit,
                amount,
            });
            Account {
                balance: account.balance + amount,
                transactions,
                ..account
            }
        } else {
            account
        }
    }

    /// 出金（新しい口座を返す）
    pub fn withdraw(account: Account, amount: f64) -> Account {
        if amount > 0.0 && account.balance >= amount {
            let mut transactions = account.transactions;
            transactions.push(Transaction {
                transaction_type: TransactionType::Withdrawal,
                amount,
            });
            Account {
                balance: account.balance - amount,
                transactions,
                ..account
            }
        } else {
            account
        }
    }

    /// 送金結果
    #[derive(Debug)]
    pub struct TransferResult {
        pub success: bool,
        pub from: Account,
        pub to: Account,
        pub error: Option<String>,
    }

    /// 送金（2つの口座間）
    pub fn transfer(from: Account, to: Account, amount: f64) -> TransferResult {
        if amount <= 0.0 {
            TransferResult {
                success: false,
                from,
                to,
                error: Some("Amount must be positive".to_string()),
            }
        } else if from.balance < amount {
            TransferResult {
                success: false,
                from,
                to,
                error: Some("Insufficient funds".to_string()),
            }
        } else {
            let new_from = withdraw(from, amount);
            let new_to = deposit(to, amount);
            TransferResult {
                success: true,
                from: new_from,
                to: new_to,
                error: None,
            }
        }
    }
}

// ============================================================
// 3. 移行戦略
// ============================================================

pub mod migration_strategies {
    use super::fp_style::*;

    /// スタイル識別子
    #[derive(Debug, Clone, PartialEq)]
    pub enum Style {
        FP,
        OO,
    }

    /// Strangler パターン用のラッパー
    #[derive(Debug, Clone)]
    pub struct StranglerAccount {
        pub style: Style,
        pub data: Account,
    }

    /// フィーチャーフラグによるアカウント作成
    pub fn create_account_strangler(
        id: &str,
        initial_balance: f64,
        use_fp: bool,
    ) -> StranglerAccount {
        let style = if use_fp { Style::FP } else { Style::OO };
        StranglerAccount {
            style,
            data: make_account(id, initial_balance),
        }
    }

    /// Strangler パターンでの入金
    pub fn account_deposit(account: StranglerAccount, amount: f64) -> StranglerAccount {
        StranglerAccount {
            data: deposit(account.data, amount),
            ..account
        }
    }

    /// 既存のインターフェースを維持するためのトレイト
    pub trait AccountOperations {
        fn get_account_balance(&self) -> f64;
        fn deposit_to_account(&mut self, amount: f64) -> f64;
        fn withdraw_from_account(&mut self, amount: f64) -> f64;
    }

    /// FPスタイルのアダプター（状態は外部で管理）
    pub struct FPAccountAdapter {
        account: Account,
    }

    impl FPAccountAdapter {
        pub fn new(id: &str, initial_balance: f64) -> FPAccountAdapter {
            FPAccountAdapter {
                account: make_account(id, initial_balance),
            }
        }

        pub fn get_account(&self) -> &Account {
            &self.account
        }
    }

    impl AccountOperations for FPAccountAdapter {
        fn get_account_balance(&self) -> f64 {
            get_balance(&self.account)
        }

        fn deposit_to_account(&mut self, amount: f64) -> f64 {
            self.account = deposit(self.account.clone(), amount);
            get_balance(&self.account)
        }

        fn withdraw_from_account(&mut self, amount: f64) -> f64 {
            self.account = withdraw(self.account.clone(), amount);
            get_balance(&self.account)
        }
    }

    pub fn make_fp_account_adapter(id: &str, initial_balance: f64) -> FPAccountAdapter {
        FPAccountAdapter::new(id, initial_balance)
    }

    // イベントソーシング

    /// イベントの種類
    #[derive(Debug, Clone, PartialEq)]
    pub enum EventType {
        Created,
        Deposited,
        Withdrawn,
    }

    /// イベント
    #[derive(Debug, Clone)]
    pub struct AccountEvent {
        pub event_type: EventType,
        pub data: std::collections::HashMap<String, String>,
        pub timestamp: i64,
    }

    /// イベント作成ヘルパー
    pub fn account_event(
        event_type: EventType,
        data: std::collections::HashMap<String, String>,
    ) -> AccountEvent {
        AccountEvent {
            event_type,
            data,
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis() as i64,
        }
    }

    /// イベントを適用して状態を更新
    pub fn apply_event(account: Account, event: &AccountEvent) -> Account {
        match event.event_type {
            EventType::Created => Account {
                id: event.data.get("id").cloned().unwrap_or_default(),
                balance: event
                    .data
                    .get("balance")
                    .and_then(|s| s.parse().ok())
                    .unwrap_or(0.0),
                transactions: Vec::new(),
            },
            EventType::Deposited => {
                let amount: f64 = event
                    .data
                    .get("amount")
                    .and_then(|s| s.parse().ok())
                    .unwrap_or(0.0);
                deposit(account, amount)
            }
            EventType::Withdrawn => {
                let amount: f64 = event
                    .data
                    .get("amount")
                    .and_then(|s| s.parse().ok())
                    .unwrap_or(0.0);
                withdraw(account, amount)
            }
        }
    }

    /// イベントのリプレイ
    pub fn replay_events(events: &[AccountEvent]) -> Account {
        events
            .iter()
            .fold(make_account("", 0.0), |acc, event| apply_event(acc, event))
    }

    /// 既存データからイベントへの変換
    pub fn migrate_to_event_sourcing(account: &Account) -> Vec<AccountEvent> {
        let mut events = Vec::new();

        // 作成イベント
        let mut creation_data = std::collections::HashMap::new();
        creation_data.insert("id".to_string(), account.id.clone());
        creation_data.insert("balance".to_string(), "0".to_string());
        events.push(account_event(EventType::Created, creation_data));

        // トランザクションイベント
        for tx in &account.transactions {
            let mut tx_data = std::collections::HashMap::new();
            tx_data.insert("amount".to_string(), tx.amount.to_string());
            let event_type = match tx.transaction_type {
                TransactionType::Deposit => EventType::Deposited,
                TransactionType::Withdrawal => EventType::Withdrawn,
            };
            events.push(account_event(event_type, tx_data));
        }

        events
    }

    // 段階的な関数抽出

    /// 利息計算（純粋関数）
    pub fn calculate_interest(balance: f64, rate: f64, days: i32) -> f64 {
        balance * rate * (days as f64 / 365.0)
    }

    /// 手数料体系
    #[derive(Debug, Clone)]
    pub struct FeeStructure {
        pub minimum_balance: f64,
        pub low_balance_fee: f64,
        pub premium_threshold: f64,
        pub standard_fee: f64,
    }

    /// 手数料計算（純粋関数）
    pub fn calculate_fee(balance: f64, fee_structure: &FeeStructure) -> f64 {
        if balance < fee_structure.minimum_balance {
            fee_structure.low_balance_fee
        } else if balance > fee_structure.premium_threshold {
            0.0
        } else {
            fee_structure.standard_fee
        }
    }

    /// 出金可能判定（純粋関数）
    pub fn can_withdraw(account: &Account, amount: f64, overdraft_limit: f64) -> bool {
        account.balance + overdraft_limit >= amount
    }

    /// 取引処理結果
    #[derive(Debug)]
    pub struct ProcessResult {
        pub success: bool,
        pub account: Account,
        pub error: Option<String>,
    }

    /// 取引ルール
    #[derive(Debug, Clone)]
    pub struct TransactionRules {
        pub overdraft_limit: f64,
    }

    /// 取引処理（副作用なし）
    pub fn process_transaction(
        account: Account,
        operation: TransactionType,
        amount: f64,
        rules: &TransactionRules,
    ) -> ProcessResult {
        let can_process = match operation {
            TransactionType::Deposit => true,
            TransactionType::Withdrawal => can_withdraw(&account, amount, rules.overdraft_limit),
        };

        if can_process {
            let new_account = match operation {
                TransactionType::Deposit => deposit(account, amount),
                TransactionType::Withdrawal => withdraw(account, amount),
            };
            ProcessResult {
                success: true,
                account: new_account,
                error: None,
            }
        } else {
            ProcessResult {
                success: false,
                account,
                error: Some("Insufficient funds".to_string()),
            }
        }
    }
}

// ============================================================
// 4. マルチメソッドによる多態性
// ============================================================

pub mod polymorphism {
    /// 図形（ADT）
    #[derive(Debug, Clone)]
    pub enum Shape {
        Circle { x: f64, y: f64, radius: f64 },
        Rectangle { x: f64, y: f64, width: f64, height: f64 },
        Triangle { x: f64, y: f64, base: f64, height: f64 },
    }

    /// 図形の面積を計算（パターンマッチで多態性）
    pub fn area(shape: &Shape) -> f64 {
        match shape {
            Shape::Circle { radius, .. } => std::f64::consts::PI * radius * radius,
            Shape::Rectangle { width, height, .. } => width * height,
            Shape::Triangle { base, height, .. } => base * height / 2.0,
        }
    }

    /// 図形を拡大（パターンマッチで多態性）
    pub fn scale(shape: &Shape, factor: f64) -> Shape {
        match shape {
            Shape::Circle { x, y, radius } => Shape::Circle {
                x: *x,
                y: *y,
                radius: radius * factor,
            },
            Shape::Rectangle { x, y, width, height } => Shape::Rectangle {
                x: *x,
                y: *y,
                width: width * factor,
                height: height * factor,
            },
            Shape::Triangle { x, y, base, height } => Shape::Triangle {
                x: *x,
                y: *y,
                base: base * factor,
                height: height * factor,
            },
        }
    }

    /// 共通操作（型に依存しない）
    pub fn translate(shape: &Shape, dx: f64, dy: f64) -> Shape {
        match shape {
            Shape::Circle { x, y, radius } => Shape::Circle {
                x: x + dx,
                y: y + dy,
                radius: *radius,
            },
            Shape::Rectangle { x, y, width, height } => Shape::Rectangle {
                x: x + dx,
                y: y + dy,
                width: *width,
                height: *height,
            },
            Shape::Triangle { x, y, base, height } => Shape::Triangle {
                x: x + dx,
                y: y + dy,
                base: *base,
                height: *height,
            },
        }
    }

    /// 周囲長を計算
    pub fn perimeter(shape: &Shape) -> f64 {
        match shape {
            Shape::Circle { radius, .. } => 2.0 * std::f64::consts::PI * radius,
            Shape::Rectangle { width, height, .. } => 2.0 * (width + height),
            Shape::Triangle { base, height, .. } => {
                // 二等辺三角形と仮定
                let side = ((base / 2.0).powi(2) + height.powi(2)).sqrt();
                base + 2.0 * side
            }
        }
    }
}

// ============================================================
// 5. イベント駆動アーキテクチャ
// ============================================================

pub mod event_driven {
    /// イベント
    #[derive(Debug, Clone)]
    pub struct Event<A> {
        pub event_type: String,
        pub data: A,
    }

    /// イベントシステム（不変）
    #[derive(Clone)]
    pub struct EventSystem<A: Clone> {
        pub handlers: HashMap<String, Vec<fn(&Event<A>) -> String>>,
        pub event_log: Vec<Event<A>>,
    }

    use std::collections::HashMap;

    impl<A: Clone> EventSystem<A> {
        /// イベントシステムを作成
        pub fn new() -> EventSystem<A> {
            EventSystem {
                handlers: HashMap::new(),
                event_log: Vec::new(),
            }
        }

        /// ハンドラを登録
        pub fn subscribe(
            mut self,
            event_type: &str,
            handler: fn(&Event<A>) -> String,
        ) -> EventSystem<A> {
            self.handlers
                .entry(event_type.to_string())
                .or_insert_with(Vec::new)
                .push(handler);
            self
        }

        /// イベントを発行
        pub fn publish(&self, event_type: &str, data: A) -> (EventSystem<A>, Vec<String>) {
            let event = Event {
                event_type: event_type.to_string(),
                data,
            };

            let results: Vec<String> = self
                .handlers
                .get(event_type)
                .map(|handlers| handlers.iter().map(|h| h(&event)).collect())
                .unwrap_or_default();

            let mut new_log = self.event_log.clone();
            new_log.push(event);

            let new_system = EventSystem {
                handlers: self.handlers.clone(),
                event_log: new_log,
            };

            (new_system, results)
        }

        /// イベントログを取得
        pub fn get_event_log(&self) -> &[Event<A>] {
            &self.event_log
        }
    }

    impl<A: Clone> Default for EventSystem<A> {
        fn default() -> Self {
            Self::new()
        }
    }
}

// ============================================================
// 6. 実践的な移行例
// ============================================================

pub mod practical_migration {
    use std::collections::HashMap;

    /// ユーザーID（値オブジェクト）
    #[derive(Debug, Clone, PartialEq, Eq, Hash)]
    pub struct UserId(String);

    impl UserId {
        pub fn new(value: &str) -> UserId {
            UserId(value.to_string())
        }

        pub fn value(&self) -> &str {
            &self.0
        }
    }

    /// メールアドレス（値オブジェクト + バリデーション）
    #[derive(Debug, Clone, PartialEq)]
    pub struct Email(String);

    impl Email {
        pub fn new(value: &str) -> Result<Email, String> {
            if value.contains('@') && value.len() > 3 {
                Ok(Email(value.to_string()))
            } else {
                Err("Invalid email format".to_string())
            }
        }

        pub fn value(&self) -> &str {
            &self.0
        }
    }

    /// ユーザー（不変エンティティ）
    #[derive(Debug, Clone)]
    pub struct User {
        pub id: UserId,
        pub name: String,
        pub email: String,
        pub active: bool,
    }

    /// ユーザー作成結果
    #[derive(Debug)]
    pub enum CreateUserResult {
        UserCreated(User),
        UserCreationFailed(Vec<String>),
    }

    /// ユーザー作成（バリデーション付き）
    pub fn create_user(id: &str, name: &str, email: &str) -> CreateUserResult {
        let mut errors = Vec::new();

        if name.is_empty() {
            errors.push("Name is required".to_string());
        }
        if !email.contains('@') {
            errors.push("Invalid email".to_string());
        }
        if id.is_empty() {
            errors.push("ID is required".to_string());
        }

        if errors.is_empty() {
            CreateUserResult::UserCreated(User {
                id: UserId::new(id),
                name: name.to_string(),
                email: email.to_string(),
                active: true,
            })
        } else {
            CreateUserResult::UserCreationFailed(errors)
        }
    }

    /// リポジトリ操作の結果
    #[derive(Debug)]
    pub enum RepositoryResult<A> {
        Found(A),
        NotFound,
        Error(String),
    }

    /// 不変リポジトリ
    #[derive(Debug, Clone)]
    pub struct UserRepository {
        users: HashMap<String, User>,
    }

    impl UserRepository {
        pub fn new() -> UserRepository {
            UserRepository {
                users: HashMap::new(),
            }
        }

        pub fn save(&self, user: User) -> UserRepository {
            let mut users = self.users.clone();
            users.insert(user.id.value().to_string(), user);
            UserRepository { users }
        }

        pub fn find_by_id(&self, id: &UserId) -> RepositoryResult<User> {
            match self.users.get(id.value()) {
                Some(user) => RepositoryResult::Found(user.clone()),
                None => RepositoryResult::NotFound,
            }
        }

        pub fn find_all(&self) -> Vec<User> {
            self.users.values().cloned().collect()
        }

        pub fn delete(&self, id: &UserId) -> UserRepository {
            let mut users = self.users.clone();
            users.remove(id.value());
            UserRepository { users }
        }

        pub fn update<F: FnOnce(User) -> User>(&self, id: &UserId, f: F) -> UserRepository {
            match self.users.get(id.value()) {
                Some(user) => {
                    let mut users = self.users.clone();
                    users.insert(id.value().to_string(), f(user.clone()));
                    UserRepository { users }
                }
                None => self.clone(),
            }
        }
    }

    impl Default for UserRepository {
        fn default() -> Self {
            Self::new()
        }
    }

    /// サービス操作の結果
    pub struct ServiceResult<A> {
        pub value: A,
        pub repository: UserRepository,
    }

    /// ユーザーサービス（純粋関数として実装）
    pub mod user_service {
        use super::*;

        pub fn register_user(
            repo: UserRepository,
            id: &str,
            name: &str,
            email: &str,
        ) -> Result<ServiceResult<User>, Vec<String>> {
            match create_user(id, name, email) {
                CreateUserResult::UserCreated(user) => {
                    let new_repo = repo.save(user.clone());
                    Ok(ServiceResult {
                        value: user,
                        repository: new_repo,
                    })
                }
                CreateUserResult::UserCreationFailed(errors) => Err(errors),
            }
        }

        pub fn deactivate_user(
            repo: UserRepository,
            id: &UserId,
        ) -> Result<ServiceResult<User>, String> {
            match repo.find_by_id(id) {
                RepositoryResult::Found(user) => {
                    let updated = User {
                        active: false,
                        ..user
                    };
                    let new_repo = repo.update(id, |_| updated.clone());
                    Ok(ServiceResult {
                        value: updated,
                        repository: new_repo,
                    })
                }
                RepositoryResult::NotFound => Err("User not found".to_string()),
                RepositoryResult::Error(msg) => Err(msg),
            }
        }

        pub fn get_all_active_users(repo: &UserRepository) -> Vec<User> {
            repo.find_all().into_iter().filter(|u| u.active).collect()
        }
    }

    /// パイプライン演算子（拡張メソッド）
    pub trait PipeExt<A> {
        fn pipe<B, F: FnOnce(A) -> B>(self, f: F) -> B;
    }

    impl<A> PipeExt<A> for A {
        fn pipe<B, F: FnOnce(A) -> B>(self, f: F) -> B {
            f(self)
        }
    }

    /// データ変換の例
    pub fn transform_user_data(users: Vec<User>) -> HashMap<String, Vec<String>> {
        users
            .into_iter()
            .filter(|u| u.active)
            .fold(HashMap::new(), |mut acc, user| {
                let key = user
                    .name
                    .chars()
                    .next()
                    .unwrap_or('_')
                    .to_uppercase()
                    .to_string();
                acc.entry(key).or_insert_with(Vec::new).push(user.email);
                acc
            })
    }
}

// ============================================================
// 7. 移行チェックリスト
// ============================================================

pub mod migration_checklist {
    /// チェック項目
    #[derive(Debug, Clone)]
    pub struct ChecklistItem {
        pub description: String,
        pub completed: bool,
    }

    impl ChecklistItem {
        pub fn new(description: &str) -> ChecklistItem {
            ChecklistItem {
                description: description.to_string(),
                completed: false,
            }
        }
    }

    /// 移行チェックリスト
    #[derive(Debug, Clone)]
    pub struct MigrationChecklist {
        pub preparation: Vec<ChecklistItem>,
        pub execution: Vec<ChecklistItem>,
        pub completion: Vec<ChecklistItem>,
    }

    /// デフォルトのチェックリスト
    pub fn default_checklist() -> MigrationChecklist {
        MigrationChecklist {
            preparation: vec![
                ChecklistItem::new("現在のコードの状態を把握"),
                ChecklistItem::new("テストカバレッジを確認"),
                ChecklistItem::new("移行の優先順位を決定"),
                ChecklistItem::new("チームへの教育"),
            ],
            execution: vec![
                ChecklistItem::new("純粋関数を抽出"),
                ChecklistItem::new("副作用を分離"),
                ChecklistItem::new("ADTに移行"),
                ChecklistItem::new("テストを追加"),
            ],
            completion: vec![
                ChecklistItem::new("古いコードを削除"),
                ChecklistItem::new("ドキュメントを更新"),
                ChecklistItem::new("パフォーマンスを確認"),
                ChecklistItem::new("チームレビュー"),
            ],
        }
    }

    /// 項目を完了としてマーク
    pub fn mark_completed(
        checklist: MigrationChecklist,
        phase: &str,
        index: usize,
    ) -> MigrationChecklist {
        let mut result = checklist;
        match phase {
            "preparation" if index < result.preparation.len() => {
                result.preparation[index].completed = true;
            }
            "execution" if index < result.execution.len() => {
                result.execution[index].completed = true;
            }
            "completion" if index < result.completion.len() => {
                result.completion[index].completed = true;
            }
            _ => {}
        }
        result
    }

    /// 進捗を計算
    pub fn calculate_progress(checklist: &MigrationChecklist) -> f64 {
        let all: Vec<&ChecklistItem> = checklist
            .preparation
            .iter()
            .chain(checklist.execution.iter())
            .chain(checklist.completion.iter())
            .collect();

        let completed = all.iter().filter(|item| item.completed).count();

        if all.is_empty() {
            0.0
        } else {
            completed as f64 / all.len() as f64 * 100.0
        }
    }
}

// ============================================================
// 8. 比較表
// ============================================================

pub mod comparison {
    /// 比較項目
    #[derive(Debug, Clone)]
    pub struct ComparisonItem {
        pub aspect: String,
        pub oo: String,
        pub fp: String,
        pub advantage: String,
    }

    /// OO vs FP 比較表
    pub fn comparison_table() -> Vec<ComparisonItem> {
        vec![
            ComparisonItem {
                aspect: "基本単位".to_string(),
                oo: "オブジェクト".to_string(),
                fp: "データ + 関数".to_string(),
                advantage: "FP: より単純な構造".to_string(),
            },
            ComparisonItem {
                aspect: "状態管理".to_string(),
                oo: "可変（mutable）".to_string(),
                fp: "不変（immutable）".to_string(),
                advantage: "FP: 予測可能".to_string(),
            },
            ComparisonItem {
                aspect: "多態性".to_string(),
                oo: "継承・インターフェース".to_string(),
                fp: "ADT・パターンマッチ".to_string(),
                advantage: "FP: より柔軟".to_string(),
            },
            ComparisonItem {
                aspect: "コード再利用".to_string(),
                oo: "継承".to_string(),
                fp: "関数合成".to_string(),
                advantage: "FP: より疎結合".to_string(),
            },
            ComparisonItem {
                aspect: "副作用".to_string(),
                oo: "どこでも可能".to_string(),
                fp: "境界に分離".to_string(),
                advantage: "FP: テスト容易".to_string(),
            },
            ComparisonItem {
                aspect: "テスト".to_string(),
                oo: "モックが必要".to_string(),
                fp: "入力→出力のみ".to_string(),
                advantage: "FP: シンプル".to_string(),
            },
            ComparisonItem {
                aspect: "デバッグ".to_string(),
                oo: "状態追跡が困難".to_string(),
                fp: "値が不変で追跡容易".to_string(),
                advantage: "FP: 容易".to_string(),
            },
            ComparisonItem {
                aspect: "並行処理".to_string(),
                oo: "ロックが必要".to_string(),
                fp: "不変データで安全".to_string(),
                advantage: "FP: 安全".to_string(),
            },
        ]
    }

    /// アドバンテージをカウント
    pub fn count_advantages() -> std::collections::HashMap<String, usize> {
        let mut result = std::collections::HashMap::new();
        for item in comparison_table() {
            let key = if item.advantage.contains("FP") {
                "FP"
            } else {
                "OO"
            };
            *result.entry(key.to_string()).or_insert(0) += 1;
        }
        result
    }
}

// ============================================================
// テスト
// ============================================================

#[cfg(test)]
mod tests {
    use super::*;

    mod oo_style_tests {
        use super::oo_style::*;

        #[test]
        fn deposit_changes_internal_state() {
            let mut acc = Account::new("A001", 1000.0);
            acc.deposit(500.0);
            assert_eq!(acc.balance(), 1500.0);
        }

        #[test]
        fn withdraw_changes_internal_state() {
            let mut acc = Account::new("A001", 1000.0);
            acc.withdraw(300.0);
            assert_eq!(acc.balance(), 700.0);
        }

        #[test]
        fn cannot_withdraw_with_insufficient_funds() {
            let mut acc = Account::new("A001", 100.0);
            acc.withdraw(200.0);
            assert_eq!(acc.balance(), 100.0);
        }

        #[test]
        fn records_transaction_history() {
            let mut acc = Account::new("A001", 1000.0);
            acc.deposit(500.0);
            acc.withdraw(200.0);
            assert_eq!(acc.transactions().len(), 2);
        }
    }

    mod fp_style_tests {
        use super::fp_style::*;

        #[test]
        fn deposit_returns_new_account() {
            let acc = make_account("A001", 1000.0);
            let new_acc = deposit(acc.clone(), 500.0);
            assert_eq!(get_balance(&acc), 1000.0); // 元は変わらない
            assert_eq!(get_balance(&new_acc), 1500.0);
        }

        #[test]
        fn withdraw_returns_new_account() {
            let acc = make_account("A001", 1000.0);
            let new_acc = withdraw(acc.clone(), 300.0);
            assert_eq!(get_balance(&acc), 1000.0);
            assert_eq!(get_balance(&new_acc), 700.0);
        }

        #[test]
        fn returns_original_with_insufficient_funds() {
            let acc = make_account("A001", 100.0);
            let new_acc = withdraw(acc, 200.0);
            assert_eq!(get_balance(&new_acc), 100.0);
        }

        #[test]
        fn chain_operations() {
            let acc = make_account("A001", 1000.0);
            let result = withdraw(deposit(acc, 500.0), 200.0);
            assert_eq!(get_balance(&result), 1300.0);
        }

        #[test]
        fn immutable_transaction_history() {
            let acc = make_account("A001", 1000.0);
            let acc2 = deposit(acc.clone(), 500.0);
            let acc3 = withdraw(acc2.clone(), 200.0);
            assert_eq!(acc.transactions.len(), 0);
            assert_eq!(acc2.transactions.len(), 1);
            assert_eq!(acc3.transactions.len(), 2);
        }

        #[test]
        fn transfer_success() {
            let from = make_account("A001", 1000.0);
            let to = make_account("A002", 500.0);
            let result = transfer(from, to, 300.0);
            assert!(result.success);
            assert_eq!(get_balance(&result.from), 700.0);
            assert_eq!(get_balance(&result.to), 800.0);
        }

        #[test]
        fn transfer_fails_with_insufficient_funds() {
            let from = make_account("A001", 100.0);
            let to = make_account("A002", 500.0);
            let result = transfer(from, to, 300.0);
            assert!(!result.success);
            assert_eq!(result.error, Some("Insufficient funds".to_string()));
        }

        #[test]
        fn transfer_fails_with_negative_amount() {
            let from = make_account("A001", 1000.0);
            let to = make_account("A002", 500.0);
            let result = transfer(from, to, -100.0);
            assert!(!result.success);
            assert_eq!(result.error, Some("Amount must be positive".to_string()));
        }
    }

    mod migration_strategies_tests {
        use super::migration_strategies;
        use super::migration_strategies::*;

        #[test]
        fn strangler_pattern_fp_mode() {
            let account = create_account_strangler("A001", 1000.0, true);
            assert_eq!(account.style, Style::FP);
            assert_eq!(account.data.balance, 1000.0);
        }

        #[test]
        fn strangler_pattern_oo_mode() {
            let account = create_account_strangler("A001", 1000.0, false);
            assert_eq!(account.style, Style::OO);
        }

        #[test]
        fn strangler_deposit() {
            let account = create_account_strangler("A001", 1000.0, true);
            let updated = account_deposit(account, 500.0);
            assert_eq!(updated.data.balance, 1500.0);
        }

        #[test]
        fn adapter_maintains_interface() {
            let mut adapter = make_fp_account_adapter("A001", 1000.0);
            assert_eq!(adapter.deposit_to_account(500.0), 1500.0);
            assert_eq!(adapter.get_account_balance(), 1500.0);
        }

        #[test]
        fn adapter_withdraw() {
            let mut adapter = make_fp_account_adapter("A001", 1000.0);
            assert_eq!(adapter.withdraw_from_account(300.0), 700.0);
        }

        #[test]
        fn adapter_internal_fp_style() {
            let mut adapter = make_fp_account_adapter("A001", 1000.0);
            adapter.deposit_to_account(500.0);
            assert_eq!(adapter.get_account().transactions.len(), 1);
        }

        #[test]
        fn test_replay_events() {
            let mut created_data = std::collections::HashMap::new();
            created_data.insert("id".to_string(), "A001".to_string());
            created_data.insert("balance".to_string(), "0".to_string());

            let mut deposit_data = std::collections::HashMap::new();
            deposit_data.insert("amount".to_string(), "1000".to_string());

            let mut withdraw_data = std::collections::HashMap::new();
            withdraw_data.insert("amount".to_string(), "300".to_string());

            let events = vec![
                account_event(EventType::Created, created_data),
                account_event(EventType::Deposited, deposit_data),
                account_event(EventType::Withdrawn, withdraw_data),
            ];

            let account = migration_strategies::replay_events(&events);
            assert_eq!(account.balance, 700.0);
        }

        #[test]
        fn calculate_interest_test() {
            let interest = calculate_interest(10000.0, 0.05, 365);
            assert!((interest - 500.0).abs() < 0.01);
        }

        #[test]
        fn calculate_fee_low_balance() {
            let fee_structure = FeeStructure {
                minimum_balance: 1000.0,
                low_balance_fee: 25.0,
                premium_threshold: 10000.0,
                standard_fee: 10.0,
            };
            assert_eq!(calculate_fee(500.0, &fee_structure), 25.0);
        }

        #[test]
        fn calculate_fee_standard() {
            let fee_structure = FeeStructure {
                minimum_balance: 1000.0,
                low_balance_fee: 25.0,
                premium_threshold: 10000.0,
                standard_fee: 10.0,
            };
            assert_eq!(calculate_fee(5000.0, &fee_structure), 10.0);
        }

        #[test]
        fn calculate_fee_premium() {
            let fee_structure = FeeStructure {
                minimum_balance: 1000.0,
                low_balance_fee: 25.0,
                premium_threshold: 10000.0,
                standard_fee: 10.0,
            };
            assert_eq!(calculate_fee(15000.0, &fee_structure), 0.0);
        }

        #[test]
        fn process_transaction_deposit() {
            use super::fp_style::*;
            let account = make_account("A001", 1000.0);
            let rules = TransactionRules {
                overdraft_limit: 0.0,
            };
            let result = process_transaction(account, TransactionType::Deposit, 500.0, &rules);
            assert!(result.success);
            assert_eq!(result.account.balance, 1500.0);
        }

        #[test]
        fn process_transaction_withdrawal_success() {
            use super::fp_style::*;
            let account = make_account("A001", 1000.0);
            let rules = TransactionRules {
                overdraft_limit: 0.0,
            };
            let result = process_transaction(account, TransactionType::Withdrawal, 500.0, &rules);
            assert!(result.success);
            assert_eq!(result.account.balance, 500.0);
        }

        #[test]
        fn process_transaction_withdrawal_failure() {
            use super::fp_style::*;
            let account = make_account("A001", 1000.0);
            let rules = TransactionRules {
                overdraft_limit: 0.0,
            };
            let result = process_transaction(account, TransactionType::Withdrawal, 1500.0, &rules);
            assert!(!result.success);
            assert_eq!(result.error, Some("Insufficient funds".to_string()));
        }
    }

    mod polymorphism_tests {
        use super::polymorphism::*;

        #[test]
        fn circle_area() {
            let circle = Shape::Circle {
                x: 0.0,
                y: 0.0,
                radius: 10.0,
            };
            assert!((area(&circle) - std::f64::consts::PI * 100.0).abs() < 0.01);
        }

        #[test]
        fn rectangle_area() {
            let rect = Shape::Rectangle {
                x: 0.0,
                y: 0.0,
                width: 10.0,
                height: 20.0,
            };
            assert_eq!(area(&rect), 200.0);
        }

        #[test]
        fn triangle_area() {
            let triangle = Shape::Triangle {
                x: 0.0,
                y: 0.0,
                base: 10.0,
                height: 8.0,
            };
            assert_eq!(area(&triangle), 40.0);
        }

        #[test]
        fn scale_circle() {
            let circle = Shape::Circle {
                x: 0.0,
                y: 0.0,
                radius: 10.0,
            };
            let scaled = scale(&circle, 2.0);
            if let Shape::Circle { radius, .. } = scaled {
                assert_eq!(radius, 20.0);
            } else {
                panic!("Expected Circle");
            }
        }

        #[test]
        fn scale_rectangle() {
            let rect = Shape::Rectangle {
                x: 0.0,
                y: 0.0,
                width: 10.0,
                height: 20.0,
            };
            let scaled = scale(&rect, 0.5);
            if let Shape::Rectangle { width, height, .. } = scaled {
                assert_eq!(width, 5.0);
                assert_eq!(height, 10.0);
            } else {
                panic!("Expected Rectangle");
            }
        }

        #[test]
        fn move_circle() {
            let circle = Shape::Circle {
                x: 0.0,
                y: 0.0,
                radius: 10.0,
            };
            let moved = translate(&circle, 5.0, 3.0);
            if let Shape::Circle { x, y, radius } = moved {
                assert_eq!(x, 5.0);
                assert_eq!(y, 3.0);
                assert_eq!(radius, 10.0);
            } else {
                panic!("Expected Circle");
            }
        }

        #[test]
        fn move_rectangle() {
            let rect = Shape::Rectangle {
                x: 0.0,
                y: 0.0,
                width: 10.0,
                height: 20.0,
            };
            let moved = translate(&rect, 5.0, 3.0);
            if let Shape::Rectangle { x, y, .. } = moved {
                assert_eq!(x, 5.0);
                assert_eq!(y, 3.0);
            } else {
                panic!("Expected Rectangle");
            }
        }

        #[test]
        fn circle_perimeter() {
            let circle = Shape::Circle {
                x: 0.0,
                y: 0.0,
                radius: 10.0,
            };
            assert!((perimeter(&circle) - 2.0 * std::f64::consts::PI * 10.0).abs() < 0.01);
        }

        #[test]
        fn rectangle_perimeter() {
            let rect = Shape::Rectangle {
                x: 0.0,
                y: 0.0,
                width: 10.0,
                height: 20.0,
            };
            assert_eq!(perimeter(&rect), 60.0);
        }
    }

    mod event_driven_tests {
        use super::event_driven::*;

        #[test]
        fn create_event_system() {
            let system: EventSystem<String> = EventSystem::new();
            assert!(system.handlers.is_empty());
            assert!(system.event_log.is_empty());
        }

        #[test]
        fn subscribe_handler() {
            let system: EventSystem<String> = EventSystem::new();
            let updated = system.subscribe("test", |_| "handled".to_string());
            assert_eq!(updated.handlers.get("test").map(|h| h.len()), Some(1));
        }

        #[test]
        fn subscribe_multiple_handlers() {
            let system: EventSystem<String> = EventSystem::new();
            let updated = system
                .subscribe("test", |_| "1".to_string())
                .subscribe("test", |_| "2".to_string());
            assert_eq!(updated.handlers.get("test").map(|h| h.len()), Some(2));
        }

        #[test]
        fn publish_event() {
            let system: EventSystem<String> = EventSystem::new();
            let subscribed = system.subscribe("greeting", |e: &Event<String>| {
                format!("Hello, {}", e.data)
            });
            let (_, results) = subscribed.publish("greeting", "World".to_string());
            assert_eq!(results.len(), 1);
            assert_eq!(results[0], "Hello, World");
        }

        #[test]
        fn event_log_recorded() {
            let system: EventSystem<String> = EventSystem::new();
            let subscribed = system.subscribe("test", |_| "ok".to_string());
            let (new_system, _) = subscribed.publish("test", "data1".to_string());
            let (final_system, _) = new_system.publish("test", "data2".to_string());
            assert_eq!(final_system.get_event_log().len(), 2);
        }
    }

    mod practical_migration_tests {
        use super::practical_migration::*;

        #[test]
        fn create_user_success() {
            match create_user("U001", "John", "john@example.com") {
                CreateUserResult::UserCreated(user) => {
                    assert_eq!(user.name, "John");
                    assert!(user.active);
                }
                _ => panic!("Should succeed"),
            }
        }

        #[test]
        fn create_user_validation_error() {
            match create_user("", "", "invalid") {
                CreateUserResult::UserCreationFailed(errors) => {
                    assert!(errors.contains(&"Name is required".to_string()));
                    assert!(errors.contains(&"Invalid email".to_string()));
                    assert!(errors.contains(&"ID is required".to_string()));
                }
                _ => panic!("Should fail"),
            }
        }

        #[test]
        fn user_id_value_object() {
            let id = UserId::new("U001");
            assert_eq!(id.value(), "U001");
        }

        #[test]
        fn email_validation() {
            assert!(Email::new("valid@example.com").is_ok());
            assert!(Email::new("invalid").is_err());
        }

        #[test]
        fn repository_save() {
            let user = User {
                id: UserId::new("U001"),
                name: "John".to_string(),
                email: "john@example.com".to_string(),
                active: true,
            };
            let repo = UserRepository::new().save(user.clone());
            if let RepositoryResult::Found(found) = repo.find_by_id(&UserId::new("U001")) {
                assert_eq!(found.name, "John");
            } else {
                panic!("Should find user");
            }
        }

        #[test]
        fn repository_not_found() {
            let repo = UserRepository::new();
            assert!(matches!(
                repo.find_by_id(&UserId::new("U001")),
                RepositoryResult::NotFound
            ));
        }

        #[test]
        fn repository_update() {
            let user = User {
                id: UserId::new("U001"),
                name: "John".to_string(),
                email: "john@example.com".to_string(),
                active: true,
            };
            let repo = UserRepository::new().save(user);
            let updated = repo.update(&UserId::new("U001"), |u| User {
                name: "Jane".to_string(),
                ..u
            });
            if let RepositoryResult::Found(found) = updated.find_by_id(&UserId::new("U001")) {
                assert_eq!(found.name, "Jane");
            } else {
                panic!("Should find user");
            }
        }

        #[test]
        fn repository_delete() {
            let user = User {
                id: UserId::new("U001"),
                name: "John".to_string(),
                email: "john@example.com".to_string(),
                active: true,
            };
            let repo = UserRepository::new().save(user).delete(&UserId::new("U001"));
            assert!(matches!(
                repo.find_by_id(&UserId::new("U001")),
                RepositoryResult::NotFound
            ));
        }

        #[test]
        fn repository_find_all() {
            let repo = UserRepository::new()
                .save(User {
                    id: UserId::new("U001"),
                    name: "John".to_string(),
                    email: "john@example.com".to_string(),
                    active: true,
                })
                .save(User {
                    id: UserId::new("U002"),
                    name: "Jane".to_string(),
                    email: "jane@example.com".to_string(),
                    active: true,
                });
            assert_eq!(repo.find_all().len(), 2);
        }

        #[test]
        fn service_register_user() {
            let repo = UserRepository::new();
            match user_service::register_user(repo, "U001", "John", "john@example.com") {
                Ok(result) => {
                    assert_eq!(result.value.name, "John");
                    assert!(matches!(
                        result.repository.find_by_id(&UserId::new("U001")),
                        RepositoryResult::Found(_)
                    ));
                }
                Err(_) => panic!("Should succeed"),
            }
        }

        #[test]
        fn service_register_user_failure() {
            let repo = UserRepository::new();
            match user_service::register_user(repo, "", "", "invalid") {
                Err(errors) => assert!(!errors.is_empty()),
                Ok(_) => panic!("Should fail"),
            }
        }

        #[test]
        fn service_deactivate_user() {
            let user = User {
                id: UserId::new("U001"),
                name: "John".to_string(),
                email: "john@example.com".to_string(),
                active: true,
            };
            let repo = UserRepository::new().save(user);
            match user_service::deactivate_user(repo, &UserId::new("U001")) {
                Ok(result) => {
                    assert!(!result.value.active);
                }
                Err(_) => panic!("Should succeed"),
            }
        }

        #[test]
        fn service_get_active_users() {
            let repo = UserRepository::new()
                .save(User {
                    id: UserId::new("U001"),
                    name: "John".to_string(),
                    email: "john@example.com".to_string(),
                    active: true,
                })
                .save(User {
                    id: UserId::new("U002"),
                    name: "Jane".to_string(),
                    email: "jane@example.com".to_string(),
                    active: false,
                });
            assert_eq!(user_service::get_all_active_users(&repo).len(), 1);
        }

        #[test]
        fn pipe_operator() {
            let result = 10.pipe(|x| x * 2).pipe(|x| x + 5);
            assert_eq!(result, 25);
        }

        #[test]
        fn transform_user_data_test() {
            let users = vec![
                User {
                    id: UserId::new("U001"),
                    name: "Alice".to_string(),
                    email: "alice@example.com".to_string(),
                    active: true,
                },
                User {
                    id: UserId::new("U002"),
                    name: "Bob".to_string(),
                    email: "bob@example.com".to_string(),
                    active: true,
                },
                User {
                    id: UserId::new("U003"),
                    name: "Anna".to_string(),
                    email: "anna@example.com".to_string(),
                    active: false,
                },
            ];
            let grouped = transform_user_data(users);
            assert_eq!(grouped.get("A"), Some(&vec!["alice@example.com".to_string()]));
            assert_eq!(grouped.get("B"), Some(&vec!["bob@example.com".to_string()]));
            assert!(grouped.get("A").map(|v| !v.contains(&"anna@example.com".to_string())).unwrap_or(true));
        }
    }

    mod migration_checklist_tests {
        use super::migration_checklist::*;

        #[test]
        fn default_checklist_exists() {
            let checklist = default_checklist();
            assert_eq!(checklist.preparation.len(), 4);
            assert_eq!(checklist.execution.len(), 4);
            assert_eq!(checklist.completion.len(), 4);
        }

        #[test]
        fn mark_item_completed() {
            let checklist = default_checklist();
            let updated = mark_completed(checklist, "preparation", 0);
            assert!(updated.preparation[0].completed);
        }

        #[test]
        fn calculate_progress_zero() {
            let checklist = default_checklist();
            assert_eq!(calculate_progress(&checklist), 0.0);
        }

        #[test]
        fn calculate_progress_partial() {
            let checklist = default_checklist();
            let updated = mark_completed(checklist, "preparation", 0);
            let progress = calculate_progress(&updated);
            assert!((progress - 100.0 / 12.0).abs() < 0.1);
        }

        #[test]
        fn calculate_progress_complete() {
            let mut checklist = default_checklist();
            for i in 0..4 {
                checklist = mark_completed(checklist, "preparation", i);
                checklist = mark_completed(checklist, "execution", i);
                checklist = mark_completed(checklist, "completion", i);
            }
            assert_eq!(calculate_progress(&checklist), 100.0);
        }
    }

    mod comparison_tests {
        use super::comparison::*;

        #[test]
        fn comparison_table_defined() {
            let table = comparison_table();
            assert_eq!(table.len(), 8);
        }

        #[test]
        fn each_item_has_oo_and_fp() {
            for item in comparison_table() {
                assert!(!item.oo.is_empty());
                assert!(!item.fp.is_empty());
            }
        }

        #[test]
        fn count_fp_advantages() {
            let advantages = count_advantages();
            assert_eq!(advantages.get("FP"), Some(&8));
        }
    }
}
