# Nix開発環境のセットアップ

このプロジェクトは、Nixを使用して再現可能な開発環境を提供します。

## 前提条件

### Nixのインストール

```bash
curl -L https://nixos.org/nix/install -o install-nix
sh ./install-nix --daemon
```

### Flakesの有効化

```bash
mkdir -p ~/.config/nix
cat << 'EOF' > ~/.config/nix/nix.conf
experimental-features = nix-command flakes
EOF
```

### シェル設定の読み込み

```bash
# bashの場合
source ~/.bash_profile

# zshの場合
source ~/.zshrc
```

## 開発環境の使用方法

### デフォルト環境（Git + Docker）

```bash
nix develop
```

共通の開発ツール（Git、Docker）が利用可能な環境に入ります。

### Node.js環境

```bash
nix develop .#node
```

Node.js 22とpnpmが利用可能な環境に入ります。

### 環境の確認

```bash
# Node.js環境で
node --version  # v22.21.1
pnpm --version  # 10.26.1
git --version
```

### 環境から抜ける

```bash
exit
```

## プロジェクト構造

```
.
├── flake.nix                  # Flakeの全体設定
├── flake.lock                 # 依存関係のロックファイル
├── shells/
│   └── shell.nix             # 共通開発環境（Git、Docker）
└── environments/
    └── node/
        └── shell.nix         # Node.js開発環境
```

## 依存関係の更新

```bash
nix flake update
```

新しい依存関係がflake.lockに反映されます。

## 利点

- **再現性**: 全ての開発者が完全に同一の環境を使用
- **宣言的**: 必要なツールをコードで管理
- **隔離性**: ホストシステムに影響を与えない
- **バージョン固定**: flake.lockで依存関係を厳密に管理
