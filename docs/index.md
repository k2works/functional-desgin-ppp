# 関数型デザイン - 原則、パターン、実践

本記事シリーズは、関数型プログラミングにおける設計原則とデザインパターンを実践的に学ぶためのガイドです。

Robert C. Martin の「Functional Design: Principles, Patterns, and Practices」をベースに、6 つの関数型言語で同じデザインパターンを実装し、言語ごとの特性と共通する本質を探求します。

## 多言語統合ガイド

6 言語の実装を横断的に比較し、関数型デザインパターンの**本質**と**言語固有の表現**を統合的に解説します。

[多言語統合ガイド](article/all/index.md)

## 言語別解説

| 言語 | 特徴 |
|------|------|
| [Clojure](article/clojure/index.md) | JVM 上の LISP 方言。動的型付け、ホモイコニシティ、マクロによるメタプログラミング |
| [Scala](article/scala/index.md) | JVM 上の OOP と FP のハイブリッド。強力な型システム、パターンマッチング |
| [Elixir](article/elixir/index.md) | Erlang VM 上の関数型言語。並行処理、パターンマッチング、OTP フレームワーク |
| [F#](article/fsharp/index.md) | .NET 上の関数型ファースト言語。代数的データ型、型推論、Computation Expression |
| [Haskell](article/haskell/index.md) | 純粋関数型言語。型クラス、モナド、遅延評価 |
| [Rust](article/rust/index.md) | システムプログラミング言語。所有権システム、トレイト、ゼロコスト抽象化 |

## 章構成

### 第 1 部: 関数型プログラミングの基礎原則

| 章 | テーマ | 概要 | 統合 |
|----|--------|------|------|
| 1 | 不変性とデータ変換 | 不変データ構造と永続データ構造による安全なデータ操作 | [6言語比較](article/all/01-immutability-and-data-transformation.md) |
| 2 | 関数合成と高階関数 | 小さな関数を組み合わせて複雑な処理を構築する手法 | [6言語比較](article/all/02-function-composition.md) |
| 3 | 多態性の実現方法 | プロトコル、型クラス、トレイトによる関数型の多態性 | [6言語比較](article/all/03-polymorphism.md) |

### 第 2 部: 仕様とテスト

| 章 | テーマ | 概要 | 統合 |
|----|--------|------|------|
| 4 | データ検証 | 各言語のバリデーション機構による仕様定義 | [6言語比較](article/all/04-data-validation.md) |
| 5 | プロパティベーステスト | 性質に基づくテストで網羅的な検証を実現 | [6言語比較](article/all/05-property-based-testing.md) |
| 6 | テスト駆動開発と関数型 | 関数型パラダイムでの TDD サイクル | [6言語比較](article/all/06-tdd-and-functional.md) |

### 第 3 部: デザインパターン - 構造パターン

| 章 | テーマ | 概要 | 統合 |
|----|--------|------|------|
| 7 | Composite パターン | 木構造による再帰的なデータ構造の表現 | [6言語比較](article/all/07-composite-pattern.md) |
| 8 | Decorator パターン | 関数合成による動的な機能拡張 | [6言語比較](article/all/08-decorator-pattern.md) |
| 9 | Adapter パターン | インターフェース変換による互換性の確保 | [6言語比較](article/all/09-adapter-pattern.md) |

### 第 4 部: デザインパターン - 振る舞いパターン

| 章 | テーマ | 概要 | 統合 |
|----|--------|------|------|
| 10 | Strategy パターン | 高階関数によるアルゴリズムの切り替え | [6言語比較](article/all/10-strategy-pattern.md) |
| 11 | Command パターン | コマンドのデータ化と実行の分離 | [6言語比較](article/all/11-command-pattern.md) |
| 12 | Visitor パターン | データ構造の走査と処理の分離 | [6言語比較](article/all/12-visitor-pattern.md) |

### 第 5 部: デザインパターン - 生成パターン

| 章 | テーマ | 概要 | 統合 |
|----|--------|------|------|
| 13 | Abstract Factory パターン | 関連オブジェクト群の生成を抽象化 | [6言語比較](article/all/13-abstract-factory-pattern.md) |
| 14 | Abstract Server パターン | サーバーインターフェースの抽象化 | [6言語比較](article/all/14-abstract-server-pattern.md) |

### 第 6 部: 実践的なケーススタディ

| 章 | テーマ | 概要 | 統合 |
|----|--------|------|------|
| 15 | Gossiping Bus Drivers | パターンの組み合わせによる問題解決 | [6言語比較](article/all/15-gossiping-bus-drivers.md) |
| 16 | 給与計算システム | ドメインモデリングとパターンの実践適用 | [6言語比較](article/all/16-payroll-system.md) |
| 17 | レンタルビデオシステム | ビジネスルールの関数型表現 | [6言語比較](article/all/17-video-rental-system.md) |
| 18 | 並行処理システム | 並行・並列処理の関数型アプローチ | [6言語比較](article/all/18-concurrency-system.md) |
| 19 | Wa-Tor シミュレーション | セルオートマトンによるシミュレーション | [6言語比較](article/all/19-wa-tor-simulation.md) |

### 第 7 部: まとめと応用

| 章 | テーマ | 概要 | 統合 |
|----|--------|------|------|
| 20 | パターン間の相互作用 | 複数パターンの組み合わせと相乗効果 | [6言語比較](article/all/20-pattern-interactions.md) |
| 21 | ベストプラクティス | 関数型デザインの原則と実践のまとめ | [6言語比較](article/all/21-best-practices.md) |
| 22 | OO から FP への移行 | オブジェクト指向から関数型への段階的移行 | [6言語比較](article/all/22-oo-to-fp-migration.md) |

## ガイド

- [多言語実装ガイド](instruction.md) - Clojure 版の記事を他の言語で実装するための手順書

## 参照

- 「Functional Design: Principles, Patterns, and Practices」Robert C. Martin
- 「Clean Code」Robert C. Martin
- 「Clojure Applied」Ben Vandgrift, Alex Miller
- 「Programming Clojure」Alex Miller, Stuart Halloway, Aaron Bedra
- 「Functional Programming in Scala」Paul Chiusano, Rúnar Bjarnason
- [Clojure 公式ドキュメント](https://clojure.org/)
- [Scala 公式ドキュメント](https://www.scala-lang.org/)
- [Elixir 公式ドキュメント](https://elixir-lang.org/)
- [F# 公式ドキュメント](https://fsharp.org/)
- [Haskell 公式ドキュメント](https://www.haskell.org/)
- [Rust 公式ドキュメント](https://www.rust-lang.org/)
