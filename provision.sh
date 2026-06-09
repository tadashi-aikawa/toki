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

# ╭──────────────────────────────────────────────────────────╮
# │                         Clean up                         │
# ╰──────────────────────────────────────────────────────────╯

launchctl remove homebrew.mxcl.colima 2>/dev/null || true
brew services cleanup

# ╭──────────────────────────────────────────────────────────╮
# │                          Shell                           │
# ╰──────────────────────────────────────────────────────────╯

brew install zsh-autosuggestions
ensure_zshrc "source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# ╭──────────────────────────────────────────────────────────╮
# │              config / rc files / dot files               │
# ╰──────────────────────────────────────────────────────────╯

# gitconfig
ln -snf "$MNT"/gitconfig ~/.gitconfig
# .inputrc
ln -snf "$MNT"/inputrc ~/.inputrc
# .zshrc
ln -snf "$MNT"/zshrc_base.sh ~/.zshrc_base.sh
ensure_zshrc "source ~/.zshrc_base.sh"

# ╭──────────────────────────────────────────────────────────╮
# │                        Base tools                        │
# ╰──────────────────────────────────────────────────────────╯

brew install wget

brew install unzip
# shellcheck disable=SC2016
# defaultのunzipよりも優先されるようにする
ensure_zshrc 'export PATH=/opt/homebrew/Cellar/unzip/6.0_8/bin:$PATH'

brew install sevenzip
brew install git

# ╭──────────────────────────────────────────────────────────╮
# │                        常駐ツール                        │
# ╰──────────────────────────────────────────────────────────╯

brew install --cask karabiner-elements
brew install --cask hammerspoon
brew install --cask google-japanese-ime
brew install --cask linearmouse

# ╭──────────────────────────────────────────────────────────╮
# │                           mise                           │
# ╰──────────────────────────────────────────────────────────╯
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

# ╭──────────────────────────────────────────────────────────╮
# │                          Docker                          │
# ╰──────────────────────────────────────────────────────────╯
brew install docker docker-compose colima
brew services start colima
# docker composeコマンド
mkdir -p ~/.docker/cli-plugins
ln -sfn /opt/homebrew/opt/docker-compose/bin/docker-compose ~/.docker/cli-plugins/docker-compose

# ╭──────────────────────────────────────────────────────────╮
# │                          Zellij                          │
# ╰──────────────────────────────────────────────────────────╯
mise use -g zellij
ensure_zshrc 'alias zl="zellij"'
ln -snf "${MNT}"/zellij/config.kdl ~/.config/zellij/config.kdl
if [[ "$MY_MAC_TAG" == "macbook_pro_home" ]]; then
  ln -snf "${MNT}"/zellij/layouts ~/.config/zellij/layouts
fi

# ╭──────────────────────────────────────────────────────────╮
# │                         Starship                         │
# ╰──────────────────────────────────────────────────────────╯
mise use -g starship
ln -snf "$MNT"/starship/starship.sh ~/.starship.sh
ensure_zshrc "source ~/.starship.sh"
mkdir -p ~/.config
ln -snf "$MNT"/starship/starship.toml ~/.config/starship.toml

# ╭──────────────────────────────────────────────────────────╮
# │                        ターミナル                        │
# ╰──────────────────────────────────────────────────────────╯

# Ghostty
brew install --cask ghostty
GHOSTTY_CONFIG_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
mkdir -p "$GHOSTTY_CONFIG_DIR"
ln -snf "$MNT"/ghostty/config "$GHOSTTY_CONFIG_DIR"/config
ln -snf "$MNT"/ghostty/shaders "$GHOSTTY_CONFIG_DIR"/shaders

# cmux
brew install --cask cmux
ln -snf "$MNT"/cmux/cmux.sh ~/.cmux.sh
ensure_zshrc "source ~/.cmux.sh"

# ╭──────────────────────────────────────────────────────────╮
# │                         エディタ                         │
# ╰──────────────────────────────────────────────────────────╯

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
mise use -g tree-sitter
# 最小構成コマンド mvim
mkdir -p ~/.config/mvim
ensure_zshrc "alias mvim='NVIM_APPNAME=mvim nvim'"
ln -snf "${MNT}"/mvim/init.lua ~/.config/mvim/init.lua

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

# VSCode
brew install --cask visual-studio-code
mkdir -p ~/Library/Application\ Support/Code/User
ln -snf "$MNT"/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -snf "$MNT"/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

# ╭──────────────────────────────────────────────────────────╮
# │                     その他GUIツール                      │
# ╰──────────────────────────────────────────────────────────╯

# Bruno
# TODO: v3が安定したら復活させる
# brew install --cask bruno

# brew install --cask homerow # FIXME: 1.5.3で動かないので1.4.1に戻しているため. なおったら入れ直す

brew install --cask raycast
brew install --cask slack
brew install --cask shottr
brew install --cask gimp
brew install --cask dbeaver-community
brew install --cask keycastr

# ╭──────────────────────────────────────────────────────────╮
# │                Languages / Runtimes / LSP                │
# ╰──────────────────────────────────────────────────────────╯

# TypeScript
mise use -g npm:typescript
# Web系ランタイム
mise use -g node@24
mise use -g pnpm
mise use -g bun
mise use -g deno
# Vue
mise use -g npm:@vue/language-server
mise use -g npm:@vtsls/language-server # Volar3から
# Prettier
mise use -g npm:@fsouza/prettierd
mise use -g npm:prettier
# HTML/CSS/JSON/ESLint LSP
mise use -g npm:vscode-langservers-extracted
mise use -g npm:@olrtg/emmet-language-server
mise use -g npm:@tailwindcss/language-server
mise use -g npm:unocss-language-server

# Go
mise use -g go
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
mise use -g lua@5.1 # Neovim 0.12にあわせる
mise use -g lua-language-server
mise use -g stylua

# YAML
mise use -g npm:yaml-language-server
# TOML
mise use -g taplo

# Markdown
mise use -g marksman

# SQL
mise use -g go:github.com/sqls-server/sqls
mise use -g cargo:sleek

# ╭──────────────────────────────────────────────────────────╮
# │                        TUI Tools                         │
# ╰──────────────────────────────────────────────────────────╯

# Codex CLI
if [[ "$MY_MAC_TAG" == "macbook_pro_home" ]]; then
  mise use -g npm:@openai/codex

  ln -snf "$MNT"/codex/codex.sh ~/.codex.sh
  ensure_zshrc "source ~/.codex.sh"

  ln -snf "$MNT"/codex/prompts ~/.codex/prompts
  ln -snf "$MNT"/codex/AGENTS.md ~/.codex/AGENTS.md
  ln -snf "$MNT"/codex/notify_macos.sh ~/.codex/notify_macos.sh
  ln -snf "$MNT"/codex/chappy.gif ~/.codex/chappy.gif
  # TODO: https://github.com/openai/codex/issues/3120 が対応されたら config.toml も
fi

# GitHub Copilot CLI
mise use -g npm:@github/copilot
if [[ "$MY_MAC_TAG" == "macbook_pro_home" ]]; then
  ln -snf "$MNT"/copilot/copilot.sh ~/.copilot.sh
  ln -snf "$MNT"/copilot/copilot-instructions.md ~/.copilot/copilot-instructions.md
fi
ensure_zshrc "source ~/.copilot.sh"

# yazi
brew install yazi font-symbols-only-nerd-font poppler resvg
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

# Lazygit
mise use -g lazygit
mkdir -p ~/Library/Application\ Support/lazygit
ln -snf "${MNT}"/lazygit/config.yml ~/Library/Application\ Support/lazygit/config.yml

# Lazydocker
mise use -g lazydocker

# btop
brew install btop

# serie
mise use -g cargo:serie
ensure_zshrc 'alias s="serie -p kitty --max-count 100"'
mkdir -p ~/.config/serie
ln -snf "$MNT"/serie/config.toml ~/.config/serie/config.toml

# ╭──────────────────────────────────────────────────────────╮
# │                        CLI Tools                         │
# ╰──────────────────────────────────────────────────────────╯

mise use -g bat
mise use -g cargo:dysk
mise use -g delta
mise use -g dust
mise use -g fd
mise use -g gitleaks
mise use -g hexyl
mise use -g hyperfine
mise use -g jq
mise use -g ripgrep
mise use -g task
mise use -g watchexec
mise use -g xh
mise use -g yq

brew install awscli # miseではpythonのパスが上書きされてしまう
brew install chafa
brew install clipboard
brew install convmv
brew install ffmpeg
brew install gifski
brew install git-lfs
brew install imagemagick
brew install pngpaste

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

# Bruno CLI
# TODO: v3が安定したら復活させる
mise use -g npm:@usebruno/cli@2.15.1

# gtr
brew trust --formula coderabbitai/tap/git-gtr
brew tap coderabbitai/tap
brew install git-gtr
git gtr config set gtr.editor.default nvim --global
ln -snf "$MNT"/gtr/gtr.sh ~/.gtr.sh
ensure_zshrc "source ~/.gtr.sh"

# ╭──────────────────────────────────────────────────────────╮
# │                  独自CLIコマンド(~/bin)                  │
# ╰──────────────────────────────────────────────────────────╯

ln -snf "$MNT"/toki/toki.sh ~/bin/toki
ln -snf "$MNT"/ss/ss.sh ~/bin/ss
ln -snf "$MNT"/otm/otm.sh ~/bin/otm # あまり使ってないのでいらないかも
