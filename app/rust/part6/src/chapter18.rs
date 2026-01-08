//! 第18章: 並行処理システム
//!
//! 状態機械パターンとイベント駆動アーキテクチャの実装。
//! Rust の並行処理プリミティブを使用した電話通話システム。

use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, AtomicI64, Ordering};
use std::sync::{Arc, Mutex, RwLock};
use std::thread::{self, JoinHandle};
use std::time::{Duration, Instant};
use tokio::sync::mpsc;

// ============================================================
// 1. 基本型定義
// ============================================================

pub type UserId = String;
pub type EventType = String;

// ============================================================
// 2. 状態機械
// ============================================================

/// 電話の状態
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum PhoneState {
    Idle,
    Calling,
    Dialing,
    WaitingForConnection,
    Talking,
}

/// 電話イベント
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum PhoneEvent {
    Call,
    Ring,
    Dialtone,
    Ringback,
    Connected,
    Disconnect,
}

/// アクションタイプ
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ActionType {
    CallerOffHook,
    CalleeOffHook,
    Dial,
    Talk,
    None,
}

/// 状態遷移結果
#[derive(Debug, Clone, Copy)]
pub struct Transition {
    pub next_state: PhoneState,
    pub action: ActionType,
}

impl Transition {
    pub fn new(next_state: PhoneState, action: ActionType) -> Self {
        Self { next_state, action }
    }
}

/// 状態機械の定義
pub mod phone_state_machine {
    use super::*;
    use std::collections::HashMap;
    use std::sync::OnceLock;

    type TransitionMap = HashMap<(PhoneState, PhoneEvent), Transition>;

    static TRANSITIONS: OnceLock<TransitionMap> = OnceLock::new();

    fn get_transitions() -> &'static TransitionMap {
        TRANSITIONS.get_or_init(|| {
            let mut map = HashMap::new();
            map.insert(
                (PhoneState::Idle, PhoneEvent::Call),
                Transition::new(PhoneState::Calling, ActionType::CallerOffHook),
            );
            map.insert(
                (PhoneState::Idle, PhoneEvent::Ring),
                Transition::new(PhoneState::WaitingForConnection, ActionType::CalleeOffHook),
            );
            map.insert(
                (PhoneState::Idle, PhoneEvent::Disconnect),
                Transition::new(PhoneState::Idle, ActionType::None),
            );
            map.insert(
                (PhoneState::Calling, PhoneEvent::Dialtone),
                Transition::new(PhoneState::Dialing, ActionType::Dial),
            );
            map.insert(
                (PhoneState::Dialing, PhoneEvent::Ringback),
                Transition::new(PhoneState::WaitingForConnection, ActionType::None),
            );
            map.insert(
                (PhoneState::WaitingForConnection, PhoneEvent::Connected),
                Transition::new(PhoneState::Talking, ActionType::Talk),
            );
            map.insert(
                (PhoneState::Talking, PhoneEvent::Disconnect),
                Transition::new(PhoneState::Idle, ActionType::None),
            );
            map
        })
    }

    pub fn transition(state: PhoneState, event: PhoneEvent) -> Option<Transition> {
        get_transitions().get(&(state, event)).copied()
    }

    pub fn is_valid_transition(state: PhoneState, event: PhoneEvent) -> bool {
        get_transitions().contains_key(&(state, event))
    }
}

// ============================================================
// 3. アクション
// ============================================================

/// アクションハンドラ
pub trait ActionHandler: Send + Sync {
    fn handle(&self, from_user: &UserId, to_user: &UserId, action: ActionType);
}

/// ログ出力アクションハンドラ
pub struct LoggingActionHandler {
    logs: Mutex<Vec<String>>,
}

impl LoggingActionHandler {
    pub fn new() -> Self {
        Self {
            logs: Mutex::new(Vec::new()),
        }
    }

    pub fn get_logs(&self) -> Vec<String> {
        self.logs.lock().unwrap().clone()
    }

    pub fn clear(&self) {
        self.logs.lock().unwrap().clear();
    }
}

impl Default for LoggingActionHandler {
    fn default() -> Self {
        Self::new()
    }
}

impl ActionHandler for LoggingActionHandler {
    fn handle(&self, from_user: &UserId, to_user: &UserId, action: ActionType) {
        let message = match action {
            ActionType::CallerOffHook => {
                format!("{} picked up the phone to call {}", from_user, to_user)
            }
            ActionType::CalleeOffHook => {
                format!("{} answered the call from {}", from_user, to_user)
            }
            ActionType::Dial => format!("{} is dialing {}", from_user, to_user),
            ActionType::Talk => format!("{} is now talking with {}", from_user, to_user),
            ActionType::None => String::new(),
        };

        if !message.is_empty() {
            self.logs.lock().unwrap().push(message);
        }
    }
}

/// サイレントアクションハンドラ（テスト用）
pub struct SilentActionHandler {
    actions: Mutex<Vec<(UserId, UserId, ActionType)>>,
}

impl SilentActionHandler {
    pub fn new() -> Self {
        Self {
            actions: Mutex::new(Vec::new()),
        }
    }

    pub fn get_actions(&self) -> Vec<(UserId, UserId, ActionType)> {
        self.actions.lock().unwrap().clone()
    }

    pub fn clear(&self) {
        self.actions.lock().unwrap().clear();
    }
}

impl Default for SilentActionHandler {
    fn default() -> Self {
        Self::new()
    }
}

impl ActionHandler for SilentActionHandler {
    fn handle(&self, from_user: &UserId, to_user: &UserId, action: ActionType) {
        if action != ActionType::None {
            self.actions
                .lock()
                .unwrap()
                .push((from_user.clone(), to_user.clone(), action));
        }
    }
}

// ============================================================
// 4. ユーザーエージェント
// ============================================================

/// ユーザー状態
#[derive(Debug, Clone)]
pub struct UserState {
    pub user_id: UserId,
    pub state: PhoneState,
    pub peer: Option<UserId>,
}

impl UserState {
    pub fn new(user_id: UserId) -> Self {
        Self {
            user_id,
            state: PhoneState::Idle,
            peer: None,
        }
    }
}

/// ユーザーエージェント
pub struct UserAgent {
    pub user_id: UserId,
    state: RwLock<UserState>,
    action_handler: Arc<dyn ActionHandler>,
}

impl UserAgent {
    pub fn new(user_id: UserId, action_handler: Arc<dyn ActionHandler>) -> Self {
        Self {
            user_id: user_id.clone(),
            state: RwLock::new(UserState::new(user_id)),
            action_handler,
        }
    }

    pub fn get_state(&self) -> PhoneState {
        self.state.read().unwrap().state
    }

    pub fn get_peer(&self) -> Option<UserId> {
        self.state.read().unwrap().peer.clone()
    }

    pub fn get_user_state(&self) -> UserState {
        self.state.read().unwrap().clone()
    }

    /// イベントを送信（同期的に状態遷移）
    pub fn send_event(&self, event: PhoneEvent, peer: Option<UserId>) -> bool {
        let mut state = self.state.write().unwrap();
        match phone_state_machine::transition(state.state, event) {
            Some(trans) => {
                let new_peer = peer.or_else(|| state.peer.clone());
                state.state = trans.next_state;
                state.peer = new_peer.clone();

                if trans.action != ActionType::None {
                    self.action_handler.handle(
                        &self.user_id,
                        &new_peer.unwrap_or_else(|| "unknown".to_string()),
                        trans.action,
                    );
                }
                true
            }
            None => false,
        }
    }

    pub fn reset(&self) {
        let mut state = self.state.write().unwrap();
        state.state = PhoneState::Idle;
        state.peer = None;
    }
}

// ============================================================
// 5. 電話システム
// ============================================================

/// 電話システム
pub struct PhoneSystem {
    users: RwLock<HashMap<UserId, Arc<UserAgent>>>,
    action_handler: Arc<dyn ActionHandler>,
}

impl PhoneSystem {
    pub fn new(action_handler: Arc<dyn ActionHandler>) -> Self {
        Self {
            users: RwLock::new(HashMap::new()),
            action_handler,
        }
    }

    pub fn create_user(&self, user_id: &str) -> Arc<UserAgent> {
        let agent = Arc::new(UserAgent::new(
            user_id.to_string(),
            Arc::clone(&self.action_handler),
        ));
        self.users
            .write()
            .unwrap()
            .insert(user_id.to_string(), Arc::clone(&agent));
        agent
    }

    pub fn get_user(&self, user_id: &str) -> Option<Arc<UserAgent>> {
        self.users.read().unwrap().get(user_id).cloned()
    }

    pub fn remove_user(&self, user_id: &str) -> Option<Arc<UserAgent>> {
        self.users.write().unwrap().remove(user_id)
    }

    /// 電話をかける
    pub fn make_call(&self, caller_id: &str, callee_id: &str) -> bool {
        let users = self.users.read().unwrap();
        match (users.get(caller_id), users.get(callee_id)) {
            (Some(caller), Some(callee)) => {
                let caller_success = caller.send_event(PhoneEvent::Call, Some(callee_id.to_string()));
                let callee_success = callee.send_event(PhoneEvent::Ring, Some(caller_id.to_string()));
                caller_success && callee_success
            }
            _ => false,
        }
    }

    /// 電話に出る
    pub fn answer_call(&self, caller_id: &str, callee_id: &str) -> bool {
        let users = self.users.read().unwrap();
        match (users.get(caller_id), users.get(callee_id)) {
            (Some(caller), Some(callee)) => {
                caller.send_event(PhoneEvent::Dialtone, None)
                    && caller.send_event(PhoneEvent::Ringback, None)
                    && caller.send_event(PhoneEvent::Connected, None)
                    && callee.send_event(PhoneEvent::Connected, None)
            }
            _ => false,
        }
    }

    /// 電話を切る
    pub fn hang_up(&self, caller_id: &str, callee_id: &str) -> bool {
        let users = self.users.read().unwrap();
        match (users.get(caller_id), users.get(callee_id)) {
            (Some(caller), Some(callee)) => {
                caller.send_event(PhoneEvent::Disconnect, None)
                    && callee.send_event(PhoneEvent::Disconnect, None)
            }
            _ => false,
        }
    }

    pub fn clear(&self) {
        self.users.write().unwrap().clear();
    }
}

// ============================================================
// 6. イベントバス
// ============================================================

/// イベント
#[derive(Debug, Clone)]
pub struct Event {
    pub event_type: EventType,
    pub data: HashMap<String, String>,
    pub timestamp: i64,
}

impl Event {
    pub fn new(event_type: &str, data: HashMap<String, String>) -> Self {
        Self {
            event_type: event_type.to_string(),
            data,
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis() as i64,
        }
    }
}

/// イベントハンドラ
pub type EventHandler = Arc<dyn Fn(&Event) + Send + Sync>;

/// イベントバス
pub struct EventBus {
    subscribers: RwLock<HashMap<EventType, Vec<EventHandler>>>,
    event_log: Mutex<Vec<Event>>,
}

impl EventBus {
    pub fn new() -> Self {
        Self {
            subscribers: RwLock::new(HashMap::new()),
            event_log: Mutex::new(Vec::new()),
        }
    }

    /// イベントを購読
    pub fn subscribe(&self, event_type: &str, handler: EventHandler) {
        let mut subs = self.subscribers.write().unwrap();
        subs.entry(event_type.to_string())
            .or_default()
            .push(handler);
    }

    /// イベントを発行（同期）
    pub fn publish(&self, event_type: &str, data: HashMap<String, String>) -> Event {
        let event = Event::new(event_type, data);
        self.event_log.lock().unwrap().push(event.clone());

        let subs = self.subscribers.read().unwrap();
        if let Some(handlers) = subs.get(event_type) {
            for handler in handlers {
                if let Err(e) = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
                    handler(&event);
                })) {
                    eprintln!("Handler error: {:?}", e);
                }
            }
        }
        event
    }

    pub fn get_event_log(&self) -> Vec<Event> {
        self.event_log.lock().unwrap().clone()
    }

    pub fn clear_log(&self) {
        self.event_log.lock().unwrap().clear();
    }

    pub fn clear(&self) {
        self.subscribers.write().unwrap().clear();
        self.clear_log();
    }
}

impl Default for EventBus {
    fn default() -> Self {
        Self::new()
    }
}

// ============================================================
// 7. 汎用状態機械
// ============================================================

/// 汎用状態機械
pub struct StateMachine<S, E>
where
    S: Clone + Eq + std::hash::Hash + Send + Sync + 'static,
    E: Clone + Eq + std::hash::Hash + Send + Sync + 'static,
{
    initial_state: S,
    state: RwLock<S>,
    transitions: HashMap<(S, E), (S, Option<Arc<dyn Fn() + Send + Sync>>)>,
}

impl<S, E> StateMachine<S, E>
where
    S: Clone + Eq + std::hash::Hash + Send + Sync + 'static,
    E: Clone + Eq + std::hash::Hash + Send + Sync + 'static,
{
    pub fn new(
        initial_state: S,
        transitions: HashMap<(S, E), (S, Option<Arc<dyn Fn() + Send + Sync>>)>,
    ) -> Self {
        Self {
            initial_state: initial_state.clone(),
            state: RwLock::new(initial_state),
            transitions,
        }
    }

    pub fn get_state(&self) -> S {
        self.state.read().unwrap().clone()
    }

    pub fn send(&self, event: E) -> bool {
        let current = self.state.read().unwrap().clone();
        match self.transitions.get(&(current, event)) {
            Some((next_state, action)) => {
                *self.state.write().unwrap() = next_state.clone();
                if let Some(action) = action {
                    action();
                }
                true
            }
            None => false,
        }
    }

    pub fn reset(&self) {
        *self.state.write().unwrap() = self.initial_state.clone();
    }
}

/// 状態機械ビルダー
pub struct StateMachineBuilder<S, E>
where
    S: Clone + Eq + std::hash::Hash + Send + Sync + 'static,
    E: Clone + Eq + std::hash::Hash + Send + Sync + 'static,
{
    initial_state: S,
    transitions: HashMap<(S, E), (S, Option<Arc<dyn Fn() + Send + Sync>>)>,
}

impl<S, E> StateMachineBuilder<S, E>
where
    S: Clone + Eq + std::hash::Hash + Send + Sync + 'static,
    E: Clone + Eq + std::hash::Hash + Send + Sync + 'static,
{
    pub fn new(initial_state: S) -> Self {
        Self {
            initial_state,
            transitions: HashMap::new(),
        }
    }

    pub fn add_transition(mut self, from: S, event: E, to: S) -> Self {
        self.transitions.insert((from, event), (to, None));
        self
    }

    pub fn add_transition_with_action<F>(mut self, from: S, event: E, to: S, action: F) -> Self
    where
        F: Fn() + Send + Sync + 'static,
    {
        self.transitions
            .insert((from, event), (to, Some(Arc::new(action))));
        self
    }

    pub fn build(self) -> StateMachine<S, E> {
        StateMachine::new(self.initial_state, self.transitions)
    }
}

// ============================================================
// 8. Pub/Sub システム
// ============================================================

/// トピック
pub struct Topic<T>
where
    T: Clone + Send + 'static,
{
    #[allow(dead_code)]
    name: String,
    subscribers: RwLock<HashMap<String, Arc<dyn Fn(T) + Send + Sync>>>,
}

impl<T> Topic<T>
where
    T: Clone + Send + 'static,
{
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            subscribers: RwLock::new(HashMap::new()),
        }
    }

    pub fn subscribe<F>(&self, subscriber_id: &str, handler: F)
    where
        F: Fn(T) + Send + Sync + 'static,
    {
        self.subscribers
            .write()
            .unwrap()
            .insert(subscriber_id.to_string(), Arc::new(handler));
    }

    pub fn unsubscribe(&self, subscriber_id: &str) {
        self.subscribers.write().unwrap().remove(subscriber_id);
    }

    pub fn publish(&self, message: T) {
        let subs = self.subscribers.read().unwrap();
        for handler in subs.values() {
            let msg = message.clone();
            if let Err(e) = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
                handler(msg);
            })) {
                eprintln!("Handler error: {:?}", e);
            }
        }
    }

    pub fn subscriber_count(&self) -> usize {
        self.subscribers.read().unwrap().len()
    }
}

/// メッセージブローカー
pub struct MessageBroker {
    topics: RwLock<HashMap<String, Arc<Topic<String>>>>,
}

impl MessageBroker {
    pub fn new() -> Self {
        Self {
            topics: RwLock::new(HashMap::new()),
        }
    }

    pub fn get_topic(&self, name: &str) -> Arc<Topic<String>> {
        let mut topics = self.topics.write().unwrap();
        topics
            .entry(name.to_string())
            .or_insert_with(|| Arc::new(Topic::new(name)))
            .clone()
    }

    pub fn remove_topic(&self, name: &str) {
        self.topics.write().unwrap().remove(name);
    }

    pub fn topic_names(&self) -> Vec<String> {
        self.topics.read().unwrap().keys().cloned().collect()
    }
}

impl Default for MessageBroker {
    fn default() -> Self {
        Self::new()
    }
}

// ============================================================
// 9. タスクキュー
// ============================================================

/// タスクキュー
pub struct TaskQueue<T>
where
    T: Send + 'static,
{
    sender: mpsc::UnboundedSender<Box<dyn FnOnce() -> T + Send>>,
    running: Arc<AtomicBool>,
    #[allow(dead_code)]
    handles: Mutex<Vec<JoinHandle<()>>>,
}

impl<T> TaskQueue<T>
where
    T: Send + 'static,
{
    pub fn new(workers: usize) -> Self {
        let (sender, receiver) = mpsc::unbounded_channel::<Box<dyn FnOnce() -> T + Send>>();
        let receiver = Arc::new(Mutex::new(receiver));
        let running = Arc::new(AtomicBool::new(true));
        let mut handles = Vec::new();

        for i in 0..workers {
            let receiver = Arc::clone(&receiver);
            let running = Arc::clone(&running);
            let handle = thread::Builder::new()
                .name(format!("TaskQueue-Worker-{}", i))
                .spawn(move || {
                    while running.load(Ordering::SeqCst) {
                        let task = {
                            let mut rx = receiver.lock().unwrap();
                            rx.try_recv().ok()
                        };
                        if let Some(task) = task {
                            let _ = task();
                        } else {
                            thread::sleep(Duration::from_millis(10));
                        }
                    }
                })
                .expect("Failed to spawn worker thread");
            handles.push(handle);
        }

        Self {
            sender,
            running,
            handles: Mutex::new(handles),
        }
    }

    pub fn submit<F>(&self, computation: F)
    where
        F: FnOnce() -> T + Send + 'static,
    {
        let _ = self.sender.send(Box::new(computation));
    }

    pub fn stop(&self) {
        self.running.store(false, Ordering::SeqCst);
    }

    pub fn is_running(&self) -> bool {
        self.running.load(Ordering::SeqCst)
    }
}

// ============================================================
// 10. 並行カウンター
// ============================================================

/// アトミックカウンター
pub struct AtomicCounter {
    initial: i64,
    counter: AtomicI64,
}

impl AtomicCounter {
    pub fn new(initial: i64) -> Self {
        Self {
            initial,
            counter: AtomicI64::new(initial),
        }
    }

    pub fn get(&self) -> i64 {
        self.counter.load(Ordering::SeqCst)
    }

    pub fn increment(&self) -> i64 {
        self.counter.fetch_add(1, Ordering::SeqCst) + 1
    }

    pub fn decrement(&self) -> i64 {
        self.counter.fetch_sub(1, Ordering::SeqCst) - 1
    }

    pub fn add(&self, delta: i64) -> i64 {
        self.counter.fetch_add(delta, Ordering::SeqCst) + delta
    }

    pub fn reset(&self) {
        self.counter.store(self.initial, Ordering::SeqCst);
    }
}

impl Default for AtomicCounter {
    fn default() -> Self {
        Self::new(0)
    }
}

/// 並行マップ
pub struct ConcurrentMap<K, V>
where
    K: Eq + std::hash::Hash + Clone,
    V: Clone,
{
    map: RwLock<HashMap<K, V>>,
}

impl<K, V> ConcurrentMap<K, V>
where
    K: Eq + std::hash::Hash + Clone,
    V: Clone,
{
    pub fn new() -> Self {
        Self {
            map: RwLock::new(HashMap::new()),
        }
    }

    pub fn put(&self, key: K, value: V) -> Option<V> {
        self.map.write().unwrap().insert(key, value)
    }

    pub fn get(&self, key: &K) -> Option<V> {
        self.map.read().unwrap().get(key).cloned()
    }

    pub fn remove(&self, key: &K) -> Option<V> {
        self.map.write().unwrap().remove(key)
    }

    pub fn contains(&self, key: &K) -> bool {
        self.map.read().unwrap().contains_key(key)
    }

    pub fn size(&self) -> usize {
        self.map.read().unwrap().len()
    }

    pub fn keys(&self) -> Vec<K> {
        self.map.read().unwrap().keys().cloned().collect()
    }

    pub fn values(&self) -> Vec<V> {
        self.map.read().unwrap().values().cloned().collect()
    }

    pub fn clear(&self) {
        self.map.write().unwrap().clear();
    }

    pub fn get_or_insert_with<F>(&self, key: K, default: F) -> V
    where
        F: FnOnce() -> V,
    {
        let read_guard = self.map.read().unwrap();
        if let Some(value) = read_guard.get(&key) {
            return value.clone();
        }
        drop(read_guard);

        let mut write_guard = self.map.write().unwrap();
        write_guard.entry(key).or_insert_with(default).clone()
    }
}

impl<K, V> Default for ConcurrentMap<K, V>
where
    K: Eq + std::hash::Hash + Clone,
    V: Clone,
{
    fn default() -> Self {
        Self::new()
    }
}

// ============================================================
// 11. 非同期イベントバス (tokio ベース)
// ============================================================

/// 非同期イベントバス
pub struct AsyncEventBus {
    sender: mpsc::UnboundedSender<Event>,
}

impl AsyncEventBus {
    pub fn new() -> (Self, mpsc::UnboundedReceiver<Event>) {
        let (sender, receiver) = mpsc::unbounded_channel();
        (Self { sender }, receiver)
    }

    pub fn publish(&self, event_type: &str, data: HashMap<String, String>) -> Result<(), mpsc::error::SendError<Event>> {
        let event = Event::new(event_type, data);
        self.sender.send(event)
    }
}

// ============================================================
// 12. タイムアウト付き操作
// ============================================================

/// タイムアウト付き操作
pub fn with_timeout<T, F>(duration: Duration, f: F) -> Option<T>
where
    F: FnOnce() -> T + Send + 'static,
    T: Send + 'static,
{
    let (sender, receiver) = std::sync::mpsc::channel();
    let handle = thread::spawn(move || {
        let result = f();
        let _ = sender.send(result);
    });

    match receiver.recv_timeout(duration) {
        Ok(result) => {
            let _ = handle.join();
            Some(result)
        }
        Err(_) => None,
    }
}

/// 再試行付き操作
pub fn with_retry<T, E, F>(max_retries: usize, delay: Duration, mut f: F) -> Result<T, E>
where
    F: FnMut() -> Result<T, E>,
{
    let mut attempts = 0;
    loop {
        match f() {
            Ok(result) => return Ok(result),
            Err(e) => {
                attempts += 1;
                if attempts >= max_retries {
                    return Err(e);
                }
                thread::sleep(delay);
            }
        }
    }
}

/// レート制限
pub struct RateLimiter {
    max_requests: usize,
    window: Duration,
    requests: Mutex<Vec<Instant>>,
}

impl RateLimiter {
    pub fn new(max_requests: usize, window: Duration) -> Self {
        Self {
            max_requests,
            window,
            requests: Mutex::new(Vec::new()),
        }
    }

    pub fn try_acquire(&self) -> bool {
        let mut requests = self.requests.lock().unwrap();
        let now = Instant::now();

        // 古いリクエストを削除
        requests.retain(|&t| now.duration_since(t) < self.window);

        if requests.len() < self.max_requests {
            requests.push(now);
            true
        } else {
            false
        }
    }

    pub fn remaining(&self) -> usize {
        let requests = self.requests.lock().unwrap();
        let now = Instant::now();
        let active = requests.iter().filter(|&&t| now.duration_since(t) < self.window).count();
        self.max_requests.saturating_sub(active)
    }
}

// ============================================================
// テスト
// ============================================================

#[cfg(test)]
mod tests {
    use super::*;

    mod phone_state_machine_tests {
        use super::*;

        #[test]
        fn idle_to_calling_on_call() {
            let result = phone_state_machine::transition(PhoneState::Idle, PhoneEvent::Call);
            assert!(result.is_some());
            let trans = result.unwrap();
            assert_eq!(trans.next_state, PhoneState::Calling);
            assert_eq!(trans.action, ActionType::CallerOffHook);
        }

        #[test]
        fn idle_to_waiting_on_ring() {
            let result = phone_state_machine::transition(PhoneState::Idle, PhoneEvent::Ring);
            assert!(result.is_some());
            let trans = result.unwrap();
            assert_eq!(trans.next_state, PhoneState::WaitingForConnection);
            assert_eq!(trans.action, ActionType::CalleeOffHook);
        }

        #[test]
        fn calling_to_dialing_on_dialtone() {
            let result = phone_state_machine::transition(PhoneState::Calling, PhoneEvent::Dialtone);
            assert!(result.is_some());
            let trans = result.unwrap();
            assert_eq!(trans.next_state, PhoneState::Dialing);
            assert_eq!(trans.action, ActionType::Dial);
        }

        #[test]
        fn dialing_to_waiting_on_ringback() {
            let result = phone_state_machine::transition(PhoneState::Dialing, PhoneEvent::Ringback);
            assert!(result.is_some());
            let trans = result.unwrap();
            assert_eq!(trans.next_state, PhoneState::WaitingForConnection);
            assert_eq!(trans.action, ActionType::None);
        }

        #[test]
        fn waiting_to_talking_on_connected() {
            let result =
                phone_state_machine::transition(PhoneState::WaitingForConnection, PhoneEvent::Connected);
            assert!(result.is_some());
            let trans = result.unwrap();
            assert_eq!(trans.next_state, PhoneState::Talking);
            assert_eq!(trans.action, ActionType::Talk);
        }

        #[test]
        fn talking_to_idle_on_disconnect() {
            let result = phone_state_machine::transition(PhoneState::Talking, PhoneEvent::Disconnect);
            assert!(result.is_some());
            let trans = result.unwrap();
            assert_eq!(trans.next_state, PhoneState::Idle);
        }

        #[test]
        fn invalid_transition_returns_none() {
            let result = phone_state_machine::transition(PhoneState::Idle, PhoneEvent::Connected);
            assert!(result.is_none());
        }

        #[test]
        fn is_valid_transition_true() {
            assert!(phone_state_machine::is_valid_transition(
                PhoneState::Idle,
                PhoneEvent::Call
            ));
        }

        #[test]
        fn is_valid_transition_false() {
            assert!(!phone_state_machine::is_valid_transition(
                PhoneState::Talking,
                PhoneEvent::Call
            ));
        }
    }

    mod user_agent_tests {
        use super::*;

        #[test]
        fn initial_state_is_idle() {
            let handler = Arc::new(SilentActionHandler::new());
            let agent = UserAgent::new("Alice".to_string(), handler);
            assert_eq!(agent.get_state(), PhoneState::Idle);
        }

        #[test]
        fn call_event_transitions_to_calling() {
            let handler = Arc::new(SilentActionHandler::new());
            let agent = UserAgent::new("Alice".to_string(), handler);

            assert!(agent.send_event(PhoneEvent::Call, Some("Bob".to_string())));
            assert_eq!(agent.get_state(), PhoneState::Calling);
            assert_eq!(agent.get_peer(), Some("Bob".to_string()));
        }

        #[test]
        fn action_is_executed() {
            let handler = Arc::new(SilentActionHandler::new());
            let handler_dyn: Arc<dyn ActionHandler> = Arc::clone(&handler) as Arc<dyn ActionHandler>;
            let agent = UserAgent::new("Alice".to_string(), handler_dyn);

            agent.send_event(PhoneEvent::Call, Some("Bob".to_string()));

            let actions = handler.get_actions();
            assert!(actions.contains(&(
                "Alice".to_string(),
                "Bob".to_string(),
                ActionType::CallerOffHook
            )));
        }

        #[test]
        fn invalid_transition_fails() {
            let handler = Arc::new(SilentActionHandler::new());
            let agent = UserAgent::new("Alice".to_string(), handler);

            assert!(!agent.send_event(PhoneEvent::Connected, None));
            assert_eq!(agent.get_state(), PhoneState::Idle);
        }

        #[test]
        fn can_reset() {
            let handler = Arc::new(SilentActionHandler::new());
            let agent = UserAgent::new("Alice".to_string(), handler);

            agent.send_event(PhoneEvent::Call, Some("Bob".to_string()));
            agent.reset();

            assert_eq!(agent.get_state(), PhoneState::Idle);
            assert_eq!(agent.get_peer(), None);
        }
    }

    mod phone_system_tests {
        use super::*;

        #[test]
        fn creates_user() {
            let handler = Arc::new(SilentActionHandler::new());
            let system = PhoneSystem::new(handler);
            let alice = system.create_user("Alice");

            assert_eq!(alice.user_id, "Alice");
            assert!(system.get_user("Alice").is_some());
        }

        #[test]
        fn makes_call() {
            let handler = Arc::new(SilentActionHandler::new());
            let system = PhoneSystem::new(handler);
            system.create_user("Alice");
            system.create_user("Bob");

            assert!(system.make_call("Alice", "Bob"));

            assert_eq!(
                system.get_user("Alice").unwrap().get_state(),
                PhoneState::Calling
            );
            assert_eq!(
                system.get_user("Bob").unwrap().get_state(),
                PhoneState::WaitingForConnection
            );
        }

        #[test]
        fn answers_call() {
            let handler = Arc::new(SilentActionHandler::new());
            let system = PhoneSystem::new(handler);
            system.create_user("Alice");
            system.create_user("Bob");

            system.make_call("Alice", "Bob");
            assert!(system.answer_call("Alice", "Bob"));

            assert_eq!(
                system.get_user("Alice").unwrap().get_state(),
                PhoneState::Talking
            );
            assert_eq!(
                system.get_user("Bob").unwrap().get_state(),
                PhoneState::Talking
            );
        }

        #[test]
        fn hangs_up() {
            let handler = Arc::new(SilentActionHandler::new());
            let system = PhoneSystem::new(handler);
            system.create_user("Alice");
            system.create_user("Bob");

            system.make_call("Alice", "Bob");
            system.answer_call("Alice", "Bob");
            assert!(system.hang_up("Alice", "Bob"));

            assert_eq!(
                system.get_user("Alice").unwrap().get_state(),
                PhoneState::Idle
            );
            assert_eq!(
                system.get_user("Bob").unwrap().get_state(),
                PhoneState::Idle
            );
        }

        #[test]
        fn call_to_nonexistent_user_fails() {
            let handler = Arc::new(SilentActionHandler::new());
            let system = PhoneSystem::new(handler);
            system.create_user("Alice");

            assert!(!system.make_call("Alice", "Bob"));
        }
    }

    mod event_bus_tests {
        use super::*;

        #[test]
        fn subscribes_and_receives_event() {
            let bus = EventBus::new();
            let received = Arc::new(Mutex::new(None::<Event>));
            let received_clone = Arc::clone(&received);

            bus.subscribe(
                "test-event",
                Arc::new(move |e: &Event| {
                    *received_clone.lock().unwrap() = Some(e.clone());
                }),
            );
            bus.publish("test-event", [("key".to_string(), "value".to_string())].into());

            let guard = received.lock().unwrap();
            assert!(guard.is_some());
            let event = guard.as_ref().unwrap();
            assert_eq!(event.event_type, "test-event");
            assert_eq!(event.data.get("key"), Some(&"value".to_string()));
        }

        #[test]
        fn multiple_handlers() {
            let bus = EventBus::new();
            let count = Arc::new(AtomicCounter::new(0));
            let count1 = Arc::clone(&count);
            let count2 = Arc::clone(&count);

            bus.subscribe("test-event", Arc::new(move |_| { count1.increment(); }));
            bus.subscribe("test-event", Arc::new(move |_| { count2.increment(); }));
            bus.publish("test-event", HashMap::new());

            assert_eq!(count.get(), 2);
        }

        #[test]
        fn event_log_records_events() {
            let bus = EventBus::new();
            bus.publish("event-1", [("a".to_string(), "1".to_string())].into());
            bus.publish("event-2", [("b".to_string(), "2".to_string())].into());

            let log = bus.get_event_log();
            assert_eq!(log.len(), 2);
            assert_eq!(log[0].event_type, "event-1");
            assert_eq!(log[1].event_type, "event-2");
        }

        #[test]
        fn handler_error_does_not_affect_others() {
            let bus = EventBus::new();
            let count = Arc::new(AtomicCounter::new(0));
            let count_clone = Arc::clone(&count);

            bus.subscribe("error-event", Arc::new(|_| panic!("Error")));
            bus.subscribe("error-event", Arc::new(move |_| { count_clone.increment(); }));
            bus.publish("error-event", HashMap::new());

            assert_eq!(count.get(), 1);
        }
    }

    mod state_machine_tests {
        use super::*;

        #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
        enum TrafficLight {
            Red,
            Yellow,
            Green,
        }

        #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
        enum TrafficEvent {
            Next,
        }

        #[test]
        fn creates_state_machine() {
            let sm = StateMachineBuilder::new(TrafficLight::Red)
                .add_transition(TrafficLight::Red, TrafficEvent::Next, TrafficLight::Green)
                .add_transition(TrafficLight::Green, TrafficEvent::Next, TrafficLight::Yellow)
                .add_transition(TrafficLight::Yellow, TrafficEvent::Next, TrafficLight::Red)
                .build();

            assert_eq!(sm.get_state(), TrafficLight::Red);
        }

        #[test]
        fn transitions_state() {
            let sm = StateMachineBuilder::new(TrafficLight::Red)
                .add_transition(TrafficLight::Red, TrafficEvent::Next, TrafficLight::Green)
                .add_transition(TrafficLight::Green, TrafficEvent::Next, TrafficLight::Yellow)
                .add_transition(TrafficLight::Yellow, TrafficEvent::Next, TrafficLight::Red)
                .build();

            assert!(sm.send(TrafficEvent::Next));
            assert_eq!(sm.get_state(), TrafficLight::Green);

            sm.send(TrafficEvent::Next);
            assert_eq!(sm.get_state(), TrafficLight::Yellow);

            sm.send(TrafficEvent::Next);
            assert_eq!(sm.get_state(), TrafficLight::Red);
        }

        #[test]
        fn executes_action() {
            let action_executed = Arc::new(AtomicBool::new(false));
            let action_executed_clone = Arc::clone(&action_executed);

            let sm = StateMachineBuilder::new(TrafficLight::Red)
                .add_transition_with_action(
                    TrafficLight::Red,
                    TrafficEvent::Next,
                    TrafficLight::Green,
                    move || {
                        action_executed_clone.store(true, Ordering::SeqCst);
                    },
                )
                .build();

            sm.send(TrafficEvent::Next);
            assert!(action_executed.load(Ordering::SeqCst));
        }
    }

    mod topic_tests {
        use super::*;

        #[test]
        fn subscribes_and_receives_message() {
            let topic: Topic<String> = Topic::new("test-topic");
            let received = Arc::new(Mutex::new(None::<String>));
            let received_clone = Arc::clone(&received);

            topic.subscribe("sub1", move |msg| {
                *received_clone.lock().unwrap() = Some(msg);
            });
            topic.publish("Hello".to_string());

            assert_eq!(*received.lock().unwrap(), Some("Hello".to_string()));
        }

        #[test]
        fn delivers_to_multiple_subscribers() {
            let topic: Topic<String> = Topic::new("test-topic");
            let count = Arc::new(AtomicCounter::new(0));
            let count1 = Arc::clone(&count);
            let count2 = Arc::clone(&count);

            topic.subscribe("sub1", move |_| { count1.increment(); });
            topic.subscribe("sub2", move |_| { count2.increment(); });
            topic.publish("Hello".to_string());

            assert_eq!(count.get(), 2);
        }

        #[test]
        fn unsubscribes() {
            let topic: Topic<String> = Topic::new("test-topic");
            let count = Arc::new(AtomicCounter::new(0));
            let count_clone = Arc::clone(&count);

            topic.subscribe("sub1", move |_| { count_clone.increment(); });
            topic.unsubscribe("sub1");
            topic.publish("Hello".to_string());

            assert_eq!(count.get(), 0);
        }
    }

    mod message_broker_tests {
        use super::*;

        #[test]
        fn gets_topic() {
            let broker = MessageBroker::new();
            let topic = broker.get_topic("news");
            assert_eq!(topic.subscriber_count(), 0);
        }

        #[test]
        fn same_name_returns_same_topic() {
            let broker = MessageBroker::new();
            let topic1 = broker.get_topic("news");
            let topic2 = broker.get_topic("news");

            assert!(Arc::ptr_eq(&topic1, &topic2));
        }

        #[test]
        fn lists_topic_names() {
            let broker = MessageBroker::new();
            broker.get_topic("topic1");
            broker.get_topic("topic2");

            let names = broker.topic_names();
            assert!(names.contains(&"topic1".to_string()));
            assert!(names.contains(&"topic2".to_string()));
        }
    }

    mod atomic_counter_tests {
        use super::*;

        #[test]
        fn operates_counter() {
            let counter = AtomicCounter::new(0);

            assert_eq!(counter.get(), 0);
            assert_eq!(counter.increment(), 1);
            assert_eq!(counter.increment(), 2);
            assert_eq!(counter.decrement(), 1);
            assert_eq!(counter.add(10), 11);
        }

        #[test]
        fn sets_initial_value() {
            let counter = AtomicCounter::new(100);
            assert_eq!(counter.get(), 100);
        }

        #[test]
        fn resets() {
            let counter = AtomicCounter::new(10);
            counter.increment();
            counter.reset();
            assert_eq!(counter.get(), 10);
        }
    }

    mod concurrent_map_tests {
        use super::*;

        #[test]
        fn puts_and_gets() {
            let map: ConcurrentMap<String, i32> = ConcurrentMap::new();
            map.put("a".to_string(), 1);
            map.put("b".to_string(), 2);

            assert_eq!(map.get(&"a".to_string()), Some(1));
            assert_eq!(map.get(&"b".to_string()), Some(2));
            assert_eq!(map.get(&"c".to_string()), None);
        }

        #[test]
        fn removes() {
            let map: ConcurrentMap<String, i32> = ConcurrentMap::new();
            map.put("a".to_string(), 1);
            map.remove(&"a".to_string());

            assert_eq!(map.get(&"a".to_string()), None);
        }

        #[test]
        fn get_or_insert_with_lazy_init() {
            let map: ConcurrentMap<String, i32> = ConcurrentMap::new();
            let initialized = Arc::new(AtomicBool::new(false));
            let init1 = Arc::clone(&initialized);
            let init2 = Arc::clone(&initialized);

            map.get_or_insert_with("a".to_string(), move || {
                init1.store(true, Ordering::SeqCst);
                42
            });
            assert!(initialized.load(Ordering::SeqCst));

            initialized.store(false, Ordering::SeqCst);
            let val = map.get_or_insert_with("a".to_string(), move || {
                init2.store(true, Ordering::SeqCst);
                100
            });
            assert!(!initialized.load(Ordering::SeqCst));
            assert_eq!(val, 42);
        }
    }

    mod action_handler_tests {
        use super::*;

        #[test]
        fn logging_handler_records_logs() {
            let handler = LoggingActionHandler::new();
            handler.handle(&"Alice".to_string(), &"Bob".to_string(), ActionType::CallerOffHook);

            let logs = handler.get_logs();
            assert_eq!(logs.len(), 1);
            assert!(logs[0].contains("Alice"));
            assert!(logs[0].contains("Bob"));
        }

        #[test]
        fn logging_handler_ignores_none_action() {
            let handler = LoggingActionHandler::new();
            handler.handle(&"Alice".to_string(), &"Bob".to_string(), ActionType::None);

            assert!(handler.get_logs().is_empty());
        }

        #[test]
        fn silent_handler_records_actions() {
            let handler = SilentActionHandler::new();
            handler.handle(&"Alice".to_string(), &"Bob".to_string(), ActionType::Dial);

            let actions = handler.get_actions();
            assert_eq!(actions.len(), 1);
            assert_eq!(
                actions[0],
                ("Alice".to_string(), "Bob".to_string(), ActionType::Dial)
            );
        }
    }

    mod rate_limiter_tests {
        use super::*;

        #[test]
        fn allows_within_limit() {
            let limiter = RateLimiter::new(3, Duration::from_secs(1));

            assert!(limiter.try_acquire());
            assert!(limiter.try_acquire());
            assert!(limiter.try_acquire());
        }

        #[test]
        fn blocks_over_limit() {
            let limiter = RateLimiter::new(2, Duration::from_secs(1));

            assert!(limiter.try_acquire());
            assert!(limiter.try_acquire());
            assert!(!limiter.try_acquire());
        }

        #[test]
        fn remaining_count() {
            let limiter = RateLimiter::new(3, Duration::from_secs(1));

            assert_eq!(limiter.remaining(), 3);
            limiter.try_acquire();
            assert_eq!(limiter.remaining(), 2);
        }
    }

    mod timeout_tests {
        use super::*;

        #[test]
        fn with_timeout_succeeds() {
            let result = with_timeout(Duration::from_secs(1), || 42);
            assert_eq!(result, Some(42));
        }

        #[test]
        fn with_timeout_times_out() {
            let result = with_timeout(Duration::from_millis(10), || {
                thread::sleep(Duration::from_secs(1));
                42
            });
            assert_eq!(result, None);
        }
    }

    mod retry_tests {
        use super::*;

        #[test]
        fn succeeds_on_first_try() {
            let result: Result<i32, &str> = with_retry(3, Duration::from_millis(1), || Ok(42));
            assert_eq!(result, Ok(42));
        }

        #[test]
        fn succeeds_after_retries() {
            let attempt = Arc::new(AtomicCounter::new(0));
            let attempt_clone = Arc::clone(&attempt);

            let result: Result<i32, &str> = with_retry(3, Duration::from_millis(1), || {
                if attempt_clone.increment() < 3 {
                    Err("not yet")
                } else {
                    Ok(42)
                }
            });
            assert_eq!(result, Ok(42));
        }

        #[test]
        fn fails_after_max_retries() {
            let result: Result<i32, &str> = with_retry(2, Duration::from_millis(1), || Err("error"));
            assert_eq!(result, Err("error"));
        }
    }
}
