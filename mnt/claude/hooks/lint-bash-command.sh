#!/bin/bash
# parliament: Bashコマンドを実行前に検査する汎用lint。
#
# Claude Code / Codex CLIのPreToolUse(matcher: Bash)から呼ばれ、stdinのhook入力から
# `.tool_input.command` を取り出してルール関数に通す。違反時はexit 2で実行を拒否し、
# stderrのメッセージだけでAgentが直し方を判断できるようにする。
#
# **これは敵対的な迂回への防御ではない**。止めたいのは善意のAgentの癖(`cat >>` 等)で、
# 意図的にすり抜けようとする形は追わない ── 追う相手がいないので、追えば誤拒否だけが増える。
# 具体的に追わないと決めたものは各ルールのヘッダに書いてある。
#
# ルールの増やし方:
#   1. `rule_<名前>()` 関数を書く(検査対象は $COMMAND。違反なら理由をstderrへ出して return 2)
#   2. 末尾の RULES 配列へ関数名を追加する
# 全ルールを走らせてから拒否するので、複数違反があってもAgentは一度で全部直せる。
set -uo pipefail
export LC_ALL=C

fail() {
    printf 'Bashコマンドlint: %s\n' "$1" >&2
    exit 2
}

command -v jq >/dev/null 2>&1 || fail '必須コマンド jq が見つかりません。'

HOOK_INPUT=$(jq -c '.' 2>/dev/null) || fail 'hook入力をJSONとして読めません。'
TOOL_NAME=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.tool_name // empty')
[ "$TOOL_NAME" = Bash ] || exit 0
COMMAND=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.tool_input.command // empty')
[ -n "$COMMAND" ] || exit 0

# Claude Code / Codex内のsub agentはagent_id / agent_typeが付く。外部から
# 起動されたCodexには付かないため、rollout先頭のoriginatorで補う。
# transcript_pathやoriginatorを読めない場合は、本人セッションの正当な
# report-metadataを止めないよう、委譲先と断定しない。
delegation_source() {
    local agent_id agent_type transcript_path first_line originator
    agent_id=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.agent_id | strings')
    agent_type=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.agent_type | strings')
    if [ -n "$agent_id" ] || [ -n "$agent_type" ]; then
        printf 'sub agent'
        return 0
    fi

    transcript_path=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.transcript_path | strings')
    [ -n "$transcript_path" ] && [ -r "$transcript_path" ] || return 1
    first_line=''
    IFS= read -r first_line < "$transcript_path" || true
    [ -n "$first_line" ] || return 1
    originator=$(printf '%s\n' "$first_line" | jq -r \
        'select(.type == "session_meta") | .payload.originator | strings' 2>/dev/null) || return 1
    case "$originator" in
        'Claude Code' | codex_exec)
            printf 'Codex (%s)' "$originator"
            return 0
            ;;
    esac
    return 1
}

# ============================================================================
# 全ルール共通のシェル解釈(awkの前置き)
#
# ヒアドキュメント本文・引用符内・コメントを検査対象から外し、単純コマンドへ分割する。
# **ここを共有するのが要点** ── かつては各ルールへ写していたが、ヒアドキュメントの
# 読み違えのような直しを1箇所で済ませられないと、写しが黙って食い違う。
# ルール固有の前処理(LC_ALLの引用外し・リダイレクト演算子の退避)は各ルール側に残す。
# ============================================================================
read -r -d '' AWK_PRELUDE <<'AWK' || true
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

function is_wrapper(w) {
    return w == "command" || w == "exec" || w == "nohup" || w == "time" ||
        w == "env" || w == "xargs" || w == "stdbuf" || w == "timeout" ||
        w == "nice" || w == "sudo" || w == "caffeinate" ||
        w == "do" || w == "then" || w == "else" || w == "elif" ||
        w == "if" || w == "while" || w == "until" || w == "!"
}

# **引用の外にある** `<<` の位置を返す(無ければ 0)。`<<<`(herestring)は除く。
# 単純な正規表現では `echo "<<EOF"` のような引用符の中の記述まで開始記号に見えてしまい、
# **以降の行が丸ごとヒアドキュメント本文として素通しになる**ため、引用状態を追う。
function heredoc_pos(s,   i, c, q, n, j, depth) {
    q = ""
    n = length(s)
    for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (q == "") {
            if (c == "\\") { i++; continue }
            if (c == "'" || c == "\"") { q = c; continue }
            # 算術式の中の `<<` はシフト演算子。`$((1<<2))` をヒアドキュメントと読まない。
            # **括弧の深さで閉じ位置を決める** ── 最初の `))` で切ると
            # `$(( (1+(2)) << 3 ))` の内側で切れて、続きがヒアドキュメントに化ける
            if (c == "(" && substr(s, i + 1, 1) == "(") {
                depth = 2
                for (j = i + 2; j <= n && depth > 0; j++) {
                    if (substr(s, j, 1) == "(") depth++
                    else if (substr(s, j, 1) == ")") depth--
                }
                if (depth > 0) return 0
                i = j - 1
                continue
            }
            if (c == "<" && substr(s, i + 1, 1) == "<") {
                if (substr(s, i + 2, 1) == "<") { i += 2; continue }
                return i
            }
        } else if (c == q) {
            q = ""
        } else if (q == "\"" && c == "\\") {
            i++
        }
    }
    return 0
}

# ヒアドキュメント開始を検出したら、開始記号+delimiterを取り除いた行を返す。
# **開始行の残り(`> memo.md` 等)は解析に残す**ので `cat <<'EOF' > memo.md` を拾える。
#
# delimiterには `-` や `.` や数字を含められる(`<<PARLIAMENT-EOF` / `<<123`)。
# ここを取りこぼすと**終端行と一致しなくなり、以降のコマンドが全部本文として素通しになる**か、
# 逆に**本文が実コマンドとして検査される**(誤拒否)。
# 数字だけのdelimiterと算術シフトの見分けは `heredoc_pos` が引き受ける。
function heredoc_open(line,   pos, rest, delim) {
    pos = heredoc_pos(line)
    if (pos == 0) return line
    rest = substr(line, pos)
    if (!match(rest, /^<<-?[ \t]*\\?["']?[A-Za-z0-9_][A-Za-z0-9_.-]*["']?/)) return line
    delim = substr(rest, RSTART, RLENGTH)
    line = substr(line, 1, pos - 1) " " substr(rest, RLENGTH + 1)
    sub(/^<</, "", delim)
    heredoc_dash = (substr(delim, 1, 1) == "-")
    sub(/^-/, "", delim)
    delim = trim(delim)
    sub(/^\\/, "", delim)
    gsub(/["']/, "", delim)
    heredoc_delim = delim
    in_heredoc = 1
    return line
}

# ヒアドキュメント本文の中か。終端行に当たったらそこで閉じる
function heredoc_body(line,   check) {
    if (!in_heredoc) return 0
    check = line
    if (heredoc_dash) sub(/^\t+/, "", check)
    if (check == heredoc_delim) in_heredoc = 0
    return 1
}

# バックスラッシュで退避された記号は**演算子ではなくただの文字**。
# `echo a \> b` はリダイレクトではないので、区切りにも演算子にも数えない。
function unescape_ops(line) { gsub(/\\["'<>|&;]/, " ", line); return line }

# 行末で引用が開いたままか。**開いたままなら次の行と繋いで1つの論理行として扱う**。
#
# 1行ずつ独立に見ると、複数行の引数 ── 別CLIへ渡す長い依頼文・複数行のコミットメッセージ ──
# の中に `cat >> foo` と書いてあるだけで拒否される(引用が行内で閉じないので、
# 引用符の中身を落とす処理が効かない)。**引数は引数**であって、コマンドではない。
# コメントの中の `'`(don't 等)を引用の開始と読まないよう、`#` 以降は見ない。
function unclosed_quote(s,   i, c, q, n) {
    q = ""
    n = length(s)
    for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (q == "") {
            if (c == "\\") { i++; continue }
            if (c == "#" && (i == 1 || substr(s, i - 1, 1) ~ /[ \t]/)) break
            if (c == "'" || c == "\"") q = c
        } else if (c == q) {
            q = ""
        } else if (q == "\"" && c == "\\") {
            i++
        }
    }
    return q != ""
}

# 引用符の中身とコメントは検査しない
function strip_quotes(line) {
    gsub(/'[^']*'/, " __QS__ ", line)
    gsub(/"[^"]*"/, " __QS__ ", line)
    sub(/(^|[ \t])#.*$/, "", line)
    return line
}

# 単純コマンドの区切りで分割し、出現順に check_segment へ渡す
# (順序どおりに渡すのは、ルール1の `export` の効き始めを正しく扱うため)
function dispatch(line,   n, segs, s) {
    gsub(/\|\||&&/, "\n", line)
    gsub(/[|;&(){}`]/, "\n", line)
    n = split(line, segs, "\n")
    for (s = 1; s <= n; s++) check_segment(segs[s])
}
AWK

# ============================================================================
# ルール1: ロケール未固定の集合演算(sort -u / uniq / comm / join)
#
# 既定ロケールの照合(strcoll)は日本語行の比較を壊し、sort -u は異なる行を
# 同一視して消し、comm / join は入力がLC_ALL=Cでソート済みでも自身のロケールで
# 壊れる(件数は合うのに中身が別物になり、エラーも警告も出ない)。
# 素の sort(-u なし)は壊れるのが並び順だけで誤発火が多いため対象外。
#
# 判定の方針:
#   - 各コマンドの先頭語(env代入・ラッパーを読み飛ばした後)だけを見る
#   - `export LC_ALL=C` はそれ以降の全コマンドを守る。`LC_ALL=C` 前置は
#     そのコマンド1つだけを守る(パイプ後段は守られない: 実測どおりの意味論)
#   - 値は C / POSIX を許可する
# ============================================================================
read -r -d '' LOCALE_SET_OPS_AWK <<'AWK' || true
# sortの引数列から一意化指定(-u / --unique)を探す。
# 引数を取る短オプション(-k -o -S -t -T)は直後の文字列を値として読み飛ばすので、
# `sort -tu`(区切り文字が u)を誤検知しない。`--` 以降はオペランド。
function sort_has_unique(tokens, n, start,   i, tok, j, c, pending_arg) {
    pending_arg = 0
    for (i = start; i <= n; i++) {
        tok = tokens[i]
        if (pending_arg) { pending_arg = 0; continue }
        if (tok == "--") break
        if (tok == "--unique") return 1
        if (tok ~ /^--/) continue
        if (tok ~ /^-./) {
            for (j = 2; j <= length(tok); j++) {
                c = substr(tok, j, 1)
                if (c == "u") return 1
                if (index("koStT", c)) {
                    if (j == length(tok)) pending_arg = 1
                    break
                }
            }
        }
    }
    return 0
}

function check_segment(seg,   n, tokens, i, guard, tok, cmd) {
    seg = trim(seg)
    if (seg == "") return
    n = split(seg, tokens, /[ \t]+/)
    if (tokens[1] == "export") {
        for (i = 2; i <= n; i++)
            if (tokens[i] == "LC_ALL=C" || tokens[i] == "LC_ALL=POSIX") exported = 1
        return
    }
    guard = exported
    i = 1
    while (i <= n) {
        tok = tokens[i]
        if (tok ~ /^[A-Za-z_][A-Za-z_0-9]*=/) {
            if (tok == "LC_ALL=C" || tok == "LC_ALL=POSIX") guard = 1
            i++
            continue
        }
        if (is_wrapper(tok)) {
            i++
            while (i <= n && (tokens[i] ~ /^-/ || tokens[i] ~ /^[0-9]+[smhd]?$/)) i++
            continue
        }
        break
    }
    if (i > n) return
    cmd = tokens[i]
    sub(/^\\/, "", cmd)
    sub(/.*\//, "", cmd)
    if (cmd == "uniq" || cmd == "comm" || cmd == "join") {
        if (!guard) print seg
        return
    }
    if (cmd == "sort" && !guard && sort_has_unique(tokens, n, i + 1)) print seg
}

{
    line = $0
    if (heredoc_body(line)) next

    # 行末バックスラッシュの継続行を連結してから解析する
    if (pending != "") { line = pending " " line; pending = "" }
    if (line ~ /\\$/) {
        pending = line
        sub(/\\$/, "", pending)
        next
    }
    # 引用が閉じないまま行が終わったら、閉じるまで繋いで1つの論理行として解析する
    if (unclosed_quote(line)) { pending = line; next }

    line = heredoc_open(line)
    line = unescape_ops(line)
    # LC_ALL指定の引用だけは、引用符を落とす前に素へ戻す(値の判定が要るため)
    gsub(/LC_ALL="C"/, "LC_ALL=C", line)
    gsub(/LC_ALL='C'/, "LC_ALL=C", line)
    gsub(/LC_ALL="POSIX"/, "LC_ALL=POSIX", line)
    gsub(/LC_ALL='POSIX'/, "LC_ALL=POSIX", line)
    line = strip_quotes(line)
    dispatch(line)
}
AWK

rule_locale_fixed_set_ops() {
    local offending
    offending=$(printf '%s\n' "$COMMAND" | awk "$AWK_PRELUDE
$LOCALE_SET_OPS_AWK")
    [ -n "$offending" ] || return 0
    {
        printf 'Bashコマンドlint: ロケール未固定の集合演算を拒否しました。\n'
        printf '  該当箇所:\n'
        printf '%s\n' "$offending" | sed 's/^/    - /'
        cat <<'MSG'
  理由: 既定ロケール(en_US.UTF-8等)では文字列比較(strcoll)が日本語行で壊れ、
  sort -u / uniq / comm / join はエラーも警告も出さずに、異なる行を同一視して
  消したり、突き合わせを総当たりにしたりします(件数が合っていても中身が壊れます)。
  直し方(どちらか):
    1. 推奨: コマンド列の先頭に `export LC_ALL=C` を置く
       → それ以降のパイプ後段・別行の sort / uniq / comm / join まで全部守られます
    2. 該当コマンドの直前に `LC_ALL=C ` を前置する(例: LC_ALL=C sort -u)
       → 前置はそのコマンド1つしか守りません。`sort | uniq` のように続く場合は
         各コマンドすべてに前置が必要です(comm / join も自身のロケールで壊れるため)
  LC_ALL=POSIX でも可。バイト一致の照合だけなら grep -Fxvf や awk の連想配列でも
  代替できます(ロケール非依存)。
MSG
    } >&2
    return 2
}

# ============================================================================
# ルール2: 委譲先からのherdrメタデータ書き込み
#
# sub agentや外部起動のCodexで `herdr pane current` を実行すると、
# 委譲元のペインが返る。そのペインへrename / report-metadataすると
# 委譲元の名義を上書きするため、読み取りは許可して書き込みだけ拒否する。
# ============================================================================
read -r -d '' HERDR_WRITE_AWK <<'AWK' || true
function check_segment(seg,   n, tokens, i, tok, cmd, noun, verb) {
    seg = trim(seg)
    if (seg == "") return
    n = split(seg, tokens, /[ \t]+/)
    i = 1
    while (i <= n) {
        tok = tokens[i]
        if (tok ~ /^[A-Za-z_][A-Za-z_0-9]*=/) {
            i++
            continue
        }
        if (is_wrapper(tok)) {
            i++
            while (i <= n && (tokens[i] ~ /^-/ || tokens[i] ~ /^[0-9]+[smhd]?$/)) i++
            continue
        }
        break
    }
    if (i + 2 > n) return
    cmd = tokens[i]
    sub(/^\\/, "", cmd)
    sub(/.*\//, "", cmd)
    if (cmd != "herdr") return
    noun = tokens[i + 1]
    verb = tokens[i + 2]
    if ((noun == "agent" && verb == "rename") ||
        (noun == "pane" && verb == "report-metadata")) print seg
}

{
    line = $0
    if (heredoc_body(line)) next

    if (pending != "") { line = pending " " line; pending = "" }
    if (line ~ /\\$/) {
        pending = line
        sub(/\\$/, "", pending)
        next
    }
    # 引用が閉じないまま行が終わったら、閉じるまで繋いで1つの論理行として解析する
    if (unclosed_quote(line)) { pending = line; next }

    line = heredoc_open(line)
    line = unescape_ops(line)
    line = strip_quotes(line)
    dispatch(line)
}
AWK

rule_delegated_herdr_write() {
    local offending source
    offending=$(printf '%s\n' "$COMMAND" | awk "$AWK_PRELUDE
$HERDR_WRITE_AWK")
    [ -n "$offending" ] || return 0
    source=$(delegation_source) || source=''
    [ -n "$source" ] || return 0
    {
        printf 'Bashコマンドlint: 委譲先からのherdrメタデータ書き込みを拒否しました。\n'
        printf '  判定: %s\n' "$source"
        printf '  該当箇所:\n'
        printf '%s\n' "$offending" | sed 's/^/    - /'
        cat <<'MSG'
  理由: 委譲先の `herdr pane current` は委譲元のペインを返すため、
  rename / report-metadataを続けると委譲元の表示名やメタデータを上書きします。
  委譲先はherdrへの報告対象外です。この報告をスキップして依頼を続行してください。
MSG
    } >&2
    return 2
}

# ============================================================================
# ルール3: Edit/Writeツールを迂回するファイル書き込み
#
# `cat >> docs/foo.md` のようにインラインで書いた内容をシェルから流し込むと、
# parliamentは差分を表示できず、Agentが最後に認識しているファイル状態と実ファイルが
# ずれても誰も気付けない。グローバル規約で禁止済みだが規約文だけでは守られないため、
# 「インラインで書いた内容をファイルへ流し込む」形だけをhookでせき止める。
#
# 対象は cat(ヒアドキュメント含む)/ echo / printf の > / >> / >| と、
# ファイル引数を取る tee。`grep ... > tmp.txt` のようなコマンド出力のキャプチャまで
# 拒否すると誤発火が多いので、**リダイレクトそのものではなく先頭コマンドで絞る**。
# 許可デバイス(/dev/null 等)とfd複製(>&2)は除外。
# `sed -i` 等のインプレース編集は別ルールの領分(ここでは見ない)。
#
# **追わないと決めたもの**(このhookは躾けであって防御ではない):
#   - コマンド名の引用・分割(`"echo" > f` / `e"ch"o > f`)
#   - `builtin` / 変数越しの起動(`E=echo; $E hi > f`)
#   - 2段以上の入れ子(`bash -c 'bash -c "…"'`。内側の検査は1段だけ)
#   - 変数やコマンド置換で組み立てた出力先(`> $OUT`)
# どれもすり抜けたところで「Agentが自分の癖を意図して通した」だけで、
# 止めたい相手はそこにいない。**追えば増えるのは誤拒否のほう**。
# ============================================================================
read -r -d '' EDITOR_BYPASS_WRITE_AWK <<'AWK' || true
# `/dev/` 配下への書き出しはファイルを作らないので対象外。
# ただし**`..` で外へ出るパスは別**(`/dev/../tmp/memo.md` は実ファイルへの書き込み)。
# 許可する名前を並べる形にはしない ── `/dev/ttys000` `/dev/pts/1` のように
# 環境ごとに違う実在デバイスまで止めることになる。
# `/dev/shm` はLinuxでは普通のファイルが作れる領域なので、名指しで除く。
function is_device(t) {
    return t ~ /^\/dev\/[A-Za-z0-9_\/.-]*$/ && t !~ /(^|\/)\.\.(\/|$)/ && t !~ /^\/dev\/shm\//
}

# リダイレクト先に実ファイルが1つでもあるか。空文字とデバイスは数えない
function has_file_target(targets,   m, parts, i) {
    m = split(targets, parts, /[ \t]+/)
    for (i = 1; i <= m; i++)
        if (parts[i] != "" && !is_device(parts[i])) return 1
    return 0
}

# 引用符付きのデバイス名から引用符だけを外す(`> "/dev/null"` を実ファイル扱いしないため)。
# **中身はそのまま残す**。固定文字列へ均すと、デバイスに見えるだけのパスまで許してしまう。
function unquote_devices(line,   out, inner) {
    out = ""
    while (match(line, /["']\/dev\/[A-Za-z0-9_\/.-]*["']/)) {
        inner = substr(line, RSTART + 1, RLENGTH - 2)
        out = out substr(line, 1, RSTART - 1) inner
        line = substr(line, RSTART + RLENGTH)
    }
    return out line
}

function check_segment(seg,   n, tokens, k, i, j, tok, rest, targets, cmd) {
    seg = trim(seg)
    if (seg == "") return
    n = split(seg, tokens, /[ \t]+/)

    # リダイレクト先を集めながら、素のトークン列(plain)を作る。
    # 先頭コマンドの判定にリダイレクトが混ざると `> out.txt cat` の類で狂うため分けておく。
    targets = ""
    k = 0
    split("", plain)
    i = 1
    while (i <= n) {
        tok = tokens[i]
        if (tok == "__FDDUP__") { i++; continue }
        if (tok == "__ALLOUT__") {
            if (i < n) targets = targets " " tokens[i + 1]
            i += 2
            continue
        }
        if (tok ~ /^[0-9]*>>?$/) {
            if (i < n) targets = targets " " tokens[i + 1]
            i += 2
            continue
        }
        if (tok ~ /^[0-9]*>>?./) {
            rest = tok
            sub(/^[0-9]*>>?/, "", rest)
            targets = targets " " rest
            i++
            continue
        }
        # 入力リダイレクト。先頭コマンドの判定から外すだけで、中身は見ない
        if (tok ~ /^[0-9]*<$/) { i += 2; continue }
        if (tok ~ /^[0-9]*<./) { i++; continue }
        plain[++k] = tok
        i++
    }
    if (k == 0) return

    i = 1
    while (i <= k) {
        tok = plain[i]
        if (tok ~ /^[A-Za-z_][A-Za-z_0-9]*=/) {
            i++
            continue
        }
        if (is_wrapper(tok)) {
            i++
            while (i <= k && (plain[i] ~ /^-/ || plain[i] ~ /^[0-9]+[smhd]?$/)) i++
            continue
        }
        break
    }
    if (i > k) return
    cmd = plain[i]
    sub(/^\\/, "", cmd)
    sub(/.*\//, "", cmd)

    if (cmd == "cat" || cmd == "echo" || cmd == "printf") {
        if (has_file_target(targets)) print seg
        return
    }
    # teeはリダイレクトではなくオペランドでファイルを取る。`| tee` だけの素通しは対象外
    if (cmd == "tee") {
        for (j = i + 1; j <= k; j++) {
            tok = plain[j]
            if (tok ~ /^-/) continue
            if (is_device(tok)) continue
            print seg
            return
        }
    }
}

{
    line = $0
    if (heredoc_body(line)) next

    if (pending != "") { line = pending " " line; pending = "" }
    if (line ~ /\\$/) {
        pending = line
        sub(/\\$/, "", pending)
        next
    }
    # 引用が閉じないまま行が終わったら、閉じるまで繋いで1つの論理行として解析する
    if (unclosed_quote(line)) { pending = line; next }

    line = heredoc_open(line)
    line = unescape_ops(line)
    line = unquote_devices(line)
    line = strip_quotes(line)

    # **分割の前にリダイレクト演算子を退避する**。`&` は区切り文字なので、
    # 素のまま split すると `>&2` が `>` と `2` に割れて「先の無いリダイレクト」に化ける。
    gsub(/&>>?/, " __ALLOUT__ ", line)
    gsub(/>&/, " __FDDUP__ ", line)
    # `>|`(noclobber の上書き)も書き込み。`|` を先に区切りとして食われると
    # リダイレクトが消えてしまうので、ここで普通の `>` へ均す
    gsub(/>\|/, " > ", line)

    # 演算子を独立した語にする。`echo hi>out.txt` のような詰め書きは、
    # 空白で切っただけでは `hi>out.txt` という1語になってリダイレクトが見えない。
    gsub(/>>/, " __APPEND__ ", line)
    gsub(/>/, " > ", line)
    gsub(/__APPEND__/, ">>", line)

    dispatch(line)
}
AWK

# `bash -c '…'` / `sh -c "…"` の内側の文字列を1件1行で書き出す。
# ラッパー越しの書き込み(`bash -c 'cat >> docs/foo.md'`)は善意でも普通に書くので、
# **内側をもう一度同じルールに通す**。追うのは1段だけで、変数展開もまたがる引用も追わない。
read -r -d '' SHELL_C_INNER_AWK <<'AWK' || true
{
    line = $0
    while (match(line, /(^|[ \t;|&(])(bash|sh|zsh)[ \t]+(-[A-Za-z]+[ \t]+)*-c[ \t]+/)) {
        line = substr(line, RSTART + RLENGTH)
        q = substr(line, 1, 1)
        if (q != "'" && q != "\"") continue
        body = substr(line, 2)
        idx = index(body, q)
        # 閉じ引用符が同じ行に無いときは、その行の残りだけを見て諦める
        if (idx == 0) { print body; break }
        print substr(body, 1, idx - 1)
        line = substr(body, idx + 1)
    }
}
AWK

rule_editor_bypass_write() {
    local offending
    offending=$(
        printf '%s\n' "$COMMAND" | awk "$AWK_PRELUDE
$EDITOR_BYPASS_WRITE_AWK"
        printf '%s\n' "$COMMAND" | awk "$SHELL_C_INNER_AWK" | awk "$AWK_PRELUDE
$EDITOR_BYPASS_WRITE_AWK"
    )
    [ -n "$offending" ] || return 0
    {
        printf 'Bashコマンドlint: Edit/Writeツールを迂回するファイル書き込みを拒否しました。\n'
        printf '  該当箇所:\n'
        printf '%s\n' "$offending" | sed 's/^/    - /'
        cat <<'MSG'
  理由: シェルから直接書くと parliament が差分を表示できず、あなたが最後に認識している
  ファイル状態と実ファイルがずれても誰も気付けません(取り違えたまま上書きが続きます)。
  直し方:
    - 新規作成・全面差し替え → Write ツール
    - 既存ファイルの一部を変える → Edit ツール(先に Read で現在の中身を読む)
  出力先が /dev/null 等のデバイスや fd複製(`>&2`)なら、そのまま書いて構いません。
  中間ファイルが要るだけなら、cat/echo/printf ではなく生成元のコマンドから直接
  リダイレクトしてください(例: `grep foo src.txt > /tmp/hit.txt` は対象外です)。
MSG
    } >&2
    return 2
}

# ============================================================================
# ルール4: シェルからのインプレース編集(sed -i / perl -i / ruby -i / awk -i inplace)
#
# ルール3と止めたい事故は同じ(parliamentが差分を出せず、Agentが認識している
# ファイル状態と実ファイルが黙ってずれる)。違うのは**塞ぎ方**で、
# **一括置換という正当な用途がある**ぶん、全部は止めない(2026-08-23 タダシ判断):
#
#   - `sed`(gsed含む)は**対象が単一ファイルのときだけ**拒否する。複数ファイル・globは
#     一括置換の典型なので通す ── 1ファイルだけを書き換えるなら、それはEditで足りる仕事
#   - `perl` / `ruby` / `awk -i inplace` は**対象を問わず拒否**。一括置換の道具としては
#     sedがあり、こちらは「Editを避けるための書き換え」で使われるほうが圧倒的に多い
#   - `/tmp` 等の一時領域は対象外。中間ファイルはそもそも差分を見せる対象ではない
#
# **判定は迷ったら通す側へ倒す**。このhookは躾けであって防御ではないので、
# 誤って止めるほうが害が大きい ── 単一ファイルと**確実に言えるとき**だけ拒否する
# (引用されたパス・変数・globが混ざったら数えられないので通す)。
#
# **表に無いオプションが1つでもあれば、そのコマンドは判定しない**。対象の数を数えるには
# 「どのオプションが値を取るか」が全部分かっている必要があり、sed / perl / ruby / awk の
# 全オプションを追い切ることはできない(BSDとGNUで値の有無すら違う `-l` のような例もある)
# ── **知らないものが混ざったら数は信用できない**ので、そこで諦める。
# 表を厚くすると拒否できる形が増える、という一方向の増え方にしておく。
#
# **スクリプトはファイルではない**。`sed`/`perl`/`ruby`/`awk` はどれも
# 「スクリプトをオプション(`-e` `-f`)で渡していなければ、**最初のオペランドがスクリプト**」
# という同じ構文なので、4つとも同じ数え方をする ── ここをsedだけ別扱いにしていたせいで、
# `sed -i s/a/b/ f.txt`(引用なし)が2ファイルに見えて通り、
# `sed -i s/a/b/ /tmp/x.md` は `s/a/b/` を実ファイルと数えて拒否していた(2026-08-23 タダシ検収)。
#
# **追わないと決めたもの**:
#   - `python -c` 等、任意コードでファイルを開いて書き換える形(コマンド名では見分けられない)
#   - `sponge` / `ed` / `ex` によるインプレース編集
#   - BSD形式の空suffix + 引用なしスクリプト(`sed -i '' s/a/b/ f.txt`)。`-i` の値とスクリプトの
#     どちらが `''` かはコマンドラインからは決まらないので、**通る側**へ倒れる
#   - コマンド名の引用・分割、変数越しの起動、2段以上の入れ子(ルール3と同じ)
# ============================================================================
read -r -d '' INPLACE_EDIT_AWK <<'AWK' || true
# 一時領域。**中間ファイルは差分を見せる対象ではない**ので、ここへの書き換えは数えない。
# scratchpad(`/private/tmp/claude-501/...`)も、macOSのTMPDIR(`/var/folders/...`)も含む。
function is_scratch(t) {
    return t ~ /^\/(private\/)?tmp\// || t ~ /^\/var\/folders\//
}

# **数を数えられないトークン**か。引用済み(`__QS__`)・変数・コマンド置換・globは、
# 中身がいくつのファイルを指すか分からない ── 分からないものは数えず、通す側へ倒す。
function is_opaque(t) {
    return t == "__QS__" || t ~ /\$/ || t ~ /[*?]/ || t ~ /\[/ || t == "-"
}

# 次の語が**オプションの値**か。`sed -i -e 's/a/b/' f.txt` の `'s/a/b/'` を
# ファイルとして数えないためのもの。
#
# **束は先頭から走査する**。末尾の1文字で決めると、`-i.save` の `e` を `-e` と読んで
# **次に来るスクリプトを値として読み飛ばし、対象の数が1つずれる**(拒否と許容が入れ替わる)。
# 値を取る文字が末尾に来たときだけ次の語が値で、途中に来たなら値は連結されている。
# `-i` は**連結でしか値を取らない**(`-i.bak`)ので、そこから先は値として扱う。
function takes_arg(tok, chars, suffixchars,   j, c) {
    if (tok !~ /^-[^-]/) return 0
    for (j = 2; j <= length(tok); j++) {
        c = substr(tok, j, 1)
        if (index(suffixchars, c)) return 0
        if (index(chars, c)) return j == length(tok)
    }
    return 0
}

# 値を**次の語**に取る長オプションか(`--file rules.sed` など)。
function long_takes_arg(tok, names) {
    return index(" " names " ", " " tok " ") > 0
}

# `--file=rules.awk` の `--file` を取り出す(値が連結された長オプションの名前)。
function long_name(tok,   p) {
    p = index(tok, "=")
    return p > 0 ? substr(tok, 1, p - 1) : tok
}

# 束の中に**スクリプト本体を供給するオプション文字**があるか(`-e` `-pe` `-eCODE`)。
# 末尾だけを見ると `-eprint` や `-frules.awk` のような**値の連結**を取り逃し、
# 「プログラムが渡されていない」と誤読して、続くファイルをプログラムファイル扱いしてしまう。
#
# **値が始まったら走査をやめる**(`stopchars`)。`-i.foo` の suffix や `-iinplace` の値まで
# フラグとして読むと、拡張子にeやfが入っているだけで「スクリプトを渡した」ことになり、
# **数が1つずれて拒否と許容が入れ替わる**。
function has_script(tok, chars, stopchars,   j, c) {
    if (chars == "") return 0
    if (tok !~ /^-[^-]/) return 0
    for (j = 2; j <= length(tok); j++) {
        c = substr(tok, j, 1)
        if (index(chars, c)) return 1
        if (index(stopchars, c)) return 0
    }
    return 0
}

# 束の中に**表に無い文字**があるか。読めないオプションが1つでもあれば、値がどこから
# 始まるかが決まらない = オペランドの数が信用できない ── 数を根拠にする判定は諦める。
# 値が始まった時点でそれ以降は表と照合しない(値の中身はフラグではない)。
function has_unknown(tok, known, valuechars,   j, c) {
    if (tok !~ /^-[^-]/) return 0
    for (j = 2; j <= length(tok); j++) {
        c = substr(tok, j, 1)
        if (!index(known, c)) return 1
        if (index(valuechars, c)) return 0
    }
    return 0
}

# 表に載っている長オプションか(値を取るもの・取らないもののどちらか)。
function long_known(name, taking, plain) {
    return long_takes_arg(name, taking) || long_takes_arg(name, plain)
}

# `-i` を含む短オプション束か。`--in-place` / `--in-place=.bak` も同じ意味。
#
# **`i` の手前に来てよいのは「値を取らない既知のフラグ」だけ**にする。未知の文字が出たら
# そこで諦めて通す ── `perl -Finput -ane …` の `input` の `i` のように、
# **オプションの値の中の文字**をインプレース指定と読むと、正当な作業を止めてしまう。
# 実際に使われる形(`-i` `-pi` `-ni` `-0pi` `-i.bak` `-I`(BSD sed))はこれで全部拾える。
function has_inplace(tok, plainflags, inplacechars,   j, c) {
    if (tok == "--in-place" || tok ~ /^--in-place=/) return 1
    if (tok ~ /^--/) return 0
    if (tok !~ /^-./) return 0
    for (j = 2; j <= length(tok); j++) {
        c = substr(tok, j, 1)
        if (index(inplacechars, c)) return 1
        if (!index(plainflags, c)) return 0
    }
    return 0
}

function check_segment(seg,   n, tokens, i, k, tok, cmd, kind, plainflags, inplacechars, argchars,
                       longargs, plainlong, scriptchars, longscript, stopchars, suffixchars, known,
                       inplace, files, scratch, sawscript, operands, endopts) {
    seg = trim(seg)
    if (seg == "") return
    n = split(seg, tokens, /[ \t]+/)

    # env代入とラッパー(env / time …)を読み飛ばして先頭コマンドを出す
    i = 1
    while (i <= n) {
        tok = tokens[i]
        if (tok ~ /^[A-Za-z_][A-Za-z_0-9]*=/) { i++; continue }
        # **xargs越しは数えられない**。実行時にstdin由来のファイルが後ろへ足されるので、
        # 書いてあるファイル数は上限ではない ── 数が分からないものは通す側へ倒す
        if (tok == "xargs") return
        if (is_wrapper(tok)) {
            i++
            while (i <= n && (tokens[i] ~ /^-/ || tokens[i] ~ /^[0-9]+[smhd]?$/)) i++
            continue
        }
        break
    }
    if (i > n) return
    cmd = tokens[i]
    sub(/^\\/, "", cmd)
    sub(/.*\//, "", cmd)

    # kind は塞ぎ方の違い。sedだけが「単一ファイルのときだけ拒否」で、他は数によらない。
    # 残りはコマンドごとのオプション表:
    #   plainflags … 値を取らないフラグ(`-i` の手前に来てよい文字)
    #   argchars / longargs … 値を**次の語**に取るオプション(読み飛ばす)
    #   scriptchars / longscript … スクリプト本体を供給するオプション
    #     (これがあれば最初のオペランドもファイル。**コマンドごとに文字が違う**ので、
    #      共通の `e/E/f` で見ると perl の `-f`・ruby の `-E` を取り違える)
    # argchars は**次の語を値に取れる**オプション、suffixchars は**値が連結でしか来ない**
    # オプション(`-i.bak` `-Mmodule`)。分けないと、`perl -C -pi -e …` の `-C` が
    # 次の `-pi` を値として食べてしまい、インプレース指定を見落とす
    #   inplacechars … インプレース指定(BSD sedは `-I` も同じ意味)
    #   plainlong … 値を取らない長オプション(表に無い長オプションが来たら判定を諦める)
    # **BSDとGNUで値の有無が違うオプション(sedの `-l`)は、どちらの表にも載せない**
    # ── 載せずに未知として諦めるほうが、数を読み違えるより安全。
    if (cmd == "sed" || cmd == "gsed") {
        kind = "sed"; plainflags = "nrEsuzbaH"; inplacechars = "iI"; argchars = "ef"
        suffixchars = "i"
        longargs = "--expression --file"
        plainlong = "--in-place --quiet --silent --regexp-extended --separate --unbuffered" \
            " --null-data --zero-terminated --posix --debug --sandbox --follow-symlinks" \
            " --binary --help --version"
        scriptchars = "ef"; longscript = "--expression --file"
    } else if (cmd == "perl") {
        kind = "always"; plainflags = "pnlacswSdtuUWvh0123456789"; inplacechars = "i"
        argchars = "eEI"; suffixchars = "iFmMCDx"
        longargs = ""; plainlong = "--help --version"
        scriptchars = "eE"; longscript = ""
    } else if (cmd == "ruby") {
        kind = "always"; plainflags = "pnlacswdvhwyU0123456789"; inplacechars = "i"
        argchars = "eEIrC"; suffixchars = "iFKx"
        longargs = "--encoding --external-encoding --internal-encoding --enable --disable"
        plainlong = "--verbose --version --help --debug --yydebug --copyright --jit"
        scriptchars = "e"; longscript = ""
    } else if (cmd == "awk" || cmd == "gawk") {
        # awkの `-i` は分離して取る値(`-i inplace`)なので、連結専用ではない
        kind = "awk"; plainflags = ""; inplacechars = ""; argchars = "vfiFl"; suffixchars = ""
        longargs = "--include --source --assign --file --field-separator --load --exec --profile" \
            " --dump-variables"
        plainlong = "--traditional --posix --lint --re-interval --sandbox --optimize" \
            " --characters-as-bytes --non-decimal-data --use-lc-numeric --debug --gen-pot" \
            " --help --version --copyright"
        scriptchars = "ef"; longscript = "--source --file"
    } else return
    # 値が始まったらフラグの走査をやめる位置(3つの判定で同じ規則を使う)
    stopchars = argchars suffixchars
    known = plainflags inplacechars argchars suffixchars

    inplace = 0
    files = 0
    scratch = 0
    sawscript = 0
    operands = 0
    endopts = 0
    for (k = i + 1; k <= n; k++) {
        tok = tokens[k]
        # `--` 以降は**オプションを見ない**。ハイフン始まりのファイル名をオプションと読むと、
        # 複数ファイルの一括置換が「単一ファイル」に見えて誤って止まる。
        # **オペランドの数え方は `--` の前後で変えない**(perl/rubyは `[--] programfile …`)
        if (!endopts && tok == "--") { endopts = 1; continue }
        if (!endopts && tok ~ /^-/ && tok != "-") {
            # **表に無いオプションが出たら、そのコマンドは判定しない**。値の位置が読めず、
            # オペランドの数がずれる ── ずれた数で拒否/許容を決めるほうが害が大きい
            if (tok ~ /^--/) {
                if (!long_known(long_name(tok), longargs, plainlong)) return
            } else if (has_unknown(tok, known, stopchars)) {
                return
            }
            if (kind == "awk") {
                # gawkのインプレースは**オプションの値**(`-i inplace`)。`-i` 単体では効かない
                if ((tok == "-i" || tok == "--include") && k < n && tokens[k + 1] == "inplace") inplace = 1
                if (tok == "-iinplace" || tok == "--include=inplace") inplace = 1
            } else if (has_inplace(tok, plainflags, inplacechars)) {
                inplace = 1
            }
            if (has_script(tok, scriptchars, stopchars)) sawscript = 1
            if (long_takes_arg(long_name(tok), longscript)) sawscript = 1
            if (tok ~ /^--/) {
                if (long_takes_arg(tok, longargs)) k++
            } else if (takes_arg(tok, argchars, suffixchars)) {
                k++
            } else if (kind == "sed" && tok == "-i" && k < n && tokens[k + 1] ~ /^\.[A-Za-z0-9._-]*$/) {
                # BSD sed の分離したバックアップ拡張子(`-i .bak`)。ファイルではなく `-i` の値
                k++
            }
            continue
        }
        # awkは**プログラムの後ろに変数代入を置ける**(`'{print}' OFS=, data.txt`)。
        # これはファイルではないので、プログラムファイルの数え方からも外す
        if (kind == "awk" && tok ~ /^[A-Za-z_][A-Za-z_0-9]*=/) continue
        operands++
        # **スクリプトをオプションで渡していなければ、最初のオペランドはスクリプト**
        # (sedなら置換式、perl/ruby/awkならプログラム)。4コマンドとも同じ構文なので同じに数える
        # ── ファイルとして数えると、対象の数がずれて拒否と許容が入れ替わる
        if (!sawscript && operands == 1) continue
        if (is_opaque(tok)) continue
        if (is_scratch(tok)) { scratch++; continue }
        files++
    }
    if (!inplace) return

    if (kind == "sed") {
        # **単一ファイルと確実に言えるときだけ**拒否する(複数・glob・変数は一括置換とみなす)
        if (files == 1) print seg
        return
    }
    # perl / ruby / awk は対象の数によらず拒否。一時領域しか触らないものだけ除く
    if (files > 0 || scratch == 0) print seg
}

{
    line = $0
    if (heredoc_body(line)) next

    if (pending != "") { line = pending " " line; pending = "" }
    if (line ~ /\\$/) {
        pending = line
        sub(/\\$/, "", pending)
        next
    }
    if (unclosed_quote(line)) { pending = line; next }

    line = heredoc_open(line)
    line = unescape_ops(line)
    line = strip_quotes(line)
    dispatch(line)
}
AWK

rule_inplace_edit() {
    local offending
    offending=$(
        printf '%s\n' "$COMMAND" | awk "$AWK_PRELUDE
$INPLACE_EDIT_AWK"
        printf '%s\n' "$COMMAND" | awk "$SHELL_C_INNER_AWK" | awk "$AWK_PRELUDE
$INPLACE_EDIT_AWK"
    )
    [ -n "$offending" ] || return 0
    {
        printf 'Bashコマンドlint: シェルからのインプレース編集を拒否しました。\n'
        printf '  該当箇所:\n'
        printf '%s\n' "$offending" | sed 's/^/    - /'
        cat <<'MSG'
  理由: シェルで直接書き換えると parliament が差分を表示できず、あなたが最後に認識している
  ファイル状態と実ファイルがずれても誰も気付けません(取り違えたまま上書きが続きます)。
  直し方:
    - 1〜数箇所 → Edit ツール(先に Read で現在の中身を読む)
    - 単一ファイルへの一括置換 → 対象を複数ファイル指定にできないか、Edit で分割できないかを
      先に検討する(それでも要るなら、なぜ要るかをタダシへ伝えてから進める)
  複数ファイル・glob への `sed -i`(一括置換の典型)と、/tmp 配下の中間ファイルは対象外です。
  `perl -i` / `ruby -i` / `awk -i inplace` は対象の数によらず使いません。
MSG
    } >&2
    return 2
}

# ============================================================================
# ルール5: 生の `codex exec`
#
# `codex exec` はstdinがEOFを返さない環境(Claude Code / CodexのBashツール)で
# 「Reading additional input from stdin...」のまま**プロンプト送信前に無限ブロック**する。
# `< /dev/null` を付ける運用ルールはVaultに書いてあったが読み忘れで4回再発した
# (実測: 空振り50分×2、32分、28分。`| tail` 併用時は進捗も見えない)ため、
# 生の呼び出しを止めて `parliament codex-exec`(stdinを閉じる・出力をファイルへ落とす・
# ハング/タイムアウト自己検知つき)へ誘導する。
#
# `< /dev/null` が付いていても止める ── stdinの他に「パイプでバッファされて進捗が
# 見えない」「待ちループの自作」という事故の残り半分があり、ラッパーはそこまで畳む。
# ラッパー内部のcodex exec実行はBashツールを通らないので、このhookには当たらない。
#
# **追わないと決めたもの**(このhookは躾けであって防御ではない):
#   - コマンド名の引用・分割・変数越しの起動(ルール3と同じ)
#   - `codex e` のような略記(実在しない)や、interactiveな素の `codex`(ブロックしない)
#   - 引用されたグローバルオプション値の後ろのexec(`codex -c model="o3" exec`)。
#     引用は __QS__ に潰れて値の区切りが読めなくなるため、通る側へ倒れる
# ============================================================================
read -r -d '' CODEX_EXEC_AWK <<'AWK' || true
# 値を**次の語**に取るラッパーのオプション。共通の読み飛ばし(`-任意` と数値)だけだと
# `timeout -s KILL 600 codex exec` の `KILL` で走査が止まり、すり抜ける(codexレビューで実測)
function wrapper_takes_arg(tok) {
    return tok == "-s" || tok == "--signal" || tok == "-u" || tok == "--user" ||
        tok == "-g" || tok == "--group" || tok == "-k" || tok == "--kill-after"
}

# 値を**次の語**に取るcodexのグローバルオプション(`codex -c k=v exec` の形を見逃さない)
function codex_takes_arg(tok) {
    return tok == "-c" || tok == "--config" || tok == "-m" || tok == "--model" ||
        tok == "-p" || tok == "--profile" || tok == "-s" || tok == "--sandbox" ||
        tok == "-C" || tok == "--cd" || tok == "-i" || tok == "--image" ||
        tok == "-o" || tok == "--output-last-message" || tok == "--output-schema" ||
        tok == "--enable" || tok == "--disable" || tok == "--local-provider" ||
        tok == "--color" || tok == "--add-dir"
}

function check_segment(seg,   n, tokens, i, j, tok, cmd) {
    seg = trim(seg)
    if (seg == "") return
    n = split(seg, tokens, /[ \t]+/)
    i = 1
    while (i <= n) {
        tok = tokens[i]
        if (tok ~ /^[A-Za-z_][A-Za-z_0-9]*=/) {
            i++
            continue
        }
        if (is_wrapper(tok)) {
            i++
            while (i <= n) {
                if (wrapper_takes_arg(tokens[i])) { i += 2; continue }
                if (tokens[i] ~ /^-/ || tokens[i] ~ /^[0-9]+[smhd]?$/) { i++; continue }
                break
            }
            continue
        }
        break
    }
    if (i + 1 > n) return
    cmd = tokens[i]
    sub(/^\\/, "", cmd)
    sub(/.*\//, "", cmd)
    if (cmd != "codex") return
    # グローバルオプションを読み飛ばし、最初のサブコマンドがexecなら拒否する
    j = i + 1
    while (j <= n && tokens[j] ~ /^-/) {
        if (codex_takes_arg(tokens[j])) j += 2
        else j++
    }
    if (j <= n && tokens[j] == "exec") print seg
}

{
    line = $0
    if (heredoc_body(line)) next

    if (pending != "") { line = pending " " line; pending = "" }
    if (line ~ /\\$/) {
        pending = line
        sub(/\\$/, "", pending)
        next
    }
    # 引用が閉じないまま行が終わったら、閉じるまで繋いで1つの論理行として解析する
    if (unclosed_quote(line)) { pending = line; next }

    line = heredoc_open(line)
    line = unescape_ops(line)
    line = strip_quotes(line)
    dispatch(line)
}
AWK

rule_raw_codex_exec() {
    local offending
    offending=$(printf '%s\n' "$COMMAND" | awk "$AWK_PRELUDE
$CODEX_EXEC_AWK")
    [ -n "$offending" ] || return 0
    {
        printf 'Bashコマンドlint: 生の codex exec を拒否しました。\n'
        printf '  該当箇所:\n'
        printf '%s\n' "$offending" | sed 's/^/    - /'
        cat <<'MSG'
  理由: codex exec はstdinがEOFを返さないこの環境で、プロンプト送信前に
  「Reading additional input from stdin...」のまま無限ブロックします(実測で最長50分の空振り)。
  パイプ(| tail 等)を挟むと進捗も見えなくなります。
  直し方: parliament codex-exec を使ってください。stdinを閉じ、出力をファイルへ落とし、
  ハング検知とタイムアウトつきで完了まで待ちます(待ちループの自作は不要です):
    parliament codex-exec -C <repo> "<プロンプト>"
    parliament codex-exec -C <repo> --prompt-file /tmp/prompt.md --effort high
  Bashツールからは run_in_background: true で起動してください(実行時間は事前に
  分からないため、フォアグラウンド呼び出しは別ルールが止めます)。
  詳細: parliament codex-exec(引数なし)で使い方が出ます。
MSG
    } >&2
    return 2
}

# ============================================================================
# ルール6: フォアグラウンドの `parliament codex-exec`
#
# Claude CodeのBashツールはフォアグラウンド実行に上限がある(既定2分、指定しても
# 最大10分)。`parliament codex-exec` の既定 `--timeout` は900秒なので、素で呼ぶと
# **ラッパーより先にBashツールが打ち切り、レビュー成果ごと失う**(2026-08-24 実測:
# effort highのレビューは540秒でも完走しなかった)。`run_in_background: true` で
# 起動すれば上限が当たらず、終了通知で結果を受け取れる。
#
# **フォアグラウンドは `--timeout` の値によらず常に拒否する**(2026-08-24 タダシ判断)。
# 当初は「実効 --timeout ≦ 540秒なら通す」逃げ道を置いたが、codexの実行時間は
# 実行前に分からないので、この逃げ道は「短いと踏んでtimeoutを縮める → 外れて
# 1回分を丸ごと失い、バックグラウンドでやり直す」という二重の無駄へ誘導していた。
# 常にバックグラウンドなら、短い依頼で増えるのは通知1往復ぶんの待ちだけ。
#
# `run_in_background` はBashツールのhook入力にしか無い。Codex CLI経由など**フラグの
# 無い環境ではフォアグラウンド扱いになり常に拒否される**。codexからの入れ子呼び出しは
# 現状想定していない(必要になったら、その環境を識別する口をこのルールに作る)。
# ============================================================================
read -r -d '' CODEX_EXEC_FG_AWK <<'AWK' || true
function check_segment(seg,   n, tokens, i, tok, cmd) {
    seg = trim(seg)
    if (seg == "") return
    n = split(seg, tokens, /[ \t]+/)
    i = 1
    while (i <= n) {
        tok = tokens[i]
        if (tok ~ /^[A-Za-z_][A-Za-z_0-9]*=/) {
            i++
            continue
        }
        if (is_wrapper(tok)) {
            i++
            while (i <= n && (tokens[i] ~ /^-/ || tokens[i] ~ /^[0-9]+[smhd]?$/)) i++
            continue
        }
        break
    }
    if (i + 1 > n) return
    cmd = tokens[i]
    sub(/^\\/, "", cmd)
    sub(/.*\//, "", cmd)
    if (cmd == "parliament" && tokens[i + 1] == "codex-exec") print seg
}

{
    line = $0
    if (heredoc_body(line)) next

    if (pending != "") { line = pending " " line; pending = "" }
    if (line ~ /\\$/) {
        pending = line
        sub(/\\$/, "", pending)
        next
    }
    # 引用が閉じないまま行が終わったら、閉じるまで繋いで1つの論理行として解析する
    if (unclosed_quote(line)) { pending = line; next }

    line = heredoc_open(line)
    line = unescape_ops(line)
    line = strip_quotes(line)
    dispatch(line)
}
AWK

rule_codex_exec_foreground() {
    local in_background offending
    in_background=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.tool_input.run_in_background == true')
    [ "$in_background" = true ] && return 0
    offending=$(printf '%s\n' "$COMMAND" | awk "$AWK_PRELUDE
$CODEX_EXEC_FG_AWK")
    [ -n "$offending" ] || return 0
    {
        printf 'Bashコマンドlint: フォアグラウンドの parliament codex-exec を拒否しました。\n'
        printf '  該当箇所:\n'
        printf '%s\n' "$offending" | sed 's/^/    - /'
        cat <<'MSG'
  理由: Bashツールのフォアグラウンド実行には上限(既定2分、最大10分)があり、
  codexの実行時間は事前に分からないため、上限を超えた時点でラッパーより先に
  ツール側が打ち切ってレビュー成果ごと失います。
  直し方: Bashツールを run_in_background: true で起動してください。
  上限が当たらず、完了時に終了通知が届きます(待ちループの自作は不要です)。
MSG
    } >&2
    return 2
}

# ============================================================================
# ルールの登録と実行
# ============================================================================

RULES=(
    rule_locale_fixed_set_ops
    rule_delegated_herdr_write
    rule_editor_bypass_write
    rule_inplace_edit
    rule_raw_codex_exec
    rule_codex_exec_foreground
)

RESULT=0
for rule in "${RULES[@]}"; do
    "$rule" || RESULT=2
done
exit "$RESULT"
