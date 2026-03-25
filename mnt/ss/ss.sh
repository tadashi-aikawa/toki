#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: ss <command> [args...]"
  echo ""
  echo "Commands:"
  echo "  start <name>              ワークスペースをリネーム"
  echo "  progress <rate> <label>   進行中ステータスに設定 (rate: 0~1)"
  echo "  wait                      人間待ちステータスに設定"
  echo "  block <note>              ブロックステータスに設定 (note省略時は『動作確認待ち』)"
  echo "  done                      完了ステータスに設定"
  echo "  workspace-name            現在のワークスペース名を取得"
  echo "  task-id                   ワークスペース名の[<id>]からidを取得"
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
  cmux workspace-action rename "$1"
  cmux set-progress "0.1" --label "タスクノート作成中......"
  ;;
progress)
  cmux set-status task "進行中" --icon sparkle --color "#A2DBFF"
  cmux set-progress "$1" --label "$2"
  ;;
wait)
  cmux set-status task "人間待ち" --icon clock --color "#FF9500"
  cmux clear-progress
  ;;
block)
  cmux set-status task "ブロック: ${1:-動作確認待ち}" --icon exclamationmark.triangle --color "#FF858F"
  cmux clear-progress
  ;;
done)
  cmux set-status task "完了" --icon checkmark --color "#34C759"
  ;;
workspace-name)
  cmux tree --json | jq -r '(.caller.workspace_ref) as $ref | .windows[].workspaces[] | select(.ref == $ref) | .title'
  ;;
task-id)
  workspace_name=$(cmux tree --json | jq -r '(.caller.workspace_ref) as $ref | .windows[].workspaces[] | select(.ref == $ref) | .title')
  if [[ "$workspace_name" =~ ^\[([0-9a-f]{10})\](\ .*)?$ ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo "Error: workspace name does not contain a valid task id: ${workspace_name}" >&2
    exit 1
  fi
  ;;
clear)
  cmux clear-progress
  cmux clear-status task
  ;;
*)
  echo "Unknown command: $command" >&2
  usage
  ;;
esac
