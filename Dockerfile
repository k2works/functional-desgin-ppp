# ベースイメージとして Ubuntu 24.04 を使用
FROM ubuntu:24.04 AS base

# 環境変数の設定
ARG NODE_MAJOR=22
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=ja_JP.UTF-8 \
    LC_ALL=ja_JP.UTF-8 \
    LC_CTYPE=ja_JP.UTF-8 \
    NODE_VER=$NODE_MAJOR

# ユーザーの設定
ARG USERNAME=ubuntu
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Ubuntu 24.04 では UID 1000 の ubuntu ユーザーが既に存在するため、必要に応じて $USERNAME にリネームして使用する
RUN if [ "$USERNAME" != "ubuntu" ]; then \
        usermod -l $USERNAME -m -d /home/$USERNAME ubuntu && \
        groupmod -n $USERNAME ubuntu; \
    fi \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# ロケールのセットアップ
RUN apt-get update && apt-get install -y \
    language-pack-ja-base \
    language-pack-ja \
    && update-locale LANG=ja_JP.UTF-8 LANGUAGE=ja_JP:ja \
    && rm -rf /var/lib/apt/lists/*

# 基本的なパッケージのインストール
 RUN apt-get update && \
     apt-get install -y \
            build-essential \
            zip \
            unzip \
            git \
            curl \
            wget \
            vim-nox \
            python3 \
            python3-pip \
            tmux \
            xz-utils \
            && apt-get clean \
            && rm -rf /var/lib/apt/lists/*

# Nixのインストール
ENV NIX_INSTALL_DIR=/nix
RUN mkdir -m 0755 $NIX_INSTALL_DIR && chown $USERNAME:$USERNAME $NIX_INSTALL_DIR
USER $USERNAME
ENV USER=$USERNAME
ENV HOME=/home/$USERNAME
RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon \
    && echo '. /home/'$USERNAME'/.nix-profile/etc/profile.d/nix.sh' >> /home/$USERNAME/.bashrc \
    && mkdir -p /home/$USERNAME/.config/nix \
    && echo "experimental-features = nix-command flakes" >> /home/$USERNAME/.config/nix/nix.conf

# Nix環境変数の設定
ENV PATH="/home/$USERNAME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:${PATH}" \
    NIX_PATH="/home/$USERNAME/.nix-profile/etc/profile.d/nix.sh:/nix/var/nix/profiles/default/etc/profile.d/nix.sh" \
    NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

USER root

# Node.jsのインストール
RUN apt-get update && apt-get install -y ca-certificates curl gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VER.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y nodejs \
    && npm install -g yarn \
    && mkdir -p /home/$USERNAME/.nvm \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/.nvm \
    && echo '#!/bin/bash\n\
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash\n\
. /home/'$USERNAME'/.nvm/nvm.sh\n\
nvm install "'$NODE_VER'"\n\
nvm use "'$NODE_VER'"' > /tmp/nvm_install.sh \
    && chmod +x /tmp/nvm_install.sh \
    && su - $USERNAME -c /tmp/nvm_install.sh \
    && rm /tmp/nvm_install.sh

# Gemini CLIのインストール
RUN npm install -g @google/gemini-cli

# Claude Codeのインストール
RUN npm install -g @anthropic-ai/claude-code

# Copilot CLIのインストール
RUN npm install -g @github/copilot

# Codex CLIのインストール
RUN npm install -g @openai/codex

# すべてのインストールが完了した後、ユーザーのホームディレクトリの所有権を確保
RUN chown -R $USERNAME:$USERNAME /home/$USERNAME

# Git safe.directory 設定（マウントされたボリューム対応）
RUN git config --global --add safe.directory /srv \
    && git config --global --add safe.directory '*'

# 作業ディレクトリの設定
WORKDIR /srv

# ユーザーを設定したユーザーに切り替える
USER $USERNAME

# デフォルトのシェルを bash に設定
SHELL ["/bin/bash", "-c"]