## 重要

- 調査をお願いしたときに勝手にコードを変更するのは禁止
- 実装をお願いしたときは必ずプランを提示し、承諾を得てからコードを変更すること

## 言語ポリシー

- 会話・レビューコメント・ドキュメントの説明は日本語で行う。
- Conventional Commits の type は英語（feat, fix など）を使用し、本文は日本語で記述してよい。

## 調査方法

- GitHubに関することは `gh api` コマンドを極力使う
  - 読み取り系エンドポイント（一覧/詳細取得）で `gh api` に `-f` / `-F` を使う場合は、必ず `--method GET`（または `-X GET`）を明示する。
  - `gh api` は `-f` / `-F` 指定時に POST 扱いになるため、未明示だと意図せず作成APIを叩くことがある。
  - 例:
    - `gh api repos/{owner}/{repo}/issues --method GET -f state=closed -f per_page=100 --paginate`
