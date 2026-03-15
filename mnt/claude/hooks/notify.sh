#!/bin/bash
notify() {
    local title="$1"
    local body="$2"
    # >dev/tty に出力しないとcopilotにインターセプトされて端末まで伝わらないので注意
    printf '\e]777;notify;%s;%s\a' "$title" "$body" >/dev/tty
}

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')

case "$EVENT" in
"Notification")
  TYPE=$(echo "$INPUT" | jq -r '.notification_type // ""')
  MSG=$(echo "$INPUT" | jq -r '.message // ""')
  [ "$TYPE" = "idle_prompt" ] && notify "Claude Code" "入力待ち: $MSG"
  ;;
"Stop")
  MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // ""' | cut -c1-50)
  notify "Claude Code" "応答完了: $MSG"
  ;;
esac
