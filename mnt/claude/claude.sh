claudine() {
  chafa --duration 0 --size 30x24 ~/.claude/claudine.gif
  GH_TOKEN=$GH_READONLY_TOKEN claude --permission-mode auto "$@"
}

cc() {
  if [[ -n "$1" && "$1" != -* ]]; then
    cmux rename-workspace "$1"
  fi
  claudine "$@"
}

ccnew() {
  ws_id=$(cmux new-workspace | awk '/^OK /{print $2}')
  cmux set-status task 'TODO' --icon sparkle --color '#ff77ff' \
    --workspace "$ws_id"
  cmux send 'claudine\n' \
    --workspace "$ws_id"
  cmux select-workspace \
    --workspace "$ws_id"
}
