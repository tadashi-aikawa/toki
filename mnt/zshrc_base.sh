export PATH=${PATH}:~/bin

alias i="cd"
alias s="bat"

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias gf="git fetch --all"
alias ga='git add'
alias gaa='git add --all'
alias gb='git checkout $(git branch -l | grep -vE "^\*" | tr -d " " | fzf)'
alias gbc='git checkout -b'
alias gco='git commit -m'
alias gbr='git branch -rl | grep -vE "HEAD|master" | tr -d " " | sed -r "s@origin/@@g" | fzf | xargs -i git checkout -b {} origin/{}'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch --all'
alias gl='git log'
gbdl() {
  git fetch -p && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -D
}

alias gls='git-graph -n 30 -s round'
alias gll='git-graph -n 5 -s round --format "%h %d %s%n 💿%ad 👤<%ae>%n%n"'
alias glll='git-graph -s round --format "%h %d %s%n 💿%ad 👤<%ae>%n%n"'
alias glls="git log --graph --all --date=format:'%Y-%m-%d %H:%M' --pretty=format:'%C(auto)%d%Creset %C(yellow reverse)%h%Creset %C(magenta)%ae%Creset %C(cyan)%ad%Creset%n%C(white bold)%w(80)%s%Creset%n%b' -10"
alias gbm='git merge --no-ff $(git branch -l | grep -vE "^\*" | tr -d " " | fzf)'
alias gs='git status --short'
alias gss='git status -v'

alias gpf="git push --force-with-lease --force-if-includes origin HEAD"

alias show='bat --pager never'

alias lg='lazygit'
alias ld='lazydocker'
alias lq='lazysql'

alias cpwd='pwd | xsel -bi'

# shellcheck disable=SC2154
alias zvim='dst=$(nvim --headless -c "lua for _, f in ipairs(vim.tbl_filter(function(file) return vim.fn.filereadable(file) == 1 end, vim.v.oldfiles)) do io.stdout:write(f .. \"\n\") end" -c "qa" | fzf --no-sort) && [[ -n $dst ]] && nvim $dst'

function v() {
  if [ -n "$VIRTUAL_ENV" ]; then
    deactivate
    echo "⏹️ Deactivated previous virtual environment: $(basename "$VIRTUAL_ENV")"
    return 0
  fi

  if [ -d ".venv" ]; then
    # shellcheck disable=SC1091
    source .venv/bin/activate
    echo "🔌 Activated .venv virtual environment"
  elif [ -d "venv" ]; then
    # shellcheck disable=SC1091
    source venv/bin/activate
    echo "🔌 Activated venv virtual environment"
  else
    echo "Error: No virtual environment (.venv or venv) found in current directory" >&2
    return 1
  fi
}


#--------------------------------------
# コマンド履歴
#--------------------------------------
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history
# 重複する古い履歴は削除
setopt histignorealldups
# セッションを跨いで履歴を共有
setopt sharehistory

#--------------------------------------
# 補完
#--------------------------------------
autoload -Uz compinit
compinit

# 高度な補完
zstyle ':completion:*' completer _expand _complete _correct _approximate
# 大文字小文字や各種記号をfuzzyに考慮して補完
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
# ドットファイルを.はじまりでなくても補完
setopt globdots
# TABを候補の選択ではなくインタラクティブな絞り込みとして使う
zstyle ':completion:*' menu select interactive
setopt menu_complete
# 候補を ls -l のリストで表示
zstyle ':completion:*' file-list all
# cdの補完で自分自身を表示しない
zstyle ':completion:*:cd:*' ignore-parents parent pwd
# 補完候補のディレクトリには色をつける
# eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
autoload colors && colors

# ╭──────────────────────────────────────────────────────────╮
# │              コマンドラインをエディタで編集              │
# ╰──────────────────────────────────────────────────────────╯
autoload -Uz edit-command-line
zle -N edit-command-line

# OSC 133 sequences
preexec() { printf "\033]133;A\033\\" }
precmd()  { printf "\033]133;B\033\\" }

# ESC単独の無効化
function ignore_esc() { true }
zle -N ignore_esc
bindkey '\e' ignore_esc

# ESC 1回押しのあとにアルファベットが入力されたらプロンプトに入力する
for char in {a..z}; do
  bindkey -r "\e$char"
done

function run_vim() {
  LBUFFER="vim"
  zle accept-line
}
zle -N run_vim

function run_yazi() {
  LBUFFER="y"
  zle accept-line
}
zle -N run_yazi

# <ESC>jでNeovim起動
bindkey '\ej' run_vim
# <ESC>lでyazi起動
bindkey '\el' run_yazi
# <ESC>eでNeovimでコマンドライン編集
bindkey '\ee' edit-command-line

