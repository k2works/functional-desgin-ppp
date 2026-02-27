//! 第8章: Decorator パターン
//!
//! Decorator パターンは、既存のオブジェクトに新しい機能を動的に追加するパターンです。
//! 関数型プログラミングでは、高階関数を使って関数をラップし、横断的関心事を追加します。

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

// =============================================================================
// 1. JournaledShape - 形状デコレータ
// =============================================================================

/// ジャーナルエントリ
#[derive(Debug, Clone, PartialEq)]
pub enum JournalEntry {
    Translate { dx: f64, dy: f64 },
    Scale { factor: f64 },
    Rotate { angle: f64 },
}

/// 基本的な形状 trait
pub trait Shape: Clone {
    fn translate(&self, dx: f64, dy: f64) -> Self;
    fn scale(&self, factor: f64) -> Self;
    fn area(&self) -> f64;
}

/// 円
#[derive(Debug, Clone, PartialEq)]
pub struct Circle {
    pub center_x: f64,
    pub center_y: f64,
    pub radius: f64,
}

impl Circle {
    pub fn new(center_x: f64, center_y: f64, radius: f64) -> Circle {
        Circle {
            center_x,
            center_y,
            radius,
        }
    }
}

impl Shape for Circle {
    fn translate(&self, dx: f64, dy: f64) -> Circle {
        Circle {
            center_x: self.center_x + dx,
            center_y: self.center_y + dy,
            radius: self.radius,
        }
    }

    fn scale(&self, factor: f64) -> Circle {
        Circle {
            center_x: self.center_x,
            center_y: self.center_y,
            radius: self.radius * factor,
        }
    }

    fn area(&self) -> f64 {
        std::f64::consts::PI * self.radius * self.radius
    }
}

/// 正方形
#[derive(Debug, Clone, PartialEq)]
pub struct Square {
    pub x: f64,
    pub y: f64,
    pub side: f64,
}

impl Square {
    pub fn new(x: f64, y: f64, side: f64) -> Square {
        Square { x, y, side }
    }
}

impl Shape for Square {
    fn translate(&self, dx: f64, dy: f64) -> Square {
        Square {
            x: self.x + dx,
            y: self.y + dy,
            side: self.side,
        }
    }

    fn scale(&self, factor: f64) -> Square {
        Square {
            x: self.x,
            y: self.y,
            side: self.side * factor,
        }
    }

    fn area(&self) -> f64 {
        self.side * self.side
    }
}

/// ジャーナル付き形状（デコレータ）
#[derive(Debug, Clone)]
pub struct JournaledShape<S: Shape> {
    pub shape: S,
    pub journal: Vec<JournalEntry>,
}

impl<S: Shape> JournaledShape<S> {
    pub fn new(shape: S) -> JournaledShape<S> {
        JournaledShape {
            shape,
            journal: Vec::new(),
        }
    }

    pub fn with_translate(&self, dx: f64, dy: f64) -> JournaledShape<S> {
        JournaledShape {
            shape: self.shape.translate(dx, dy),
            journal: {
                let mut j = self.journal.clone();
                j.push(JournalEntry::Translate { dx, dy });
                j
            },
        }
    }

    pub fn with_scale(&self, factor: f64) -> JournaledShape<S> {
        JournaledShape {
            shape: self.shape.scale(factor),
            journal: {
                let mut j = self.journal.clone();
                j.push(JournalEntry::Scale { factor });
                j
            },
        }
    }

    pub fn area(&self) -> f64 {
        self.shape.area()
    }

    pub fn clear_journal(&self) -> JournaledShape<S> {
        JournaledShape {
            shape: self.shape.clone(),
            journal: Vec::new(),
        }
    }

    /// ジャーナルを再生
    pub fn replay(&self, entries: &[JournalEntry]) -> JournaledShape<S> {
        entries.iter().fold(self.clone(), |js, entry| match entry {
            JournalEntry::Translate { dx, dy } => js.with_translate(*dx, *dy),
            JournalEntry::Scale { factor } => js.with_scale(*factor),
            JournalEntry::Rotate { .. } => js, // 現在は無視
        })
    }
}

// =============================================================================
// 2. ログ収集器
// =============================================================================

/// ログ収集器
#[derive(Debug, Clone, Default)]
pub struct LogCollector {
    logs: Rc<RefCell<Vec<String>>>,
}

impl LogCollector {
    pub fn new() -> LogCollector {
        LogCollector {
            logs: Rc::new(RefCell::new(Vec::new())),
        }
    }

    pub fn add(&self, message: &str) {
        self.logs.borrow_mut().push(message.to_string());
    }

    pub fn get_all(&self) -> Vec<String> {
        self.logs.borrow().clone()
    }

    pub fn clear(&self) {
        self.logs.borrow_mut().clear();
    }

    pub fn last(&self) -> Option<String> {
        self.logs.borrow().last().cloned()
    }

    pub fn len(&self) -> usize {
        self.logs.borrow().len()
    }

    pub fn is_empty(&self) -> bool {
        self.logs.borrow().is_empty()
    }
}

// =============================================================================
// 3. メトリクス収集器
// =============================================================================

/// メトリクス収集器
#[derive(Debug, Clone, Default)]
pub struct MetricsCollector {
    metrics: Rc<RefCell<HashMap<String, Vec<u64>>>>,
}

impl MetricsCollector {
    pub fn new() -> MetricsCollector {
        MetricsCollector {
            metrics: Rc::new(RefCell::new(HashMap::new())),
        }
    }

    pub fn record(&self, name: &str, value: u64) {
        self.metrics
            .borrow_mut()
            .entry(name.to_string())
            .or_default()
            .push(value);
    }

    pub fn get(&self, name: &str) -> Vec<u64> {
        self.metrics
            .borrow()
            .get(name)
            .cloned()
            .unwrap_or_default()
    }

    pub fn average(&self, name: &str) -> Option<f64> {
        let values = self.get(name);
        if values.is_empty() {
            None
        } else {
            Some(values.iter().sum::<u64>() as f64 / values.len() as f64)
        }
    }

    pub fn clear(&self) {
        self.metrics.borrow_mut().clear();
    }
}

// =============================================================================
// 4. 関数デコレータ
// =============================================================================

/// ログ付き関数を作成
pub fn with_logging<'a, A, B, F>(
    f: F,
    name: &'a str,
    log: &'a LogCollector,
) -> impl Fn(A) -> B + 'a
where
    F: Fn(A) -> B + 'a,
    A: std::fmt::Debug,
    B: std::fmt::Debug,
{
    move |a: A| {
        log.add(&format!("[{}] called with: {:?}", name, a));
        let result = f(a);
        log.add(&format!("[{}] returned: {:?}", name, result));
        result
    }
}

/// タイミング計測付き関数を作成
pub fn with_timing<'a, A, B, F>(
    f: F,
    name: &'a str,
    metrics: &'a MetricsCollector,
) -> impl Fn(A) -> B + 'a
where
    F: Fn(A) -> B + 'a,
{
    move |a: A| {
        let start = Instant::now();
        let result = f(a);
        let elapsed = start.elapsed().as_nanos() as u64;
        metrics.record(name, elapsed);
        result
    }
}

/// リトライ付き関数を作成
pub fn with_retry<A, B, F, E>(f: F, max_retries: u32) -> impl Fn(A) -> Result<B, E>
where
    F: Fn(A) -> Result<B, E>,
    A: Clone,
    E: Clone,
{
    move |a: A| {
        let mut last_error = None;
        for _ in 0..=max_retries {
            match f(a.clone()) {
                Ok(result) => return Ok(result),
                Err(e) => last_error = Some(e),
            }
        }
        Err(last_error.unwrap())
    }
}

/// キャッシュ付き関数を作成（スレッドセーフ版）
pub fn with_cache<A, B, F>(f: F) -> impl Fn(A) -> B
where
    F: Fn(A) -> B,
    A: std::hash::Hash + Eq + Clone,
    B: Clone,
{
    let cache: Arc<Mutex<HashMap<A, B>>> = Arc::new(Mutex::new(HashMap::new()));

    move |a: A| {
        let mut cache_guard = cache.lock().unwrap();
        if let Some(result) = cache_guard.get(&a) {
            return result.clone();
        }
        let result = f(a.clone());
        cache_guard.insert(a, result.clone());
        result
    }
}

/// バリデーション付き関数を作成
pub fn with_validation<A, B, F, V>(
    f: F,
    validator: V,
    error_msg: &str,
) -> impl Fn(A) -> Result<B, String>
where
    F: Fn(A) -> B,
    V: Fn(&A) -> bool,
    A: std::fmt::Debug,
{
    let error_msg = error_msg.to_string();
    move |a: A| {
        if validator(&a) {
            Ok(f(a))
        } else {
            Err(format!("{}: {:?}", error_msg, a))
        }
    }
}

/// デフォルト値付き関数を作成
pub fn with_default<A, B, F, E>(f: F, default: B) -> impl Fn(A) -> B
where
    F: Fn(A) -> Result<B, E>,
    B: Clone,
{
    move |a: A| f(a).unwrap_or_else(|_| default.clone())
}

/// Option 結果に変換
pub fn with_option_result<A, B, F, E>(f: F) -> impl Fn(A) -> Option<B>
where
    F: Fn(A) -> Result<B, E>,
{
    move |a: A| f(a).ok()
}

// =============================================================================
// 5. 監査機能付きリスト
// =============================================================================

/// 監査機能付きリスト
#[derive(Debug, Clone, PartialEq)]
pub struct AuditedList<A: Clone> {
    pub items: Vec<A>,
    pub operations: Vec<String>,
}

impl<A: Clone + std::fmt::Debug + PartialEq> AuditedList<A> {
    pub fn new() -> AuditedList<A> {
        AuditedList {
            items: Vec::new(),
            operations: Vec::new(),
        }
    }

    pub fn from_vec(items: Vec<A>) -> AuditedList<A> {
        AuditedList {
            items,
            operations: vec!["from_vec".to_string()],
        }
    }

    pub fn add(&self, item: A) -> AuditedList<A> {
        let mut new_items = self.items.clone();
        new_items.push(item.clone());
        let mut new_ops = self.operations.clone();
        new_ops.push(format!("add({:?})", item));
        AuditedList {
            items: new_items,
            operations: new_ops,
        }
    }

    pub fn remove(&self, item: &A) -> AuditedList<A> {
        let new_items: Vec<A> = self.items.iter().filter(|i| *i != item).cloned().collect();
        let mut new_ops = self.operations.clone();
        new_ops.push(format!("remove({:?})", item));
        AuditedList {
            items: new_items,
            operations: new_ops,
        }
    }

    pub fn map<B: Clone + std::fmt::Debug + PartialEq, F: Fn(&A) -> B>(
        &self,
        f: F,
    ) -> AuditedList<B> {
        let new_items = self.items.iter().map(f).collect();
        let mut new_ops = self.operations.clone();
        new_ops.push("map".to_string());
        AuditedList {
            items: new_items,
            operations: new_ops,
        }
    }

    pub fn filter<F: Fn(&A) -> bool>(&self, predicate: F) -> AuditedList<A> {
        let new_items = self.items.iter().filter(|i| predicate(i)).cloned().collect();
        let mut new_ops = self.operations.clone();
        new_ops.push("filter".to_string());
        AuditedList {
            items: new_items,
            operations: new_ops,
        }
    }

    pub fn len(&self) -> usize {
        self.items.len()
    }

    pub fn is_empty(&self) -> bool {
        self.items.is_empty()
    }

    pub fn to_vec(&self) -> Vec<A> {
        self.items.clone()
    }
}

impl<A: Clone + std::fmt::Debug + PartialEq> Default for AuditedList<A> {
    fn default() -> Self {
        Self::new()
    }
}

// =============================================================================
// 6. HTTP クライアントデコレータ（シミュレーション）
// =============================================================================

/// HTTP レスポンス
#[derive(Debug, Clone, PartialEq)]
pub struct HttpResponse {
    pub status: u16,
    pub body: String,
    pub headers: HashMap<String, String>,
}

impl HttpResponse {
    pub fn new(status: u16, body: &str) -> HttpResponse {
        HttpResponse {
            status,
            body: body.to_string(),
            headers: HashMap::new(),
        }
    }
}

/// HTTP クライアント trait
pub trait HttpClient {
    fn get(&self, url: &str) -> HttpResponse;
}

/// シンプルな HTTP クライアント
#[derive(Debug, Clone)]
pub struct SimpleHttpClient;

impl HttpClient for SimpleHttpClient {
    fn get(&self, url: &str) -> HttpResponse {
        HttpResponse::new(200, &format!("Response from {}", url))
    }
}

/// ログ付き HTTP クライアント
pub struct LoggingHttpClient<C: HttpClient> {
    client: C,
    log: LogCollector,
}

impl<C: HttpClient> LoggingHttpClient<C> {
    pub fn new(client: C, log: LogCollector) -> LoggingHttpClient<C> {
        LoggingHttpClient { client, log }
    }
}

impl<C: HttpClient> HttpClient for LoggingHttpClient<C> {
    fn get(&self, url: &str) -> HttpResponse {
        self.log.add(&format!("[HTTP] GET {}", url));
        let response = self.client.get(url);
        self.log.add(&format!("[HTTP] Response: {}", response.status));
        response
    }
}

/// キャッシュ付き HTTP クライアント
pub struct CachingHttpClient<C: HttpClient> {
    client: C,
    cache: RefCell<HashMap<String, HttpResponse>>,
}

impl<C: HttpClient> CachingHttpClient<C> {
    pub fn new(client: C) -> CachingHttpClient<C> {
        CachingHttpClient {
            client,
            cache: RefCell::new(HashMap::new()),
        }
    }

    pub fn clear_cache(&self) {
        self.cache.borrow_mut().clear();
    }
}

impl<C: HttpClient> HttpClient for CachingHttpClient<C> {
    fn get(&self, url: &str) -> HttpResponse {
        if let Some(cached) = self.cache.borrow().get(url) {
            return cached.clone();
        }
        let response = self.client.get(url);
        self.cache
            .borrow_mut()
            .insert(url.to_string(), response.clone());
        response
    }
}

// =============================================================================
// 7. 遅延処理のデコレータ
// =============================================================================

/// 遅延付き関数を作成
pub fn with_delay<A, B, F>(f: F, delay: Duration) -> impl Fn(A) -> B
where
    F: Fn(A) -> B,
{
    move |a: A| {
        std::thread::sleep(delay);
        f(a)
    }
}

/// レート制限付き関数を作成
pub fn with_rate_limit<A, B, F>(f: F, min_interval: Duration) -> impl Fn(A) -> B
where
    F: Fn(A) -> B,
{
    let last_call: Arc<Mutex<Option<Instant>>> = Arc::new(Mutex::new(None));

    move |a: A| {
        let mut last = last_call.lock().unwrap();
        if let Some(last_time) = *last {
            let elapsed = last_time.elapsed();
            if elapsed < min_interval {
                std::thread::sleep(min_interval - elapsed);
            }
        }
        *last = Some(Instant::now());
        f(a)
    }
}

// =============================================================================
// テスト
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    // -------------------------------------------------------------------------
    // JournaledShape テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_journaled_circle_translate() {
        let circle = Circle::new(0.0, 0.0, 1.0);
        let journaled = JournaledShape::new(circle);
        let moved = journaled.with_translate(5.0, 3.0);

        assert_eq!(moved.shape.center_x, 5.0);
        assert_eq!(moved.shape.center_y, 3.0);
        assert_eq!(moved.journal.len(), 1);
    }

    #[test]
    fn test_journaled_circle_scale() {
        let circle = Circle::new(0.0, 0.0, 1.0);
        let journaled = JournaledShape::new(circle);
        let scaled = journaled.with_scale(2.0);

        assert_eq!(scaled.shape.radius, 2.0);
        assert_eq!(scaled.journal.len(), 1);
    }

    #[test]
    fn test_journaled_multiple_operations() {
        let circle = Circle::new(0.0, 0.0, 1.0);
        let journaled = JournaledShape::new(circle);
        let transformed = journaled.with_translate(5.0, 0.0).with_scale(2.0);

        assert_eq!(transformed.journal.len(), 2);
        assert_eq!(transformed.shape.center_x, 5.0);
        assert_eq!(transformed.shape.radius, 2.0);
    }

    #[test]
    fn test_journaled_clear_journal() {
        let circle = Circle::new(0.0, 0.0, 1.0);
        let journaled = JournaledShape::new(circle).with_translate(5.0, 0.0);
        let cleared = journaled.clear_journal();

        assert!(cleared.journal.is_empty());
        assert_eq!(cleared.shape.center_x, 5.0);
    }

    #[test]
    fn test_journaled_replay() {
        let circle = Circle::new(0.0, 0.0, 1.0);
        let journaled = JournaledShape::new(circle);
        let entries = vec![
            JournalEntry::Translate { dx: 1.0, dy: 2.0 },
            JournalEntry::Scale { factor: 3.0 },
        ];
        let replayed = journaled.replay(&entries);

        assert_eq!(replayed.shape.center_x, 1.0);
        assert_eq!(replayed.shape.center_y, 2.0);
        assert_eq!(replayed.shape.radius, 3.0);
    }

    // -------------------------------------------------------------------------
    // LogCollector テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_log_collector() {
        let log = LogCollector::new();
        log.add("message 1");
        log.add("message 2");

        assert_eq!(log.len(), 2);
        assert_eq!(log.last(), Some("message 2".to_string()));
    }

    #[test]
    fn test_log_collector_clear() {
        let log = LogCollector::new();
        log.add("message");
        log.clear();

        assert!(log.is_empty());
    }

    // -------------------------------------------------------------------------
    // MetricsCollector テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_metrics_collector() {
        let metrics = MetricsCollector::new();
        metrics.record("test", 100);
        metrics.record("test", 200);

        assert_eq!(metrics.get("test"), vec![100, 200]);
        assert_eq!(metrics.average("test"), Some(150.0));
    }

    #[test]
    fn test_metrics_empty_average() {
        let metrics = MetricsCollector::new();
        assert_eq!(metrics.average("nonexistent"), None);
    }

    // -------------------------------------------------------------------------
    // 関数デコレータテスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_with_logging() {
        let log = LogCollector::new();
        let double = |x: i32| x * 2;
        let logged = with_logging(double, "double", &log);

        let result = logged(5);
        assert_eq!(result, 10);
        assert_eq!(log.len(), 2);
    }

    #[test]
    fn test_with_timing() {
        let metrics = MetricsCollector::new();
        let double = |x: i32| x * 2;
        let timed = with_timing(double, "double", &metrics);

        let _ = timed(5);
        assert!(!metrics.get("double").is_empty());
    }

    #[test]
    fn test_with_retry_success() {
        let f = |x: i32| -> Result<i32, &str> { Ok(x * 2) };
        let with_retries = with_retry(f, 3);

        assert_eq!(with_retries(5), Ok(10));
    }

    #[test]
    fn test_with_retry_failure() {
        let call_count = std::cell::Cell::new(0);
        let f = |_: i32| -> Result<i32, &str> {
            call_count.set(call_count.get() + 1);
            Err("always fails")
        };
        let with_retries = with_retry(f, 2);

        assert!(with_retries(5).is_err());
        assert_eq!(call_count.get(), 3); // 最初の呼び出し + 2回リトライ
    }

    #[test]
    fn test_with_cache() {
        let call_count = std::cell::Cell::new(0);
        let expensive = |x: i32| {
            call_count.set(call_count.get() + 1);
            x * 2
        };
        let cached = with_cache(expensive);

        assert_eq!(cached(5), 10);
        assert_eq!(cached(5), 10); // キャッシュから
        assert_eq!(cached(3), 6); // 新規計算
        assert_eq!(call_count.get(), 2);
    }

    #[test]
    fn test_with_validation_valid() {
        let f = |x: i32| x * 2;
        let validated = with_validation(f, |x| *x > 0, "must be positive");

        assert_eq!(validated(5), Ok(10));
    }

    #[test]
    fn test_with_validation_invalid() {
        let f = |x: i32| x * 2;
        let validated = with_validation(f, |x| *x > 0, "must be positive");

        assert!(validated(-1).is_err());
    }

    #[test]
    fn test_with_default() {
        let f = |x: i32| -> Result<i32, &str> {
            if x > 0 {
                Ok(x * 2)
            } else {
                Err("negative")
            }
        };
        let with_def = with_default(f, 0);

        assert_eq!(with_def(5), 10);
        assert_eq!(with_def(-1), 0);
    }

    // -------------------------------------------------------------------------
    // AuditedList テスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_audited_list_add() {
        let list: AuditedList<i32> = AuditedList::new();
        let list = list.add(1).add(2).add(3);

        assert_eq!(list.len(), 3);
        assert_eq!(list.operations.len(), 3);
    }

    #[test]
    fn test_audited_list_remove() {
        let list = AuditedList::from_vec(vec![1, 2, 3]);
        let list = list.remove(&2);

        assert_eq!(list.to_vec(), vec![1, 3]);
        assert!(list.operations.iter().any(|op| op.contains("remove")));
    }

    #[test]
    fn test_audited_list_map() {
        let list = AuditedList::from_vec(vec![1, 2, 3]);
        let doubled = list.map(|x| x * 2);

        assert_eq!(doubled.to_vec(), vec![2, 4, 6]);
        assert!(doubled.operations.iter().any(|op| op == "map"));
    }

    #[test]
    fn test_audited_list_filter() {
        let list = AuditedList::from_vec(vec![1, 2, 3, 4, 5]);
        let evens = list.filter(|x| x % 2 == 0);

        assert_eq!(evens.to_vec(), vec![2, 4]);
        assert!(evens.operations.iter().any(|op| op == "filter"));
    }

    // -------------------------------------------------------------------------
    // HTTP クライアントテスト
    // -------------------------------------------------------------------------

    #[test]
    fn test_simple_http_client() {
        let client = SimpleHttpClient;
        let response = client.get("http://example.com");

        assert_eq!(response.status, 200);
        assert!(response.body.contains("example.com"));
    }

    #[test]
    fn test_logging_http_client() {
        let log = LogCollector::new();
        let client = LoggingHttpClient::new(SimpleHttpClient, log.clone());

        let _ = client.get("http://example.com");
        assert_eq!(log.len(), 2);
    }

    #[test]
    fn test_caching_http_client() {
        let client = CachingHttpClient::new(SimpleHttpClient);

        let response1 = client.get("http://example.com");
        let response2 = client.get("http://example.com");

        assert_eq!(response1, response2);
    }

    #[test]
    fn test_caching_http_client_clear() {
        let client = CachingHttpClient::new(SimpleHttpClient);

        let _ = client.get("http://example.com");
        client.clear_cache();

        // キャッシュがクリアされているので再度リクエスト
        let _ = client.get("http://example.com");
    }
}
