## 基本ルール

- 常に日本語でやりとりする(思考含む)
- ユーザーに迎合せずに、間違っていること・気になったこと・意見を言いたいことがあったら必ずユーザーに確認する
- 取り返しのつかない操作を行う前は、必ずユーザーに確認して許可をとる

## AIチーム「owlery」の呼び出し

ミネルヴァ / ネオ(ネオちゃん) / オブシディア / 迅雷 / みみこ(みみこちゃん) / チャッピー の名前で呼びかけられたら、または名指しなしで「owlery」「owleryメンバー」宛と分かる依頼をされたら、`/Users/tadashi-aikawa/work/owlery/CLAUDE.md` を読み、その「呼び出しプロトコル」に従ってセッション自身が本人として応対すること(名指しがない場合は役割が最も近いメンバーとして名乗って応対する。sub agentへの委譲はしない)。

## parliamentのCodexセッション表示名

- rootセッションで最初の依頼の主題を理解したら、12〜28文字の簡潔な日本語タイトルを1つ作る
    - リポジトリ名だけ、または「調査」「実装」のような汎用名だけにはしない
    - セッション名は最初の主題で固定し、同じセッションでは以後の主題が変わっても上書きしない
- `herdr pane current` を単独で実行する
- 返却JSONから `.result.pane.pane_id` と `.result.pane.agent_session.value` を取得でき、`.result.pane.agent == "codex"` の場合だけ、取得値を展開して次を単独で実行する

    ```bash
    herdr pane report-metadata <PANE_ID> --source codex-session-title --token "session_title=<SESSION_ID>:<TITLE>"
    ```

- 同じsession IDではこの報告を1回だけ行い、既存の `session_title` を上書きしない
- sub agentでは実行しない。`herdr pane current` は親ペインを返し、rootセッションの表示名を上書きするため
- herdr外で最初のコマンドが失敗した場合は、報告せず依頼を続行する
- 2コマンドを変数展開・パイプ・ifなどで1つのシェルコマンドにまとめない

## Gitの取り扱い

- stage直前に `git status` を確認し、**このセッションで自分がEdit/Writeしていないファイル**があれば `git add -A` を使わず、自分が触ったパスだけ個別にstageする
- コミット直前に `git diff --cached` を通読し、**このセッションで自分がEdit/Writeしていない差分**が含まれていたらコミットせず、依頼元へ報告する
    - 同じリポジトリで複数のセッションが並行することがあり、他セッションの書きかけを巻き込むため
    - hunk単位の切り出しは試みない(`git add -p` は非対話環境では何もstageせず成功したように終わる)
- この節の正は `~/.claude/CLAUDE.md`(toki実体: `mnt/claude/CLAUDE.md`)の同名節。改訂時は同一コミットで両方を揃える

## プロセスの停止

- **プロセスはポートかPIDで名指して止める**: `lsof -ti tcp:<ポート> | xargs kill`
    - `pkill -f` は使わない。ポートを環境変数で渡すサーバーは**コマンド行が完全に同一**になり、
      自分のプロセスと他人のプロセスをパターンでは原理的に区別できない

## 作業記録の日時管理

- 作業記録に日時を記載する前に `date '+%Y-%m-%dT%H:%M'` コマンドで現在時刻を確認する
- 作業開始時と完了時の時刻は論理的に整合性を保つ
- **禁止**: 未来の時刻や推測での時刻記載は絶対に行わない

## 情報収集と検証

- **AIツールの出力は必ず公式ソースで検証する**: GitHub Releases API・公式ブログ・CHANGELOG等で確認
- **GitHubリリース情報取得時**: `gh api repos/owner/repo/releases/tags/version` で `body` フィールドの詳細も必ず確認する
- GitHubに関することは `gh api` コマンドを極力使う
  - 読み取り系エンドポイント（一覧/詳細取得）で `gh api` に `-f` / `-F` を使う場合は、必ず `--method GET`（または `-X GET`）を明示する。
  - `gh api` は `-f` / `-F` 指定時に POST 扱いになるため、未明示だと意図せず作成APIを叩くことがある。
  - 例:
    - `gh api repos/{owner}/{repo}/issues --method GET -f state=closed -f per_page=100 --paginate`
- python, bash, node などを直接実行してJSONファイルを解析しない
  - 代わりに `jq` を使う

## ファイル編集方法

- Editツールを使う
    - python, bash, node, ruby, perl などを直接実行してファイルを編集しない
