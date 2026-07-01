#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: plan [<md file>]"
  echo ""
  echo "herdr上で起動中のAIエージェントの最新planファイルをleafで表示します。"
  echo ""
  echo "引数なし: 現在のペインのエージェントを自動判別し、最新のplanを開く"
  echo "引数あり: 指定したMarkdownファイルを開く"
  exit 1
}

case "${1:-}" in
-h | --help)
  usage
  ;;
esac

find_claude_plan() {
  local plans_dir="$HOME/.claude/plans"
  if [[ ! -d "$plans_dir" ]]; then
    echo "Error: Claude Codeのplansディレクトリが見つかりません: ${plans_dir}" >&2
    return 1
  fi

  local plan_file
  plan_file=$(ls -t "$plans_dir"/*.md 2>/dev/null | head -1)
  if [[ -z "$plan_file" ]]; then
    echo "Error: Claude Codeのplanファイルが見つかりません" >&2
    return 1
  fi

  echo "$plan_file"
}

find_copilot_plan() {
  local session_dir="$HOME/.copilot/session-state"
  if [[ ! -d "$session_dir" ]]; then
    echo "Error: GitHub Copilot CLIのsession-stateディレクトリが見つかりません: ${session_dir}" >&2
    return 1
  fi

  local plan_file
  plan_file=$(find "$session_dir" -name "plan.md" -exec stat -f '%m %N' {} + 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  if [[ -z "$plan_file" ]]; then
    echo "Error: GitHub Copilot CLIのplanファイルが見つかりません" >&2
    return 1
  fi

  echo "$plan_file"
}

find_codex_plan() {
  local target_cwd="${1:-$PWD}"
  local sessions_dir="$HOME/.codex/sessions"
  if [[ ! -d "$sessions_dir" ]]; then
    echo "Error: Codex CLIのsessionsディレクトリが見つかりません: ${sessions_dir}" >&2
    return 1
  fi

  local plan_text=""

  while IFS= read -r file; do
    jq -e --arg cwd "$target_cwd" '
      select(.type == "session_meta")
      | .payload.cwd == $cwd
    ' "$file" >/dev/null 2>&1 || continue

    local extracted
    extracted=$(jq -rs -r '
      [.[] | select(.type == "event_msg" and .payload.type == "item_completed")
      | .payload.item
      | select(.type == "Plan")
      | .text] | last // empty
    ' "$file" 2>/dev/null)

    if [[ -n "$extracted" ]]; then
      plan_text="$extracted"
      break
    fi
  done < <(find "$sessions_dir" -name "*.jsonl" 2>/dev/null | sort -r)

  if [[ -z "$plan_text" ]]; then
    echo "Error: Codex CLIのplanが見つかりません (cwd: $target_cwd)" >&2
    return 1
  fi

  local tmp_file
  tmp_file=$(mktemp /tmp/codex-plan-XXXXXX)
  printf '%s\n' "$plan_text" >"$tmp_file"

  echo "$tmp_file"
}

get_plan_file() {
  if [[ $# -ge 1 ]]; then
    local file="$1"
    if [[ ! -f "$file" ]]; then
      echo "Error: ファイルが見つかりません: ${file}" >&2
      exit 1
    fi
    echo "$file"
    return
  fi

  local pane_id="${HERDR_PANE_ID:-${HERDR_ACTIVE_PANE_ID:-}}"
  if [[ -z "$pane_id" ]]; then
    echo "Error: HERDR_PANE_ID/HERDR_ACTIVE_PANE_ID が設定されていません。herdr内で実行してください。" >&2
    exit 1
  fi

  local pane_info
  pane_info=$(herdr pane list | jq -r --arg pid "$pane_id" '.result.panes[] | select(.pane_id == $pid)')

  local agent
  agent=$(echo "$pane_info" | jq -r '.agent // empty')

  if [[ -z "$agent" ]]; then
    echo "Error: 現在のペインでエージェントが検出できません (pane_id: ${pane_id})" >&2
    exit 1
  fi

  local pane_cwd
  pane_cwd=$(echo "$pane_info" | jq -r '.cwd // empty')

  case "$agent" in
  claude)
    find_claude_plan
    ;;
  copilot)
    find_copilot_plan
    ;;
  codex)
    find_codex_plan "$pane_cwd"
    ;;
  *)
    echo "Error: 未対応のエージェント: ${agent}" >&2
    exit 1
    ;;
  esac
}

plan_file=$(get_plan_file "$@")
if [[ -z "$plan_file" ]]; then
  echo "Error: planファイルのパスが空です" >&2
  exit 1
fi

NEW_PANE=$(herdr pane split --direction right --focus | jq -r '.result.pane.pane_id')
herdr pane run "$NEW_PANE" "leaf --watch --editor 'nvim +{\$line} +\"setlocal ft=markdown\" +\"normal! zz\"' $(printf '%q' "$plan_file")"
