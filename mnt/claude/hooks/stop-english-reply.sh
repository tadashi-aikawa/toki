#!/bin/bash
# Claude Code Stop: 長い英語の最終返答を日本語で書き直させる。
# 入力が欠けている・壊れている場合は、返答を止めない。

command -v jq >/dev/null 2>&1 || exit 0

decision=$(jq -r '
  if type != "object" or .stop_hook_active == true or (.last_assistant_message | type) != "string" then
    "allow"
  else
    .last_assistant_message
    | gsub("(?s)```.*?```"; "")
    | gsub("(?s)```.*$"; "")
    | gsub("(?s)~~~.*?~~~"; "")
    | gsub("(?s)~~~.*$"; "")
    | gsub("`[^`\n]*`"; "")
    | gsub("https?://[^[:space:]<>]+"; "")
    | gsub("[[:space:]]"; "") as $body
    | ($body | length) as $size
    | ($body | [scan("[ぁ-ヿ㐀-鿿々〆]")] | length) as $japanese
    | ($body | [scan("[A-Za-z]")] | length) as $latin
    | if $size >= 40 and $latin >= 20 and $japanese * 100 < $size * 20 then "block" else "allow" end
  end
' 2>/dev/null) || exit 0

if [ "$decision" = block ]; then
  printf '%s\n' '{"decision":"block","reason":"直前の返答が英語になっています。同じ内容を日本語で書き直してください。"}'
fi
