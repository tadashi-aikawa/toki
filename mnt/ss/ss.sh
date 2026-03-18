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
  ;;
progress)
  cmux set-status task "進行中" --icon sparkle --color "#007AFF"
  cmux set-progress "$1" --label "$2"
  ;;
wait)
  cmux set-status task "人間待ち" --icon clock --color "#FF9500"
  cmux clear-progress
  ;;
block)
  cmux set-status task "ブロック: ${1:-動作確認待ち}" --icon exclamationmark.triangle --color "#FF3B30"
  cmux clear-progress
  ;;
done)
  cmux set-status task "完了" --icon checkmark --color "#34C759"
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
