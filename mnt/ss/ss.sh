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
  echo "  plan [all|copilot|codex|claude]"
  echo "                            最新のplanを開く (default: all)"
  echo "  clear                     ステータスとプログレスをクリア"
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift

open_plan_file() {
  local plan_file="$1"
  cmux markdown "$plan_file"
  nvim --remote-tab "$plan_file" 2>/dev/null || nvim "$plan_file"
}

current_claude_project_dir() {
  local encoded_pwd
  encoded_pwd=$(printf '%s' "$PWD" | sed 's#/#-#g')
  printf '%s/projects/%s\n' "$HOME/.claude" "$encoded_pwd"
}

copilot_plan_candidates() {
  find "$HOME/.copilot/session-state" -name "plan.md" -exec stat -f '%m	%N	copilot' {} \; 2>/dev/null || true
}

claude_plan_candidates() {
  local project_dir
  project_dir=$(current_claude_project_dir)
  if [[ ! -d "$project_dir" ]]; then
    return
  fi

  jq -r '
    select(.type == "attachment" and .attachment.type == "plan_mode_exit")
    | select(.attachment.planFilePath != null)
    | .attachment.planFilePath
  ' "$project_dir"/*.jsonl 2>/dev/null \
    | while IFS= read -r plan_file; do
      if [[ -f "$plan_file" ]]; then
        stat -f '%m	%N	claude' "$plan_file"
      fi
    done
}

codex_plan_candidates() {
  find "$HOME/.codex/sessions" -name "*.jsonl" 2>/dev/null \
    | sort -r \
    | while IFS= read -r file; do
      if [[ "${found:-0}" == "1" ]]; then
        continue
      fi

      jq -e --arg cwd "$PWD" '
        select(.type == "session_meta")
        | .payload.cwd == $cwd
      ' "$file" >/dev/null 2>&1 || continue

      jq -e '
        select(.type == "response_item" and .payload.type == "message")
        | .payload.content[]?
        | select(.type == "output_text")
        | .text
        | contains("<proposed_plan>")
      ' "$file" >/dev/null 2>&1 || continue

      stat -f '%m	%N	codex' "$file"
      found=1
    done
}

extract_codex_plan() {
  local session_file="$1"
  local plan_file="/tmp/ss-plan-codex.md"

  jq -s -r '
    [
      .[]
      | select(.type == "response_item" and .payload.type == "message")
      | .payload.content[]?
      | select(.type == "output_text")
      | .text
      | select(contains("<proposed_plan>"))
    ]
    | last
    | capture("(?s)<proposed_plan>\\n?(?<plan>.*)\\n?</proposed_plan>").plan
  ' "$session_file" >"$plan_file"

  printf '%s\n' "$plan_file"
}

latest_plan_candidate() {
  local target="$1"

  case "$target" in
  all)
    {
      copilot_plan_candidates
      claude_plan_candidates
      codex_plan_candidates
    } | sort -rn | head -1
    ;;
  copilot)
    copilot_plan_candidates | sort -rn | head -1
    ;;
  claude)
    claude_plan_candidates | sort -rn | head -1
    ;;
  codex)
    codex_plan_candidates | sort -rn | head -1
    ;;
  *)
    echo "Unknown plan target: $target" >&2
    usage
    ;;
  esac
}

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
plan)
  target="${1:-all}"
  case "$target" in
  all | copilot | codex | claude) ;;
  *)
    echo "Unknown plan target: $target" >&2
    usage
    ;;
  esac

  candidate=$(latest_plan_candidate "$target")
  if [[ -z "${candidate:-}" ]]; then
    echo "plan が見つかりません: $target" >&2
    exit 1
  fi

  plan_file=$(printf '%s\n' "$candidate" | cut -f2)
  agent=$(printf '%s\n' "$candidate" | cut -f3)
  if [[ "$agent" == "codex" ]]; then
    plan_file=$(extract_codex_plan "$plan_file")
  fi
  open_plan_file "$plan_file"
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
