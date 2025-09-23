#!/bin/bash

# JSONから最後のエージェント発言を抽出
LAST_MESSAGE=$(echo "$1" | jq -r '.["last-assistant-message"] // "Codex task completed"')

# osascriptで通知表示
osascript -e "display notification \"$LAST_MESSAGE\" with title \"Codex\""
# 音
afplay /System/Library/Sounds/Blow.aiff
