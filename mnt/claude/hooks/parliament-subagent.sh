#!/bin/sh
# parliament: sub agent の終了をローカルの parliament サーバーへ報告する。
#
# **Claude Code の動作に一切影響させない**のが最優先。
# parliament が起動していなくても、jq が無くても、常に exit 0 で抜ける。
#
# 役割は「表示を速く畳む」ことだけ。この報告が届かなくても parliament は
# mtime の停止から終了を推定するので、機能が失われるわけではない。
#
# 設置: scripts/install-hooks.ts が ~/.claude/hooks/ へコピーし、
#       ~/.claude/settings.json の SubagentStop に登録する。
set -u

# フック入力(JSON)は標準入力から来る。agent_id だけあればよい
payload=$(cat 2>/dev/null) || exit 0
[ -n "$payload" ] || exit 0

# jq が無い環境でも動くよう、素朴な文字列抽出にフォールバックする
if command -v jq >/dev/null 2>&1; then
  agent_id=$(printf '%s' "$payload" | jq -r '.agent_id // empty' 2>/dev/null) || exit 0
else
  agent_id=$(printf '%s' "$payload" | sed -n 's/.*"agent_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi
[ -n "$agent_id" ] || exit 0

# -m 1 で待ちを1秒に切る。応答は見ない(サーバーは常に即座に ok を返す)
printf '{"event":"stop","agentId":"%s"}' "$agent_id" | curl -sS -m 1 -X POST \
  -H 'content-type: application/json' --data-binary @- \
  "${PARLIAMENT_URL:-http://127.0.0.1:4747}/api/subagents/report" >/dev/null 2>&1

exit 0
