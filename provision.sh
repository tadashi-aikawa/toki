#!/bin/bash

set -eu

CURRENT_DIR_PATH=$(readlink -f "$(pwd)")

MNT="${CURRENT_DIR_PATH}/mnt"
mkdir -p ~/bin

# no cat && { catのインストール処理 }
function no() {
  echo "🔍 $1 コマンドの存在確認"
  ! command -v "$1" >/dev/null
}

# ~/.zshrcに引数と一致する文があることを保証します
# 既に存在すれば何もせず、存在しなければ最後に追記します
function ensure_zshrc() {
  local content="$1"

  if ! grep -qxF -- "$content" ~/.zshrc; then
    echo "$content" >>~/.zshrc
    echo "👍 '${content}' was added to .zshrc."
  else
    echo "👌 '${content}' is already present in .zshrc."
  fi
}

# ~/.bashrcに引数と一致する文があることを保証します
# 既に存在すれば何もせず、存在しなければ最後に追記します
function ensure_bashrc() {
  local content="$1"

  if ! grep -qxF -- "$content" ~/.bashrc; then
    echo "$content" >>~/.bashrc
    echo "👍 '${content}' was added to .bashrc."
  else
    echo "👌 '${content}' is already present in .bashrc."
  fi
}

#----------------------------------------------------------------------
# Shell
#----------------------------------------------------------------------

brew install zsh-autosuggestions
ensure_zshrc "source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

#----------------------------------------------------------------------
# config / rc files / dot files
#----------------------------------------------------------------------

# gitconfig
ln -snf "$MNT"/gitconfig ~/.gitconfig

# .inputrc
ln -snf "$MNT"/inputrc ~/.inputrc

# .zshrc
ln -snf "$MNT"/zshrc_base.sh ~/.zshrc_base.sh
ensure_zshrc "source ~/.zshrc_base.sh"

#----------------------------------------------------------------------
# Base
#----------------------------------------------------------------------

brew install wget

brew install unzip
# shellcheck disable=SC2016
# defaultのunzipよりも優先されるようにする
ensure_zshrc 'export PATH=/opt/homebrew/Cellar/unzip/6.0_8/bin:$PATH'

brew install p7zip

#----------------------------------------------------------------------
# GUI Tools
#----------------------------------------------------------------------

# ターミナル
brew install --cask ghostty
mkdir -p ~/Library/Application\ Support/com.mitchellh.ghostty
ln -snf "$MNT"/ghostty/config ~/Library/Application\ Support/com.mitchellh.ghostty/config

# ランチャー
brew install --cask raycast

# タスク切換え
brew install --cask alt-tab

# キーマップ制御
brew install --cask karabiner-elements

# 日本語入力
brew install --cask google-japanese-ime

# LinearMouse
brew install --cask linearmouse

# Slack
brew install --cask slack

# スクリーンショット
brew install --cask shottr

# DBeaver
brew install --cask dbeaver-community

#----------------------------------------------------------------------
# Runtime manager
#----------------------------------------------------------------------

# mise
no mise && {
  curl https://mise.run | sh
  # 大丈夫かな?
  eval "$(~/.local/bin/mise activate bash)"
}

# shellcheck disable=SC2034
# miseの-yフラグ省略
MISE_YES=1
mise settings experimental=true

# shellcheck disable=SC2016
ensure_zshrc 'eval "$(~/.local/bin/mise activate zsh)"'
# shellcheck disable=SC2016
ensure_bashrc 'eval "$(~/.local/bin/mise activate bash)"'

#----------------------------------------------------------------------
# Prompt
#----------------------------------------------------------------------

# Starship
mise use -g starship
ln -snf "$MNT"/starship/starship.sh ~/.starship.sh
ensure_zshrc "source ~/.starship.sh"
mkdir -p ~/.config
ln -snf "$MNT"/starship/starship.toml ~/.config/starship.toml

#----------------------------------------------------------------------
# Editor
#----------------------------------------------------------------------

# Neovim
mise use -g neovim
ensure_zshrc 'alias vim=nvim'
mkdir -p ~/.config/nvim
ln -snf "${MNT}"/nvim/lua ~/.config/nvim/lua
ln -snf "${MNT}"/nvim/init.lua ~/.config/nvim/init.lua
ln -snf "${MNT}"/nvim/snippets ~/.config/nvim/snippets
ln -snf "${MNT}"/nvim/after ~/.config/nvim/after
ln -snf "${MNT}"/nvim/luasnippets ~/.config/nvim/luasnippets

#----------------------------------------------------------------------
# Languages / Runtimes / LSP
#----------------------------------------------------------------------

# Node.js
mise use -g node@22

# Bun
mise use -g bun

# Deno
mise use -g deno

# Golang
mise use -g go@1.22
mise use -g go@1.23
mise use -g go@1.24
# shellcheck disable=SC2016
ensure_zshrc 'export GOPATH=$HOME/go'
# shellcheck disable=SC2016
ensure_zshrc 'export PATH=$PATH:$GOPATH/bin'
mise use -g gofumpt
mise use -g golangci-lint
mise use -g go:golang.org/x/tools/gopls@latest
mise use -g go:github.com/nametake/golangci-lint-langserver@latest

# Rust
mise use -g rust
rustup component add rust-analyzer

# Python
mise use -g python@3.12
mise use -g python@3.13
mise use -g npm:pyright
mise use -g ruff
mise use -g uv

# Bash
mise use -g npm:bash-language-server
mise use -g shellcheck
mise use -g shfmt

# Lua
mise use -g lua@5.1 # Neovim 0.10にあわせる
mise use -g lua-language-server
mise use -g stylua

# Prettier
mise use -g npm:@fsouza/prettierd
mise use -g npm:prettier

# HTML/CSS/JSON/ESLint LSP
mise use -g npm:vscode-langservers-extracted
mise use -g npm:@olrtg/emmet-language-server
mise use -g npm:@tailwindcss/language-server

# YAML
mise use -g npm:yaml-language-server

# TypeScript
mise use -g npm:typescript
mise use -g npm:typescript-language-server

# Vue
mise use -g npm:@vue/language-server
mise use -g npm:@vue/typescript-plugin

# Svelte
mise use -g npm:svelte-language-server

# SQL
mise use -g go:github.com/sqls-server/sqls
mise use -g cargo:sleek

# Docker
brew install docker docker-compose colima
brew services start colima

#----------------------------------------------------------------------
# TUI Tools
#----------------------------------------------------------------------

# Lazygit
mise use -g lazygit
mkdir -p ~/Library/Application\ Support/lazygit
ln -snf "${MNT}"/lazygit/config.yml ~/Library/Application\ Support/lazygit/config.yml

# Lazydocker
mise use -g lazydocker

# Lazysql
mise use -g go:github.com/jorgerojas26/lazysql@0.3.7

#----------------------------------------------------------------------
# CLI Tools
#----------------------------------------------------------------------

# fd
mise use -g fd

# ripgrep
mise use -g ripgrep

# bat
mise use -g bat

# dust
mise use -g dust

# xh
mise use -g xh

# jq
mise use -g jq

# bottom
mise use -g bottom

# zoxide
mise use -g zoxide
ln -snf "$MNT"/zoxide/zoxide.sh ~/.zoxide.sh
ensure_zshrc "source ~/.zoxide.sh"

# eza
mise use -g eza
ln -snf "$MNT"/eza/eza.sh ~/.eza.sh
ensure_zshrc "source ~/.eza.sh"

# fzf
mise use -g fzf
ln -snf "$MNT"/fzf/fzf.sh ~/.fzf.sh
ensure_zshrc "source ~/.fzf.sh"
ensure_zshrc "source <(fzf --zsh)"

# delta
mise use -g delta

# git-graph
no git-graph && {
  wget https://github.com/mlange-42/git-graph/releases/download/0.6.0/git-graph-0.6.0-macos-amd64.tar.gz -O /tmp/git-graph.tar.gz
  tar xvf /tmp/git-graph.tar.gz -C ~/bin/
}

# awscli
mise use -g awscli

# Task
mise use -g task

# watchexec
mise use -g watchexec

# Marp CLI
mise use -g marp-cli

# Bruno CLI
mise use -g npm:@usebruno/cli

# chafa
brew install chafa

# imagemagick(magick)
brew install imagemagick

# ffmpeg
brew install ffmpeg

# pngpaste
brew install pngpaste

# toki
ln -snf "$MNT"/toki/toki.sh ~/bin/toki
