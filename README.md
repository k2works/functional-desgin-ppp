# 関数型デザイン - 原則、パターン、実践

## 概要

### 目的

Robert C. Martin の「Functional Design: Principles, Patterns, and Practices」をベースに、6 つの関数型言語で同じデザインパターンを実装し、言語ごとの特性と共通する本質を探求します。

### 言語別解説

| 言語 | 特徴 |
|------|------|
| Clojure | JVM 上の LISP 方言。動的型付け、ホモイコニシティ、マクロによるメタプログラミング |
| Scala | JVM 上の OOP と FP のハイブリッド。強力な型システム、パターンマッチング |
| Elixir | Erlang VM 上の関数型言語。並行処理、パターンマッチング、OTP フレームワーク |
| F# | .NET 上の関数型ファースト言語。代数的データ型、型推論、Computation Expression |
| Haskell | 純粋関数型言語。型クラス、モナド、遅延評価 |
| Rust | システムプログラミング言語。所有権システム、トレイト、ゼロコスト抽象化 |

### 前提

| ソフトウェア | バージョン | 備考 |
| :----------- | :--------- | :--- |
| Node.js      | 22.x       | ドキュメントビルド用 |
| Nix          | 2.x        | 各言語の開発環境管理 |

### プロジェクト構造

```
apps/                    # 言語別実装
├── clojure/part{1..7}/  # Clojure 実装
├── elixir/part{1..7}/   # Elixir 実装
├── fsharp/part{1..7}/   # F# 実装
├── haskell/part{1..7}/  # Haskell 実装
├── rust/part{1..7}/     # Rust 実装
└── scala/part{1..7}/    # Scala 実装

docs/
├── article/             # 言語別解説記事（全 22 章 × 6 言語）
│   ├── clojure/
│   ├── elixir/
│   ├── fsharp/
│   ├── haskell/
│   ├── rust/
│   └── scala/
├── instruction.md       # 多言語実装ガイド
└── reference/           # リファレンスドキュメント
```

## 構成

- [構築](#構築)
- [配置](#配置)
- [運用](#運用)
- [開発](#開発)

## 詳細

### Quick Start

```bash
npm install
npm start
```

### 構築

```bash
claude mcp add -s project memory -- npx @modelcontextprotocol/server-memory
claude mcp add -s project codex -- npx @openai/codex mcp-server
```

#### AI アシスタント（Skills）

`.claude/skills/` ディレクトリに定義された Skills により、AI アシスタントがタスクに応じた専門的な指示を自動的に読み込みます。Progressive Disclosure（段階的開示）により、必要なスキルのみがコンテキストに展開されます。

##### Skills 一覧

| カテゴリ | スキル | 説明 |
| :--- | :--- | :--- |
| **オーケストレーション** | `orchestrating-analysis` | 分析フェーズ全体のワークフロー案内 |
| | `orchestrating-development` | 開発フェーズ全体の TDD ワークフロー案内 |
| | `orchestrating-project` | 計画・進捗管理フェーズ全体のワークフロー案内 |
| **分析** | `analyzing-business` | ビジネスアーキテクチャ分析 |
| | `analyzing-requirements` | RDRA 2.0 に基づく要件定義 |
| | `analyzing-usecases` | ユースケース・ユーザーストーリー作成 |
| | `analyzing-architecture` | アーキテクチャ設計 |
| | `analyzing-data-model` | データモデル設計 |
| | `analyzing-domain-model` | ドメインモデル設計 |
| | `analyzing-ui-design` | UI 設計 |
| | `analyzing-tech-stack` | 技術スタック選定 |
| | `analyzing-test-strategy` | テスト戦略策定 |
| | `analyzing-non-functional` | 非機能要件定義 |
| | `analyzing-operation` | 運用要件定義 |
| **開発** | `developing-backend` | バックエンド TDD（インサイドアウト） |
| | `developing-frontend` | フロントエンド TDD（アウトサイドイン） |
| | `developing-release` | リリースワークフロー（品質ゲート・バージョン管理・CHANGELOG） |
| **計画・進捗** | `planning-releases` | リリース・イテレーション計画 |
| | `syncing-github-project` | GitHub Project 同期 |
| | `tracking-progress` | 進捗分析・レポート生成 |
| **運用** | `managing-operations` | 環境構築・デプロイ・監視 |
| | `killing-processes` | 開発プロセス強制終了 |
| **ドキュメント・Git** | `managing-docs` | ドキュメント管理・Lint |
| | `git-commit` | Conventional Commits 準拠のコミット |
| | `creating-adr` | ADR 作成 |
| **共通** | `ai-agent-guidelines` | AI Agent 実行ガイドライン |

##### カスタマイズ

新しいスキルを追加するには、`.claude/skills/<skill-name>/SKILL.md` を作成します。テンプレートは `.claude/SKILLS_TEMPLATE.md` を参照してください。

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

### 運用

#### ドキュメントの編集

1. ローカル環境でMkDocsサーバーを起動
   ```
   docker-compose up mkdocs
   ```
   または、Gulpタスクを使用:
   ```
   npm run docs:serve
   ```

2. ブラウザで http://localhost:8000 にアクセスして編集結果をプレビュー

3. `docs/`ディレクトリ内のMarkdownファイルを編集

4. 変更をコミットしてプッシュ
   ```
   git add .
   git commit -m "ドキュメントの更新"
   git push
   ```

#### Gulpタスクの使用

プロジェクトには以下のGulpタスクが用意されています：

##### MkDocsタスク

- MkDocsサーバーの起動:
  ```
  npm run docs:serve
  ```
  または
  ```
  npx gulp mkdocs:serve
  ```

- MkDocsサーバーの停止:
  ```
  npm run docs:stop
  ```
  または
  ```
  npx gulp mkdocs:stop
  ```

- MkDocsドキュメントのビルド:
  ```
  npm run docs:build
  ```
  または
  ```
  npx gulp mkdocs:build
  ```

##### 作業履歴（ジャーナル）タスク

- すべてのコミット日付の作業履歴を生成:
  ```
  npm run journal
  ```
  または
  ```
  npx gulp journal:generate
  ```

- 特定の日付の作業履歴を生成:
  ```
  npx gulp journal:generate:date --date=YYYY-MM-DD
  ```
  (例: `npx gulp journal:generate:date --date=2023-04-01`)

生成された作業履歴は `docs/journal/` ディレクトリに保存され、各ファイルには指定された日付のコミット情報が含まれます。

#### GitHub Container Registry

このプロジェクトでは、GitHub Container Registry（GHCR）を使用して開発コンテナイメージを管理しています。

##### 自動ビルド・プッシュ

タグをプッシュすると、GitHub Actions が自動的にコンテナイメージをビルドし、GHCR にプッシュします。

```bash
# タグを作成してプッシュ
git tag 0.0.1
git push origin 0.0.1
```

##### イメージの取得・実行

GHCR からイメージを取得して実行するには：

```bash
# イメージをプル
docker pull ghcr.io/k2works/{project_name}:latest

# または特定バージョン
docker pull ghcr.io/k2works/{project_name}:0.0.1

# コンテナを実行
docker run -it -v $(pwd):/srv ghcr.io/k2works/{project_name}:latest
```

または、docker-compose を使用してローカルでビルド・実行することもできます：

```bash
# 開発環境を起動して中に入る
docker-compose run --rm dev bash
```

認証が必要な場合は、以下のコマンドでログインします：

```bash
# GitHub Personal Access Token でログイン
echo $GITHUB_TOKEN | docker login ghcr.io -u <username> --password-stdin
```

##### 権限設定

- リポジトリの Settings → Actions → General で `Read and write permissions` を設定
- `GITHUB_TOKEN` に `packages: write` 権限が付与されています

##### Dev Container の使用

VS Code で Dev Container を使用する場合：

1. VS Code で「Dev Containers: Reopen in Container」を実行
2. または「Dev Containers: Rebuild and Reopen in Container」で再ビルド

**[⬆ back to top](#構成)**

### 開発

#### Nix による開発環境

Nix を使用して、再現可能な開発環境を構築できます。

##### 準備

1. [Nix をインストール](https://nixos.org/download.html)します。
2. Flakes を有効にします（`~/.config/nix/nix.conf` に `experimental-features = nix-command flakes` を追加）。

##### 環境の利用

- **デフォルト環境（共通ツール）に入る:**
  ```bash
  nix develop
  ```

- **各言語の環境に入る:**
  ```bash
  nix develop .#clojure
  nix develop .#elixir
  nix develop .#fsharp    # .NET 環境
  nix develop .#haskell
  nix develop .#rust
  nix develop .#scala
  ```

- **Node.js / Python 環境に入る:**
  ```bash
  nix develop .#node
  nix develop .#python
  ```

環境から抜けるには `exit` を入力します。

##### テストの実行

各言語の Nix 環境に入り、対応する Part ディレクトリでテストを実行します。

```bash
# Clojure
nix develop .#clojure --command bash -c "cd apps/clojure/part1 && clj -M:spec"

# Elixir
nix develop .#elixir --command bash -c "cd apps/elixir/part1 && mix deps.get && mix test"

# F#
nix develop .#fsharp --command bash -c "cd apps/fsharp/part1 && dotnet test"

# Haskell
nix develop .#haskell --command bash -c "cd apps/haskell/part1 && cabal update && cabal test"

# Rust
nix develop .#rust --command bash -c "cd apps/rust/part1 && cargo test"

# Scala
nix develop .#scala --command bash -c "cd apps/scala/part1 && sbt test"
```

##### 依存関係の更新

```bash
nix flake update
```

**[⬆ back to top](#構成)**

## 参照

- 「Functional Design: Principles, Patterns, and Practices」Robert C. Martin
- 「Clean Code」Robert C. Martin
- [Clojure 公式ドキュメント](https://clojure.org/)
- [Scala 公式ドキュメント](https://www.scala-lang.org/)
- [Elixir 公式ドキュメント](https://elixir-lang.org/)
- [F# 公式ドキュメント](https://fsharp.org/)
- [Haskell 公式ドキュメント](https://www.haskell.org/)
- [Rust 公式ドキュメント](https://www.rust-lang.org/)
