#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: stask <絵文字><タスク名>"
  echo ""
  echo "Minervaのタスクノートを新規作成します。"
  echo ""
  echo "Environment:"
  echo "  TASKS_DIR  タスクノートの保存先ディレクトリ (必須)"
  echo ""
  echo "Example:"
  echo "  TASKS_DIR=~/work/minerva/tasks stask 🔧テスト"
  exit 1
}

if [[ -z "${TASKS_DIR:-}" ]]; then
  echo "Error: TASKS_DIR が設定されていません" >&2
  usage
fi

if [[ $# -lt 1 ]]; then
  usage
fi

name="$1"
id=$(uuidgen | tr '[:upper:]' '[:lower:]' | cut -c1-5)
datetime=$(date '+%Y-%m-%dT%H:%M')
filepath="${TASKS_DIR}/${name}.md"

if [[ -f "$filepath" ]]; then
  echo "Error: 既に存在します: ${filepath}" >&2
  exit 1
fi

cat >"$filepath" <<EOF
---
id: "${id}"
summary: ""
status: ⚪todo
created: ${datetime}
updated: ${datetime}
note: ""
---

## 概要



## 計画



## 作業メモ



## 総括

### 対応内容

### 対応による恩恵

### 備考・注意事項

### 参考リンク
EOF

echo "作成しました: ${filepath}"
