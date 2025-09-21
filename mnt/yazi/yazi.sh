function y() {
  _FZF_OPTS="${FZF_DEFAULT_OPTS}
  --height 90%
  --preview 'bat --style=numbers --color=always {}'
  --preview-window=up,50%,wrap
  "

  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd

  FZF_DEFAULT_OPTS="${_FZF_OPTS}" yazi "$@" --cwd-file="$tmp"

  IFS= read -r -d '' cwd <"$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

export YAZI_ZOXIDE_OPTS="
  --reverse
  --style=full:rounded
  --height 75%
  --margin 0,5%
  --preview-window=down,50%,wrap
  --preview 'eza -l --icons --sort modified -r --color=always {2..}'
  --no-sort
  --exact
"
