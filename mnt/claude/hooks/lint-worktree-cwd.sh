#!/bin/bash
# parliament: worktreeの切り先がセッションのcwd任せになる事故を、実行前に止める。
#
# Claude CodeのPreToolUse(matcher: EnterWorktree|Agent)から呼ばれる。止めたいのは
# 「**今どのリポジトリに立っているか**を確かめないままworktreeを切る」という一種類の癖で、
# 現れ方が2つあるので2ルールに分かれている:
#
#   1. worktreeの中に居座ったまま `EnterWorktree` を呼ぶ ── ツール側も拒否するが、文言が
#      「cwdと同じpath」としか言わないため、戻り方(`ExitWorktree`)に辿り着けず作業が続く
#   2. `cd` でVaultなどへ移った状態のまま `isolation: "worktree"` でsub agentを起動する ──
#      cwdのリポジトリにworktreeが切られる。誰も拒否しないので**気づかないまま完走する**
#
# 2はcwdが正しいかを機械が判定できない(promptの言及先とcwdが食い違っていても、
# Vaultのノートを読ませるだけの正当な委譲と区別がつかない)。そこで判定をやめ、
# **切り先の宣言をpromptに要求する**。`worktree: <絶対パス>` の1行がcwdのリポジトリと
# 一致しなければ拒否する。宣言を書く行為そのものが「今どこに立っているか」の確認になる。
#
# 宣言の受け口は広く取る。発注文はMarkdownなので、宣言だけ素の行に置かれるとは限らない。
# 拾えない形で書かれると「宣言したのに拒否」になり、**宣言を書く習慣そのものが定着しない**。
# 受理する形は `parse_declaration` のヘッダに列挙してある。
#
# 意図的に検査しないもの:
#   - `isolation` なしのAgent起動: worktreeを切らないので事故が起きない。委譲の大半はこちら
#   - `isolation: "remote"`: ローカルのcwdと無関係
#   - `ExitWorktree`: 戻る操作は常に安全
#   - cwdとpromptの言及先の食い違い: 上記のとおり正当な委譲と区別できない。宣言で代替する
#   - コードフェンスの内外: 宣言候補は全部集めて食い違いだけを見るので、区別する必要がない
#
# これは敵対的な迂回への防御ではない(`worktree:` 行を機械的に書き足せば通る)。
# 止めたいのは善意のAgentの手癖で、宣言のために一度立ち止まらせることが目的。
set -uo pipefail
unset CDPATH
export LC_ALL=C

# 全角空白(U+3000)。日本語の発注文では行頭・行末に紛れ込む。LC_ALL=Cでは
# [[:space:]] に含まれないので、バイト列として自前で剥がす。
# `$'\uXXXX'` はbash 4.2以降なので、3.2でも読める8進エスケープで書く。
IDEOGRAPHIC_SPACE=$'\343\200\200'

fail() {
    printf 'worktree cwd lint: %s\n' "$1" >&2
    exit 2
}

command -v jq >/dev/null 2>&1 || fail '必須コマンド jq が見つかりません。'

HOOK_INPUT=$(jq -c '.' 2>/dev/null) || fail 'hook入力をJSONとして読めません。'
TOOL_NAME=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.tool_name // empty')
ISOLATION=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.tool_input.isolation // empty')

# 検査対象でなければ何もしない。cwdを触る前に抜けるので、対象外の呼び出しには
# ディレクトリの存在確認すら走らせない。
case "$TOOL_NAME" in
    EnterWorktree) ;;
    Agent) [ "$ISOLATION" = worktree ] || exit 0 ;;
    *) exit 0 ;;
esac

# 先頭・末尾の空白を落とす。ASCIIの空白類と全角空白の両方を剥がす
trim() {
    local s=$1
    while :; do
        case "$s" in
            [[:space:]]*) s=${s#?} ;;
            "$IDEOGRAPHIC_SPACE"*) s=${s#"$IDEOGRAPHIC_SPACE"} ;;
            *) break ;;
        esac
    done
    while :; do
        case "$s" in
            *[[:space:]]) s=${s%?} ;;
            *"$IDEOGRAPHIC_SPACE") s=${s%"$IDEOGRAPHIC_SPACE"} ;;
            *) break ;;
        esac
    done
    printf '%s' "$s"
}

# ディレクトリを物理パスへ正規化する。`/var` と `/private/var` のような論理パスの差を
# 潰すため、cwd側と宣言側の**両方**をこの関数に通してから突き合わせる。
# ディレクトリ専用 ── ファイルを渡された場合は失敗させ、呼び出し側で「リポジトリではない」
# として扱う(親だけ物理化した中途半端なパスを返すと、比較の意味が崩れる)。
canonical() {
    local target=$1
    [ -n "$target" ] || return 1
    [ -d "$target" ] || return 1
    (cd -- "$target" 2>/dev/null && pwd -P) || return 1
}

# `git rev-parse --show-toplevel` の値。worktreeの中ではworktree自身のパスが返る
repo_toplevel() {
    local dir=$1 top
    dir=$(canonical "$dir") || return 1
    top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || return 1
    canonical "$top"
}

# linked worktree(`git worktree add` で作られた作業ツリー)の中に居るか。
# 本体リポジトリでは `--git-dir` と `--git-common-dir` が一致し、linked worktreeでは
# `--git-dir` だけが `<共通>/worktrees/<名前>` を指す。ディレクトリ名の規約
# (`.claude/worktrees/` 等)には依存しない ── 置き場所はツールの都合で変わるため。
worktree_name() {
    local dir=$1 git_dir common_dir
    git_dir=$(git -C "$dir" rev-parse --absolute-git-dir 2>/dev/null) || return 1
    common_dir=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
    git_dir=$(canonical "$git_dir") || return 1
    common_dir=$(canonical "$common_dir") || return 1
    [ "$git_dir" != "$common_dir" ] || return 1
    basename -- "$git_dir"
}

# linked worktreeから見た本体リポジトリの作業ツリー(`--git-common-dir` の親)
main_worktree() {
    local dir=$1 common_dir
    common_dir=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
    common_dir=$(canonical "$common_dir") || return 1
    canonical "$(dirname -- "$common_dir")"
}

# cwdは検査の土台。**対象の呼び出しでこれが読めないなら通してはいけない** ──
# Claude Codeはcwdが消えているとセッション開始地やホームへフォールバックするので、
# 「読めない」は起こりうる状態であり、そこで安全策を解除すると宣言の不変条件が崩れる。
CWD_RAW=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.cwd // empty')
CWD=$(canonical "$CWD_RAW") || {
    {
        printf 'worktree cwd lint: 現在地(cwd)を特定できません。\n'
        printf '  hook入力のcwd: %s\n' "${CWD_RAW:-(空)}"
        cat <<'MSG'
  理由: worktreeはcwdのリポジトリに切られます。cwdが読めないと切り先が決まらないため、
  ここで通すと「宣言したリポジトリに切られる」という前提そのものが崩れます。
  直し方: 作業したいリポジトリへ cd してから呼び出し直してください。
MSG
    } >&2
    exit 2
}

# ============================================================================
# 宣言の解析
#
# 受理する形(1行に収まっているものだけ):
#   worktree: /abs/path              裸の宣言
#       worktree: /abs/path          ASCII・全角の字下げ
#   - worktree: /abs/path            箇条書き(`-` `*` `+`)
#   **worktree**: /abs/path          キーの強調
#   `worktree`: /abs/path            キーのコードスパン
#   worktree: `/abs/path`            値のコードスパン(対になっているときだけ剥がす)
#   worktree: ~/path                 チルダはシェルを経ていないのでここで展開する
#
# 受理しないもの:
#   worktree: .                      相対パス。「絶対パスを書く」ことが現在地の確認になる
#   worktree: `/abs/path             片側だけのコードスパン
# ============================================================================

# 1行から宣言の値を取り出す。宣言でなければ非0で返る
parse_declaration() {
    local line=$1 key value
    line=${line%$'\r'}
    line=$(trim "$line")
    case "$line" in
        '- '* | '* '* | '+ '*) line=$(trim "${line#??}") ;;
    esac
    case "$line" in
        *:*) ;;
        *) return 1 ;;
    esac

    # キーの装飾も**対になっているときだけ**剥がす。値側と同じ扱いにしておかないと、
    # 片側だけのコードスパンが宣言として成立してしまう
    key=$(trim "${line%%:*}")
    case "$key" in
        '`'*'`')
            key=$(trim "${key#\`}")
            key=$(trim "${key%\`}")
            ;;
    esac
    case "$key" in
        '**'*'**')
            key=$(trim "${key#\*\*}")
            key=$(trim "${key%\*\*}")
            ;;
        '*'*'*')
            key=$(trim "${key#\*}")
            key=$(trim "${key%\*}")
            ;;
    esac
    [ "$key" = worktree ] || return 1

    value=$(trim "${line#*:}")
    # コードスパンは両側揃っているときだけ剥がす。片側だけのものは値の一部として残り、
    # 絶対パス判定で弾かれる
    case "$value" in
        '`'*'`') value=$(trim "${value#\`}") && value=$(trim "${value%\`}") ;;
    esac
    # shellcheck disable=SC2088 # 引用は意図どおり(展開ではなくリテラルとの比較)
    case "$value" in
        '~') value=$HOME ;;
        '~/'*) value=$HOME/${value#'~/'} ;;
    esac
    [ -n "$value" ] || return 1
    printf '%s' "$value"
}

# ============================================================================
# ルール1: worktreeの中から EnterWorktree を呼ばない
#
# ツール側も拒否するが、返る文言は「cwdと同じpathは作れない」だけで、
# **戻り方を教えてくれない**。戻り先の実パスまで出して復帰できるようにする。
# ============================================================================
rule_enter_worktree_from_worktree() {
    [ "$TOOL_NAME" = EnterWorktree ] || return 0
    local name main
    name=$(worktree_name "$CWD") || return 0
    main=$(main_worktree "$CWD") || main='(本体リポジトリのパスを特定できませんでした)'
    {
        printf 'worktree cwd lint: worktreeの中から EnterWorktree を呼んでいます。\n'
        printf '  現在地: %s\n' "$CWD"
        printf '  worktree名: %s\n' "$name"
        cat <<MSG
  理由: EnterWorktreeは今いる作業ツリーを起点に切るため、ここから呼ぶと入れ子になるか、
  cwdと同じpathとして拒否されます。前の作業のworktreeに居座ったままなのが典型です。
  直し方: 先に ExitWorktree(action: "keep")で本体リポジトリへ戻ってください。
  戻り先: $main
  別のリポジトリで切りたい場合は、戻ったあとそのリポジトリへ cd してから呼びます。
MSG
    } >&2
    return 2
}

# ============================================================================
# ルール2: isolation: "worktree" の委譲は切り先をpromptで宣言する
#
# cwdが意図どおりかは機械には判定できないので、宣言との一致だけを見る。
# 宣言が無い/食い違う場合に、**今のcwdのリポジトリ**を明示して拒否する。
# ============================================================================
rule_agent_worktree_declaration() {
    [ "$TOOL_NAME" = Agent ] || return 0

    local top
    if ! top=$(repo_toplevel "$CWD"); then
        {
            printf 'worktree cwd lint: gitリポジトリの外から isolation: "worktree" の委譲を起動しています。\n'
            printf '  現在地: %s\n' "$CWD"
            cat <<'MSG'
  理由: worktreeはcwdのリポジトリに切られます。リポジトリの外では切り先が決まりません。
  直し方: 対象リポジトリへ cd してから起動し直してください。
MSG
        } >&2
        return 2
    fi

    local name main
    if name=$(worktree_name "$CWD"); then
        main=$(main_worktree "$CWD") || main='(本体リポジトリのパスを特定できませんでした)'
        {
            printf 'worktree cwd lint: worktreeの中から isolation: "worktree" の委譲を起動しています。\n'
            printf '  現在地: %s\n' "$CWD"
            printf '  worktree名: %s\n' "$name"
            cat <<MSG
  理由: sub agentのworktreeはcwdのリポジトリに切られるため、ここから起動すると
  作業ツリーが入れ子になります。前の作業のworktreeに居座ったままなのが典型です。
  直し方: ExitWorktree(action: "keep")で本体リポジトリへ戻ってから起動し直してください。
  戻り先: $main
MSG
        } >&2
        return 2
    fi

    # 宣言候補を全部集める。**最初の1件だけを見ない** ── 例示のコードフェンスが先にあると
    # 本文の宣言が無視され、食い違いを見逃す
    local prompt line value declared='' resolved='' candidate
    prompt=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.tool_input.prompt // empty')
    while IFS= read -r line; do
        value=$(parse_declaration "$line") || continue
        # 相対パスは**絶対パスの宣言が別にあっても拒否する**。1件でも混ざっていれば、
        # どちらを意図したかは決められない
        case "$value" in
            /*) ;;
            *)
                {
                    printf 'worktree cwd lint: 切り先の宣言が相対パスです。\n'
                    printf '  宣言: %s\n' "$value"
                    printf '  現在地: %s\n' "$CWD"
                    printf '  切られるリポジトリ: %s\n' "$top"
                    cat <<MSG
  理由: 相対パスは現在地に対して解決されるため、宣言しても現在地の確認になりません。
  絶対パスで書くことが、cwdとの食い違いに気づく唯一の機会です。
  直し方: 宣言を絶対パスに直してください。

    worktree: $top
MSG
                } >&2
                return 2
                ;;
        esac
        candidate=$(repo_toplevel "$value") || candidate="!$value"
        if [ -z "$declared" ]; then
            declared=$value
            resolved=$candidate
        elif [ "$candidate" != "$resolved" ]; then
            {
                printf 'worktree cwd lint: 切り先の宣言が複数あり、食い違っています。\n'
                printf '  1つ目: %s\n' "$declared"
                printf '  2つ目: %s\n' "$value"
                cat <<'MSG'
  理由: どれを意図した宣言か決められません。例示のコードフェンスに書いた宣言が
  本文の宣言と食い違っている場合もここに来ます。
  直し方: promptに残す宣言を1つにしてください。
MSG
            } >&2
            return 2
        fi
    done <<EOF
$(printf '%s\n' "$prompt" | grep -i 'worktree' 2>/dev/null || true)
EOF

    if [ -z "$declared" ]; then
        {
            printf 'worktree cwd lint: isolation: "worktree" の委譲に切り先の宣言がありません。\n'
            printf '  現在地: %s\n' "$CWD"
            printf '  切られるリポジトリ: %s\n' "$top"
            cat <<MSG
  理由: sub agentのworktreeは**起動側のcwdのリポジトリ**に切られます。cwdはBashの cd や
  前のEnterWorktreeで動くため、意図と食い違っていても誰も気づけません。絶対パスで書くことが、
  その食い違いに気づく唯一の機会になります。
  直し方: 上の「切られるリポジトリ」で合っているか確かめ、合っているならpromptへ次の1行を
  足して起動し直してください。

    worktree: $top

  違うリポジトリで作業させたいなら、先にそのリポジトリへ cd してから起動し直します。
MSG
        } >&2
        return 2
    fi

    case "$resolved" in
        '!'*)
            {
                printf 'worktree cwd lint: 宣言された切り先がgitリポジトリではありません。\n'
                printf '  宣言: %s\n' "$declared"
                printf '  切られるリポジトリ: %s\n' "$top"
                cat <<MSG
  直し方: 宣言をリポジトリの絶対パスにするか、対象リポジトリへ cd してから起動し直してください。

    worktree: $top
MSG
            } >&2
            return 2
            ;;
    esac

    [ "$resolved" = "$top" ] && return 0
    {
        printf 'worktree cwd lint: 宣言された切り先と、実際に切られるリポジトリが違います。\n'
        printf '  宣言: %s\n' "$resolved"
        printf '  実際に切られるリポジトリ: %s\n' "$top"
        printf '  現在地: %s\n' "$CWD"
        cat <<'MSG'
  理由: sub agentのworktreeは起動側のcwdのリポジトリに切られます。宣言だけでは切り先は動きません。
  直し方: 宣言したリポジトリへ移動してから起動し直してください。
MSG
        # パスにシェルのメタ文字が入っていても、そのまま貼れる形で出す
        printf '\n    cd -- %q\n' "$resolved"
    } >&2
    return 2
}

RULES=(
    rule_enter_worktree_from_worktree
    rule_agent_worktree_declaration
)

RESULT=0
for rule in "${RULES[@]}"; do
    "$rule" || RESULT=2
done
exit "$RESULT"
