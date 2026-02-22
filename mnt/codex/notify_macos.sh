#!/bin/bash

LAST_MESSAGE=$(echo "$1" | jq -r '.["last-assistant-message"] // "Codex task completed"')
# cmux前提
cmux notify --title "Codex" --body "$LAST_MESSAGE"
