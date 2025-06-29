# Release Command

GitHubリポジトリのリリース作業を自動化します。

## 実行手順

1. **CIが成功していることを確認**
   - GitHub ActionsのTestsワークフローが失敗していたら中断する
       - 成功していれば次へ

2. **リリース作業実行**
   - README.mdを参照してリリース手順を確認し実行

3. **リリース完了確認**
   - GitHubリリースページを定期的に確認
   - 新しいリリースが作成されたことを確認

4. **関連issueに返信**
   - リリースに関係するissue(コミットメッセージに記載された#つきの番号)に対して
      - リリースした旨をコメントする
      - ステータスをclosedに変更

5. **Bluesky投稿準備**
   - リリース情報を取得してフォーマット
   - 投稿内容を出力 (ユーザーが手動でそれをコピー)
   - ユーザーが手動でBlueskyに投稿（OGPカード表示や動画添付が可能）

6. **リポジトリの最新化**
   - `git pull` でremoteの変更点を取り込む

### 4について

#### コメントフォーマット

```
<投稿者全員にメンション>

Released in [<バージョン>](<リリースノートのURL>) 🚀 
```

**具体例:** https://github.com/tadashi-aikawa/obsidian-another-quick-switcher/releases/tag/13.7.1 の場合

```
@craziedde 
Released in [v13.7.1](https://github.com/tadashi-aikawa/obsidian-another-quick-switcher/releases/tag/13.7.1) 🚀 
```

### 5について

#### 投稿フォーマット

```
📦 ${プロダクト名} ${バージョン} 🚀

・箇条書きで新機能やメインの変更点を列挙

${GitHubリリースページのURL}
```

## 必要な設定

- GitHub CLIが認証済みであること


## 使用方法

```
/release
```

このコマンドを実行すると、上記の手順が自動的に実行されます。
