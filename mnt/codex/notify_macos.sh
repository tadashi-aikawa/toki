#!/bin/bash

notify() {
  local title="$1"
  local body="$2"
  printf '\e]777;notify;%s;%s\a' "$title" "$body" >/dev/tty
}

LAST_MESSAGE=$(echo "$1" | jq -r '.["last-assistant-message"] // "Codex task completed"')
notify "🤖Codex" "$LAST_MESSAGE"
