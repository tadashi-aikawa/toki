#!/usr/bin/env bash
# security-guard.sh のテストランナー
# security-guard.test.jsonl の各ケースを流し、expect と実際のexit codeを突き合わせる
set -u
cd "$(dirname "$0")"

pass=0; fail=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  expect=$(printf '%s' "$line" | jq -r '.expect')
  name=$(printf '%s' "$line" | jq -r '.name')
  raw=$(printf '%s' "$line" | jq -r '.raw // empty')
  if [ -n "$raw" ]; then
    input="$raw"
  else
    input=$(printf '%s' "$line" | jq -c '.case')
  fi
  printf '%s' "$input" | ./security-guard.sh >/dev/null 2>&1
  actual=$?
  if [ "$actual" -eq "$expect" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "FAIL: $name (expect=$expect actual=$actual)"
  fi
done < security-guard.test.jsonl

echo "----"
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
