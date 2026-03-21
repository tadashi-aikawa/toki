# 情報収集と検証のベストプラクティス

- **AIツールの出力は必ず公式ソースで検証する**: GitHub Releases API・公式ブログ・CHANGELOG等で確認
- **GitHubリリース情報取得時**: `gh api repos/owner/repo/releases/tags/version` で `body` フィールドの詳細も必ず確認する
