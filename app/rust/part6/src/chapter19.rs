//! 第19章: Wa-Tor シミュレーション
//!
//! セルオートマトンによる捕食者-被食者モデルの実装。
//! 魚（被食者）とサメ（捕食者）の生態系シミュレーション。

use rand::prelude::*;
use std::collections::{HashMap, HashSet};

// ============================================================
// 1. 設定パラメータ
// ============================================================

pub mod config {
    /// 魚の繁殖年齢
    pub const FISH_REPRODUCTION_AGE: i32 = 6;

    /// サメの繁殖年齢
    pub const SHARK_REPRODUCTION_AGE: i32 = 5;
    /// サメの繁殖に必要な体力
    pub const SHARK_REPRODUCTION_HEALTH: i32 = 8;
    /// サメの初期体力
    pub const SHARK_STARTING_HEALTH: i32 = 5;
    /// 捕食時の体力回復量
    pub const SHARK_EATING_HEALTH: i32 = 5;
    /// サメの最大体力
    pub const SHARK_MAX_HEALTH: i32 = 10;
}

// ============================================================
// 2. 座標と方向
// ============================================================

/// 座標
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Position {
    pub x: i32,
    pub y: i32,
}

impl Position {
    pub fn new(x: i32, y: i32) -> Self {
        Self { x, y }
    }
}

impl std::ops::Add for Position {
    type Output = Position;

    fn add(self, other: Position) -> Position {
        Position::new(self.x + other.x, self.y + other.y)
    }
}

/// 8方向の移動差分
pub fn direction_deltas() -> Vec<Position> {
    let mut deltas = Vec::new();
    for dx in -1..=1 {
        for dy in -1..=1 {
            if dx != 0 || dy != 0 {
                deltas.push(Position::new(dx, dy));
            }
        }
    }
    deltas
}

// ============================================================
// 3. セルの定義
// ============================================================

/// セルの種類
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Cell {
    /// 水（空のセル）
    Water,
    /// 魚（被食者）
    Fish(Fish),
    /// サメ（捕食者）
    Shark(Shark),
}

impl Cell {
    pub fn display(&self) -> char {
        match self {
            Cell::Water => '.',
            Cell::Fish(_) => 'f',
            Cell::Shark(_) => 'S',
        }
    }

    pub fn is_water(&self) -> bool {
        matches!(self, Cell::Water)
    }

    pub fn is_fish(&self) -> bool {
        matches!(self, Cell::Fish(_))
    }

    pub fn is_shark(&self) -> bool {
        matches!(self, Cell::Shark(_))
    }
}

/// 魚（被食者）
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Fish {
    pub age: i32,
}

impl Fish {
    pub fn new() -> Self {
        Self { age: 0 }
    }

    pub fn with_age(age: i32) -> Self {
        Self { age }
    }

    pub fn increment_age(&self) -> Self {
        Self { age: self.age + 1 }
    }

    pub fn reproduction_age() -> i32 {
        config::FISH_REPRODUCTION_AGE
    }
}

impl Default for Fish {
    fn default() -> Self {
        Self::new()
    }
}

/// サメ（捕食者）
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Shark {
    pub age: i32,
    pub health: i32,
}

impl Shark {
    pub fn new() -> Self {
        Self {
            age: 0,
            health: config::SHARK_STARTING_HEALTH,
        }
    }

    pub fn with_age_and_health(age: i32, health: i32) -> Self {
        Self { age, health }
    }

    pub fn increment_age(&self) -> Self {
        Self {
            age: self.age + 1,
            health: self.health,
        }
    }

    pub fn decrement_health(&self) -> Self {
        Self {
            age: self.age,
            health: self.health - 1,
        }
    }

    pub fn feed(&self) -> Self {
        let new_health = (self.health + config::SHARK_EATING_HEALTH).min(config::SHARK_MAX_HEALTH);
        Self {
            age: self.age,
            health: new_health,
        }
    }

    pub fn reproduction_age() -> i32 {
        config::SHARK_REPRODUCTION_AGE
    }
}

impl Default for Shark {
    fn default() -> Self {
        Self::new()
    }
}

// ============================================================
// 4. ワールド
// ============================================================

/// シミュレーションワールド
#[derive(Debug, Clone)]
pub struct World {
    pub width: i32,
    pub height: i32,
    pub cells: HashMap<Position, Cell>,
    pub generation: i32,
}

impl World {
    /// 空のワールドを作成
    pub fn new(width: i32, height: i32) -> Self {
        let mut cells = HashMap::new();
        for x in 0..width {
            for y in 0..height {
                cells.insert(Position::new(x, y), Cell::Water);
            }
        }
        Self {
            width,
            height,
            cells,
            generation: 0,
        }
    }

    /// 座標をトーラス上でラップ
    pub fn wrap(&self, pos: Position) -> Position {
        Position::new(
            ((pos.x % self.width) + self.width) % self.width,
            ((pos.y % self.height) + self.height) % self.height,
        )
    }

    /// セルを取得
    pub fn get_cell(&self, pos: Position) -> Cell {
        self.cells.get(&self.wrap(pos)).cloned().unwrap_or(Cell::Water)
    }

    /// セルを設定
    pub fn set_cell(&self, pos: Position, cell: Cell) -> Self {
        let mut new_cells = self.cells.clone();
        new_cells.insert(self.wrap(pos), cell);
        Self {
            width: self.width,
            height: self.height,
            cells: new_cells,
            generation: self.generation,
        }
    }

    /// 隣接セルの座標を取得（8方向）
    pub fn neighbors(&self, pos: Position) -> Vec<Position> {
        direction_deltas()
            .iter()
            .map(|&d| self.wrap(pos + d))
            .collect()
    }

    /// 隣接する空のセルを取得
    pub fn empty_neighbors(&self, pos: Position) -> Vec<Position> {
        self.neighbors(pos)
            .into_iter()
            .filter(|&p| self.get_cell(p).is_water())
            .collect()
    }

    /// 隣接する魚のセルを取得
    pub fn fish_neighbors(&self, pos: Position) -> Vec<Position> {
        self.neighbors(pos)
            .into_iter()
            .filter(|&p| self.get_cell(p).is_fish())
            .collect()
    }

    /// ワールドの表示
    pub fn display(&self) -> String {
        let mut result = String::new();
        for y in 0..self.height {
            for x in 0..self.width {
                result.push(self.get_cell(Position::new(x, y)).display());
            }
            if y < self.height - 1 {
                result.push('\n');
            }
        }
        result
    }

    /// 統計情報
    pub fn statistics(&self) -> Statistics {
        let mut fish = 0;
        let mut sharks = 0;
        let mut water = 0;

        for cell in self.cells.values() {
            match cell {
                Cell::Fish(_) => fish += 1,
                Cell::Shark(_) => sharks += 1,
                Cell::Water => water += 1,
            }
        }

        Statistics {
            fish,
            sharks,
            water,
            generation: self.generation,
        }
    }

    /// 全座標を取得
    pub fn all_positions(&self) -> Vec<Position> {
        let mut positions = Vec::new();
        for x in 0..self.width {
            for y in 0..self.height {
                positions.push(Position::new(x, y));
            }
        }
        positions
    }

    /// ランダムに生物を配置
    pub fn populate_random<R: Rng>(&self, fish_count: usize, shark_count: usize, rng: &mut R) -> Self {
        let mut positions: Vec<_> = self.all_positions();
        positions.shuffle(rng);

        let fish_positions: Vec<_> = positions.iter().take(fish_count).cloned().collect();
        let shark_positions: Vec<_> = positions.iter().skip(fish_count).take(shark_count).cloned().collect();

        let mut world = self.clone();
        for pos in fish_positions {
            world = world.set_cell(pos, Cell::Fish(Fish::new()));
        }
        for pos in shark_positions {
            world = world.set_cell(pos, Cell::Shark(Shark::new()));
        }
        world
    }
}

/// 統計情報
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Statistics {
    pub fish: i32,
    pub sharks: i32,
    pub water: i32,
    pub generation: i32,
}

impl Statistics {
    pub fn total(&self) -> i32 {
        self.fish + self.sharks + self.water
    }
}

// ============================================================
// 5. アクション結果
// ============================================================

/// セルの更新結果
#[derive(Debug, Clone)]
pub enum CellUpdate {
    /// 移動
    Move {
        from: Position,
        to: Position,
        cell: Cell,
    },
    /// 繁殖
    Reproduce {
        parent: Position,
        child: Position,
        parent_cell: Cell,
        child_cell: Cell,
    },
    /// 捕食
    Eat {
        from: Position,
        to: Position,
        cell: Cell,
    },
    /// 死亡
    Die { at: Position },
    /// 変更なし
    NoChange,
}

// ============================================================
// 6. シミュレーションロジック
// ============================================================

pub mod simulation {
    use super::*;

    /// 動物の移動を試みる
    pub fn try_move<R: Rng>(cell: &Cell, pos: Position, world: &World, rng: &mut R) -> Option<CellUpdate> {
        let empty = world.empty_neighbors(pos);
        if empty.is_empty() {
            return None;
        }
        let target = empty[rng.gen_range(0..empty.len())];
        Some(CellUpdate::Move {
            from: pos,
            to: target,
            cell: cell.clone(),
        })
    }

    /// 動物の繁殖を試みる
    pub fn try_reproduce<R: Rng>(
        cell: &Cell,
        age: i32,
        reproduction_age: i32,
        pos: Position,
        world: &World,
        rng: &mut R,
    ) -> Option<CellUpdate> {
        if age < reproduction_age {
            return None;
        }

        let empty = world.empty_neighbors(pos);
        if empty.is_empty() {
            return None;
        }

        let child_pos = empty[rng.gen_range(0..empty.len())];
        let (parent_cell, child_cell) = match cell {
            Cell::Fish(_) => (Cell::Fish(Fish::new()), Cell::Fish(Fish::new())),
            Cell::Shark(shark) => (
                Cell::Shark(Shark::with_age_and_health(0, shark.health)),
                Cell::Shark(Shark::new()),
            ),
            Cell::Water => return None,
        };

        Some(CellUpdate::Reproduce {
            parent: pos,
            child: child_pos,
            parent_cell,
            child_cell,
        })
    }

    /// サメの捕食を試みる
    pub fn try_eat<R: Rng>(shark: &Shark, pos: Position, world: &World, rng: &mut R) -> Option<CellUpdate> {
        let fish_cells = world.fish_neighbors(pos);
        if fish_cells.is_empty() {
            return None;
        }
        let target = fish_cells[rng.gen_range(0..fish_cells.len())];
        Some(CellUpdate::Eat {
            from: pos,
            to: target,
            cell: Cell::Shark(shark.feed()),
        })
    }

    /// 魚のティック処理
    pub fn tick_fish<R: Rng>(fish: &Fish, pos: Position, world: &World, rng: &mut R) -> CellUpdate {
        let aged_fish = fish.increment_age();
        let aged_cell = Cell::Fish(aged_fish.clone());

        // 優先順位: 繁殖 > 移動
        if let Some(update) = try_reproduce(
            &aged_cell,
            aged_fish.age,
            Fish::reproduction_age(),
            pos,
            world,
            rng,
        ) {
            return update;
        }

        if let Some(update) = try_move(&aged_cell, pos, world, rng) {
            return update;
        }

        CellUpdate::NoChange
    }

    /// サメのティック処理
    pub fn tick_shark<R: Rng>(shark: &Shark, pos: Position, world: &World, rng: &mut R) -> CellUpdate {
        // 体力が尽きたら死亡
        if shark.health <= 1 {
            return CellUpdate::Die { at: pos };
        }

        let aged_shark = shark.increment_age().decrement_health();
        let aged_cell = Cell::Shark(aged_shark.clone());

        // 優先順位: 繁殖 > 捕食 > 移動
        if let Some(update) = try_reproduce(
            &aged_cell,
            aged_shark.age,
            Shark::reproduction_age(),
            pos,
            world,
            rng,
        ) {
            return update;
        }

        if let Some(update) = try_eat(&aged_shark, pos, world, rng) {
            return update;
        }

        if let Some(update) = try_move(&aged_cell, pos, world, rng) {
            return update;
        }

        CellUpdate::NoChange
    }

    /// セルのティック処理
    pub fn tick_cell<R: Rng>(cell: &Cell, pos: Position, world: &World, rng: &mut R) -> CellUpdate {
        match cell {
            Cell::Water => CellUpdate::NoChange,
            Cell::Fish(fish) => tick_fish(fish, pos, world, rng),
            Cell::Shark(shark) => tick_shark(shark, pos, world, rng),
        }
    }

    /// 更新を適用
    pub fn apply_update(world: &World, update: &CellUpdate) -> World {
        match update {
            CellUpdate::Move { from, to, cell } => {
                world.set_cell(*from, Cell::Water).set_cell(*to, cell.clone())
            }
            CellUpdate::Reproduce {
                parent,
                child,
                parent_cell,
                child_cell,
            } => world
                .set_cell(*parent, parent_cell.clone())
                .set_cell(*child, child_cell.clone()),
            CellUpdate::Eat { from, to, cell } => {
                world.set_cell(*from, Cell::Water).set_cell(*to, cell.clone())
            }
            CellUpdate::Die { at } => world.set_cell(*at, Cell::Water),
            CellUpdate::NoChange => world.clone(),
        }
    }

    /// ワールドの1ステップを実行
    pub fn tick<R: Rng>(world: &World, rng: &mut R) -> World {
        let mut positions = world.all_positions();
        positions.shuffle(rng);
        let mut processed = HashSet::new();

        let mut new_world = world.clone();

        for pos in positions {
            if processed.contains(&pos) {
                continue;
            }

            let cell = new_world.get_cell(pos);
            let update = tick_cell(&cell, pos, &new_world, rng);

            match &update {
                CellUpdate::Move { from, to, .. } => {
                    processed.insert(*from);
                    processed.insert(*to);
                }
                CellUpdate::Reproduce { parent, child, .. } => {
                    processed.insert(*parent);
                    processed.insert(*child);
                }
                CellUpdate::Eat { from, to, .. } => {
                    processed.insert(*from);
                    processed.insert(*to);
                }
                CellUpdate::Die { at } => {
                    processed.insert(*at);
                }
                CellUpdate::NoChange => {}
            }

            new_world = apply_update(&new_world, &update);
        }

        World {
            width: new_world.width,
            height: new_world.height,
            cells: new_world.cells,
            generation: new_world.generation + 1,
        }
    }

    /// N ステップ実行
    pub fn run<R: Rng>(world: &World, steps: usize, rng: &mut R) -> World {
        let mut current = world.clone();
        for _ in 0..steps {
            current = tick(&current, rng);
        }
        current
    }

    /// 履歴付きで実行
    pub fn run_with_history<R: Rng>(world: &World, steps: usize, rng: &mut R) -> Vec<World> {
        let mut history = vec![world.clone()];
        let mut current = world.clone();
        for _ in 0..steps {
            current = tick(&current, rng);
            history.push(current.clone());
        }
        history
    }
}

// ============================================================
// 7. シミュレーションビルダー
// ============================================================

pub struct SimulationBuilder {
    width: i32,
    height: i32,
    fish_count: usize,
    shark_count: usize,
    initial_cells: HashMap<Position, Cell>,
    seed: Option<u64>,
}

impl SimulationBuilder {
    pub fn new() -> Self {
        Self {
            width: 10,
            height: 10,
            fish_count: 0,
            shark_count: 0,
            initial_cells: HashMap::new(),
            seed: None,
        }
    }

    pub fn with_size(mut self, width: i32, height: i32) -> Self {
        self.width = width;
        self.height = height;
        self
    }

    pub fn with_fish(mut self, count: usize) -> Self {
        self.fish_count = count;
        self
    }

    pub fn with_sharks(mut self, count: usize) -> Self {
        self.shark_count = count;
        self
    }

    pub fn with_cell(mut self, pos: Position, cell: Cell) -> Self {
        self.initial_cells.insert(pos, cell);
        self
    }

    pub fn with_seed(mut self, seed: u64) -> Self {
        self.seed = Some(seed);
        self
    }

    pub fn build(self) -> World {
        let mut rng: Box<dyn RngCore> = match self.seed {
            Some(seed) => Box::new(StdRng::seed_from_u64(seed)),
            None => Box::new(thread_rng()),
        };

        let mut world = World::new(self.width, self.height);

        // 初期セルを配置
        for (pos, cell) in self.initial_cells {
            world = world.set_cell(pos, cell);
        }

        // ランダムに生物を追加
        if self.fish_count > 0 || self.shark_count > 0 {
            world = world.populate_random(self.fish_count, self.shark_count, &mut rng);
        }

        world
    }
}

impl Default for SimulationBuilder {
    fn default() -> Self {
        Self::new()
    }
}

// ============================================================
// 8. DSL
// ============================================================

pub mod dsl {
    use super::*;

    pub fn world(width: i32, height: i32) -> World {
        World::new(width, height)
    }

    pub fn fish() -> Fish {
        Fish::new()
    }

    pub fn fish_with_age(age: i32) -> Fish {
        Fish::with_age(age)
    }

    pub fn shark() -> Shark {
        Shark::new()
    }

    pub fn shark_with(age: i32, health: i32) -> Shark {
        Shark::with_age_and_health(age, health)
    }

    pub fn pos(x: i32, y: i32) -> Position {
        Position::new(x, y)
    }

    /// World の拡張メソッド
    pub trait WorldDsl {
        fn place(self, cell: Cell, pos: Position) -> World;
        fn place_fish(self, pos: Position) -> World;
        fn place_shark(self, pos: Position) -> World;
        fn populate(self, fish_count: usize, shark_count: usize) -> World;
        fn step(self) -> World;
        fn steps(self, n: usize) -> World;
        fn history(self, n: usize) -> Vec<World>;
    }

    impl WorldDsl for World {
        fn place(self, cell: Cell, pos: Position) -> World {
            self.set_cell(pos, cell)
        }

        fn place_fish(self, pos: Position) -> World {
            self.set_cell(pos, Cell::Fish(Fish::new()))
        }

        fn place_shark(self, pos: Position) -> World {
            self.set_cell(pos, Cell::Shark(Shark::new()))
        }

        fn populate(self, fish_count: usize, shark_count: usize) -> World {
            self.populate_random(fish_count, shark_count, &mut thread_rng())
        }

        fn step(self) -> World {
            simulation::tick(&self, &mut thread_rng())
        }

        fn steps(self, n: usize) -> World {
            simulation::run(&self, n, &mut thread_rng())
        }

        fn history(self, n: usize) -> Vec<World> {
            simulation::run_with_history(&self, n, &mut thread_rng())
        }
    }
}

// ============================================================
// 9. 関数型コンビネータ
// ============================================================

pub mod combinators {
    use super::*;

    /// 条件が満たされるまでシミュレーションを実行
    pub fn run_until<R, P>(world: &World, predicate: P, max_steps: usize, rng: &mut R) -> (World, usize)
    where
        R: Rng,
        P: Fn(&World) -> bool,
    {
        let mut current = world.clone();
        let mut steps = 0;

        while steps < max_steps && !predicate(&current) {
            current = simulation::tick(&current, rng);
            steps += 1;
        }

        (current, steps)
    }

    /// 統計情報を収集しながらシミュレーションを実行
    pub fn run_with_stats<R: Rng>(world: &World, steps: usize, rng: &mut R) -> Vec<(usize, Statistics)> {
        let history = simulation::run_with_history(world, steps, rng);
        history
            .into_iter()
            .enumerate()
            .map(|(i, w)| (i, w.statistics()))
            .collect()
    }

    /// 絶滅判定
    pub fn is_extinct(world: &World) -> bool {
        let stats = world.statistics();
        stats.fish == 0 || stats.sharks == 0
    }

    /// 安定判定（個体数が一定範囲内）
    pub fn is_stable(
        world: &World,
        min_fish: i32,
        max_fish: i32,
        min_sharks: i32,
        max_sharks: i32,
    ) -> bool {
        let stats = world.statistics();
        stats.fish >= min_fish
            && stats.fish <= max_fish
            && stats.sharks >= min_sharks
            && stats.sharks <= max_sharks
    }
}

// ============================================================
// 10. 可視化ヘルパー
// ============================================================

pub mod visualizer {
    use super::*;

    /// ASCIIアートで表示
    pub fn to_ascii(world: &World) -> String {
        world.display()
    }

    /// 統計情報を文字列で表示
    pub fn stats_to_string(stats: &Statistics) -> String {
        format!(
            "Gen: {}, Fish: {}, Sharks: {}",
            stats.generation, stats.fish, stats.sharks
        )
    }

    /// ヒストグラムを表示
    pub fn histogram(history: &[Statistics], max_width: usize) -> String {
        if history.is_empty() {
            return String::new();
        }

        let max_count = history
            .iter()
            .map(|s| s.fish.max(s.sharks))
            .max()
            .unwrap_or(0);

        if max_count == 0 {
            return "No data".to_string();
        }

        history
            .iter()
            .enumerate()
            .map(|(i, stats)| {
                let fish_bar = "f".repeat((stats.fish as usize * max_width / max_count as usize).max(0));
                let shark_bar = "S".repeat((stats.sharks as usize * max_width / max_width).max(0));
                format!("{:3}: {} | {}", i, fish_bar, shark_bar)
            })
            .collect::<Vec<_>>()
            .join("\n")
    }
}

// ============================================================
// テスト
// ============================================================

#[cfg(test)]
mod tests {
    use super::*;

    mod position_tests {
        use super::*;

        #[test]
        fn adds_positions() {
            let p1 = Position::new(1, 2);
            let p2 = Position::new(3, 4);
            assert_eq!(p1 + p2, Position::new(4, 6));
        }
    }

    mod cell_tests {
        use super::*;

        mod water {
            use super::*;

            #[test]
            fn display_is_dot() {
                assert_eq!(Cell::Water.display(), '.');
            }
        }

        mod fish {
            use super::*;

            #[test]
            fn display_is_f() {
                assert_eq!(Cell::Fish(Fish::new()).display(), 'f');
            }

            #[test]
            fn initial_age_is_0() {
                assert_eq!(Fish::new().age, 0);
            }

            #[test]
            fn can_set_age() {
                assert_eq!(Fish::with_age(5).age, 5);
            }

            #[test]
            fn increments_age() {
                assert_eq!(Fish::with_age(3).increment_age(), Fish::with_age(4));
            }
        }

        mod shark {
            use super::*;

            #[test]
            fn display_is_s() {
                assert_eq!(Cell::Shark(Shark::new()).display(), 'S');
            }

            #[test]
            fn initial_age_is_0() {
                assert_eq!(Shark::new().age, 0);
            }

            #[test]
            fn initial_health_is_config_value() {
                assert_eq!(Shark::new().health, config::SHARK_STARTING_HEALTH);
            }

            #[test]
            fn can_set_age() {
                assert_eq!(Shark::with_age_and_health(5, 5).age, 5);
            }

            #[test]
            fn decrements_health() {
                let shark = Shark::with_age_and_health(0, 5);
                assert_eq!(shark.decrement_health().health, 4);
            }

            #[test]
            fn feed_recovers_health() {
                let shark = Shark::with_age_and_health(0, 3).feed();
                assert_eq!(
                    shark.health,
                    (3 + config::SHARK_EATING_HEALTH).min(config::SHARK_MAX_HEALTH)
                );
            }

            #[test]
            fn health_does_not_exceed_max() {
                let shark = Shark::with_age_and_health(0, config::SHARK_MAX_HEALTH - 1).feed();
                assert_eq!(shark.health, config::SHARK_MAX_HEALTH);
            }
        }
    }

    mod world_tests {
        use super::*;

        mod creation {
            use super::*;

            #[test]
            fn creates_empty_world() {
                let world = World::new(5, 5);
                assert_eq!(world.width, 5);
                assert_eq!(world.height, 5);
                assert_eq!(world.cells.len(), 25);
            }

            #[test]
            fn all_cells_are_water() {
                let world = World::new(3, 3);
                for pos in world.all_positions() {
                    assert!(world.get_cell(pos).is_water());
                }
            }
        }

        mod wrapping {
            use super::*;

            #[test]
            fn positive_coords_unchanged() {
                let world = World::new(5, 5);
                assert_eq!(world.wrap(Position::new(2, 3)), Position::new(2, 3));
            }

            #[test]
            fn negative_coords_wrap() {
                let world = World::new(5, 5);
                assert_eq!(world.wrap(Position::new(-1, -1)), Position::new(4, 4));
            }

            #[test]
            fn overflow_coords_wrap() {
                let world = World::new(5, 5);
                assert_eq!(world.wrap(Position::new(6, 7)), Position::new(1, 2));
            }
        }

        mod cell_operations {
            use super::*;

            #[test]
            fn gets_cell() {
                let world = World::new(5, 5).set_cell(Position::new(2, 2), Cell::Fish(Fish::new()));
                assert!(world.get_cell(Position::new(2, 2)).is_fish());
            }

            #[test]
            fn sets_cell() {
                let world = World::new(5, 5);
                let updated = world.set_cell(Position::new(1, 1), Cell::Shark(Shark::new()));
                assert!(updated.get_cell(Position::new(1, 1)).is_shark());
            }

            #[test]
            fn sets_cell_with_wrap() {
                let world = World::new(5, 5).set_cell(Position::new(6, 6), Cell::Fish(Fish::new()));
                assert!(world.get_cell(Position::new(1, 1)).is_fish());
            }
        }

        mod neighbors {
            use super::*;

            #[test]
            fn gets_8_neighbors() {
                let world = World::new(5, 5);
                let neighbors = world.neighbors(Position::new(2, 2));
                assert_eq!(neighbors.len(), 8);
            }

            #[test]
            fn edge_neighbors_wrap() {
                let world = World::new(5, 5);
                let neighbors = world.neighbors(Position::new(0, 0));
                assert!(neighbors.contains(&Position::new(4, 4)));
                assert!(neighbors.contains(&Position::new(4, 0)));
                assert!(neighbors.contains(&Position::new(0, 4)));
            }

            #[test]
            fn gets_empty_neighbors() {
                let world = World::new(3, 3)
                    .set_cell(Position::new(1, 0), Cell::Fish(Fish::new()))
                    .set_cell(Position::new(0, 1), Cell::Shark(Shark::new()));
                let empty = world.empty_neighbors(Position::new(1, 1));
                assert!(empty.contains(&Position::new(2, 0)));
                assert!(!empty.contains(&Position::new(1, 0)));
            }

            #[test]
            fn gets_fish_neighbors() {
                let world = World::new(3, 3)
                    .set_cell(Position::new(1, 0), Cell::Fish(Fish::new()))
                    .set_cell(Position::new(0, 1), Cell::Fish(Fish::new()))
                    .set_cell(Position::new(2, 1), Cell::Shark(Shark::new()));
                let fish_cells = world.fish_neighbors(Position::new(1, 1));
                assert!(fish_cells.contains(&Position::new(1, 0)));
                assert!(fish_cells.contains(&Position::new(0, 1)));
                assert!(!fish_cells.contains(&Position::new(2, 1)));
            }
        }

        mod display {
            use super::*;

            #[test]
            fn displays_world_as_string() {
                let world = World::new(3, 3)
                    .set_cell(Position::new(1, 1), Cell::Fish(Fish::new()))
                    .set_cell(Position::new(0, 0), Cell::Shark(Shark::new()));
                let display = world.display();
                assert!(display.contains('S'));
                assert!(display.contains('f'));
                assert!(display.contains('.'));
            }
        }

        mod statistics {
            use super::*;

            #[test]
            fn gets_statistics() {
                let world = World::new(5, 5)
                    .set_cell(Position::new(0, 0), Cell::Fish(Fish::new()))
                    .set_cell(Position::new(1, 1), Cell::Fish(Fish::new()))
                    .set_cell(Position::new(2, 2), Cell::Shark(Shark::new()));
                let stats = world.statistics();
                assert_eq!(stats.fish, 2);
                assert_eq!(stats.sharks, 1);
                assert_eq!(stats.water, 22);
            }
        }

        mod random_population {
            use super::*;

            #[test]
            fn populates_randomly() {
                let world = World::new(10, 10);
                let populated = world.populate_random(20, 5, &mut StdRng::seed_from_u64(42));
                let stats = populated.statistics();
                assert_eq!(stats.fish, 20);
                assert_eq!(stats.sharks, 5);
            }
        }
    }

    mod simulation_tests {
        use super::*;

        mod try_move {
            use super::*;

            #[test]
            fn moves_when_empty_neighbor_exists() {
                let world = World::new(3, 3).set_cell(Position::new(1, 1), Cell::Fish(Fish::new()));
                let result = simulation::try_move(
                    &Cell::Fish(Fish::new()),
                    Position::new(1, 1),
                    &world,
                    &mut StdRng::seed_from_u64(42),
                );
                assert!(result.is_some());
            }

            #[test]
            fn does_not_move_when_no_empty_neighbor() {
                let mut world = World::new(1, 1);
                world = world.set_cell(Position::new(0, 0), Cell::Fish(Fish::new()));
                let result = simulation::try_move(
                    &Cell::Fish(Fish::new()),
                    Position::new(0, 0),
                    &world,
                    &mut StdRng::seed_from_u64(42),
                );
                assert!(result.is_none());
            }
        }

        mod try_reproduce {
            use super::*;

            #[test]
            fn reproduces_at_reproduction_age() {
                let world = World::new(3, 3).set_cell(Position::new(1, 1), Cell::Fish(Fish::with_age(6)));
                let result = simulation::try_reproduce(
                    &Cell::Fish(Fish::with_age(6)),
                    6,
                    Fish::reproduction_age(),
                    Position::new(1, 1),
                    &world,
                    &mut StdRng::seed_from_u64(42),
                );
                assert!(result.is_some());
            }

            #[test]
            fn does_not_reproduce_below_age() {
                let world = World::new(3, 3).set_cell(Position::new(1, 1), Cell::Fish(Fish::with_age(3)));
                let result = simulation::try_reproduce(
                    &Cell::Fish(Fish::with_age(3)),
                    3,
                    Fish::reproduction_age(),
                    Position::new(1, 1),
                    &world,
                    &mut StdRng::seed_from_u64(42),
                );
                assert!(result.is_none());
            }

            #[test]
            fn does_not_reproduce_when_no_empty_neighbor() {
                let mut world = World::new(3, 3);
                for x in 0..3 {
                    for y in 0..3 {
                        world = world.set_cell(Position::new(x, y), Cell::Fish(Fish::new()));
                    }
                }
                let result = simulation::try_reproduce(
                    &Cell::Fish(Fish::with_age(10)),
                    10,
                    Fish::reproduction_age(),
                    Position::new(1, 1),
                    &world,
                    &mut StdRng::seed_from_u64(42),
                );
                assert!(result.is_none());
            }
        }

        mod try_eat {
            use super::*;

            #[test]
            fn eats_when_fish_neighbor_exists() {
                let world = World::new(3, 3)
                    .set_cell(Position::new(1, 1), Cell::Shark(Shark::new()))
                    .set_cell(Position::new(1, 0), Cell::Fish(Fish::new()));
                let result = simulation::try_eat(
                    &Shark::new(),
                    Position::new(1, 1),
                    &world,
                    &mut StdRng::seed_from_u64(42),
                );
                assert!(result.is_some());
                if let Some(CellUpdate::Eat { cell, .. }) = result {
                    if let Cell::Shark(shark) = cell {
                        assert_eq!(
                            shark.health,
                            (config::SHARK_STARTING_HEALTH + config::SHARK_EATING_HEALTH)
                                .min(config::SHARK_MAX_HEALTH)
                        );
                    }
                }
            }

            #[test]
            fn does_not_eat_when_no_fish_neighbor() {
                let world = World::new(3, 3).set_cell(Position::new(1, 1), Cell::Shark(Shark::new()));
                let result = simulation::try_eat(
                    &Shark::new(),
                    Position::new(1, 1),
                    &world,
                    &mut StdRng::seed_from_u64(42),
                );
                assert!(result.is_none());
            }
        }

        mod tick_shark {
            use super::*;

            #[test]
            fn dies_when_health_depleted() {
                let update = simulation::tick_shark(
                    &Shark::with_age_and_health(0, 1),
                    Position::new(1, 1),
                    &World::new(3, 3),
                    &mut StdRng::seed_from_u64(42),
                );
                assert!(matches!(update, CellUpdate::Die { .. }));
            }
        }

        mod apply_update {
            use super::*;

            #[test]
            fn applies_move_update() {
                let world = World::new(3, 3).set_cell(Position::new(1, 1), Cell::Fish(Fish::new()));
                let updated = simulation::apply_update(
                    &world,
                    &CellUpdate::Move {
                        from: Position::new(1, 1),
                        to: Position::new(2, 2),
                        cell: Cell::Fish(Fish::with_age(1)),
                    },
                );
                assert!(updated.get_cell(Position::new(1, 1)).is_water());
                assert!(updated.get_cell(Position::new(2, 2)).is_fish());
            }

            #[test]
            fn applies_reproduce_update() {
                let world = World::new(3, 3).set_cell(Position::new(1, 1), Cell::Fish(Fish::with_age(6)));
                let updated = simulation::apply_update(
                    &world,
                    &CellUpdate::Reproduce {
                        parent: Position::new(1, 1),
                        child: Position::new(2, 2),
                        parent_cell: Cell::Fish(Fish::new()),
                        child_cell: Cell::Fish(Fish::new()),
                    },
                );
                assert!(updated.get_cell(Position::new(1, 1)).is_fish());
                assert!(updated.get_cell(Position::new(2, 2)).is_fish());
            }

            #[test]
            fn applies_eat_update() {
                let world = World::new(3, 3)
                    .set_cell(Position::new(1, 1), Cell::Shark(Shark::new()))
                    .set_cell(Position::new(2, 2), Cell::Fish(Fish::new()));
                let updated = simulation::apply_update(
                    &world,
                    &CellUpdate::Eat {
                        from: Position::new(1, 1),
                        to: Position::new(2, 2),
                        cell: Cell::Shark(Shark::new().feed()),
                    },
                );
                assert!(updated.get_cell(Position::new(1, 1)).is_water());
                assert!(updated.get_cell(Position::new(2, 2)).is_shark());
            }

            #[test]
            fn applies_die_update() {
                let world = World::new(3, 3).set_cell(Position::new(1, 1), Cell::Shark(Shark::new()));
                let updated = simulation::apply_update(&world, &CellUpdate::Die { at: Position::new(1, 1) });
                assert!(updated.get_cell(Position::new(1, 1)).is_water());
            }
        }

        mod tick {
            use super::*;

            #[test]
            fn increments_generation() {
                let world = World::new(3, 3);
                let updated = simulation::tick(&world, &mut StdRng::seed_from_u64(42));
                assert_eq!(updated.generation, 1);
            }

            #[test]
            fn runs_multiple_steps() {
                let world = World::new(10, 10).populate_random(10, 2, &mut StdRng::seed_from_u64(42));
                let updated = simulation::run(&world, 10, &mut StdRng::seed_from_u64(42));
                assert_eq!(updated.generation, 10);
            }

            #[test]
            fn runs_with_history() {
                let world = World::new(10, 10).populate_random(10, 2, &mut StdRng::seed_from_u64(42));
                let history = simulation::run_with_history(&world, 5, &mut StdRng::seed_from_u64(42));
                assert_eq!(history.len(), 6); // 初期状態 + 5ステップ
            }
        }
    }

    mod builder_tests {
        use super::*;

        #[test]
        fn builds_simulation_with_builder() {
            let world = SimulationBuilder::new()
                .with_size(10, 10)
                .with_fish(20)
                .with_sharks(5)
                .with_seed(42)
                .build();

            assert_eq!(world.width, 10);
            assert_eq!(world.height, 10);
            let stats = world.statistics();
            assert_eq!(stats.fish, 20);
            assert_eq!(stats.sharks, 5);
        }

        #[test]
        fn places_cells_directly() {
            let world = SimulationBuilder::new()
                .with_size(5, 5)
                .with_cell(Position::new(2, 2), Cell::Fish(Fish::with_age(5)))
                .with_cell(Position::new(3, 3), Cell::Shark(Shark::with_age_and_health(3, 8)))
                .build();

            assert_eq!(world.get_cell(Position::new(2, 2)), Cell::Fish(Fish::with_age(5)));
            assert_eq!(
                world.get_cell(Position::new(3, 3)),
                Cell::Shark(Shark::with_age_and_health(3, 8))
            );
        }
    }

    mod dsl_tests {
        use super::*;
        use dsl::*;

        #[test]
        fn creates_world_with_dsl() {
            let w = world(5, 5);
            assert_eq!(w.width, 5);
        }

        #[test]
        fn places_fish_with_dsl() {
            let w = world(5, 5).place_fish(pos(2, 2));
            assert!(w.get_cell(pos(2, 2)).is_fish());
        }

        #[test]
        fn places_shark_with_dsl() {
            let w = world(5, 5).place_shark(pos(2, 2));
            assert!(w.get_cell(pos(2, 2)).is_shark());
        }

        #[test]
        fn executes_step_with_dsl() {
            let w = world(5, 5).step();
            assert_eq!(w.generation, 1);
        }

        #[test]
        fn executes_multiple_steps_with_dsl() {
            let w = world(5, 5).steps(10);
            assert_eq!(w.generation, 10);
        }

        #[test]
        fn gets_history_with_dsl() {
            let h = world(5, 5).history(5);
            assert_eq!(h.len(), 6);
        }
    }

    mod combinator_tests {
        use super::*;

        #[test]
        fn runs_until_condition() {
            let world = World::new(10, 10).populate_random(50, 10, &mut StdRng::seed_from_u64(42));
            let (result, steps) = combinators::run_until(
                &world,
                |w| w.statistics().sharks == 0,
                100,
                &mut StdRng::seed_from_u64(42),
            );
            assert!(steps <= 100);
            // シミュレーションが動作することを確認
            let _ = result;
        }

        #[test]
        fn collects_stats() {
            let world = World::new(10, 10).populate_random(10, 2, &mut StdRng::seed_from_u64(42));
            let stats = combinators::run_with_stats(&world, 5, &mut StdRng::seed_from_u64(42));
            assert_eq!(stats.len(), 6);
            assert_eq!(stats[0].0, 0);
        }

        #[test]
        fn detects_extinction() {
            let world = World::new(5, 5).set_cell(Position::new(0, 0), Cell::Fish(Fish::new()));
            assert!(combinators::is_extinct(&world)); // サメがいない

            let world2 = World::new(5, 5)
                .set_cell(Position::new(0, 0), Cell::Fish(Fish::new()))
                .set_cell(Position::new(1, 1), Cell::Shark(Shark::new()));
            assert!(!combinators::is_extinct(&world2));
        }

        #[test]
        fn checks_stability() {
            let world = World::new(10, 10).populate_random(30, 5, &mut StdRng::seed_from_u64(42));
            assert!(combinators::is_stable(&world, 20, 40, 3, 10));
            assert!(!combinators::is_stable(&world, 50, 60, 3, 10));
        }
    }

    mod visualizer_tests {
        use super::*;

        #[test]
        fn displays_as_ascii() {
            let world = World::new(3, 3)
                .set_cell(Position::new(1, 1), Cell::Fish(Fish::new()))
                .set_cell(Position::new(0, 0), Cell::Shark(Shark::new()));
            let ascii = visualizer::to_ascii(&world);
            assert!(ascii.contains('S'));
            assert!(ascii.contains('f'));
        }

        #[test]
        fn formats_stats_as_string() {
            let stats = Statistics {
                fish: 10,
                sharks: 5,
                water: 85,
                generation: 42,
            };
            let str = visualizer::stats_to_string(&stats);
            assert!(str.contains("42"));
            assert!(str.contains("10"));
            assert!(str.contains("5"));
        }
    }

    mod scenario_tests {
        use super::*;

        #[test]
        fn fish_reproduce_in_fish_only_world() {
            let world = World::new(10, 10).populate_random(10, 0, &mut StdRng::seed_from_u64(42));
            let result = simulation::run(&world, 20, &mut StdRng::seed_from_u64(42));
            assert!(result.statistics().fish >= 10);
        }

        #[test]
        fn sharks_starve_in_shark_only_world() {
            let world = World::new(5, 5).populate_random(0, 5, &mut StdRng::seed_from_u64(42));
            let result = simulation::run(&world, 20, &mut StdRng::seed_from_u64(42));
            assert!(result.statistics().sharks < 5);
        }

        #[test]
        fn predator_prey_interaction() {
            let mut rng = StdRng::seed_from_u64(42);
            let world = World::new(20, 20).populate_random(100, 20, &mut rng);
            let history = simulation::run_with_history(&world, 50, &mut rng);

            // シミュレーションが動作することを確認
            assert_eq!(history.len(), 51);
            // 個体数が変動することを確認
            let fish_counts: Vec<_> = history.iter().map(|w| w.statistics().fish).collect();
            let unique_counts: HashSet<_> = fish_counts.iter().collect();
            assert!(unique_counts.len() > 1);
        }
    }
}
