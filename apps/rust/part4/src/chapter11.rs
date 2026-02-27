//! 第11章: Command パターン
//!
//! Command パターンは、リクエストをオブジェクトとしてカプセル化し、
//! 異なるリクエストでクライアントをパラメータ化できるようにするパターンです。

use std::collections::HashMap;

// =============================================================================
// 1. 基本的な Command パターン
// =============================================================================

/// コマンド trait
pub trait Command {
    fn execute(&self) -> Result<(), String>;
    fn undo(&self) -> Result<(), String>;
    fn name(&self) -> &str;
}

/// テキストエディタ（レシーバー）
#[derive(Debug, Clone, Default)]
pub struct TextEditor {
    pub content: String,
}

impl TextEditor {
    pub fn new() -> Self {
        TextEditor {
            content: String::new(),
        }
    }

    pub fn insert(&mut self, text: &str, position: usize) {
        self.content.insert_str(position.min(self.content.len()), text);
    }

    pub fn delete(&mut self, start: usize, length: usize) -> String {
        let end = (start + length).min(self.content.len());
        let deleted: String = self.content.chars().skip(start).take(end - start).collect();
        self.content = format!(
            "{}{}",
            &self.content[..start.min(self.content.len())],
            &self.content[end.min(self.content.len())..]
        );
        deleted
    }

    pub fn content(&self) -> &str {
        &self.content
    }
}

/// 挿入コマンド
#[derive(Debug, Clone)]
pub struct InsertCommand {
    pub text: String,
    pub position: usize,
}

/// 削除コマンド
#[derive(Debug, Clone)]
pub struct DeleteCommand {
    pub start: usize,
    pub length: usize,
    pub deleted_text: Option<String>,
}

// =============================================================================
// 2. 関数型アプローチ
// =============================================================================

/// イミュータブルなエディタコマンド
#[derive(Debug, Clone, PartialEq)]
pub enum EditorCommand {
    Insert { text: String, position: usize },
    Delete { start: usize, length: usize },
    Replace { start: usize, length: usize, new_text: String },
}

/// エディタ状態
#[derive(Debug, Clone, PartialEq)]
pub struct EditorState {
    pub content: String,
    pub cursor: usize,
}

impl EditorState {
    pub fn new() -> Self {
        EditorState {
            content: String::new(),
            cursor: 0,
        }
    }

    pub fn from_content(content: &str) -> Self {
        EditorState {
            content: content.to_string(),
            cursor: 0,
        }
    }

    /// コマンドを適用
    pub fn apply(&self, command: &EditorCommand) -> EditorState {
        match command {
            EditorCommand::Insert { text, position } => {
                let pos = (*position).min(self.content.len());
                let new_content = format!(
                    "{}{}{}",
                    &self.content[..pos],
                    text,
                    &self.content[pos..]
                );
                EditorState {
                    content: new_content,
                    cursor: pos + text.len(),
                }
            }
            EditorCommand::Delete { start, length } => {
                let s = (*start).min(self.content.len());
                let e = (s + length).min(self.content.len());
                let new_content = format!("{}{}", &self.content[..s], &self.content[e..]);
                EditorState {
                    content: new_content,
                    cursor: s,
                }
            }
            EditorCommand::Replace { start, length, new_text } => {
                let s = (*start).min(self.content.len());
                let e = (s + length).min(self.content.len());
                let new_content = format!("{}{}{}", &self.content[..s], new_text, &self.content[e..]);
                EditorState {
                    content: new_content,
                    cursor: s + new_text.len(),
                }
            }
        }
    }

    /// コマンドの逆を計算
    pub fn inverse(&self, command: &EditorCommand) -> EditorCommand {
        match command {
            EditorCommand::Insert { text, position } => EditorCommand::Delete {
                start: *position,
                length: text.len(),
            },
            EditorCommand::Delete { start, length } => {
                let s = (*start).min(self.content.len());
                let e = (s + length).min(self.content.len());
                let deleted: String = self.content[s..e].to_string();
                EditorCommand::Insert {
                    text: deleted,
                    position: *start,
                }
            }
            EditorCommand::Replace { start, length, new_text } => {
                let s = (*start).min(self.content.len());
                let e = (s + length).min(self.content.len());
                let old_text: String = self.content[s..e].to_string();
                EditorCommand::Replace {
                    start: *start,
                    length: new_text.len(),
                    new_text: old_text,
                }
            }
        }
    }
}

impl Default for EditorState {
    fn default() -> Self {
        Self::new()
    }
}

/// コマンド履歴
#[derive(Debug, Clone)]
pub struct CommandHistory {
    pub states: Vec<EditorState>,
    pub current: usize,
}

impl CommandHistory {
    pub fn new(initial_state: EditorState) -> Self {
        CommandHistory {
            states: vec![initial_state],
            current: 0,
        }
    }

    pub fn current_state(&self) -> &EditorState {
        &self.states[self.current]
    }

    pub fn execute(&self, command: &EditorCommand) -> CommandHistory {
        let new_state = self.current_state().apply(command);
        let mut new_states = self.states[..=self.current].to_vec();
        new_states.push(new_state);
        CommandHistory {
            states: new_states,
            current: self.current + 1,
        }
    }

    pub fn undo(&self) -> Option<CommandHistory> {
        if self.current > 0 {
            Some(CommandHistory {
                states: self.states.clone(),
                current: self.current - 1,
            })
        } else {
            None
        }
    }

    pub fn redo(&self) -> Option<CommandHistory> {
        if self.current + 1 < self.states.len() {
            Some(CommandHistory {
                states: self.states.clone(),
                current: self.current + 1,
            })
        } else {
            None
        }
    }

    pub fn can_undo(&self) -> bool {
        self.current > 0
    }

    pub fn can_redo(&self) -> bool {
        self.current + 1 < self.states.len()
    }
}

// =============================================================================
// 3. マクロコマンド
// =============================================================================

/// マクロ（複数コマンドの組み合わせ）
#[derive(Debug, Clone)]
pub struct MacroCommand {
    pub name: String,
    pub commands: Vec<EditorCommand>,
}

impl MacroCommand {
    pub fn new(name: &str) -> Self {
        MacroCommand {
            name: name.to_string(),
            commands: Vec::new(),
        }
    }

    pub fn add(&self, command: EditorCommand) -> Self {
        let mut new_commands = self.commands.clone();
        new_commands.push(command);
        MacroCommand {
            name: self.name.clone(),
            commands: new_commands,
        }
    }

    pub fn execute(&self, state: &EditorState) -> EditorState {
        self.commands.iter().fold(state.clone(), |s, cmd| s.apply(cmd))
    }
}

// =============================================================================
// 4. 計算コマンド
// =============================================================================

/// 計算コマンド
#[derive(Debug, Clone, PartialEq)]
pub enum CalcCommand {
    Add(f64),
    Subtract(f64),
    Multiply(f64),
    Divide(f64),
    Clear,
}

/// 計算機状態
#[derive(Debug, Clone, PartialEq)]
pub struct Calculator {
    pub value: f64,
}

impl Calculator {
    pub fn new() -> Self {
        Calculator { value: 0.0 }
    }

    pub fn execute(&self, command: &CalcCommand) -> Result<Calculator, String> {
        match command {
            CalcCommand::Add(n) => Ok(Calculator { value: self.value + n }),
            CalcCommand::Subtract(n) => Ok(Calculator { value: self.value - n }),
            CalcCommand::Multiply(n) => Ok(Calculator { value: self.value * n }),
            CalcCommand::Divide(n) => {
                if *n == 0.0 {
                    Err("Division by zero".to_string())
                } else {
                    Ok(Calculator { value: self.value / n })
                }
            }
            CalcCommand::Clear => Ok(Calculator::new()),
        }
    }

    pub fn inverse(command: &CalcCommand) -> CalcCommand {
        match command {
            CalcCommand::Add(n) => CalcCommand::Subtract(*n),
            CalcCommand::Subtract(n) => CalcCommand::Add(*n),
            CalcCommand::Multiply(n) => CalcCommand::Divide(*n),
            CalcCommand::Divide(n) => CalcCommand::Multiply(*n),
            CalcCommand::Clear => CalcCommand::Clear,
        }
    }
}

impl Default for Calculator {
    fn default() -> Self {
        Self::new()
    }
}

// =============================================================================
// 5. トランザクションコマンド
// =============================================================================

/// 銀行口座
#[derive(Debug, Clone, PartialEq)]
pub struct BankAccount {
    pub id: String,
    pub balance: f64,
}

impl BankAccount {
    pub fn new(id: &str, initial_balance: f64) -> Self {
        BankAccount {
            id: id.to_string(),
            balance: initial_balance,
        }
    }
}

/// 銀行取引コマンド
#[derive(Debug, Clone, PartialEq)]
pub enum BankCommand {
    Deposit { account_id: String, amount: f64 },
    Withdraw { account_id: String, amount: f64 },
    Transfer { from_id: String, to_id: String, amount: f64 },
}

/// 銀行状態
#[derive(Debug, Clone)]
pub struct Bank {
    pub accounts: HashMap<String, BankAccount>,
}

impl Bank {
    pub fn new() -> Self {
        Bank {
            accounts: HashMap::new(),
        }
    }

    pub fn add_account(&self, account: BankAccount) -> Bank {
        let mut new_accounts = self.accounts.clone();
        new_accounts.insert(account.id.clone(), account);
        Bank { accounts: new_accounts }
    }

    pub fn execute(&self, command: &BankCommand) -> Result<Bank, String> {
        match command {
            BankCommand::Deposit { account_id, amount } => {
                let account = self.accounts.get(account_id).ok_or("Account not found")?;
                let new_account = BankAccount {
                    balance: account.balance + amount,
                    ..account.clone()
                };
                Ok(self.add_account(new_account))
            }
            BankCommand::Withdraw { account_id, amount } => {
                let account = self.accounts.get(account_id).ok_or("Account not found")?;
                if account.balance < *amount {
                    return Err("Insufficient funds".to_string());
                }
                let new_account = BankAccount {
                    balance: account.balance - amount,
                    ..account.clone()
                };
                Ok(self.add_account(new_account))
            }
            BankCommand::Transfer { from_id, to_id, amount } => {
                let from = self.accounts.get(from_id).ok_or("Source account not found")?;
                let to = self.accounts.get(to_id).ok_or("Destination account not found")?;
                if from.balance < *amount {
                    return Err("Insufficient funds".to_string());
                }
                let new_from = BankAccount {
                    balance: from.balance - amount,
                    ..from.clone()
                };
                let new_to = BankAccount {
                    balance: to.balance + amount,
                    ..to.clone()
                };
                Ok(self.add_account(new_from).add_account(new_to))
            }
        }
    }
}

impl Default for Bank {
    fn default() -> Self {
        Self::new()
    }
}

// =============================================================================
// テスト
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    // -------------------------------------------------------------------------
    // TextEditor テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_text_editor_insert() {
        let mut editor = TextEditor::new();
        editor.insert("Hello", 0);
        assert_eq!(editor.content(), "Hello");

        editor.insert(" World", 5);
        assert_eq!(editor.content(), "Hello World");
    }

    #[test]
    fn test_text_editor_delete() {
        let mut editor = TextEditor::new();
        editor.content = "Hello World".to_string();
        let deleted = editor.delete(5, 6);
        assert_eq!(deleted, " World");
        assert_eq!(editor.content(), "Hello");
    }

    // -------------------------------------------------------------------------
    // EditorState テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_editor_state_insert() {
        let state = EditorState::from_content("Hello");
        let cmd = EditorCommand::Insert {
            text: " World".to_string(),
            position: 5,
        };
        let new_state = state.apply(&cmd);
        assert_eq!(new_state.content, "Hello World");
    }

    #[test]
    fn test_editor_state_delete() {
        let state = EditorState::from_content("Hello World");
        let cmd = EditorCommand::Delete { start: 5, length: 6 };
        let new_state = state.apply(&cmd);
        assert_eq!(new_state.content, "Hello");
    }

    #[test]
    fn test_editor_state_replace() {
        let state = EditorState::from_content("Hello World");
        let cmd = EditorCommand::Replace {
            start: 6,
            length: 5,
            new_text: "Rust".to_string(),
        };
        let new_state = state.apply(&cmd);
        assert_eq!(new_state.content, "Hello Rust");
    }

    // -------------------------------------------------------------------------
    // CommandHistory テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_command_history_execute() {
        let history = CommandHistory::new(EditorState::new());
        let history = history.execute(&EditorCommand::Insert {
            text: "Hello".to_string(),
            position: 0,
        });
        assert_eq!(history.current_state().content, "Hello");
    }

    #[test]
    fn test_command_history_undo() {
        let history = CommandHistory::new(EditorState::new());
        let history = history.execute(&EditorCommand::Insert {
            text: "Hello".to_string(),
            position: 0,
        });
        let history = history.undo().unwrap();
        assert_eq!(history.current_state().content, "");
    }

    #[test]
    fn test_command_history_redo() {
        let history = CommandHistory::new(EditorState::new());
        let history = history.execute(&EditorCommand::Insert {
            text: "Hello".to_string(),
            position: 0,
        });
        let history = history.undo().unwrap();
        let history = history.redo().unwrap();
        assert_eq!(history.current_state().content, "Hello");
    }

    // -------------------------------------------------------------------------
    // MacroCommand テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_macro_command() {
        let macro_cmd = MacroCommand::new("Format")
            .add(EditorCommand::Insert {
                text: "Hello".to_string(),
                position: 0,
            })
            .add(EditorCommand::Insert {
                text: " World".to_string(),
                position: 5,
            });

        let state = EditorState::new();
        let result = macro_cmd.execute(&state);
        assert_eq!(result.content, "Hello World");
    }

    // -------------------------------------------------------------------------
    // Calculator テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_calculator_add() {
        let calc = Calculator::new();
        let calc = calc.execute(&CalcCommand::Add(5.0)).unwrap();
        assert_eq!(calc.value, 5.0);
    }

    #[test]
    fn test_calculator_operations() {
        let calc = Calculator::new()
            .execute(&CalcCommand::Add(10.0)).unwrap()
            .execute(&CalcCommand::Multiply(2.0)).unwrap()
            .execute(&CalcCommand::Subtract(5.0)).unwrap();
        assert_eq!(calc.value, 15.0);
    }

    #[test]
    fn test_calculator_division_by_zero() {
        let calc = Calculator::new().execute(&CalcCommand::Add(10.0)).unwrap();
        let result = calc.execute(&CalcCommand::Divide(0.0));
        assert!(result.is_err());
    }

    #[test]
    fn test_calculator_inverse() {
        let inverse = Calculator::inverse(&CalcCommand::Add(5.0));
        assert_eq!(inverse, CalcCommand::Subtract(5.0));
    }

    // -------------------------------------------------------------------------
    // Bank テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_bank_deposit() {
        let bank = Bank::new().add_account(BankAccount::new("A1", 100.0));
        let bank = bank.execute(&BankCommand::Deposit {
            account_id: "A1".to_string(),
            amount: 50.0,
        }).unwrap();
        assert_eq!(bank.accounts.get("A1").unwrap().balance, 150.0);
    }

    #[test]
    fn test_bank_withdraw() {
        let bank = Bank::new().add_account(BankAccount::new("A1", 100.0));
        let bank = bank.execute(&BankCommand::Withdraw {
            account_id: "A1".to_string(),
            amount: 30.0,
        }).unwrap();
        assert_eq!(bank.accounts.get("A1").unwrap().balance, 70.0);
    }

    #[test]
    fn test_bank_transfer() {
        let bank = Bank::new()
            .add_account(BankAccount::new("A1", 100.0))
            .add_account(BankAccount::new("A2", 50.0));

        let bank = bank.execute(&BankCommand::Transfer {
            from_id: "A1".to_string(),
            to_id: "A2".to_string(),
            amount: 25.0,
        }).unwrap();

        assert_eq!(bank.accounts.get("A1").unwrap().balance, 75.0);
        assert_eq!(bank.accounts.get("A2").unwrap().balance, 75.0);
    }

    #[test]
    fn test_bank_insufficient_funds() {
        let bank = Bank::new().add_account(BankAccount::new("A1", 10.0));
        let result = bank.execute(&BankCommand::Withdraw {
            account_id: "A1".to_string(),
            amount: 50.0,
        });
        assert!(result.is_err());
    }
}
