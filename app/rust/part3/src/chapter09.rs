//! 第9章: Adapter パターン
//!
//! Adapter パターンは、既存のクラスのインターフェースを、
//! クライアントが期待する別のインターフェースに変換するパターンです。

use std::collections::HashMap;

// =============================================================================
// 1. Switchable インターフェース (Target)
// =============================================================================

/// スイッチの共通 trait
pub trait Switchable {
    fn turn_on(&self) -> Box<dyn Switchable>;
    fn turn_off(&self) -> Box<dyn Switchable>;
    fn is_on(&self) -> bool;
}

// =============================================================================
// 2. VariableLight (Adaptee)
// =============================================================================

/// 可変強度ライト - 強度を0-100で設定する既存クラス
#[derive(Debug, Clone, PartialEq)]
pub struct VariableLight {
    pub intensity: u8,
}

impl VariableLight {
    pub fn new(intensity: u8) -> VariableLight {
        VariableLight {
            intensity: intensity.min(100),
        }
    }

    pub fn set_intensity(&self, value: u8) -> VariableLight {
        VariableLight::new(value.min(100))
    }

    pub fn brighten(&self, amount: u8) -> VariableLight {
        self.set_intensity(self.intensity.saturating_add(amount))
    }

    pub fn dim(&self, amount: u8) -> VariableLight {
        self.set_intensity(self.intensity.saturating_sub(amount))
    }
}

// =============================================================================
// 3. VariableLightAdapter (Adapter)
// =============================================================================

/// VariableLight を Switchable インターフェースに適応させるアダプター
#[derive(Debug, Clone, PartialEq)]
pub struct VariableLightAdapter {
    pub light: VariableLight,
    pub min_intensity: u8,
    pub max_intensity: u8,
}

impl VariableLightAdapter {
    pub fn new(min_intensity: u8, max_intensity: u8) -> VariableLightAdapter {
        VariableLightAdapter {
            light: VariableLight::new(min_intensity),
            min_intensity,
            max_intensity,
        }
    }

    pub fn from_light(light: VariableLight) -> VariableLightAdapter {
        VariableLightAdapter {
            light,
            min_intensity: 0,
            max_intensity: 100,
        }
    }

    pub fn turn_on_immutable(&self) -> VariableLightAdapter {
        VariableLightAdapter {
            light: self.light.set_intensity(self.max_intensity),
            min_intensity: self.min_intensity,
            max_intensity: self.max_intensity,
        }
    }

    pub fn turn_off_immutable(&self) -> VariableLightAdapter {
        VariableLightAdapter {
            light: self.light.set_intensity(self.min_intensity),
            min_intensity: self.min_intensity,
            max_intensity: self.max_intensity,
        }
    }

    pub fn is_on(&self) -> bool {
        self.light.intensity > self.min_intensity
    }

    pub fn get_intensity(&self) -> u8 {
        self.light.intensity
    }
}

// =============================================================================
// 4. データフォーマットアダプター
// =============================================================================

/// 旧ユーザーフォーマット
#[derive(Debug, Clone, PartialEq)]
pub struct OldUserFormat {
    pub first_name: String,
    pub last_name: String,
    pub email_address: String,
    pub phone_number: String,
}

/// 新ユーザーフォーマット
#[derive(Debug, Clone, PartialEq)]
pub struct NewUserFormat {
    pub name: String,
    pub email: String,
    pub phone: String,
    pub metadata: HashMap<String, String>,
}

/// ユーザーフォーマットアダプター
pub struct UserFormatAdapter;

impl UserFormatAdapter {
    /// 旧フォーマット → 新フォーマット
    pub fn adapt_old_to_new(old: &OldUserFormat) -> NewUserFormat {
        let mut metadata = HashMap::new();
        metadata.insert("migrated".to_string(), "true".to_string());
        metadata.insert("original_format".to_string(), "old".to_string());

        NewUserFormat {
            name: format!("{} {}", old.last_name, old.first_name),
            email: old.email_address.clone(),
            phone: old.phone_number.clone(),
            metadata,
        }
    }

    /// 新フォーマット → 旧フォーマット
    pub fn adapt_new_to_old(new_user: &NewUserFormat) -> OldUserFormat {
        let name_parts: Vec<&str> = new_user.name.splitn(2, ' ').collect();
        let last_name = name_parts.first().unwrap_or(&"").to_string();
        let first_name = name_parts.get(1).unwrap_or(&"").to_string();

        OldUserFormat {
            first_name,
            last_name,
            email_address: new_user.email.clone(),
            phone_number: new_user.phone.clone(),
        }
    }
}

// =============================================================================
// 5. 温度単位アダプター
// =============================================================================

/// 摂氏温度
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Celsius(pub f64);

/// 華氏温度
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Fahrenheit(pub f64);

/// ケルビン温度
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Kelvin(pub f64);

/// 温度変換アダプター
pub struct TemperatureAdapter;

impl TemperatureAdapter {
    pub fn celsius_to_fahrenheit(c: Celsius) -> Fahrenheit {
        Fahrenheit(c.0 * 9.0 / 5.0 + 32.0)
    }

    pub fn fahrenheit_to_celsius(f: Fahrenheit) -> Celsius {
        Celsius((f.0 - 32.0) * 5.0 / 9.0)
    }

    pub fn celsius_to_kelvin(c: Celsius) -> Kelvin {
        Kelvin(c.0 + 273.15)
    }

    pub fn kelvin_to_celsius(k: Kelvin) -> Celsius {
        Celsius(k.0 - 273.15)
    }

    pub fn fahrenheit_to_kelvin(f: Fahrenheit) -> Kelvin {
        Self::celsius_to_kelvin(Self::fahrenheit_to_celsius(f))
    }

    pub fn kelvin_to_fahrenheit(k: Kelvin) -> Fahrenheit {
        Self::celsius_to_fahrenheit(Self::kelvin_to_celsius(k))
    }
}

// =============================================================================
// 6. 日時フォーマットアダプター
// =============================================================================

/// 日時アダプター
pub struct DateTimeAdapter;

impl DateTimeAdapter {
    /// Unix タイムスタンプ → ISO 8601 文字列（簡易版）
    pub fn from_unix_timestamp(timestamp: i64) -> String {
        // 簡易実装: 実際のプロジェクトでは chrono クレートを使用
        format!("{}", timestamp)
    }

    /// 日付文字列のフォーマット変換
    pub fn convert_format(date_str: &str, from_format: &str, to_format: &str) -> Option<String> {
        // 簡易実装: YYYY-MM-DD ⇔ DD/MM/YYYY の変換
        match (from_format, to_format) {
            ("YYYY-MM-DD", "DD/MM/YYYY") => {
                let parts: Vec<&str> = date_str.split('-').collect();
                if parts.len() == 3 {
                    Some(format!("{}/{}/{}", parts[2], parts[1], parts[0]))
                } else {
                    None
                }
            }
            ("DD/MM/YYYY", "YYYY-MM-DD") => {
                let parts: Vec<&str> = date_str.split('/').collect();
                if parts.len() == 3 {
                    Some(format!("{}-{}-{}", parts[2], parts[1], parts[0]))
                } else {
                    None
                }
            }
            _ => None,
        }
    }
}

// =============================================================================
// 7. ファイルシステムアダプター
// =============================================================================

/// ローカルファイルシステム（既存インターフェース）
pub trait LocalFileSystem {
    fn read_file(&self, path: &str) -> Result<String, String>;
    fn write_file(&self, path: &str, content: &str) -> Result<(), String>;
    fn delete_file(&self, path: &str) -> Result<(), String>;
    fn exists(&self, path: &str) -> bool;
}

/// クラウドストレージ（異なるインターフェース）
pub trait CloudStorage {
    fn get_object(&self, bucket: &str, key: &str) -> Result<Vec<u8>, String>;
    fn put_object(&self, bucket: &str, key: &str, data: &[u8]) -> Result<(), String>;
    fn delete_object(&self, bucket: &str, key: &str) -> Result<(), String>;
    fn object_exists(&self, bucket: &str, key: &str) -> bool;
}

/// インメモリクラウドストレージ（テスト用）
#[derive(Default)]
pub struct InMemoryCloudStorage {
    storage: std::cell::RefCell<HashMap<(String, String), Vec<u8>>>,
}

impl InMemoryCloudStorage {
    pub fn new() -> Self {
        InMemoryCloudStorage {
            storage: std::cell::RefCell::new(HashMap::new()),
        }
    }
}

impl CloudStorage for InMemoryCloudStorage {
    fn get_object(&self, bucket: &str, key: &str) -> Result<Vec<u8>, String> {
        self.storage
            .borrow()
            .get(&(bucket.to_string(), key.to_string()))
            .cloned()
            .ok_or_else(|| format!("{}/{} not found", bucket, key))
    }

    fn put_object(&self, bucket: &str, key: &str, data: &[u8]) -> Result<(), String> {
        self.storage
            .borrow_mut()
            .insert((bucket.to_string(), key.to_string()), data.to_vec());
        Ok(())
    }

    fn delete_object(&self, bucket: &str, key: &str) -> Result<(), String> {
        self.storage
            .borrow_mut()
            .remove(&(bucket.to_string(), key.to_string()));
        Ok(())
    }

    fn object_exists(&self, bucket: &str, key: &str) -> bool {
        self.storage
            .borrow()
            .contains_key(&(bucket.to_string(), key.to_string()))
    }
}

/// クラウドストレージをローカルファイルシステムとして使用するアダプター
pub struct CloudStorageAdapter<C: CloudStorage> {
    cloud_storage: C,
    bucket: String,
}

impl<C: CloudStorage> CloudStorageAdapter<C> {
    pub fn new(cloud_storage: C, bucket: &str) -> Self {
        CloudStorageAdapter {
            cloud_storage,
            bucket: bucket.to_string(),
        }
    }
}

impl<C: CloudStorage> LocalFileSystem for CloudStorageAdapter<C> {
    fn read_file(&self, path: &str) -> Result<String, String> {
        let data = self.cloud_storage.get_object(&self.bucket, path)?;
        String::from_utf8(data).map_err(|e| e.to_string())
    }

    fn write_file(&self, path: &str, content: &str) -> Result<(), String> {
        self.cloud_storage
            .put_object(&self.bucket, path, content.as_bytes())
    }

    fn delete_file(&self, path: &str) -> Result<(), String> {
        self.cloud_storage.delete_object(&self.bucket, path)
    }

    fn exists(&self, path: &str) -> bool {
        self.cloud_storage.object_exists(&self.bucket, path)
    }
}

// =============================================================================
// 8. ロガーアダプター
// =============================================================================

/// 標準ロガーインターフェース
pub trait StandardLogger {
    fn debug(&self, message: &str);
    fn info(&self, message: &str);
    fn warn(&self, message: &str);
    fn error(&self, message: &str);
}

/// レガシーロガー（異なるインターフェース）
pub trait LegacyLogger {
    fn log(&self, level: u8, message: &str);
}

pub const LOG_LEVEL_DEBUG: u8 = 0;
pub const LOG_LEVEL_INFO: u8 = 1;
pub const LOG_LEVEL_WARN: u8 = 2;
pub const LOG_LEVEL_ERROR: u8 = 3;

/// テスト用レガシーロガー
#[derive(Default)]
pub struct TestLegacyLogger {
    logs: std::cell::RefCell<Vec<(u8, String)>>,
}

impl TestLegacyLogger {
    pub fn new() -> Self {
        TestLegacyLogger {
            logs: std::cell::RefCell::new(Vec::new()),
        }
    }

    pub fn get_logs(&self) -> Vec<(u8, String)> {
        self.logs.borrow().clone()
    }

    pub fn clear(&self) {
        self.logs.borrow_mut().clear();
    }
}

impl LegacyLogger for TestLegacyLogger {
    fn log(&self, level: u8, message: &str) {
        self.logs.borrow_mut().push((level, message.to_string()));
    }
}

/// レガシーロガーを標準ロガーとして使用するアダプター
pub struct LegacyLoggerAdapter<L: LegacyLogger> {
    legacy_logger: L,
}

impl<L: LegacyLogger> LegacyLoggerAdapter<L> {
    pub fn new(legacy_logger: L) -> Self {
        LegacyLoggerAdapter { legacy_logger }
    }
}

impl<L: LegacyLogger> StandardLogger for LegacyLoggerAdapter<L> {
    fn debug(&self, message: &str) {
        self.legacy_logger.log(LOG_LEVEL_DEBUG, message);
    }

    fn info(&self, message: &str) {
        self.legacy_logger.log(LOG_LEVEL_INFO, message);
    }

    fn warn(&self, message: &str) {
        self.legacy_logger.log(LOG_LEVEL_WARN, message);
    }

    fn error(&self, message: &str) {
        self.legacy_logger.log(LOG_LEVEL_ERROR, message);
    }
}

/// 参照用 LegacyLogger 実装
impl<L: LegacyLogger> LegacyLogger for &L {
    fn log(&self, level: u8, message: &str) {
        (*self).log(level, message);
    }
}

// =============================================================================
// 9. 通貨アダプター
// =============================================================================

/// 通貨
#[derive(Debug, Clone, PartialEq)]
pub struct Money {
    pub amount: f64,
    pub currency: String,
}

impl Money {
    pub fn new(amount: f64, currency: &str) -> Money {
        Money {
            amount,
            currency: currency.to_string(),
        }
    }
}

/// 為替レートプロバイダー
pub trait ExchangeRateProvider {
    fn get_rate(&self, from: &str, to: &str) -> Option<f64>;
}

/// 固定レートプロバイダー（テスト用）
pub struct FixedRateProvider {
    rates: HashMap<(String, String), f64>,
}

impl FixedRateProvider {
    pub fn new(rates: Vec<((&str, &str), f64)>) -> Self {
        let rates = rates
            .into_iter()
            .map(|((from, to), rate)| ((from.to_string(), to.to_string()), rate))
            .collect();
        FixedRateProvider { rates }
    }
}

impl ExchangeRateProvider for FixedRateProvider {
    fn get_rate(&self, from: &str, to: &str) -> Option<f64> {
        if from == to {
            return Some(1.0);
        }
        self.rates
            .get(&(from.to_string(), to.to_string()))
            .cloned()
            .or_else(|| {
                self.rates
                    .get(&(to.to_string(), from.to_string()))
                    .map(|r| 1.0 / r)
            })
    }
}

/// 通貨変換アダプター
pub struct CurrencyAdapter<P: ExchangeRateProvider> {
    rate_provider: P,
}

impl<P: ExchangeRateProvider> CurrencyAdapter<P> {
    pub fn new(rate_provider: P) -> Self {
        CurrencyAdapter { rate_provider }
    }

    pub fn convert(&self, money: &Money, to_currency: &str) -> Option<Money> {
        if money.currency == to_currency {
            return Some(money.clone());
        }
        self.rate_provider
            .get_rate(&money.currency, to_currency)
            .map(|rate| Money::new(money.amount * rate, to_currency))
    }
}

// =============================================================================
// 10. 関数アダプター
// =============================================================================

/// 関数アダプター
pub struct FunctionAdapter;

impl FunctionAdapter {
    /// (A, B) => C を A => B => C にカリー化
    pub fn curry<A, B, C, F>(f: F) -> impl Fn(A) -> Box<dyn Fn(B) -> C>
    where
        F: Fn(A, B) -> C + Clone + 'static,
        A: Clone + 'static,
        B: 'static,
        C: 'static,
    {
        move |a: A| {
            let f = f.clone();
            let a = a.clone();
            Box::new(move |b: B| f(a.clone(), b))
        }
    }

    /// 引数の順序を入れ替え
    pub fn flip<A, B, C, F>(f: F) -> impl Fn(B, A) -> C
    where
        F: Fn(A, B) -> C,
    {
        move |b: B, a: A| f(a, b)
    }

    /// Option を Result に変換
    pub fn option_to_result<A, E>(option: Option<A>, error: E) -> Result<A, E> {
        option.ok_or(error)
    }

    /// Result を Option に変換
    pub fn result_to_option<A, E>(result: Result<A, E>) -> Option<A> {
        result.ok()
    }
}

// =============================================================================
// 11. イテレーターアダプター
// =============================================================================

/// Java 風イテレーター
pub trait JavaStyleIterator {
    type Item;
    fn has_next(&self) -> bool;
    fn next(&mut self) -> Option<Self::Item>;
}

/// 配列の Java 風イテレーター
pub struct ArrayJavaIterator<T: Clone> {
    array: Vec<T>,
    index: usize,
}

impl<T: Clone> ArrayJavaIterator<T> {
    pub fn new(array: Vec<T>) -> Self {
        ArrayJavaIterator { array, index: 0 }
    }
}

impl<T: Clone> JavaStyleIterator for ArrayJavaIterator<T> {
    type Item = T;

    fn has_next(&self) -> bool {
        self.index < self.array.len()
    }

    fn next(&mut self) -> Option<T> {
        if self.has_next() {
            let item = self.array[self.index].clone();
            self.index += 1;
            Some(item)
        } else {
            None
        }
    }
}

/// Java 風イテレーターを Rust イテレーターに変換するアダプター
pub struct JavaIteratorAdapter<J: JavaStyleIterator> {
    java_iter: J,
}

impl<J: JavaStyleIterator> JavaIteratorAdapter<J> {
    pub fn new(java_iter: J) -> Self {
        JavaIteratorAdapter { java_iter }
    }
}

impl<J: JavaStyleIterator> Iterator for JavaIteratorAdapter<J> {
    type Item = J::Item;

    fn next(&mut self) -> Option<Self::Item> {
        self.java_iter.next()
    }
}

// =============================================================================
// テスト
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    // -------------------------------------------------------------------------
    // VariableLight / VariableLightAdapter テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_variable_light_intensity() {
        let light = VariableLight::new(50);
        assert_eq!(light.intensity, 50);

        let brightened = light.brighten(30);
        assert_eq!(brightened.intensity, 80);

        let dimmed = brightened.dim(40);
        assert_eq!(dimmed.intensity, 40);
    }

    #[test]
    fn test_variable_light_adapter_on_off() {
        let adapter = VariableLightAdapter::new(0, 100);
        assert!(!adapter.is_on());

        let on = adapter.turn_on_immutable();
        assert!(on.is_on());
        assert_eq!(on.get_intensity(), 100);

        let off = on.turn_off_immutable();
        assert!(!off.is_on());
        assert_eq!(off.get_intensity(), 0);
    }

    #[test]
    fn test_variable_light_adapter_custom_range() {
        let adapter = VariableLightAdapter::new(10, 80);
        let on = adapter.turn_on_immutable();
        assert_eq!(on.get_intensity(), 80);

        let off = on.turn_off_immutable();
        assert_eq!(off.get_intensity(), 10);
        assert!(!off.is_on()); // 10 is min, so not "on"
    }

    // -------------------------------------------------------------------------
    // UserFormatAdapter テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_user_format_old_to_new() {
        let old = OldUserFormat {
            first_name: "太郎".to_string(),
            last_name: "山田".to_string(),
            email_address: "taro@example.com".to_string(),
            phone_number: "090-1234-5678".to_string(),
        };

        let new = UserFormatAdapter::adapt_old_to_new(&old);
        assert_eq!(new.name, "山田 太郎");
        assert_eq!(new.email, "taro@example.com");
        assert!(new.metadata.contains_key("migrated"));
    }

    #[test]
    fn test_user_format_new_to_old() {
        let new = NewUserFormat {
            name: "山田 太郎".to_string(),
            email: "taro@example.com".to_string(),
            phone: "090-1234-5678".to_string(),
            metadata: HashMap::new(),
        };

        let old = UserFormatAdapter::adapt_new_to_old(&new);
        assert_eq!(old.last_name, "山田");
        assert_eq!(old.first_name, "太郎");
    }

    // -------------------------------------------------------------------------
    // TemperatureAdapter テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_celsius_to_fahrenheit() {
        let celsius = Celsius(0.0);
        let fahrenheit = TemperatureAdapter::celsius_to_fahrenheit(celsius);
        assert!((fahrenheit.0 - 32.0).abs() < 0.001);
    }

    #[test]
    fn test_fahrenheit_to_celsius() {
        let fahrenheit = Fahrenheit(212.0);
        let celsius = TemperatureAdapter::fahrenheit_to_celsius(fahrenheit);
        assert!((celsius.0 - 100.0).abs() < 0.001);
    }

    #[test]
    fn test_celsius_to_kelvin() {
        let celsius = Celsius(0.0);
        let kelvin = TemperatureAdapter::celsius_to_kelvin(celsius);
        assert!((kelvin.0 - 273.15).abs() < 0.001);
    }

    #[test]
    fn test_round_trip_temperature() {
        let original = Celsius(25.0);
        let fahrenheit = TemperatureAdapter::celsius_to_fahrenheit(original);
        let back = TemperatureAdapter::fahrenheit_to_celsius(fahrenheit);
        assert!((original.0 - back.0).abs() < 0.001);
    }

    // -------------------------------------------------------------------------
    // DateTimeAdapter テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_date_format_conversion() {
        let iso = "2024-01-15";
        let eu = DateTimeAdapter::convert_format(iso, "YYYY-MM-DD", "DD/MM/YYYY");
        assert_eq!(eu, Some("15/01/2024".to_string()));

        let back = DateTimeAdapter::convert_format(&eu.unwrap(), "DD/MM/YYYY", "YYYY-MM-DD");
        assert_eq!(back, Some("2024-01-15".to_string()));
    }

    // -------------------------------------------------------------------------
    // CloudStorageAdapter テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_cloud_storage_adapter() {
        let cloud = InMemoryCloudStorage::new();
        let fs = CloudStorageAdapter::new(cloud, "my-bucket");

        fs.write_file("test.txt", "Hello, World!").unwrap();
        assert!(fs.exists("test.txt"));

        let content = fs.read_file("test.txt").unwrap();
        assert_eq!(content, "Hello, World!");

        fs.delete_file("test.txt").unwrap();
        assert!(!fs.exists("test.txt"));
    }

    // -------------------------------------------------------------------------
    // LegacyLoggerAdapter テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_legacy_logger_adapter() {
        let legacy = TestLegacyLogger::new();
        let adapter = LegacyLoggerAdapter::new(&legacy);

        adapter.debug("debug message");
        adapter.info("info message");
        adapter.warn("warn message");
        adapter.error("error message");

        let logs = legacy.get_logs();
        assert_eq!(logs.len(), 4);
        assert_eq!(logs[0], (LOG_LEVEL_DEBUG, "debug message".to_string()));
        assert_eq!(logs[3], (LOG_LEVEL_ERROR, "error message".to_string()));
    }

    // -------------------------------------------------------------------------
    // CurrencyAdapter テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_currency_conversion() {
        let rates = FixedRateProvider::new(vec![
            (("USD", "JPY"), 150.0),
            (("EUR", "USD"), 1.1),
        ]);
        let adapter = CurrencyAdapter::new(rates);

        let usd = Money::new(100.0, "USD");
        let jpy = adapter.convert(&usd, "JPY").unwrap();
        assert!((jpy.amount - 15000.0).abs() < 0.001);
        assert_eq!(jpy.currency, "JPY");
    }

    #[test]
    fn test_currency_same_currency() {
        let rates = FixedRateProvider::new(vec![]);
        let adapter = CurrencyAdapter::new(rates);

        let usd = Money::new(100.0, "USD");
        let result = adapter.convert(&usd, "USD").unwrap();
        assert_eq!(result.amount, 100.0);
    }

    // -------------------------------------------------------------------------
    // FunctionAdapter テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_function_curry() {
        let add = |a: i32, b: i32| a + b;
        let curried = FunctionAdapter::curry(add);
        let add_5 = curried(5);
        assert_eq!(add_5(3), 8);
    }

    #[test]
    fn test_function_flip() {
        let divide = |a: f64, b: f64| a / b;
        let flipped = FunctionAdapter::flip(divide);
        assert_eq!(flipped(2.0, 10.0), 5.0);
    }

    #[test]
    fn test_option_to_result() {
        let some: Option<i32> = Some(42);
        let result = FunctionAdapter::option_to_result(some, "error");
        assert_eq!(result, Ok(42));

        let none: Option<i32> = None;
        let result = FunctionAdapter::option_to_result(none, "error");
        assert_eq!(result, Err("error"));
    }

    // -------------------------------------------------------------------------
    // JavaIteratorAdapter テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_java_iterator_adapter() {
        let java_iter = ArrayJavaIterator::new(vec![1, 2, 3]);
        let rust_iter = JavaIteratorAdapter::new(java_iter);

        let collected: Vec<i32> = rust_iter.collect();
        assert_eq!(collected, vec![1, 2, 3]);
    }
}
