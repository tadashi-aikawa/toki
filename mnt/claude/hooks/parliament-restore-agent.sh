#!/bin/sh
# parliament: /resume で消える herdr の agent名義(rename値)を復元する。
#
# 何が起きているか:
#   `/resume` すると旧セッションの SessionEnd が reason=resume で発火し、
#   既存フックの `herdr agent rename "$pid" ""` が名義をクリアする。
#   再開後のセッションは呼び出しプロトコルのrenameを再実行しないので名無しのまま残り、
#   parliament の Now画面は `agents[].name` をメンバー判定のキーにしているため
#   「メンバー未特定」へ落ちる。
#
# どう直すか:
#   **`display_agent`(日本語の表示名)は rename のクリアでは消えない**ので、
#   そこから owlery の名簿を逆引きして slug を復元する。
#   セッション(AI)の行動に依存せず、フックだけで完結する。
#
# 設計上の約束:
#   - **名義が生きているなら何もしない**(冪等)。上書きで壊さない
#   - 名簿に無い表示名なら何もしない。**推測で名前を付けない**
#   - Claude Code の動作に影響させない。何が失敗しても常に exit 0
set -u

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v herdr >/dev/null 2>&1 || exit 0

# matcher で resume に絞って登録しているが、matcher の解釈は版で変わりうる。
# 誤って startup で名義を蘇らせないよう、ここでも自分で確かめる
src=$(printf '%s' "$input" | jq -r '.source // empty' 2>/dev/null) || exit 0
[ "$src" = "resume" ] || exit 0

pane=$(herdr pane current 2>/dev/null | jq -r '.result.pane.pane_id // empty' 2>/dev/null) || exit 0
[ -n "$pane" ] || exit 0

snap=$(herdr api snapshot 2>/dev/null) || exit 0

# 名義が生きているなら触らない
name=$(printf '%s' "$snap" | jq -r --arg p "$pane" \
  '.result.snapshot.agents[]? | select(.pane_id==$p) | .name // empty' 2>/dev/null)
[ -z "$name" ] || exit 0

display=$(printf '%s' "$snap" | jq -r --arg p "$pane" \
  '.result.snapshot.panes[]? | select(.pane_id==$p) | .display_agent // empty' 2>/dev/null)
[ -n "$display" ] || exit 0

vault="${OWLERY_VAULT:-$HOME/work/owlery}"
[ -f "$vault/CLAUDE.md" ] || exit 0

# 表示名 → slug。**日本語を正規表現パターンに入れない**(grep -F の固定文字列照合で拾い、
# 抽出は slug 側のASCIIパターンだけで行う)。macOSのawkは日本語の文字列比較が壊れる
slug=$(grep -F "[[$display]]" "$vault/CLAUDE.md" 2>/dev/null |
  sed -n 's/^| *\[\[[^]]*\]\] *| *`\([a-z0-9_-][a-z0-9_-]*\)` *|.*/\1/p' | head -1)
[ -n "$slug" ] || exit 0

# 実機の状態を変えずに動作を確かめるための逃げ道(デバッグ用)
if [ -n "${PARLIAMENT_HOOK_DRY_RUN:-}" ]; then
  echo "[dry-run] herdr agent rename $pane $slug  (display_agent=$display)" >&2
  exit 0
fi

herdr agent rename "$pane" "$slug" >/dev/null 2>&1
exit 0
