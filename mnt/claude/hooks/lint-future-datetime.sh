#!/bin/bash
# parliament: Markdownへ未来の日時を書こうとする編集を、実ファイルへ書かれる前に拒否する。
#
# Claude CodeのEdit/Write/MultiEditとCodex CLIのapply_patchから「その編集で新しく現れる行」を
# 取り出し、日時として読める箇所がフック実行時刻より後ならexit 2で実編集を拒否する。
#
# lint-task-note.shと違ってVault限定ではない(作業ディレクトリを問わず全ての.mdが対象)。
# 日時の取り違えはVault外のリポジトリのfrontmatterでも起きるため射程を広く取り、
# 代わりに「何を検査するか」を列挙式にして、意味を判定できないキーへは触れない。
#
# 検査するのは3種類だけ:
#   1. 日時キー行(created / updated / done / period_start / period_end /
#      tadashi_daily_note_date)。frontmatterの書式だが、frontmatterの範囲は判定していない
#   2. ファイル名が YYYY-MM-DD.md のときの `## HH:mm ` 見出し(基準日はファイル名から取る。
#      日付ファイル名でなければ時刻の基準日が決まらないので検査しない)
#   3. トップレベル箇条書きの先頭ISO日時 `- YYYY-MM-DDTHH:mm`(Vaultの経過欄の書式)
#
# 意図的に検査しないもの(誤検知は全セッションの編集を止めるため、疑わしければ検査しない):
#   - due: 未来が正常なフィールド
#   - date: 静的サイトジェネレータの公開予定日という一般的な未来用法があり、Vault外で誤検知になる
#   - 列挙外のキー: 未知キーの意味は判定できず、due型のフィールドを巻き込むと編集自体ができなくなる
#   - T??:?? のプレースホルダ: 時刻不明を表す既存規約を壊さない(日付だけで判定する)
#   - 値の後ろに空白とYAMLコメント以外が続くもの: `2026-08-21T12:30+14:00`(タイムゾーン付き)や
#     `2026-08-21T12:30 draft`(ただの文字列)はローカル日時の辞書順比較では正しく判定できない。
#     暦として存在しない日付(`2099-02-31`)・時刻(`99:99`)も同じ扱い。誤った判定を出すより検査しない
#   - .md 以外のファイル
#
# 「新しく現れる行だけ」を見るのは、既存の未来値を温存する編集を弾かないため
# (既にある値のせいでファイルの他の箇所が直せなくなる事故を構造的に防ぐ)。
#
# この材料の取り方に伴う既知の割り切り(いずれも設計として受け入れているもの):
#   - 行の一部だけを置換するEdit(`old_string: "PLACEHOLDER"` → `new_string: "<未来日時>"` など)は、
#     完成後の行ではなく置換断片を見るため見逃す。逆に断片の先頭が検査対象の形に見えると、
#     完成後は対象外の行でも拒否する
#   - 行単位の集合差なので、同一行が別の箇所へ移動しただけの編集と、既にある行の複製は見逃す
#   - 行だけを見るのでfrontmatterの範囲・`## 経過` の内側・コードフェンスの内外を区別できない。
#     コードフェンス内へ**新しく**書く未来日時の例示や、`- <未来のISO日時> ...` の予定表は拒否される
#     (既存の例示は追加行に現れないので無害。新しく書く例示は過去日時で書けば足りる)
set -uo pipefail
unset CDPATH
# 日時の大小はゼロ埋め固定幅の辞書順で判定する。ロケール依存の照合順で壊さないためバイト比較へ固定する。
export LC_ALL=C

fail() {
    printf '未来時刻lint: %s\n' "$1" >&2
    exit 2
}

command -v jq >/dev/null 2>&1 || fail '必須コマンド jq が見つかりません。'

# NTP補正や分境界で正常な記入を弾く事故を避けるための猶予(分)。date '+%Y-%m-%dT%H:%M' は秒を
# 切り捨てるので取得値が未来になることは構造上ないが、正常な記入を弾く方が痛い。
# 無効化のスイッチは設けない(抜け道を作らない)。猶予分数だけ上書きできる。
TOLERANCE_LIMIT=1440
TOLERANCE_MINUTES=${PARLIAMENT_FUTURE_DATETIME_TOLERANCE_MINUTES:-1}
tolerance_error() {
    fail "PARLIAMENT_FUTURE_DATETIME_TOLERANCE_MINUTES は0〜${TOLERANCE_LIMIT}の整数で指定してください(受領値: ${TOLERANCE_MINUTES})。"
}
case "$TOLERANCE_MINUTES" in
    '' | *[!0-9]*) tolerance_error ;;
esac
# 桁数を先に見る。巨大な値は算術展開自体が失敗して以降の判定が崩れる。
[ "${#TOLERANCE_MINUTES}" -le 4 ] || tolerance_error
# 先頭ゼロ(08 など)はbashの算術で8進数と解釈されて失敗するため10進へ固定する。
TOLERANCE_MINUTES=$((10#$TOLERANCE_MINUTES))
[ "$TOLERANCE_MINUTES" -le "$TOLERANCE_LIMIT" ] || tolerance_error

# 現在時刻と上限は同じepochから導出する。dateを2回呼ぶと分境界で猶予が1分余計に伸びる。
# 整形はBSD date(macOS)を優先し、GNU dateへフォールバックする。
EPOCH=$(date '+%s') || fail '現在時刻を取得できません。'
stamp_at() {
    date -r "$1" '+%Y-%m-%dT%H:%M' 2>/dev/null || date -d "@$1" '+%Y-%m-%dT%H:%M'
}
NOW=$(stamp_at "$EPOCH") || fail '現在時刻を整形できません。'
LIMIT=$(stamp_at "$((EPOCH + TOLERANCE_MINUTES * 60))") || fail '許容上限を整形できません。'
# 日付のみの値は上限の日付と比べる。日付境界で猶予が効かず正常な記入を弾くのを避ける。
LIMIT_DAY=${LIMIT%T*}

# hook入力は終了コードだけでなく型も見る。jqが正常終了する不正型(文字列のはずが配列など)を
# 空値として素通しさせず、fail-closedで拒否する。
JQ_GUARD='def guard($label):
    if . == null then ""
    elif type == "string" then .
    else error("\($label) が文字列ではありません。") end;
def guard_list($label):
    if . == null then []
    elif type == "array" then .
    else error("\($label) が配列ではありません。") end;'

HOOK_INPUT=$(jq -c '.' 2>/dev/null) || fail 'hook入力をJSONとして読めません。'
read_hook() { # <jqのオプション> <フィルタ>
    local flag=$1
    shift
    printf '%s\n' "$HOOK_INPUT" | jq "$flag" "${JQ_GUARD} $1"
}
TOOL_NAME=$(read_hook -r '.tool_name | guard("tool_name")') ||
    fail 'hook入力から tool_name を読めません。'
HOOK_CWD=$(read_hook -r '.cwd | guard("cwd")') || fail 'hook入力から cwd を読めません。'
[ -n "$HOOK_CWD" ] || HOOK_CWD=$PWD

TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/parliament-future-datetime-lint.XXXXXX") ||
    fail '一時領域を作成できません。'
trap 'rm -rf -- "$TMP_ROOT"' EXIT
# 検査対象は `<絶対パス><US><追加行>` の1行1件。区切りにタブを使うと、タブを含む正当な
# ファイル名でパスと本文の境界を誤る(Unixのパスはタブを許す)ため制御文字のUSを使う。
SEP=$(printf '\037')
RECORDS=$TMP_ROOT/records
: >"$RECORDS"

resolve_path() {
    case "$1" in
        /*) printf '%s\n' "$1" ;;
        *) printf '%s/%s\n' "$HOOK_CWD" "$1" ;;
    esac
}

is_markdown() {
    case "$1" in
        *.md) return 0 ;;
        *) return 1 ;;
    esac
}

# USと改行を含むパスはレコード形式を壊す。素通し(=見逃し)にせず、理由を出して拒否する。
check_record_safe() {
    case "$1" in
        *"$SEP"* | *'
'*) fail "対象パスに制御文字が含まれており、安全に検査できません: ${1}" ;;
    esac
}

# 変更後にあって変更前になかった行を、awkの連想配列で取り出す(O(n))。
# jqの `IN($kept[])` は行数の二次時間になり、1万行で約7秒かかってhookのtimeoutに届く(実測)。
#
# パスとファイル名は `awk -v` ではなく環境変数で渡す。`-v` の値はawkがエスケープとして
# 再解釈するため、`note\037.md` のような正当なファイル名がUSへ化けて境界が壊れる。
# 行末のCRは比較の前に落とす。CRLFの実ファイルへLFで書くだけの編集を「新しい行」と
# 誤認して既存の未来値の温存を拒否してしまうため。
emit_added() { # <パス> <変更前ファイル> <変更後ファイル>
    PARLIAMENT_LINT_PATH=$1 PARLIAMENT_LINT_BASELINE=$2 awk -v sep="$SEP" '
        BEGIN {
            path = ENVIRON["PARLIAMENT_LINT_PATH"]
            baseline = ENVIRON["PARLIAMENT_LINT_BASELINE"]
        }
        { line = $0; sub(/\r$/, "", line) }
        FILENAME == baseline { kept[line] = 1; next }
        !(line in kept) { printf "%s%s%s\n", path, sep, line }
    ' "$2" "$3" >>"$RECORDS" || fail "${1} の追加行を取り出せません。"
}

# 除外の単位はツールごとに違う。MultiEditは「全editのold_stringの合併」を変更前として扱う:
# editをまたいで未来行を移動しただけの編集を拒否しないため(edit単位で差を取ると拒否になる)。
collect_claude() {
    local raw path old=$TMP_ROOT/old new=$TMP_ROOT/new
    raw=$(read_hook -r '.tool_input.file_path | guard("file_path")') ||
        fail 'hook入力から file_path を読めません。'
    [ -n "$raw" ] || exit 0
    path=$(resolve_path "$raw")
    is_markdown "$path" || exit 0
    check_record_safe "$path"

    case "$TOOL_NAME" in
        Write)
            # Writeの変更前は実ファイルの現在の中身。新規作成なら空として扱う。
            if [ -f "$path" ]; then
                cp -- "$path" "$old" || fail "${path} を一時領域へ複製できません。"
            else
                : >"$old"
            fi
            read_hook -j '.tool_input.content | guard("content")' >"$new" ||
                fail 'hook入力から content を読めません。'
            ;;
        Edit)
            read_hook -j '.tool_input.old_string | guard("old_string")' >"$old" ||
                fail 'hook入力から old_string を読めません。'
            read_hook -j '.tool_input.new_string | guard("new_string")' >"$new" ||
                fail 'hook入力から new_string を読めません。'
            ;;
        MultiEdit)
            read_hook -j '[.tool_input.edits | guard_list("edits") | .[]
                | .old_string | guard("old_string")] | join("\n")' >"$old" ||
                fail 'hook入力から edits を読めません。'
            read_hook -j '[.tool_input.edits | guard_list("edits") | .[]
                | .new_string | guard("new_string")] | join("\n")' >"$new" ||
                fail 'hook入力から edits を読めません。'
            ;;
    esac
    emit_added "$path" "$old" "$new"
}

# apply_patchの入力はdiff形式そのものなので、`+`行=新しく現れる行として直接取れる
# (lint-task-note.shのようにapply_patch実行ファイルへ依存しない)。
# 同じpatch内で`-`行にも同じ本文があれば、値の温存(移動)と見なして除外する。
collect_codex() {
    local patch_command status
    patch_command=$(read_hook -r '.tool_input.command | guard("command")') ||
        fail 'hook入力から command を読めません。'
    [ -n "$patch_command" ] || exit 0
    PARLIAMENT_LINT_CWD=$HOOK_CWD awk -v sep="$SEP" '
        BEGIN { cwd = ENVIRON["PARLIAMENT_LINT_CWD"] }
        function absolute(p) { return (p ~ /^\//) ? p : cwd "/" p }
        # パスにUSが入るとレコードの境界が壊れる。素通し(=見逃し)にせず専用の終了コードで返す。
        function adopt(p) {
            if (index(p, sep)) exit 3
            path = p
        }
        # CRLFのpatchでは `note.md\r` になり .md へ一致しなくなるので、解釈の前に落とす。
        { sub(/\r$/, "") }
        /^\*\*\* (Add|Update|Delete) File: / {
            adopt(absolute(substr($0, index($0, "File: ") + 6)))
            next
        }
        /^\*\*\* Move to: / {
            adopt(absolute(substr($0, index($0, "to: ") + 4)))
            next
        }
        /^\*\*\* / { next }
        path == "" || path !~ /\.md$/ { next }
        /^\+/ { added[++total] = path sep substr($0, 2); next }
        /^-/ { removed[path sep substr($0, 2)] = 1; next }
        END {
            for (i = 1; i <= total; i++) if (!(added[i] in removed)) print added[i]
        }
    ' <<<"$patch_command" >>"$RECORDS"
    status=$?
    [ "$status" -eq 0 ] && return 0
    [ "$status" -eq 3 ] &&
        fail 'patch対象のパスに制御文字が含まれており、安全に検査できません。'
    fail 'apply_patchの追加行を取り出せません。'
}

case "$TOOL_NAME" in
    Edit | Write | MultiEdit) collect_claude ;;
    apply_patch) collect_codex ;;
    *) exit 0 ;;
esac

[ -s "$RECORDS" ] || exit 0

# レコードは収集時にCR正規化済み。ここでは日時として読める箇所だけを判定する。
VIOLATIONS=$(awk -v limit="$LIMIT" -v limit_day="$LIMIT_DAY" -v sep="$SEP" '
    function valid_day(day,    year, month, mday, length_of_month) {
        if (day !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) return 0
        year = substr(day, 1, 4) + 0
        month = substr(day, 6, 2) + 0
        mday = substr(day, 9, 2) + 0
        if (month < 1 || month > 12 || mday < 1) return 0
        length_of_month = 31
        if (month == 4 || month == 6 || month == 9 || month == 11) length_of_month = 30
        else if (month == 2)
            length_of_month = (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28
        return (mday <= length_of_month)
    }
    function valid_clock(clock) {
        if (clock !~ /^[0-9][0-9]:[0-9][0-9]$/) return 0
        return (substr(clock, 1, 2) + 0 <= 23 && substr(clock, 4, 2) + 0 <= 59)
    }
    # 値の後ろに許すのは空白だけ、または空白+YAMLコメント。`+09:00` や ` draft` が続く値は
    # 辞書順比較では正しく判定できないので、判定せず素通しする(誤った判定を出さない)。
    # 空白のない `#` はYAMLコメントではないので受け付けない。
    function tail_ok(tail) {
        return (tail ~ /^[ \t]*$/ || tail ~ /^[ \t]+#/)
    }
    # 日時キーの値を読み、KIND(T=日時 / D=日付のみ / 空=判定しない)とVALUEを立てる。
    function judge(raw,    rest, quote, day, separator, probe, consumed, tail) {
        KIND = ""
        VALUE = ""
        rest = raw
        quote = substr(rest, 1, 1)
        if (quote == "\"" || quote == "'"'"'") rest = substr(rest, 2)
        else quote = ""

        day = substr(rest, 1, 10)
        if (!valid_day(day)) return
        separator = substr(rest, 11, 1)
        probe = substr(rest, 12, 5)
        if ((separator == "T" || separator == " ") && probe ~ /^[0-9][0-9]:[0-9][0-9]$/) {
            if (!valid_clock(probe)) return
            consumed = 16
            KIND = "T"
            VALUE = day "T" probe
        } else if ((separator == "T" || separator == " ") && probe == "??:??") {
            # T??:?? は時刻不明のプレースホルダ。日付だけで判定する。
            consumed = 16
            KIND = "D"
            VALUE = day
        } else {
            consumed = 10
            KIND = "D"
            VALUE = day
        }

        tail = substr(rest, consumed + 1)
        if (quote != "") {
            if (substr(tail, 1, 1) != quote) { KIND = ""; VALUE = ""; return }
            tail = substr(tail, 2)
        }
        if (!tail_ok(tail)) { KIND = ""; VALUE = "" }
    }
    function report(path, reason, value) {
        if (path != shown) {
            printf "%s\n", path
            shown = path
        }
        printf "- 違反: %s(%s)。\n  該当行: %s\n", reason, value, line
        found = 1
    }
    {
        boundary = index($0, sep)
        path = substr($0, 1, boundary - 1)
        line = substr($0, boundary + 1)
        base = path
        sub(/^.*\//, "", base)
        file_day = ""
        if (base ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\.md$/ && valid_day(substr(base, 1, 10)))
            file_day = substr(base, 1, 10)

        # 1. 日時キー。コロンの後に空白が要る(`updated:2026-...` はYAMLのマッピングではなく
        #    単一のスカラーなので、キーとして扱わない)。
        if (line ~ /^(created|updated|done|period_start|period_end|tadashi_daily_note_date):[ \t]/) {
            colon = index(line, ":")
            key = substr(line, 1, colon - 1)
            rest = substr(line, colon + 1)
            sub(/^[ \t]+/, "", rest)
            judge(rest)
            if (KIND == "T" && VALUE > limit)
                report(path, key " が未来の日時です", VALUE)
            else if (KIND == "D" && VALUE > limit_day)
                report(path, key " が未来の日付です", VALUE)
        }

        # 2. 日誌の記載時刻見出し。基準日はファイル名から取る。
        if (file_day != "" && line ~ /^## [0-9][0-9]:[0-9][0-9]([ \t]|$)/) {
            clock = substr(line, 4, 5)
            if (valid_clock(clock) && (file_day "T" clock) > limit)
                report(path, "見出しの記載時刻が未来です", file_day "T" clock)
        }

        # 3. トップレベル箇条書きの先頭ISO日時(Vaultの経過欄の書式)。
        if (line ~ /^- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]([ \t]|$)/) {
            progress = substr(line, 3, 16)
            if (valid_day(substr(progress, 1, 10)) && valid_clock(substr(progress, 12, 5)) &&
                progress > limit)
                report(path, "箇条書きの先頭日時が未来です", progress)
        }
    }
    END { if (found) exit 1 }
' "$RECORDS")
CHECK_STATUS=$?
[ "$CHECK_STATUS" -eq 0 ] && exit 0
# 違反あり=1。それ以外はawk自身の失敗なので、素通しさせずfail-closedで拒否する。
[ "$CHECK_STATUS" -eq 1 ] || fail '追加行を検査できませんでした。'

{
    printf '未来時刻lint: 未来の日時を書こうとしています(現在 %s / 許容上限 %s)。\n' "$NOW" "$LIMIT"
    printf '%s\n' "$VIOLATIONS"
    cat <<'MSG'
  正しいルール（引用）: 「日時は必ず date '+%Y-%m-%dT%H:%M' で実時刻を取得する。推測・未来時刻の記載は禁止」
  直し方: 日時を書く直前に date '+%Y-%m-%dT%H:%M' を実行し、その出力をそのまま貼る(1ファイルごとに取り直す)。
  補足: 最初に取った値の使い回しは過去へずれるだけで弾かれません。未来へずれるのはdateを取らずに書いたときです。
        復元できない過去の時刻は T??:?? で表せます。未来が正常な due / date は検査対象外です。
        検査対象は「その編集で新しく現れる行」だけなので、既にある未来値を温存する編集は弾きません。
        コードフェンス内へ新しく書く例示も対象です(例示の日時は過去で書いてください)。
MSG
} >&2
exit 2
