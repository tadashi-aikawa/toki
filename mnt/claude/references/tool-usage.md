# ツール使用の絶対ルール

**MUST FOLLOW - サブエージェント含む全ての操作に適用**

## 禁止事項

- `ls`, `find`, `cat`, `awk`, `head`, `tail` などをパイプで組み合わせたファイル探索・読み取り
  - NG例: `ls | awk | grep`, `find | xargs ls`, `cat file.txt | grep`, `find ... | head`
- python, bash, node などを直接実行してJSONファイルを解析
  - 代わりに `jq` を使う

## 必須ルール

| 用途 | 使用すべきツール |
|------|-----------------|
| ファイル探索 | `Glob` ツール |
| ファイル内容検索 | `Grep` ツール |
| ファイル読み取り | `Read` ツール |
