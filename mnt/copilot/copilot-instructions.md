## はじめに

`~/.claude/references/session-lifecycle.md` を Read ツールで読み込んで内容を理解してください。

## 基本ルール

- 常に日本語でやりとりしてください

## ツール使用の絶対ルール (MUST FOLLOW - サブエージェント含む全ての操作に適用)

- **禁止**: `ls`, `find`, `cat`, `awk`, `head`, `tail` などをパイプで組み合わせたファイル探索・読み取り
  - NG例: `ls | awk | grep`, `find | xargs ls`, `cat file.txt | grep`, `find ... | head`
- **必須**: ファイル探索 → `Glob` ツール、ファイル内容検索 → `Grep` ツール、ファイル読み取り → `Read` ツール


