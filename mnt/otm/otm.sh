#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: otm <subcommand> [options]"
  echo ""
  echo "Subcommands:"
  echo "  create <絵文字><タスク名>         Minervaのタスクノートを新規作成"
  echo "  property --id <id> [options]    タスクノートのプロパティを更新"
  echo "  path --id <id>                   タスクノートのフルパスを出力"
  echo ""
  echo "Environment:"
  echo "  TASKS_DIR  タスクノートの保存先ディレクトリ (必須)"
  exit 1
}

usage_create() {
  echo "Usage: otm create <絵文字><タスク名>"
  echo ""
  echo "Minervaのタスクノートを新規作成します。"
  echo ""
  echo "Example:"
  echo "  otm create 🔧テスト"
  exit 1
}

usage_property() {
  echo "Usage: otm property --id <id> [options]"
  echo ""
  echo "タスクノートのプロパティを更新します。"
  echo ""
  echo "Options:"
  echo "  --id <id>          タスクノートのid (必須)"
  echo "  --summary <val>    summaryを更新"
  echo "  --status <val>     statusを更新 (todo|progress|wait|block|done)"
  echo "  --note <val>       noteを更新"
  echo "  --assignee <val>   assigneeを更新 (human|claude-code|codex-cli|github-copilot-cli)"
  echo "  --updated          updatedを現在時刻で更新"
  echo ""
  echo "Example:"
  echo "  otm property --id abc12 --status progress --updated"
  exit 1
}

usage_path() {
  echo "Usage: otm path --id <id>"
  echo ""
  echo "タスクノートのフルパスを出力します。"
  echo ""
  echo "Options:"
  echo "  --id <id>  タスクノートのid (必須)"
  exit 1
}

check_tasks_dir() {
  if [[ -z "${TASKS_DIR:-}" ]]; then
    echo "Error: TASKS_DIR が設定されていません" >&2
    usage
  fi
}

cmd_create() {
  if [[ $# -lt 1 ]]; then
    usage_create
  fi

  case "$1" in
  -h | --help)
    usage_create
    ;;
  esac

  local name="$1"

  # Claude Codeのpermissionルール(glob pattern)で禁則文字となる文字を禁止
  case "$name" in
  *:* | *\** | *\?* | *\[* | *\]* | *\{* | *\}* | *\\*)
    echo "Error: タスク名に使用できない文字が含まれています: : * ? [ ] { } \\" >&2
    echo "  (Claude Codeのpermissionルールと競合するため)" >&2
    exit 1
    ;;
  esac
  local id
  id=$(openssl rand -hex 5)
  local datetime
  datetime=$(date '+%Y-%m-%dT%H:%M')
  local filepath="${TASKS_DIR}/${name}.md"

  if [[ -f "$filepath" ]]; then
    echo "Error: 既に存在します: ${filepath}" >&2
    exit 1
  fi

  cat >"$filepath" <<EOF
---
id: ${id}
summary: ""
status: ⚪todo
created: ${datetime}
updated: ${datetime}
note: ""
assignee: ""
---

## 概要



## 計画



## 総括

### 対応内容



### 対応による恩恵



### 詳細



### 備考・注意事項



### 参考リンク



## 作業メモ



EOF

  echo "${id}"
}

map_status() {
  local val="$1"
  case "$val" in
  todo) echo "⚪TODO" ;;
  progress) echo "🔵進行中" ;;
  wait) echo "🟡人間待ち" ;;
  block) echo "🔴ブロック" ;;
  done) echo "🟢完了" ;;
  *)
    echo "Error: 不明なstatus: ${val} (todo|progress|wait|block|done)" >&2
    exit 1
    ;;
  esac
}

validate_assignee() {
  local val="$1"
  case "$val" in
  human | claude-code | codex-cli | github-copilot-cli) echo "$val" ;;
  *)
    echo "Error: 不明なassignee: ${val} (human|claude-code|codex-cli|github-copilot-cli)" >&2
    exit 1
    ;;
  esac
}

cmd_property() {
  local id=""
  local summary=""
  local status=""
  local note=""
  local assignee=""
  local update_updated=false
  local has_option=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --id)
      id="$2"
      shift 2
      ;;
    --summary)
      summary="$2"
      has_option=true
      shift 2
      ;;
    --status)
      status="$2"
      has_option=true
      shift 2
      ;;
    --note)
      note="$2"
      has_option=true
      shift 2
      ;;
    --assignee)
      assignee="$2"
      has_option=true
      shift 2
      ;;
    --updated)
      update_updated=true
      has_option=true
      shift
      ;;
    -h | --help)
      usage_property
      ;;
    *)
      echo "Error: 不明なオプション: $1" >&2
      usage_property
      ;;
    esac
  done

  if [[ -z "$id" ]]; then
    echo "Error: --id は必須です" >&2
    usage_property
  fi

  if [[ "$has_option" == false ]]; then
    echo "Error: 更新するプロパティを1つ以上指定してください" >&2
    usage_property
  fi

  # ファイル検索
  local matched_files
  matched_files=$(grep -rl "id: \"\?${id}\"\?" "$TASKS_DIR" || true)

  if [[ -z "$matched_files" ]]; then
    echo "Error: id '${id}' のタスクノートが見つかりません" >&2
    exit 1
  fi

  local file_count
  file_count=$(echo "$matched_files" | wc -l | tr -d ' ')

  if [[ "$file_count" -gt 1 ]]; then
    echo "Error: id '${id}' に一致するファイルが複数見つかりました:" >&2
    echo "$matched_files" >&2
    exit 1
  fi

  local filepath="$matched_files"

  # vault rootを取得してvault相対パスを算出
  local vault_root
  vault_root=$(obsidian vault info=path)
  local rel_path="${filepath#$vault_root/}"

  # 各プロパティを更新
  if [[ -n "$summary" ]]; then
    obsidian "property:set" "name=summary" "value=${summary}" "path=${rel_path}"
  fi

  if [[ -n "$status" ]]; then
    local mapped_status
    mapped_status=$(map_status "$status")
    obsidian "property:set" "name=status" "value=${mapped_status}" "path=${rel_path}"
  fi

  if [[ -n "$note" ]]; then
    obsidian "property:set" "name=note" "value=${note}" "path=${rel_path}"
  fi

  if [[ -n "$assignee" ]]; then
    local validated_assignee
    validated_assignee=$(validate_assignee "$assignee")
    obsidian "property:set" "name=assignee" "value=${validated_assignee}" "path=${rel_path}"
  fi

  if [[ "$update_updated" == true ]]; then
    local now
    now=$(date '+%Y-%m-%dT%H:%M')
    obsidian "property:set" "name=updated" "value=${now}" "type=datetime" "path=${rel_path}"
  fi
}

cmd_path() {
  local id=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --id)
      id="$2"
      shift 2
      ;;
    -h | --help)
      usage_path
      ;;
    *)
      echo "Error: 不明なオプション: $1" >&2
      usage_path
      ;;
    esac
  done

  if [[ -z "$id" ]]; then
    echo "Error: --id は必須です" >&2
    usage_path
  fi

  # ファイル検索
  local matched_files
  matched_files=$(grep -rl "id: \"\?${id}\"\?" "$TASKS_DIR" || true)

  if [[ -z "$matched_files" ]]; then
    echo "Error: id '${id}' のタスクノートが見つかりません" >&2
    exit 1
  fi

  local file_count
  file_count=$(echo "$matched_files" | wc -l | tr -d ' ')

  if [[ "$file_count" -gt 1 ]]; then
    echo "Error: id '${id}' に一致するファイルが複数見つかりました:" >&2
    echo "$matched_files" >&2
    exit 1
  fi

  echo "$matched_files"
}

# --- メイン ---

check_tasks_dir

if [[ $# -lt 1 ]]; then
  usage
fi

subcommand="$1"
shift

case "$subcommand" in
-h | --help)
  usage
  ;;
create)
  cmd_create "$@"
  ;;
property)
  cmd_property "$@"
  ;;
path)
  cmd_path "$@"
  ;;
*)
  echo "Error: 不明なサブコマンド: ${subcommand}" >&2
  usage
  ;;
esac
