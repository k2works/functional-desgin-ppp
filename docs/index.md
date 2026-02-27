# 関数型デザイン - 原則、パターン、実践

本記事シリーズは、関数型プログラミングにおける設計原則とデザインパターンを実践的に学ぶためのガイドです。

Robert C. Martin の「Functional Design: Principles, Patterns, and Practices」をベースに、6 つの関数型言語で同じデザインパターンを実装し、言語ごとの特性と共通する本質を探求します。

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

| 章 | テーマ | 概要 |
|----|--------|------|
| 1 | 不変性とデータ変換 | 不変データ構造と永続データ構造による安全なデータ操作 |
| 2 | 関数合成と高階関数 | 小さな関数を組み合わせて複雑な処理を構築する手法 |
| 3 | 多態性の実現方法 | プロトコル、型クラス、トレイトによる関数型の多態性 |

### 第 2 部: 仕様とテスト

| 章 | テーマ | 概要 |
|----|--------|------|
| 4 | データ検証 | 各言語のバリデーション機構による仕様定義 |
| 5 | プロパティベーステスト | 性質に基づくテストで網羅的な検証を実現 |
| 6 | テスト駆動開発と関数型 | 関数型パラダイムでの TDD サイクル |

### 第 3 部: デザインパターン - 構造パターン

| 章 | テーマ | 概要 |
|----|--------|------|
| 7 | Composite パターン | 木構造による再帰的なデータ構造の表現 |
| 8 | Decorator パターン | 関数合成による動的な機能拡張 |
| 9 | Adapter パターン | インターフェース変換による互換性の確保 |

### 第 4 部: デザインパターン - 振る舞いパターン

| 章 | テーマ | 概要 |
|----|--------|------|
| 10 | Strategy パターン | 高階関数によるアルゴリズムの切り替え |
| 11 | Command パターン | コマンドのデータ化と実行の分離 |
| 12 | Visitor パターン | データ構造の走査と処理の分離 |

### 第 5 部: デザインパターン - 生成パターン

| 章 | テーマ | 概要 |
|----|--------|------|
| 13 | Abstract Factory パターン | 関連オブジェクト群の生成を抽象化 |
| 14 | Abstract Server パターン | サーバーインターフェースの抽象化 |

### 第 6 部: 実践的なケーススタディ

| 章 | テーマ | 概要 |
|----|--------|------|
| 15 | Gossiping Bus Drivers | パターンの組み合わせによる問題解決 |
| 16 | 給与計算システム | ドメインモデリングとパターンの実践適用 |
| 17 | レンタルビデオシステム | ビジネスルールの関数型表現 |
| 18 | 並行処理システム | 並行・並列処理の関数型アプローチ |
| 19 | Wa-Tor シミュレーション | セルオートマトンによるシミュレーション |

### 第 7 部: まとめと応用

| 章 | テーマ | 概要 |
|----|--------|------|
| 20 | パターン間の相互作用 | 複数パターンの組み合わせと相乗効果 |
| 21 | ベストプラクティス | 関数型デザインの原則と実践のまとめ |
| 22 | OO から FP への移行 | オブジェクト指向から関数型への段階的移行 |

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
