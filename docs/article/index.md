# 関数型デザイン - 原則、パターン、実践

本記事シリーズは、関数型プログラミングにおける設計原則とデザインパターンを実践的に学ぶためのガイドです。

## 言語別解説

### Clojure 版

Clojure を使った関数型プログラミングの実装例です。従来のオブジェクト指向デザインパターンを関数型パラダイムでどのように表現し、活用できるかを探求します。

- [Clojure 解説](clojure/index.md)

## 章構成（Clojure）

### 第1部: 関数型プログラミングの基礎原則

| 章 | 内容 |
|----|------|
| 1 | [不変性とデータ変換](clojure/01-immutability-and-data-transformation.md) |
| 2 | [関数合成と高階関数](clojure/02-function-composition.md) |
| 3 | [多態性の実現方法](clojure/03-polymorphism.md) |

### 第2部: 仕様とテスト

| 章 | 内容 |
|----|------|
| 4 | [Clojure Spec による仕様定義](clojure/04-clojure-spec.md) |
| 5 | [プロパティベーステスト](clojure/05-property-based-testing.md) |
| 6 | [テスト駆動開発と関数型プログラミング](clojure/06-tdd-in-functional.md) |

### 第3部: デザインパターン - 構造パターン

| 章 | 内容 |
|----|------|
| 7 | [Composite パターン](clojure/07-composite-pattern.md) |
| 8 | [Decorator パターン](clojure/08-decorator-pattern.md) |
| 9 | [Adapter パターン](clojure/09-adapter-pattern.md) |

### 第4部: デザインパターン - 振る舞いパターン

| 章 | 内容 |
|----|------|
| 10 | [Strategy パターン](clojure/10-strategy-pattern.md) |
| 11 | [Command パターン](clojure/11-command-pattern.md) |
| 12 | [Visitor パターン](clojure/12-visitor-pattern.md) |

### 第5部: デザインパターン - 生成パターン

| 章 | 内容 |
|----|------|
| 13 | [Abstract Factory パターン](clojure/13-abstract-factory-pattern.md) |
| 14 | [Abstract Server パターン](clojure/14-abstract-server-pattern.md) |

### 第6部: 実践的なケーススタディ

| 章 | 内容 |
|----|------|
| 15 | [ゴシップ好きなバスの運転手](clojure/15-gossiping-bus-drivers.md) |
| 16 | [給与計算システム](clojure/16-payroll-system.md) |
| 17 | [レンタルビデオシステム](clojure/17-video-rental-system.md) |
| 18 | [並行処理システム](clojure/18-concurrency-system.md) |
| 19 | [Wa-Tor シミュレーション](clojure/19-wator-simulation.md) |

### 第7部: まとめと応用

| 章 | 内容 |
|----|------|
| 20 | [パターン間の相互作用](clojure/20-pattern-interactions.md) |
| 21 | [関数型デザインのベストプラクティス](clojure/21-best-practices.md) |
| 22 | [オブジェクト指向から関数型への移行](clojure/22-oo-to-fp-migration.md) |

## 参照

- 「Functional Design: Principles, Patterns, and Practices」Robert C. Martin
- 「Clean Code」Robert C. Martin
- 「Clojure Applied」Ben Vandgrift, Alex Miller
- 「Programming Clojure」Alex Miller, Stuart Halloway, Aaron Bedra
- [Clojure 公式ドキュメント](https://clojure.org/)
