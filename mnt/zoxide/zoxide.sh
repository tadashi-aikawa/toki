eval "$(mise x -- zoxide init zsh)"
export _ZO_FZF_OPTS="
  --reverse
  --style=full:rounded
  --height 75%
  --margin 0,5%
  --preview-window=down,50%,wrap
  --preview 'eza -l --icons --sort modified -r --color=always {2..}'
  --no-sort
  --exact
"
