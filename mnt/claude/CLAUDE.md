## 基本ルール

- 常に日本語でやりとりする(思考含む)
- **禁止**: エージェントが自律的に `/task-done` や statusを『🟢完了』にする処理を行ってはいけない (ユーザーがプロンプトで明示的に `/task-done` を実行した場合は許可)

## セッション開始時の必須アクション

1. `~/.claude/references/session-lifecycle.md` を **Read ツールで読み込み**、記載された手順に従うこと
2. 応答の開始前・完了後にそれぞれ指定のコマンドを実行すること

## その他の情報

### ツール使用の絶対ルール (MUST FOLLOW)

詳細は `~/.claude/references/tool-usage.md` を参照。サブエージェント含む全ての操作に適用。

### ファイル編集のベストプラクティス

詳細は `~/.claude/references/editing-guidelines.md` を参照。

### 作業記録の日時管理

詳細は `~/.claude/references/datetime-management.md` を参照。

### 情報収集と検証のベストプラクティス

詳細は `~/.claude/references/information-verification.md` を参照。
