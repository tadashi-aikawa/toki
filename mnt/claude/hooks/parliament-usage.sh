#!/bin/sh
# parliament: Claude Code の statusline 入力からレート枠の観測値だけを書き出す。
#
# statusline は頻繁に実行されるため、何が失敗しても stdout を汚さず常に exit 0 で抜け、
# Claude Code の statusline 自体を壊さない。
#
# 月別の履歴は、トークン消費ペースの分析ビューが参照する唯一の履歴源になる。
set -u

# jq が無ければ入力にも触れず、statusline をそのまま動かす
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null) || exit 0

# usedPercent を小数第1位へ丸めるのは、生値が小刻みに動くと「変わったときだけ追記する」が
# 効かず履歴が膨らむため。0.1% あれば消費ペースの分析には十分な解像度がある。
#
# **読めない窓は null にして、もう片方は読む**。片方の異常でまとめて捨てると、
# 供給元がフィールドを1つ変えた日に両方の枠が黙って消える。
payload=$(printf '%s' "$input" | jq -c '
  def window($value):
    if ($value | type) != "object" or ($value.used_percentage | type) != "number" then null
    else
      {
        usedPercent: (($value.used_percentage * 10 | round) / 10),
        resetsAt: (if ($value.resets_at | type) == "number" then $value.resets_at else null end)
      }
    end;
  {
    fiveHour: window(.rate_limits.five_hour),
    sevenDay: window(.rate_limits.seven_day)
  }
' 2>/dev/null) || exit 0

[ "$payload" != '{"fiveHour":null,"sevenDay":null}' ] || exit 0

if [ -n "${PARLIAMENT_USAGE_DIR:-}" ]; then
  usage_dir=$PARLIAMENT_USAGE_DIR
else
  # set -u の環境でも HOME 未定義を statusline の失敗へ波及させない
  [ -n "${HOME:-}" ] || exit 0
  usage_dir=$HOME/.parliament/usage
fi
history_dir=$usage_dir/history
latest=$usage_dir/claude-latest.json
mkdir -p "$history_dir" 2>/dev/null || exit 0

observed_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null) || exit 0
month=$(date -u '+%Y-%m' 2>/dev/null) || exit 0
record=$(printf '%s' "$payload" | jq -c --arg t "$observed_at" '. + {observedAt:$t}' 2>/dev/null) || exit 0

prev=""
if [ -f "$latest" ]; then
  prev=$(jq -c 'del(.observedAt)' "$latest" 2>/dev/null) || prev=""
fi

tmp=$latest.tmp.$$
printf '%s\n' "$record" >"$tmp" 2>/dev/null || {
  rm -f "$tmp" 2>/dev/null
  exit 0
}
mv "$tmp" "$latest" 2>/dev/null || {
  rm -f "$tmp" 2>/dev/null
  exit 0
}

if [ "$prev" != "$payload" ]; then
  printf '%s\n' "$record" >>"$history_dir/claude-$month.jsonl" 2>/dev/null || exit 0
fi

exit 0
