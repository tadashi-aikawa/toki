#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title memo
# @raycast.mode compact
# @raycast.icon https://publish-01.obsidian.md/access/35d05cd1bf5cc500e11cc8ba57daaf88/favicon-64.png

# @raycast.argument1 { "type": "text", "placeholder": "message", "optional": false }

echo "- [ ] $1" >>~/work/pkm/task.md
