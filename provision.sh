#!/bin/bash

# $MY_MAC_TAG で端末を判定して処理を分岐

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

# yaziプラグイン/フレーバーがインストールされていなければインストールします
function ensure_yazi_install() {
  local content="$1"

  if ! ya pkg list | grep -q "$1"; then
    ya pkg add "$1"
  else
    echo "👌 '${1}' is already installed"
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

brew install sevenzip

brew install git

#----------------------------------------------------------------------
# GUI Tools
#----------------------------------------------------------------------

# ターミナル
brew install --cask ghostty
GHOSTTY_CONFIG_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
mkdir -p "$GHOSTTY_CONFIG_DIR"
ln -snf "$MNT"/ghostty/config "$GHOSTTY_CONFIG_DIR"/config
ln -snf "$MNT"/ghostty/shaders "$GHOSTTY_CONFIG_DIR"/shaders

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

# VSCode
brew install --cask visual-studio-code
mkdir -p ~/Library/Application\ Support/Code/User
ln -snf "$MNT"/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -snf "$MNT"/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

# GIMP
brew install --cask gimp

# Bruno
# TODO: v3が安定したら復活させる
# brew install --cask bruno

# Scoot
brew install --cask scoot

# Homerow
brew install --cask homerow

# KeyCastr
brew install --cask keycastr

# JankyBorders
brew tap FelixKratz/formulae
brew install borders
mkdir -p ~/.config/borders
ln -snf "$MNT"/borders/bordersrc ~/.config/borders/bordersrc

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
ensure_zshrc "alias vimj='nvim -c \"set filetype=json\"'"
ensure_zshrc "alias vimm='nvim -c \"set filetype=markdown\"'"
ensure_zshrc "export EDITOR=nvim"
mkdir -p ~/.config/nvim
ln -snf "${MNT}"/nvim/lua ~/.config/nvim/lua
ln -snf "${MNT}"/nvim/init.lua ~/.config/nvim/init.lua
ln -snf "${MNT}"/nvim/snippets ~/.config/nvim/snippets
ln -snf "${MNT}"/nvim/after ~/.config/nvim/after
ln -snf "${MNT}"/nvim/luasnippets ~/.config/nvim/luasnippets

# Obsidian(一部設定のみ)
if [[ "$MY_MAC_TAG" == "macbook_pro_home" ]]; then
  MAIN_VAULT_ROOT="$HOME/work/minerva"
else
  MAIN_VAULT_ROOT="$HOME/work/pkm"
fi
mkdir -p "${MAIN_VAULT_ROOT}"/.obsidian/snippets
mkdir -p "${MAIN_VAULT_ROOT}"/.obsidian/plugins/obsidian-another-quick-switcher
ln -snf "${MNT}"/obsidian/obsidian.vimrc "${MAIN_VAULT_ROOT}"/obsidian.vimrc
ln -snf "${MNT}"/obsidian/.obsidian/hotkeys.json "${MAIN_VAULT_ROOT}"/.obsidian/hotkeys.json
ln -snf "${MNT}"/obsidian/.obsidian/snippets/owl.css "${MAIN_VAULT_ROOT}"/.obsidian/snippets/owl.css
ln -snf "${MNT}"/obsidian/.obsidian/plugins/obsidian-another-quick-switcher/data.json "${MAIN_VAULT_ROOT}"/.obsidian/plugins/obsidian-another-quick-switcher/data.json

#----------------------------------------------------------------------
# Languages / Runtimes / LSP
#----------------------------------------------------------------------

# Node.js
mise use -g node@22
mise use -g node@24

# pnpm
mise use -g pnpm

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
mise use -g ruff
mise use -g uv
mise use -g pipx
mise use -g npm:pyright      # LSP
mise use -g npm:basedpyright # LSP
mise use -g pipx:ty          # LSP

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

# Vue
mise use -g npm:@vue/language-server
mise use -g npm:@vtsls/language-server # Volar3から

# Svelte
mise use -g npm:svelte-language-server

# Markdown
mise use -g marksman

# SQL
mise use -g go:github.com/sqls-server/sqls
mise use -g cargo:sleek

# Docker
brew install docker docker-compose colima
brew services start colima
# docker composeコマンド
mkdir -p ~/.docker/cli-plugins
ln -sfn /opt/homebrew/opt/docker-compose/bin/docker-compose ~/.docker/cli-plugins/docker-compose

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
mise use -g go:github.com/jorgerojas26/lazysql

#----------------------------------------------------------------------
# CLI Tools
#----------------------------------------------------------------------

if [[ "$MY_MAC_TAG" == "macbook_pro_home" ]]; then
  # Codex CLI
  mise use -g npm:@openai/codex
  ln -snf "$MNT"/codex/prompts ~/.codex/prompts
  ln -snf "$MNT"/codex/AGENTS.md ~/.codex/AGENTS.md
  ln -snf "$MNT"/codex/notify_macos.sh ~/.codex/notify_macos.sh
  # TODO: https://github.com/openai/codex/issues/3120 が対応されたら config.toml も
fi

# GitHub Copilot CLI
mise use -g npm:@github/copilot

# fd
mise use -g fd

# ripgrep
mise use -g ripgrep

# bat
mise use -g bat

# dust
mise use -g dust

# dysk
mise use -g cargo:dysk

# xh
mise use -g xh

# jq
mise use -g jq

# btop
brew install btop

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

# serie
mise use -g cargo:https://github.com/tadashi-aikawa/serie
ensure_zshrc 'alias "s=serie --max-commits 100"'
mkdir -p ~/.config/serie
ln -snf "$MNT"/serie/config.toml ~/.config/serie/config.toml

# keifu
mise use -g cargo:keifu

# awscli (miseではpythonのパスが上書きされてしまう)
brew install awscli

# Task
mise use -g task

# watchexec
mise use -g watchexec

# Marp CLI
mise use -g marp-cli

# Bruno CLI
# TODO: v3が安定したら復活させる
mise use -g npm:@usebruno/cli@2.15.1

# chafa
brew install chafa

# imagemagick(magick)
brew install imagemagick

# ffmpeg
brew install ffmpeg

# pngpaste
brew install pngpaste

# Git LFS
brew install git-lfs

# toki
ln -snf "$MNT"/toki/toki.sh ~/bin/toki

# convmf
brew install convmv

# Clipboard Project
brew install clipboard

# yazi
brew install yazi font-symbols-only-nerd-font
ln -snf "$MNT"/yazi/yazi.sh ~/.yazi.sh
mkdir -p ~/.config/yazi
ln -snf "$MNT"/yazi/yazi.toml ~/.config/yazi/yazi.toml
ln -snf "$MNT"/yazi/keymap.toml ~/.config/yazi/keymap.toml
ln -snf "$MNT"/yazi/init.lua ~/.config/yazi/init.lua
ln -snf "$MNT"/yazi/plugins/bunny-private.yazi ~/.config/yazi/plugins/bunny-private.yazi
ln -snf "$MNT"/yazi/plugins/folder-rules.yazi ~/.config/yazi/plugins/folder-rules.yazi

ensure_zshrc "source ~/.yazi.sh"
ensure_zshrc "export EDITOR=nvim"
ensure_yazi_install "yazi-rs/plugins:smart-enter"
ensure_yazi_install "yazi-rs/plugins:git"
ensure_yazi_install "yazi-rs/plugins:full-border"
ensure_yazi_install "yazi-rs/plugins:toggle-pane"
ensure_yazi_install "orhnk/system-clipboard"
ensure_yazi_install "stelcodes/bunny"

# poppler (for yazi)
brew install poppler
# resvg (for yazi)
brew install resvg
