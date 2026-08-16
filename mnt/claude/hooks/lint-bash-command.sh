#!/bin/bash
# parliament: Bashコマンドを実行前に検査する汎用lint。
#
# Claude Code / Codex CLIのPreToolUse(matcher: Bash)から呼ばれ、stdinのhook入力から
# `.tool_input.command` を取り出してルール関数に通す。違反時はexit 2で実行を拒否し、
# stderrのメッセージだけでAgentが直し方を判断できるようにする。
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

# ============================================================================
# ルール1: ロケール未固定の集合演算(sort -u / uniq / comm / join)
#
# 既定ロケールの照合(strcoll)は日本語行の比較を壊し、sort -u は異なる行を
# 同一視して消し、comm / join は入力がLC_ALL=Cでソート済みでも自身のロケールで
# 壊れる(件数は合うのに中身が別物になり、エラーも警告も出ない)。
# 素の sort(-u なし)は壊れるのが並び順だけで誤発火が多いため対象外。
# ============================================================================

# 解析はawkで行う。方針:
#   - ヒアドキュメント本文・引用符内・コメントは検査対象から外す(誤検知の抑制)
#   - `|` `;` `&&` `||` `&` `(` `)` `{` `}` バッククォートで単純コマンドへ分割し、
#     各コマンドの先頭語(env代入・ラッパーを読み飛ばした後)だけを判定する
#   - `export LC_ALL=C` はそれ以降の全コマンドを守る。`LC_ALL=C` 前置は
#     そのコマンド1つだけを守る(パイプ後段は守られない: 実測どおりの意味論)
#   - 値は C / POSIX を許可する
read -r -d '' LOCALE_SET_OPS_AWK <<'AWK' || true
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

function is_wrapper(w) {
    return w == "command" || w == "exec" || w == "nohup" || w == "time" ||
        w == "env" || w == "xargs" || w == "stdbuf" || w == "timeout" ||
        w == "nice" || w == "sudo" || w == "caffeinate" ||
        w == "do" || w == "then" || w == "else" || w == "elif" ||
        w == "if" || w == "while" || w == "until" || w == "!"
}

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

    # ヒアドキュメント本文は読み飛ばす
    if (in_heredoc) {
        check = line
        if (heredoc_dash) sub(/^\t+/, "", check)
        if (check == heredoc_delim) in_heredoc = 0
        next
    }

    # 行末バックスラッシュの継続行を連結してから解析する
    if (pending != "") { line = pending " " line; pending = "" }
    if (line ~ /\\$/) {
        pending = line
        sub(/\\$/, "", pending)
        next
    }

    # ヒアドキュメント開始の検出(<<< は除外)。開始行の残り(パイプ等)は解析対象に残す
    if (match(line, /(^|[^<])<<-?[ \t]*\\?["']?[A-Za-z_][A-Za-z_0-9]*["']?/)) {
        if (substr(line, RSTART, 1) != "<") { RSTART++; RLENGTH-- }
        delim = substr(line, RSTART, RLENGTH)
        line = substr(line, 1, RSTART - 1) " " substr(line, RSTART + RLENGTH)
        sub(/^<</, "", delim)
        heredoc_dash = (substr(delim, 1, 1) == "-")
        sub(/^-/, "", delim)
        delim = trim(delim)
        sub(/^\\/, "", delim)
        gsub(/["']/, "", delim)
        heredoc_delim = delim
        in_heredoc = 1
    }

    # 引用符の中身は検査しない。ただしLC_ALL指定の引用だけは先に素へ戻す
    gsub(/\\["']/, " ", line)
    gsub(/LC_ALL="C"/, "LC_ALL=C", line)
    gsub(/LC_ALL='C'/, "LC_ALL=C", line)
    gsub(/LC_ALL="POSIX"/, "LC_ALL=POSIX", line)
    gsub(/LC_ALL='POSIX'/, "LC_ALL=POSIX", line)
    gsub(/'[^']*'/, " __QS__ ", line)
    gsub(/"[^"]*"/, " __QS__ ", line)
    sub(/(^|[ \t])#.*$/, "", line)

    # 単純コマンドの区切りで分割し、出現順に検査する(exportの効き始めを順序どおりに扱う)
    gsub(/\|\||&&/, "\n", line)
    gsub(/[|;&(){}`]/, "\n", line)
    n = split(line, segs, "\n")
    for (s = 1; s <= n; s++) check_segment(segs[s])
}
AWK

rule_locale_fixed_set_ops() {
    local offending
    offending=$(printf '%s\n' "$COMMAND" | awk "$LOCALE_SET_OPS_AWK")
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
# ルールの登録と実行
# ============================================================================

RULES=(
    rule_locale_fixed_set_ops
)

RESULT=0
for rule in "${RULES[@]}"; do
    "$rule" || RESULT=2
done
exit "$RESULT"
