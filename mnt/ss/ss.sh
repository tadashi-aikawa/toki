#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: ss <command> [args...]"
  echo ""
  echo "Commands:"
  echo "  start                     ワークスペースを開始"
  echo "  progress <rate> <label>   進行中ステータスに設定 (rate: 0~1)"
  echo "  wait                      人間待ちステータスに設定"
  echo "  block <note>              ブロックステータスに設定 (note省略時は『動作確認待ち』)"
  echo "  workspace-name            現在のワークスペース名を取得"
  echo "  clear                     ステータスとプログレスをクリア"
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift

case "$command" in
start)
  cmux set-status task "進行中" --icon sparkle --color "#3A9BFF"
  ;;
progress)
  cmux set-status task "進行中" --icon sparkle --color "#3A9BFF"
  cmux workspace-action --action clear-color
  cmux set-progress "$1" --label "$2"
  ;;
wait)
  cmux set-status task "人間待ち" --icon clock --color "#fff"
  cmux workspace-action --action set-color --color "#CC7A00"
  cmux clear-progress
  ;;
block)
  cmux set-status task "ブロック: ${1:-動作確認待ち}" --icon exclamationmark.triangle --color "#fff"
  cmux workspace-action --action set-color --color "#D94B5F"
  cmux clear-progress
  ;;
workspace-name)
  cmux tree --json | jq -r '(.caller.workspace_ref) as $ref | .windows[].workspaces[] | select(.ref == $ref) | .title'
  ;;
clear)
  cmux clear-progress
  cmux clear-status task
  cmux workspace-action --action clear-color
  cmux clear-notifications
  ;;
*)
  echo "Unknown command: $command" >&2
  usage
  ;;
esac
