# Scala で学ぶ関数型デザイン

## はじめに

本記事シリーズは、関数型プログラミングにおける設計原則とデザインパターンを Scala を使って実践的に学ぶためのガイドです。Scala のオブジェクト指向と関数型のハイブリッドな特性を活かし、従来のデザインパターンを関数型パラダイムでどのように表現し、活用できるかを探求します。

## 記事構成

### 第1部: 関数型プログラミングの基礎原則

1. [不変性とデータ変換](./01-immutability-and-data-transformation.md)
   - case class と不変データ構造
   - データ変換パイプライン
   - 副作用の分離

2. [関数合成と高階関数](./02-function-composition.md)
   - andThen と compose による関数合成
   - カリー化と部分適用
   - 高階関数の活用

3. [多態性の実現方法](./03-polymorphism.md)
   - sealed trait と代数的データ型
   - トレイトとミックスイン
   - 型クラスによる既存型の拡張

### 第2部: 仕様とテスト（予定）

4. データバリデーション
   - 型によるバリデーション
   - Validated/Either によるエラーハンドリング
   - カスタムバリデータの作成

5. プロパティベーステスト
   - ScalaCheck の基本
   - ジェネレータの作成
   - プロパティの定義と検証

6. テスト駆動開発と関数型プログラミング
   - ScalaTest によるテスト
   - Red-Green-Refactor サイクル
   - テストファーストの関数設計

### 第3部以降（予定）

構造パターン、振る舞いパターン、生成パターン、ケーススタディなど、Clojure 版と同様の内容を Scala で実装していきます。

---

## 本シリーズの特徴

### Scala の特性を活かした実装

Scala 3 の新機能（enum、given/using、拡張メソッドなど）を活用し、モダンな関数型プログラミングを学びます。

### 実践重視

すべてのパターンは ScalaTest による実際に動作するテストコードを含みます。理論だけでなく、実装を通じて理解を深めることを重視しています。

### 段階的な学習

基礎から応用へと段階的に内容が進行します。各章は独立して読むこともできますが、順番に読むことでより深い理解が得られます。

---

## 対象読者

- 関数型プログラミングに興味がある Scala 開発者
- Scala を学習中の開発者
- オブジェクト指向デザインパターンの知識があり、関数型での表現を学びたい開発者
- Clojure 版と比較して学習したい開発者

---

## 前提知識

- プログラミングの基礎知識
- Scala の基本的な文法（case class、trait、パターンマッチングなど）
- デザインパターンの基本概念（推奨）

---

## 開発環境

本シリーズのコードは以下の環境で動作確認しています：

- Scala 3.3.1
- sbt 1.9.7
- ScalaTest 3.2.17
- Nix による環境管理

### 環境構築

```bash
# Nix を使用した開発環境の起動
nix develop .#scala

# テストの実行
cd app/scala/part1
sbt test
```

---

## 参考書籍

本シリーズは以下の書籍の内容を参考にしています：

- 「Functional Design: Principles, Patterns, and Practices」Robert C. Martin
- 「Functional Programming in Scala」Paul Chiusano, Rúnar Bjarnason
- 「Programming in Scala」Martin Odersky, Lex Spoon, Bill Venners
- 「Scala with Cats」Noel Welsh, Dave Gurnell
