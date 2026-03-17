claudine() {
  chafa --duration 0 --size 30x24 ~/.claude/claudine.gif
  GH_TOKEN=$GH_READONLY_TOKEN claude "$@"
}

cc() {
  cmux set-status task 'TODO' --icon sparkle --color '#ff77ff'
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

# TODO: リファクタリングして切り出したい
sss() {
  cmux workspace-action rename "$1"
}

ssp() {
  cmux set-status task "進行中" --icon sparkle --color "#007AFF"
  cmux set-progress "$1" --label "$2"
}

ssw() {
  cmux set-status task "待ち" --icon clock --color "#FF9500"
  cmux clear-progress
}

ssd() {
  cmux set-status task "完了" --icon checkmark --color "#34C759"
}

ssc() {
  cmux clear-progress
  cmux clear-status task
}
