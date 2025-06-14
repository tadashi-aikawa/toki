#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Base64 Decode
# @raycast.mode compact
# @raycast.icon https://publish-01.obsidian.md/access/35d05cd1bf5cc500e11cc8ba57daaf88/favicon-64.png

# @raycast.argument1 { "type": "text", "placeholder": "text", "optional": true }

set -o pipefail

echo "${1:-$(pbpaste)}" | base64 -d | tee >(pbcopy)
