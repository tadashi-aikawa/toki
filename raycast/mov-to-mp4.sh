#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title mov to mp4
# @raycast.mode silent

# Optional parameters:
# @raycast.icon https://publish-01.obsidian.md/access/35d05cd1bf5cc500e11cc8ba57daaf88/favicon-64.png

# Raycast v2はスクリプトのディレクトリをカレントにしないため、自分の位置から絶対パスで解決する
DIR_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

"${DIR_PATH}/../mnt/toki/toki.sh" mp4
