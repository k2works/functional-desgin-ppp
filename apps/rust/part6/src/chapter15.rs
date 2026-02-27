//! 第15章: ゴシップ好きなバスの運転手
//!
//! バス運転手が停留所で出会ったときに噂を共有するシミュレーション。
//! 全ての運転手が全ての噂を知るまでに何分かかるかを計算します。

use std::collections::{HashMap, HashSet};

// ============================================================
// 1. データモデル
// ============================================================

/// 噂を表す型
pub type Rumor = String;

/// 停留所を表す型
pub type Stop = i32;

/// ドライバーを表す構造体
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Driver {
    pub name: String,
    pub route: Vec<Stop>,
    pub position: usize,
    pub rumors: HashSet<Rumor>,
}

impl Driver {
    /// ルートと噂を持つドライバーを作成
    pub fn new(name: &str, route: Vec<Stop>, rumors: HashSet<Rumor>) -> Self {
        Self {
            name: name.to_string(),
            route,
            position: 0,
            rumors,
        }
    }

    /// 自動噂付きドライバーを作成
    pub fn with_auto_rumor(name: &str, route: Vec<Stop>) -> Self {
        let mut rumors = HashSet::new();
        rumors.insert(format!("rumor-{}", name));
        Self {
            name: name.to_string(),
            route,
            position: 0,
            rumors,
        }
    }

    /// 現在の停留所を取得
    pub fn current_stop(&self) -> Stop {
        self.route[self.position % self.route.len()]
    }

    /// 次の停留所に移動
    pub fn move_forward(&self) -> Self {
        Self {
            position: self.position + 1,
            ..self.clone()
        }
    }

    /// 噂を追加
    pub fn add_rumors(&self, new_rumors: &HashSet<Rumor>) -> Self {
        let mut combined = self.rumors.clone();
        combined.extend(new_rumors.clone());
        Self {
            rumors: combined,
            ..self.clone()
        }
    }
}

// ============================================================
// 2. ワールド（シミュレーション状態）
// ============================================================

/// シミュレーション世界を表す構造体
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct World {
    pub drivers: Vec<Driver>,
    pub time: i32,
}

impl World {
    /// 新しいワールドを作成
    pub fn new(drivers: Vec<Driver>) -> Self {
        Self { drivers, time: 0 }
    }

    /// 全ドライバーを移動
    pub fn move_drivers(&self) -> Self {
        Self {
            drivers: self.drivers.iter().map(|d| d.move_forward()).collect(),
            ..self.clone()
        }
    }

    /// 各停留所にいるドライバーをグループ化
    pub fn drivers_by_stop(&self) -> HashMap<Stop, Vec<&Driver>> {
        let mut groups: HashMap<Stop, Vec<&Driver>> = HashMap::new();
        for driver in &self.drivers {
            groups
                .entry(driver.current_stop())
                .or_default()
                .push(driver);
        }
        groups
    }

    /// 同じ停留所にいるドライバー間で噂を共有
    pub fn spread_rumors(&self) -> Self {
        let groups = self.drivers_by_stop();
        
        // 各停留所で噂を共有
        let mut updated_rumors: HashMap<String, HashSet<Rumor>> = HashMap::new();
        
        for drivers_at_stop in groups.values() {
            // この停留所にいる全ドライバーの噂を集める
            let all_rumors: HashSet<Rumor> = drivers_at_stop
                .iter()
                .flat_map(|d| d.rumors.clone())
                .collect();
            
            // 各ドライバーに全噂を追加
            for driver in drivers_at_stop {
                updated_rumors.insert(driver.name.clone(), all_rumors.clone());
            }
        }
        
        // 元の順序を保持しながら噂を更新
        let new_drivers = self
            .drivers
            .iter()
            .map(|d| {
                if let Some(new_rumors) = updated_rumors.get(&d.name) {
                    Self::with_rumors(d, new_rumors.clone())
                } else {
                    d.clone()
                }
            })
            .collect();
        
        Self {
            drivers: new_drivers,
            ..self.clone()
        }
    }

    fn with_rumors(driver: &Driver, rumors: HashSet<Rumor>) -> Driver {
        Driver {
            rumors,
            ..driver.clone()
        }
    }

    /// 1ステップ実行（移動→噂の伝播）
    pub fn step(&self) -> Self {
        let moved = self.move_drivers();
        let spread = moved.spread_rumors();
        Self {
            time: self.time + 1,
            ..spread
        }
    }

    /// 全ドライバーが同じ噂を持っているか確認
    pub fn all_rumors_shared(&self) -> bool {
        if self.drivers.is_empty() {
            return true;
        }
        
        let first_rumors = &self.drivers[0].rumors;
        self.drivers.iter().all(|d| &d.rumors == first_rumors)
    }

    /// 全噂の集合
    pub fn all_rumors(&self) -> HashSet<Rumor> {
        self.drivers
            .iter()
            .flat_map(|d| d.rumors.clone())
            .collect()
    }
}

// ============================================================
// 3. シミュレーション
// ============================================================

/// シミュレーション結果
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SimulationResult {
    Completed(i32),
    Never,
}

impl SimulationResult {
    pub fn is_completed(&self) -> bool {
        matches!(self, SimulationResult::Completed(_))
    }

    pub fn minutes(&self) -> Option<i32> {
        match self {
            SimulationResult::Completed(m) => Some(*m),
            SimulationResult::Never => None,
        }
    }
}

/// シミュレーションを実行
pub fn simulate(world: &World, max_minutes: i32) -> SimulationResult {
    if world.drivers.len() <= 1 {
        return SimulationResult::Completed(0);
    }
    
    if world.all_rumors_shared() {
        return SimulationResult::Completed(0);
    }
    
    let mut current = world.step();
    
    loop {
        if current.time > max_minutes {
            return SimulationResult::Never;
        }
        
        if current.all_rumors_shared() {
            return SimulationResult::Completed(current.time);
        }
        
        current = current.step();
    }
}

/// シミュレーションを実行し、経過を記録
pub fn simulate_with_history(world: &World, max_minutes: i32) -> (SimulationResult, Vec<World>) {
    if world.drivers.len() <= 1 {
        return (SimulationResult::Completed(0), vec![world.clone()]);
    }
    
    let mut history = vec![world.clone()];
    let mut current = world.step();
    
    loop {
        history.push(current.clone());
        
        if current.time > max_minutes {
            return (SimulationResult::Never, history);
        }
        
        if current.all_rumors_shared() {
            return (SimulationResult::Completed(current.time), history);
        }
        
        current = current.step();
    }
}

// ============================================================
// 4. ヘルパー関数
// ============================================================

/// ドライバーが特定の時間後にどの停留所にいるかを計算
pub fn stop_at_time(driver: &Driver, time: usize) -> Stop {
    driver.route[(driver.position + time) % driver.route.len()]
}

/// 2人のドライバーが出会う最初の時間を計算
pub fn first_meeting_time(d1: &Driver, d2: &Driver, max_time: usize) -> Option<usize> {
    (0..=max_time).find(|&t| stop_at_time(d1, t) == stop_at_time(d2, t))
}

/// ルートの最小公倍数を計算
pub fn route_lcm(routes: &[Vec<Stop>]) -> usize {
    fn gcd(a: usize, b: usize) -> usize {
        if b == 0 { a } else { gcd(b, a % b) }
    }
    
    fn lcm(a: usize, b: usize) -> usize {
        a * b / gcd(a, b)
    }
    
    routes
        .iter()
        .map(|r| r.len())
        .reduce(lcm)
        .unwrap_or(1)
}

// ============================================================
// 5. 拡張シミュレーション
// ============================================================

/// 遅延付きドライバー（休憩を取る）
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DelayedDriver {
    pub name: String,
    pub route: Vec<Stop>,
    pub position: usize,
    pub rumors: HashSet<Rumor>,
    pub delay: i32,
    pub delay_pattern: Vec<i32>,
}

impl DelayedDriver {
    pub fn new(name: &str, route: Vec<Stop>, rumors: HashSet<Rumor>) -> Self {
        Self {
            name: name.to_string(),
            route,
            position: 0,
            rumors,
            delay: 0,
            delay_pattern: Vec::new(),
        }
    }

    pub fn current_stop(&self) -> Stop {
        self.route[self.position % self.route.len()]
    }

    pub fn move_forward(&self) -> Self {
        if self.delay > 0 {
            Self {
                delay: self.delay - 1,
                ..self.clone()
            }
        } else {
            let next_pos = self.position + 1;
            let next_delay = if !self.delay_pattern.is_empty() {
                self.delay_pattern[next_pos % self.delay_pattern.len()]
            } else {
                0
            };
            Self {
                position: next_pos,
                delay: next_delay,
                ..self.clone()
            }
        }
    }

    pub fn add_rumors(&self, new_rumors: &HashSet<Rumor>) -> Self {
        let mut combined = self.rumors.clone();
        combined.extend(new_rumors.clone());
        Self {
            rumors: combined,
            ..self.clone()
        }
    }
}

/// 遅延付きワールド
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DelayedWorld {
    pub drivers: Vec<DelayedDriver>,
    pub time: i32,
}

impl DelayedWorld {
    pub fn new(drivers: Vec<DelayedDriver>) -> Self {
        Self { drivers, time: 0 }
    }

    pub fn move_drivers(&self) -> Self {
        Self {
            drivers: self.drivers.iter().map(|d| d.move_forward()).collect(),
            ..self.clone()
        }
    }

    pub fn drivers_by_stop(&self) -> HashMap<Stop, Vec<&DelayedDriver>> {
        let mut groups: HashMap<Stop, Vec<&DelayedDriver>> = HashMap::new();
        for driver in &self.drivers {
            groups
                .entry(driver.current_stop())
                .or_default()
                .push(driver);
        }
        groups
    }

    pub fn spread_rumors(&self) -> Self {
        let groups = self.drivers_by_stop();
        let mut updated_rumors: HashMap<String, HashSet<Rumor>> = HashMap::new();
        
        for drivers_at_stop in groups.values() {
            let all_rumors: HashSet<Rumor> = drivers_at_stop
                .iter()
                .flat_map(|d| d.rumors.clone())
                .collect();
            
            for driver in drivers_at_stop {
                updated_rumors.insert(driver.name.clone(), all_rumors.clone());
            }
        }
        
        let new_drivers = self
            .drivers
            .iter()
            .map(|d| {
                if let Some(new_rumors) = updated_rumors.get(&d.name) {
                    DelayedDriver {
                        rumors: new_rumors.clone(),
                        ..d.clone()
                    }
                } else {
                    d.clone()
                }
            })
            .collect();
        
        Self {
            drivers: new_drivers,
            ..self.clone()
        }
    }

    pub fn step(&self) -> Self {
        let moved = self.move_drivers();
        let spread = moved.spread_rumors();
        Self {
            time: self.time + 1,
            ..spread
        }
    }

    pub fn all_rumors_shared(&self) -> bool {
        if self.drivers.is_empty() {
            return true;
        }
        
        let first_rumors = &self.drivers[0].rumors;
        self.drivers.iter().all(|d| &d.rumors == first_rumors)
    }
}

pub fn simulate_delayed(world: &DelayedWorld, max_minutes: i32) -> SimulationResult {
    if world.drivers.len() <= 1 {
        return SimulationResult::Completed(0);
    }
    
    if world.all_rumors_shared() {
        return SimulationResult::Completed(0);
    }
    
    let mut current = world.step();
    
    loop {
        if current.time > max_minutes {
            return SimulationResult::Never;
        }
        
        if current.all_rumors_shared() {
            return SimulationResult::Completed(current.time);
        }
        
        current = current.step();
    }
}

// ============================================================
// 6. 統計情報
// ============================================================

/// シミュレーション統計
#[derive(Debug, Clone)]
pub struct SimulationStats {
    pub total_minutes: i32,
    pub total_meetings: i32,
    pub meetings_by_stop: HashMap<Stop, i32>,
    pub rumor_spread_timeline: Vec<(i32, usize)>,
}

/// 統計情報付きシミュレーション
pub fn simulate_with_stats(world: &World, max_minutes: i32) -> (SimulationResult, SimulationStats) {
    if world.drivers.len() <= 1 {
        return (
            SimulationResult::Completed(0),
            SimulationStats {
                total_minutes: 0,
                total_meetings: 0,
                meetings_by_stop: HashMap::new(),
                rumor_spread_timeline: Vec::new(),
            },
        );
    }
    
    let mut meetings = 0;
    let mut meetings_by_stop: HashMap<Stop, i32> = HashMap::new();
    let mut timeline = Vec::new();
    
    let mut current = world.step();
    
    loop {
        // 統計情報を収集
        let current_meetings = current
            .drivers_by_stop()
            .values()
            .filter(|drivers| drivers.len() > 1)
            .count() as i32;
        meetings += current_meetings;
        
        for (stop, drivers) in current.drivers_by_stop() {
            if drivers.len() > 1 {
                *meetings_by_stop.entry(stop).or_insert(0) += 1;
            }
        }
        
        let shared_count = current.drivers[0].rumors.len();
        timeline.push((current.time, shared_count));
        
        if current.time > max_minutes {
            return (
                SimulationResult::Never,
                SimulationStats {
                    total_minutes: current.time,
                    total_meetings: meetings,
                    meetings_by_stop,
                    rumor_spread_timeline: timeline,
                },
            );
        }
        
        if current.all_rumors_shared() {
            return (
                SimulationResult::Completed(current.time),
                SimulationStats {
                    total_minutes: current.time,
                    total_meetings: meetings,
                    meetings_by_stop,
                    rumor_spread_timeline: timeline,
                },
            );
        }
        
        current = current.step();
    }
}

// ============================================================
// 7. ビルダーパターン
// ============================================================

/// シミュレーションビルダー
#[derive(Default)]
pub struct SimulationBuilder {
    drivers: Vec<Driver>,
    max_minutes: i32,
}

impl SimulationBuilder {
    pub fn new() -> Self {
        Self {
            drivers: Vec::new(),
            max_minutes: 480,
        }
    }

    pub fn add_driver(mut self, name: &str, route: Vec<Stop>, rumors: HashSet<Rumor>) -> Self {
        self.drivers.push(Driver::new(name, route, rumors));
        self
    }

    pub fn add_driver_with_auto_rumor(mut self, name: &str, route: Vec<Stop>) -> Self {
        self.drivers.push(Driver::with_auto_rumor(name, route));
        self
    }

    pub fn with_max_minutes(mut self, minutes: i32) -> Self {
        self.max_minutes = minutes;
        self
    }

    pub fn build(&self) -> World {
        World::new(self.drivers.clone())
    }

    pub fn run(&self) -> SimulationResult {
        simulate(&World::new(self.drivers.clone()), self.max_minutes)
    }

    pub fn run_with_history(&self) -> (SimulationResult, Vec<World>) {
        simulate_with_history(&World::new(self.drivers.clone()), self.max_minutes)
    }

    pub fn run_with_stats(&self) -> (SimulationResult, SimulationStats) {
        simulate_with_stats(&World::new(self.drivers.clone()), self.max_minutes)
    }
}

pub fn builder() -> SimulationBuilder {
    SimulationBuilder::new()
}

// ============================================================
// 8. DSL for route definition
// ============================================================

pub mod route_dsl {
    use super::Stop;

    /// ルートを範囲で定義
    pub fn range(start: Stop, end: Stop) -> Vec<Stop> {
        (start..=end).collect()
    }

    /// ルートを逆順で定義
    pub fn reverse(route: &[Stop]) -> Vec<Stop> {
        route.iter().rev().cloned().collect()
    }

    /// ルートを往復で定義
    pub fn round_trip(route: &[Stop]) -> Vec<Stop> {
        if route.len() <= 1 {
            return route.to_vec();
        }
        let mut result = route.to_vec();
        result.extend(route.iter().rev().skip(1).cloned());
        result
    }

    /// 複数のセグメントを結合
    pub fn concat(segments: &[&[Stop]]) -> Vec<Stop> {
        segments.iter().flat_map(|s| s.iter().cloned()).collect()
    }
}

// ============================================================
// 9. 関数型コンビネータ
// ============================================================

/// 世界の変換関数の型
pub type WorldTransform = Box<dyn Fn(World) -> World>;

/// 変換を合成
pub fn compose(transforms: Vec<fn(World) -> World>) -> impl Fn(World) -> World {
    move |world| transforms.iter().fold(world, |w, t| t(w))
}

/// 条件付き変換
pub fn when<F, G>(condition: F, transform: G) -> impl Fn(World) -> World
where
    F: Fn(&World) -> bool,
    G: Fn(World) -> World,
{
    move |world| {
        if condition(&world) {
            transform(world)
        } else {
            world
        }
    }
}

/// N回変換を適用
pub fn repeat<F>(n: usize, transform: F) -> impl Fn(World) -> World
where
    F: Fn(World) -> World,
{
    move |world| (0..n).fold(world, |w, _| transform(w))
}

/// 条件が満たされるまで変換を適用
pub fn until<F, G>(condition: F, transform: G) -> impl Fn(World) -> World
where
    F: Fn(&World) -> bool,
    G: Fn(World) -> World,
{
    move |world| {
        let mut current = world;
        while !condition(&current) {
            current = transform(current);
        }
        current
    }
}

// ============================================================
// テスト
// ============================================================

#[cfg(test)]
mod tests {
    use super::*;

    // Helper to create HashSet from slice
    fn rumors(items: &[&str]) -> HashSet<Rumor> {
        items.iter().map(|s| s.to_string()).collect()
    }

    // ============================================================
    // 1. Driver データモデル
    // ============================================================

    mod driver_tests {
        use super::*;

        #[test]
        fn creates_driver_with_route_and_rumors() {
            let driver = Driver::new("D1", vec![1, 2, 3], rumors(&["rumor-a"]));
            assert_eq!(driver.name, "D1");
            assert_eq!(driver.route, vec![1, 2, 3]);
            assert_eq!(driver.rumors, rumors(&["rumor-a"]));
        }

        #[test]
        fn creates_driver_with_auto_rumor() {
            let driver = Driver::with_auto_rumor("D1", vec![1, 2, 3]);
            assert_eq!(driver.rumors, rumors(&["rumor-D1"]));
        }

        #[test]
        fn gets_current_stop_at_initial_position() {
            let driver = Driver::new("D1", vec![1, 2, 3], HashSet::new());
            assert_eq!(driver.current_stop(), 1);
        }

        #[test]
        fn gets_current_stop_after_move() {
            let driver = Driver::new("D1", vec![1, 2, 3], HashSet::new()).move_forward();
            assert_eq!(driver.current_stop(), 2);
        }

        #[test]
        fn moves_to_next_stop() {
            let driver = Driver::new("D1", vec![1, 2, 3], HashSet::new());
            assert_eq!(driver.move_forward().current_stop(), 2);
            assert_eq!(driver.move_forward().move_forward().current_stop(), 3);
        }

        #[test]
        fn route_cycles() {
            let driver = Driver::new("D1", vec![1, 2, 3], HashSet::new());
            let after_cycle = driver.move_forward().move_forward().move_forward();
            assert_eq!(after_cycle.current_stop(), 1);
        }

        #[test]
        fn adds_rumors() {
            let driver = Driver::new("D1", vec![1], rumors(&["a"]));
            let updated = driver.add_rumors(&rumors(&["b", "c"]));
            assert_eq!(updated.rumors, rumors(&["a", "b", "c"]));
        }

        #[test]
        fn same_rumors_do_not_duplicate() {
            let driver = Driver::new("D1", vec![1], rumors(&["a"]));
            let updated = driver.add_rumors(&rumors(&["a", "b"]));
            assert_eq!(updated.rumors, rumors(&["a", "b"]));
        }
    }

    // ============================================================
    // 2. World データモデル
    // ============================================================

    mod world_tests {
        use super::*;

        #[test]
        fn groups_drivers_by_stop() {
            let world = World::new(vec![
                Driver::new("D1", vec![1, 2], HashSet::new()),
                Driver::new("D2", vec![1, 3], HashSet::new()),
                Driver::new("D3", vec![2, 3], HashSet::new()),
            ]);
            let by_stop = world.drivers_by_stop();
            let stop1_names: Vec<_> = by_stop[&1].iter().map(|d| &d.name).collect();
            assert!(stop1_names.contains(&&"D1".to_string()));
            assert!(stop1_names.contains(&&"D2".to_string()));
        }

        #[test]
        fn moves_all_drivers() {
            let world = World::new(vec![
                Driver::new("D1", vec![1, 2], HashSet::new()),
                Driver::new("D2", vec![3, 4], HashSet::new()),
            ]);
            let moved = world.move_drivers();
            let stops: Vec<_> = moved.drivers.iter().map(|d| d.current_stop()).collect();
            assert!(stops.contains(&2));
            assert!(stops.contains(&4));
        }

        #[test]
        fn spreads_rumors_between_drivers_at_same_stop() {
            let world = World::new(vec![
                Driver::new("D1", vec![1], rumors(&["a"])),
                Driver::new("D2", vec![1], rumors(&["b"])),
            ]);
            let spread = world.spread_rumors();
            for d in &spread.drivers {
                assert_eq!(d.rumors, rumors(&["a", "b"]));
            }
        }

        #[test]
        fn does_not_spread_rumors_between_different_stops() {
            let world = World::new(vec![
                Driver::new("D1", vec![1], rumors(&["a"])),
                Driver::new("D2", vec![2], rumors(&["b"])),
            ]);
            let spread = world.spread_rumors();
            assert_eq!(
                spread.drivers.iter().find(|d| d.name == "D1").unwrap().rumors,
                rumors(&["a"])
            );
            assert_eq!(
                spread.drivers.iter().find(|d| d.name == "D2").unwrap().rumors,
                rumors(&["b"])
            );
        }

        #[test]
        fn step_moves_and_spreads_rumors() {
            let world = World::new(vec![
                Driver::new("D1", vec![1, 2], rumors(&["a"])),
                Driver::new("D2", vec![3, 2], rumors(&["b"])),
            ]);
            let stepped = world.step();
            assert_eq!(stepped.time, 1);
            assert_eq!(stepped.drivers.iter().find(|d| d.name == "D1").unwrap().current_stop(), 2);
            assert_eq!(stepped.drivers.iter().find(|d| d.name == "D2").unwrap().current_stop(), 2);
            for d in &stepped.drivers {
                assert_eq!(d.rumors, rumors(&["a", "b"]));
            }
        }

        #[test]
        fn all_rumors_shared_when_same() {
            let world = World::new(vec![
                Driver::new("D1", vec![1], rumors(&["a", "b"])),
                Driver::new("D2", vec![2], rumors(&["a", "b"])),
            ]);
            assert!(world.all_rumors_shared());
        }

        #[test]
        fn not_all_rumors_shared_when_different() {
            let world = World::new(vec![
                Driver::new("D1", vec![1], rumors(&["a"])),
                Driver::new("D2", vec![2], rumors(&["b"])),
            ]);
            assert!(!world.all_rumors_shared());
        }

        #[test]
        fn empty_world_is_complete() {
            let world = World::new(vec![]);
            assert!(world.all_rumors_shared());
        }
    }

    // ============================================================
    // 3. シミュレーション
    // ============================================================

    mod simulation_tests {
        use super::*;

        #[test]
        fn drivers_meeting_next_step_complete_in_1_minute() {
            let world = World::new(vec![
                Driver::new("D1", vec![1, 2], rumors(&["a"])),
                Driver::new("D2", vec![3, 2], rumors(&["b"])),
            ]);
            assert_eq!(simulate(&world, 480), SimulationResult::Completed(1));
        }

        #[test]
        fn drivers_cycling_to_meet_complete_in_2_steps() {
            let world = World::new(vec![
                Driver::new("D1", vec![1, 2], rumors(&["a"])),
                Driver::new("D2", vec![1, 3], rumors(&["b"])),
            ]);
            assert_eq!(simulate(&world, 480), SimulationResult::Completed(2));
        }

        #[test]
        fn drivers_never_meeting_returns_never() {
            let world = World::new(vec![
                Driver::new("D1", vec![1], rumors(&["a"])),
                Driver::new("D2", vec![2], rumors(&["b"])),
            ]);
            assert_eq!(simulate(&world, 10), SimulationResult::Never);
        }

        #[test]
        fn single_driver_completes_immediately() {
            let world = World::new(vec![
                Driver::new("D1", vec![1, 2], rumors(&["a"])),
            ]);
            assert_eq!(simulate(&world, 480), SimulationResult::Completed(0));
        }

        #[test]
        fn three_drivers_meeting_sequentially() {
            let world = World::new(vec![
                Driver::new("D1", vec![3, 1, 2, 3], rumors(&["a"])),
                Driver::new("D2", vec![3, 2, 3, 1], rumors(&["b"])),
                Driver::new("D3", vec![4, 2, 3, 4, 5], rumors(&["c"])),
            ]);
            let result = simulate(&world, 480);
            assert!(result.is_completed());
        }

        #[test]
        fn history_simulation_returns_states() {
            let world = World::new(vec![
                Driver::new("D1", vec![1, 2], rumors(&["a"])),
                Driver::new("D2", vec![3, 2], rumors(&["b"])),
            ]);
            let (result, history) = simulate_with_history(&world, 480);
            assert_eq!(result, SimulationResult::Completed(1));
            assert_eq!(history.len(), 2);
            assert_eq!(history[0].time, 0);
            assert_eq!(history[1].time, 1);
        }
    }

    // ============================================================
    // 4. ヘルパー関数
    // ============================================================

    mod helper_tests {
        use super::*;

        #[test]
        fn stop_at_time_calculates_position() {
            let driver = Driver::new("D1", vec![1, 2, 3], HashSet::new());
            assert_eq!(stop_at_time(&driver, 0), 1);
            assert_eq!(stop_at_time(&driver, 1), 2);
            assert_eq!(stop_at_time(&driver, 2), 3);
            assert_eq!(stop_at_time(&driver, 3), 1); // cycles
        }

        #[test]
        fn first_meeting_time_finds_meeting() {
            let d1 = Driver::new("D1", vec![1, 2, 3], HashSet::new());
            let d2 = Driver::new("D2", vec![3, 2, 1], HashSet::new());
            assert_eq!(first_meeting_time(&d1, &d2, 480), Some(1)); // both at 2
        }

        #[test]
        fn first_meeting_time_returns_none_when_no_meeting() {
            let d1 = Driver::new("D1", vec![1], HashSet::new());
            let d2 = Driver::new("D2", vec![2], HashSet::new());
            assert_eq!(first_meeting_time(&d1, &d2, 10), None);
        }

        #[test]
        fn route_lcm_calculates_correctly() {
            assert_eq!(route_lcm(&[vec![1, 2], vec![1, 2, 3]]), 6); // lcm(2, 3)
            assert_eq!(route_lcm(&[vec![1, 2, 3, 4], vec![1, 2, 3, 4, 5, 6]]), 12); // lcm(4, 6)
        }
    }

    // ============================================================
    // 5. 統計情報
    // ============================================================

    mod stats_tests {
        use super::*;

        #[test]
        fn stats_simulation_returns_statistics() {
            let world = World::new(vec![
                Driver::new("D1", vec![1, 2], rumors(&["a"])),
                Driver::new("D2", vec![3, 2], rumors(&["b"])),
            ]);
            let (result, stats) = simulate_with_stats(&world, 480);

            assert_eq!(result, SimulationResult::Completed(1));
            assert_eq!(stats.total_minutes, 1);
            assert!(stats.total_meetings > 0);
        }
    }

    // ============================================================
    // 6. ビルダーパターン
    // ============================================================

    mod builder_tests {
        use super::*;

        #[test]
        fn builds_simulation() {
            let result = builder()
                .add_driver("D1", vec![1, 2], rumors(&["a"]))
                .add_driver("D2", vec![3, 2], rumors(&["b"]))
                .run();

            assert_eq!(result, SimulationResult::Completed(1));
        }

        #[test]
        fn adds_drivers_with_auto_rumor() {
            let result = builder()
                .add_driver_with_auto_rumor("D1", vec![1, 2])
                .add_driver_with_auto_rumor("D2", vec![3, 2])
                .run();

            assert_eq!(result, SimulationResult::Completed(1));
        }

        #[test]
        fn sets_max_minutes() {
            let result = builder()
                .add_driver("D1", vec![1], rumors(&["a"]))
                .add_driver("D2", vec![2], rumors(&["b"]))
                .with_max_minutes(5)
                .run();

            assert_eq!(result, SimulationResult::Never);
        }

        #[test]
        fn runs_with_history() {
            let (result, history) = builder()
                .add_driver("D1", vec![1, 2], rumors(&["a"]))
                .add_driver("D2", vec![3, 2], rumors(&["b"]))
                .run_with_history();

            assert_eq!(result, SimulationResult::Completed(1));
            assert!(!history.is_empty());
        }
    }

    // ============================================================
    // 7. RouteDSL
    // ============================================================

    mod route_dsl_tests {
        use super::route_dsl::*;

        #[test]
        fn range_creates_route() {
            assert_eq!(range(1, 5), vec![1, 2, 3, 4, 5]);
        }

        #[test]
        fn reverse_reverses_route() {
            assert_eq!(reverse(&[1, 2, 3]), vec![3, 2, 1]);
        }

        #[test]
        fn round_trip_creates_round_trip_route() {
            assert_eq!(round_trip(&[1, 2, 3]), vec![1, 2, 3, 2, 1]);
        }

        #[test]
        fn concat_joins_segments() {
            assert_eq!(concat(&[&[1, 2][..], &[3, 4][..]]), vec![1, 2, 3, 4]);
        }
    }

    // ============================================================
    // 8. 関数型コンビネータ
    // ============================================================

    mod combinator_tests {
        use super::*;

        #[test]
        fn compose_composes_transforms() {
            let world = World::new(vec![
                Driver::new("D1", vec![1, 2, 3], rumors(&["a"])),
            ]);
            let double_move = compose(vec![
                |w: World| w.move_drivers(),
                |w: World| w.move_drivers(),
            ]);
            let result = double_move(world);
            assert_eq!(result.drivers[0].current_stop(), 3);
        }

        #[test]
        fn when_applies_conditionally() {
            let world = World::new(vec![
                Driver::new("D1", vec![1, 2], rumors(&["a"])),
            ]);
            let move_if_at_1 = when(
                |w: &World| w.drivers[0].current_stop() == 1,
                |w: World| w.move_drivers(),
            );
            let result = move_if_at_1(world);
            assert_eq!(result.drivers[0].current_stop(), 2);
        }

        #[test]
        fn when_skips_when_condition_false() {
            let world = World::new(vec![
                Driver::new("D1", vec![1, 2], rumors(&["a"])),
            ]).move_drivers();
            let move_if_at_1 = when(
                |w: &World| w.drivers[0].current_stop() == 1,
                |w: World| w.move_drivers(),
            );
            let result = move_if_at_1(world);
            assert_eq!(result.drivers[0].current_stop(), 2); // no change
        }

        #[test]
        fn repeat_applies_n_times() {
            let world = World::new(vec![
                Driver::new("D1", vec![1, 2, 3, 4, 5], rumors(&["a"])),
            ]);
            let move_thrice = repeat(3, |w: World| w.move_drivers());
            let result = move_thrice(world);
            assert_eq!(result.drivers[0].current_stop(), 4);
        }

        #[test]
        fn until_applies_until_condition_met() {
            let world = World::new(vec![
                Driver::new("D1", vec![1, 2], rumors(&["a"])),
                Driver::new("D2", vec![3, 2], rumors(&["b"])),
            ]);
            let until_shared = until(
                |w: &World| w.all_rumors_shared(),
                |w: World| w.step(),
            );
            let result = until_shared(world);
            assert!(result.all_rumors_shared());
        }
    }

    // ============================================================
    // 9. 遅延付きシミュレーション
    // ============================================================

    mod delayed_tests {
        use super::*;

        #[test]
        fn delayed_drivers_without_delay_work_normally() {
            let mut rumors1 = HashSet::new();
            rumors1.insert("a".to_string());
            let mut rumors2 = HashSet::new();
            rumors2.insert("b".to_string());
            
            let world = DelayedWorld::new(vec![
                DelayedDriver::new("D1", vec![1, 2], rumors1),
                DelayedDriver::new("D2", vec![1, 3], rumors2),
            ]);
            assert_eq!(simulate_delayed(&world, 480), SimulationResult::Completed(2));
        }

        #[test]
        fn delayed_driver_stays_at_stop() {
            let driver = DelayedDriver {
                name: "D1".to_string(),
                route: vec![1, 2, 3],
                position: 0,
                rumors: HashSet::new(),
                delay: 2,
                delay_pattern: Vec::new(),
            };
            let moved1 = driver.move_forward();
            assert_eq!(moved1.current_stop(), 1);
            assert_eq!(moved1.delay, 1);

            let moved2 = moved1.move_forward();
            assert_eq!(moved2.current_stop(), 1);
            assert_eq!(moved2.delay, 0);

            let moved3 = moved2.move_forward();
            assert_eq!(moved3.current_stop(), 2);
        }
    }

    // ============================================================
    // 10. エッジケース
    // ============================================================

    mod edge_case_tests {
        use super::*;

        #[test]
        fn all_same_rumors_completes_immediately() {
            let world = World::new(vec![
                Driver::new("D1", vec![1, 2], rumors(&["a"])),
                Driver::new("D2", vec![3, 4], rumors(&["a"])),
            ]);
            assert_eq!(simulate(&world, 480), SimulationResult::Completed(0));
        }

        #[test]
        fn empty_world_completes_immediately() {
            let world = World::new(vec![]);
            assert_eq!(simulate(&world, 480), SimulationResult::Completed(0));
        }

        #[test]
        fn single_stop_route_drivers() {
            let world = World::new(vec![
                Driver::new("D1", vec![1], rumors(&["a"])),
                Driver::new("D2", vec![1], rumors(&["b"])),
            ]);
            assert_eq!(simulate(&world, 480), SimulationResult::Completed(1));
        }

        #[test]
        fn same_route_drivers_always_meet() {
            let world = World::new(vec![
                Driver::new("D1", vec![1, 2, 3], rumors(&["a"])),
                Driver::new("D2", vec![1, 2, 3], rumors(&["b"])),
            ]);
            let result = simulate(&world, 480);
            assert!(result.is_completed());
        }
    }
}
