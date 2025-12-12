# 関数型デザイン - 原則、パターン、実践

## 概要

本プロジェクトは、関数型プログラミングにおける設計原則とデザインパターンを実践的に学ぶためのリポジトリです。Clojure を主な実装言語として、従来のオブジェクト指向デザインパターンを関数型パラダイムでどのように表現し、活用できるかを探求します。

### 目的

- 関数型プログラミングの基礎原則を理解する
- オブジェクト指向デザインパターンを関数型で実装する方法を学ぶ
- テスト駆動開発（TDD）と関数型プログラミングを組み合わせる
- 実践的なケーススタディを通じて応用力を身につける

### 前提

| ソフトウェア | バージョン | 備考                     |
| :----------- | :--------- | :----------------------- |
| Clojure      | 1.11+      | 実装言語                 |
| Java         | 17+        | Clojure 実行環境         |
| Python       | 3.9+       | MkDocs ドキュメント生成  |
| Docker       | 20.10+     | コンテナ環境（任意）     |

## 構成

- [クイックスタート](#クイックスタート)
- [プロジェクト構造](#プロジェクト構造)
- [章構成](#章構成)
- [構築](#構築)
- [配置](#配置)
- [開発](#開発)

## 詳細

### クイックスタート

```bash
# ドキュメントサーバー起動
pip install mkdocs mkdocs-material
mkdocs serve

# Clojure テスト実行（例: Part1）
cd app/clojure/part1
clj -X:test
```

### プロジェクト構造

```
functional-desgin-ppp/
├── app/
│   └── clojure/
│       ├── part1/          # 基礎原則
│       ├── part2/          # 仕様とテスト
│       ├── part3/          # 構造パターン
│       ├── part4/          # 振る舞いパターン
│       ├── part5/          # 生成パターン
│       ├── part6/          # ケーススタディ
│       └── part7/          # まとめと応用
├── docs/
│   └── article/
│       └── clojure/        # 解説記事（全22章）
└── mkdocs.yml              # ドキュメント設定
```

### 章構成

| Part | 内容                       | 章                                           |
| ---- | -------------------------- | -------------------------------------------- |
| 1    | 関数型プログラミングの基礎 | 不変性、関数合成、多態性                     |
| 2    | 仕様とテスト               | Clojure Spec、プロパティベーステスト、TDD    |
| 3    | 構造パターン               | Composite、Decorator、Adapter                |
| 4    | 振る舞いパターン           | Strategy、Command、Visitor                   |
| 5    | 生成パターン               | Abstract Factory、Abstract Server            |
| 6    | ケーススタディ             | バス運転手、給与計算、レンタルビデオ、Wa-Tor |
| 7    | まとめと応用               | パターン相互作用、ベストプラクティス、移行   |

**[⬆ back to top](#構成)**

### 構築

#### MCP サーバー設定

```bash
claude mcp add github npx @modelcontextprotocol/server-github -e GITHUB_PERSONAL_ACCESS_TOKEN=xxxxxxxxxxxxxxx
claude mcp add --transport http byterover-mcp --scope user https://mcp.byterover.dev/v2/mcp
claude mcp add github npx -y @modelcontextprotocol/server-github -s project
```

**[⬆ back to top](#構成)**

### 配置

#### GitHub Pages セットアップ

1. **GitHub リポジトリの Settings を開く**
    - リポジトリページで `Settings` タブをクリック

2. **Pages 設定を開く**
    - 左サイドバーの `Pages` をクリック

3. **Source を設定**
    - `Source` で `Deploy from a branch` を選択
    - `Branch` で `gh-pages` を選択し、フォルダは `/ (root)` を選択
    - `Save` をクリック

4. **初回デプロイ**
    - main ブランチにプッシュすると GitHub Actions が自動実行
    - Actions タブでデプロイ状況を確認

**[⬆ back to top](#構成)**

### 開発

#### Clojure テスト実行

```bash
# 各 Part ディレクトリで実行
cd app/clojure/part1
clj -X:test
```

#### ドキュメントプレビュー

```bash
mkdocs serve
# http://localhost:8000 でプレビュー
```

**[⬆ back to top](#構成)**

## 参照

- 「Functional Design: Principles, Patterns, and Practices」Robert C. Martin
- 「Clean Code」Robert C. Martin
- 「Clojure Applied」Ben Vandgrift, Alex Miller
- 「Programming Clojure」Alex Miller, Stuart Halloway, Aaron Bedra
- [Clojure 公式ドキュメント](https://clojure.org/)
