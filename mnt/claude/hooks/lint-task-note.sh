#!/bin/bash
# parliament: owlery互換Vaultのタスク・knowledgeノートを、編集前に検証する。
#
# Claude CodeのEdit/WriteとCodex CLIのapply_patchを一時領域へ再現し、
# shared/tasks・shared/knowledge直下のMarkdownをlintする。違反時はexit 2で実編集を拒否する。
set -uo pipefail
unset CDPATH
# macOS BSD awkはUTF-8ロケールで異なる日本語見出しを等値扱いするため、バイト比較へ固定する。
export LC_ALL=C

fail() {
    printf 'タスクノートlint: %s\n' "$1" >&2
    exit 2
}

for dependency in jq yq realpath; do
    command -v "$dependency" >/dev/null 2>&1 || fail "必須コマンド ${dependency} が見つかりません。"
done

HOOK_INPUT=$(jq -c '.' 2>/dev/null) || fail 'hook入力をJSONとして読めません。'
HOOK_CWD=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.cwd // empty')
[ -n "$HOOK_CWD" ] || HOOK_CWD=$PWD

expand_home() {
    local home_prefix
    home_prefix=$(printf '\176/')
    case "$1" in
        '~') printf '%s\n' "$HOME" ;;
        "$home_prefix"*) printf '%s/%s\n' "$HOME" "${1#"$home_prefix"}" ;;
        *) printf '%s\n' "$1" ;;
    esac
}

resolve_vault() {
    local configured=${PARLIAMENT_VAULT:-}
    local config_path=${PARLIAMENT_CONFIG:-$HOME/.config/parliament/config.toml}
    local config_json

    if [ -z "$configured" ]; then
        config_path=$(expand_home "$config_path")
        if [ -n "${PARLIAMENT_CONFIG:-}" ] && [ ! -f "$config_path" ]; then
            fail "明示された設定ファイル ${config_path} が見つかりません。"
        fi
        if [ -f "$config_path" ]; then
            config_json=$(yq -p=toml -o=json '.' "$config_path" 2>/dev/null) || \
                fail "設定ファイル ${config_path} をTOMLとして読めません。"
            if ! printf '%s\n' "$config_json" | jq -e \
                '(.vault == null) or ((.vault | type) == "object" and ((.vault.path == null) or ((.vault.path | type) == "string" and (.vault.path | length) > 0)))' \
                >/dev/null; then
                fail 'vault.path は空でない文字列で指定してください。'
            fi
            configured=$(printf '%s\n' "$config_json" | jq -r '.vault.path // empty')
        fi
    fi
    [ -n "$configured" ] || configured=$HOME/work/owlery
    configured=$(expand_home "$configured")
    realpath -q "$configured" || fail "Vaultパス ${configured} を解決できません。"
}

VAULT_ROOT=$(resolve_vault)
TASK_DIR=$VAULT_ROOT/shared/tasks
KNOWLEDGE_DIR=$VAULT_ROOT/shared/knowledge

resolve_tool_path() {
    local candidate
    local parent
    local basename
    local canonical_parent

    case "$1" in
        /*) candidate=$1 ;;
        *) candidate=$HOOK_CWD/$1 ;;
    esac
    parent=$(dirname -- "$candidate")
    basename=$(basename -- "$candidate")
    canonical_parent=$(realpath -q "$parent") || return 1
    printf '%s/%s\n' "$canonical_parent" "$basename"
}

is_task_path() {
    local absolute=$1
    [ "$(dirname -- "$absolute")" = "$TASK_DIR" ] && [ "${absolute##*.}" = md ]
}

is_linted_note_path() {
    local absolute=$1
    local parent

    parent=$(dirname -- "$absolute")
    { [ "$parent" = "$TASK_DIR" ] || [ "$parent" = "$KNOWLEDGE_DIR" ]; } && \
        [ "${absolute##*.}" = md ]
}

lint_file() {
    local candidate=$1
    local display_path=$2
    local lint_task_frontmatter=$3
    local frontmatter
    local frontmatter_json
    local status=''
    local done_value=''
    local frontmatter_end
    local note_errors
    local progress_errors
    local section_errors
    local linebreak_errors
    local errors=''

    if [ "$lint_task_frontmatter" -eq 1 ] && ! frontmatter=$(awk '
        NR == 1 {
            if ($0 != "---") exit 3
            next
        }
        /^---$/ {
            found = 1
            exit
        }
        { print }
        END {
            if (!found) exit 4
        }
    ' "$candidate"); then
        errors="${errors}\n- 違反: frontmatterを区切る先頭と末尾の --- が必要です。\n  正しいルール（引用）: 「タスクノートは templates/task.md に準拠し、フロントマターを必ず付ける」"
    elif [ "$lint_task_frontmatter" -eq 1 ] && ! frontmatter_json=$(printf '%s\n' "$frontmatter" | yq -o=json '.' 2>/dev/null); then
        errors="${errors}\n- 違反: frontmatterをYAMLとして解釈できません。\n  正しいルール（引用）: 「タスクノートは templates/task.md に準拠し、フロントマターを必ず付ける」"
    elif [ "$lint_task_frontmatter" -eq 1 ]; then
        status=$(printf '%s\n' "$frontmatter_json" | jq -r 'if (.status | type) == "string" then .status else "" end')
        if ! printf '%s\n' "$frontmatter_json" | jq -e \
            '.status as $status | ($status | type) == "string" and (["todo", "doing", "waiting", "pending", "done", "declined"] | index($status)) != null' \
            >/dev/null; then
            errors="${errors}\n- 違反: status「${status:-<文字列ではない値>}」は値域外です。\n  正しいルール（引用）: 「status の値域は todo / doing / waiting / pending / done / declined」"
        fi

        # status行の行末コメントは旧テンプレート由来の残骸。値が必ず埋まるフィールドのため
        # done・sessionsのように空欄時の書式提示としてコメントを残す必要がない。
        if printf '%s\n' "$frontmatter" | grep -qE '^status:[[:space:]]*[^[:space:]#]*[[:space:]]+#'; then
            errors="${errors}\n- 違反: status 行に行末コメントが残っています(旧テンプレート由来の残骸)。\n  正しいルール（引用）: 「status の行末にはコメントを書かない。templates/task.md の status: 行にコメントはなく、残っているものは旧テンプレート由来の残骸」\n  補足: done・sessions のコメントは逆に消さずに残す(空欄のまま他者へ渡るため)"
        fi

        if [ "$status" = waiting ] && ! printf '%s\n' "$frontmatter_json" | jq -e \
            '(.waiting_for | type) == "string" and (.waiting_for | length) > 0' >/dev/null; then
            errors="${errors}\n- 違反: status: waiting では waiting_for に単数の待ち先が必要です。\n  正しいルール（引用）: 「waiting へフリップするときは、frontmatter の waiting_for に待ち先を必ず記入する。値域は単数」"
        fi

        if ! printf '%s\n' "$frontmatter_json" | jq -e \
            '(.waiting_for == null) or ((.waiting_for | type) == "string" and ((.waiting_for | length) == 0 or (.waiting_for | test("^[a-z][a-z0-9-]*$"))))' \
            >/dev/null; then
            errors="${errors}\n- 違反: waiting_for は小文字英数字とハイフンで構成する人の識別子が必要です。\n  正しいルール（引用）: 「値域は人の識別子のみ。何を待つかは書かず経過欄へ」\n  正しい例: waiting_for: tadashi"
        fi

        done_value=$(printf '%s\n' "$frontmatter_json" | jq -r 'if (.done | type) == "string" then .done else "" end')
        if [ "$status" = "done" ]; then
            if [[ ! "$done_value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T([0-9]{2}:[0-9]{2}|\?\?:\?\?)$ ]]; then
                errors="${errors}\n- 違反: status: done では done に YYYY-MM-DDTHH:mm または YYYY-MM-DDT??:?? 形式の時刻が必要です。\n  正しいルール（引用）: 「done へフリップするときは、frontmatter の done フィールドに実時刻を必ず記入する。復元できない時刻は T??:?? で表す」"
            fi
        elif [ -n "$done_value" ]; then
            errors="${errors}\n- 違反: status: done 以外では done を空欄にする必要があります。\n  正しいルール（引用）: 「done 以外では done フィールドを空欄にする」"
        fi

        if ! printf '%s\n' "$frontmatter_json" | jq -e \
            '(.sessions == null) or ((.sessions | type) == "array")' >/dev/null; then
            errors="${errors}\n- 違反: sessions に値がある場合はYAMLリストが必要です。欠落・nullは許容されます。\n  正しいルール（引用）: 「sessions は欠落・nullを許容する。値がある場合はYAMLリストで記述する」"
        fi

        # blocked_by はタスク依存のエッジ元。plaintextを通すと、依存が本文に書かれただけの
        # 状態と区別できずparliamentのエッジ解決から静かに漏れるため、Wikiリンク形式を強制する。
        if ! printf '%s\n' "$frontmatter_json" | jq -e \
            '(.blocked_by == null) or ((.blocked_by | type) == "array")' >/dev/null; then
            errors="${errors}\n- 違反: blocked_by に値がある場合はYAMLリストが必要です。欠落・nullは許容されます。\n  正しいルール（引用）: 「進行の前提になっている未完了タスクがあるなら、frontmatterの blocked_by へそのタスクノートへのWikiリンクをリストで記入する」「複数可(前提タスクが複数あるのは自然な状態で、タスクを割るサインではない)」"
        elif ! printf '%s\n' "$frontmatter_json" | jq -e \
            '(.blocked_by == null) or (.blocked_by | all(if type == "string" then test("^\\[\\[[^\\[\\]]+\\]\\]$") else false end))' \
            >/dev/null; then
            errors="${errors}\n- 違反: blocked_by の各要素は \"[[タスク名]]\" 形式のWikiリンク文字列が必要です。\n  正しいルール（引用）: 「値域は shared/tasks/ のタスクノートへのWikiリンク(parent / project と同形式のクォート付き)のみ。人・外部の待ち先は書かない(それは waiting_for の領分)」"
        fi
    fi

    # frontmatterはYAMLであってMarkdownではない。ここを本文と混ぜると、YAMLコメントへ
    # 「## 経過」と書くだけで欠落検査を回避できてしまう。終端が見つからないときだけ0を返し、
    # その場合は何もスキップしない(検査を緩める方向へは倒さない)。
    frontmatter_end=$(awk '
        { sub(/\r$/, "") }
        NR == 1 && $0 != "---" { exit }
        NR > 1 && $0 == "---" {
            print NR
            exit
        }
    ' "$candidate")
    [ -n "$frontmatter_end" ] || frontmatter_end=0

    # 経過欄まわりの違反(トップレベル項目の書式・経過より後のLV2節・経過見出しの欠落)は、
    # どれもコードフェンスの内外判定を共有するため1パスで拾い、行頭のタグで振り分ける。
    note_errors=$(awk -v task_note="$lint_task_frontmatter" -v fm_end="$frontmatter_end" '
        function marker_length(line, marker,    i) {
            if (substr(line, 1, 1) != marker) return 0
            for (i = 1; substr(line, i, 1) == marker; i++);
            return i - 1
        }
        # CRLFのノートを素通しさせない。行末の \r が残ると「## 経過」の完全一致が外れ、
        # 経過欄の検査ごと丸ごと回避できてしまう(検査を緩める方向の差なので黙って通せない)。
        {
            sub(/\r$/, "")
        }
        # ここまで来て残るCRは、CommonMarkでは改行だがawkのレコード区切りではない。
        # このズレを許すと1レコードに複数行が畳み込まれ、見出しも箇条書きも認識できない。
        # 読めない入力として拒否する(黙って通すと検査を素通りしたことに誰も気づけない)。
        /\r/ {
            print "linebreak:" NR
            unreadable = 1
        }
        # CRの検査だけはfrontmatterにも効かせる。以降のMarkdown検査は本文だけを見る。
        NR <= fm_end {
            next
        }
        # 規約や書式を説明するノートは、コードフェンス内へ見出しや箇条書きの例示を貼る。
        # フェンスの内側は本文ではないため、経過欄の開始・終端・違反判定すべてから除外する。
        # CommonMarkに合わせ、3スペースまでインデントされたbacktick / tildeのフェンスも扱う。
        # 開きより短い閉じ記号は無視する(判定は standup-pack.sh と同じ意味論)。
        {
            probe = $0
            for (i = 0; i < 3 && substr(probe, 1, 1) == " "; i++) probe = substr(probe, 2)
            marker = substr(probe, 1, 1)
            marker_len = 0
            if (marker == "`" || marker == "~") marker_len = marker_length(probe, marker)
            if (!fenced && (marker == "`" || marker == "~") && marker_len >= 3) {
                fenced = 1
                fence_marker = marker
                fence_len = marker_len
            } else if (fenced && marker == fence_marker && marker_len >= fence_len && substr(probe, marker_len + 1) ~ /^[ \t]*$/) {
                fenced = 0
            }
        }
        # 「## 経過」は最後のLV2見出しでなければならない(タスクノートのみの規約)。
        # 経過欄の中の ### 小見出しは従来どおり許容するため、LV2だけを違反として拾う。
        # seen_progress は in_progress と違い見出しで下ろさない ── 経過より後のLV2節が
        # 複数あるノートで、2つ目以降を取りこぼさないようにするため。
        !fenced && task_note == 1 && seen_progress && /^## / {
            print "section:" NR ":" $0
        }
        # 末尾空白も経過欄の開始として扱う。Markdownは見出しタイトルを詰めて読むため、
        # 「## 経過 」は画面上は経過節であり、ここで外すとhookだけが見逃す不整合になる。
        !fenced && /^## 経過[ \t]*$/ {
            seen_progress = 1
            in_progress = 1
            next
        }
        # 検査対象は「## 経過」直下のトップレベル項目のみ。
        # 経過欄に ### 小見出しを立てて設計メモ等を書くノートがあるため、
        # 見出しは深さを問わず経過欄の終端として扱う(ATX記法=# の後に空白)。
        !fenced && in_progress && /^#+ / {
            in_progress = 0
        }
        !fenced && in_progress && /^- / && $0 !~ /^- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T([0-9][0-9]:[0-9][0-9]|\?\?:\?\?)( |$)/ {
            print "progress:" NR ":" $0
        }
        # 「## 経過」そのものが無ければ、経過欄の書式検査もLV2位置検査も空振りする。
        # 見出しを消す・改名するだけで経過欄のlintをまとめて回避できてしまうため、
        # 欠落そのものをタスクノートの違反として扱う(テンプレ準拠ルール上も元々違反)。
        # 読めない入力のときは原因がそちらなので、二重には指摘しない。
        END {
            if (task_note == 1 && !seen_progress && !unreadable) print "missing:1"
        }
    ' "$candidate")
    progress_errors=$(printf '%s\n' "$note_errors" | sed -n 's/^progress://p')
    section_errors=$(printf '%s\n' "$note_errors" | sed -n 's/^section://p')
    linebreak_errors=$(printf '%s\n' "$note_errors" | sed -n 's/^linebreak:/  行: /p')
    if [ -n "$linebreak_errors" ]; then
        errors="${errors}\n- 違反: 改行として扱われないCRが行の途中にあります。この状態では見出しも箇条書きも読み取れません。\n${linebreak_errors}\n  正しい直し方: 改行コードをLFに揃えてください(CRLFは可、CR単独は不可)。"
    fi
    if printf '%s\n' "$note_errors" | grep -q '^missing:'; then
        errors="${errors}\n- 違反: 「## 経過」の見出しがありません。\n  正しいルール（引用）: 「本文はテンプレートの ## 内容 / ## 成果物 / ## 経過 を基本とし、## 経過 を必ず最後のLV2見出しにする」\n  補足: 経過欄は着手・判断・完了を残す唯一の場所。中身がまだ無くても見出しは残す"
    fi
    if [ -n "$progress_errors" ]; then
        errors="${errors}\n- 違反: 経過欄のトップレベル項目がISO日時で始まっていません。\n${progress_errors}\n  正しいルール（引用）: 「経過欄のトップレベル項目は YYYY-MM-DDTHH:mm または YYYY-MM-DDT??:?? を先頭に書く。日付のみと空白区切りは禁止」"
    fi
    if [ -n "$section_errors" ]; then
        errors="${errors}\n- 違反: 「## 経過」より後にLV2見出しがあります。\n${section_errors}\n  正しいルール（引用）: 「本文はテンプレートの ## 内容 / ## 成果物 / ## 経過 を基本とし、## 経過 を必ず最後のLV2見出しにする」「補足のLV2節(後続タスク候補・タダシへの確認事項・補足など)を足すときは成果物と経過の間に置く」\n  補足: 経過欄の中の ### 小見出しは従来どおり可"
    fi

    if [ -n "$errors" ]; then
        printf 'Vaultノートlint: %s\n%b\n' "$display_path" "$errors" >&2
        return 2
    fi
}

TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/parliament-task-lint.XXXXXX") || fail '一時領域を作成できません。'
trap 'rm -rf -- "$TMP_ROOT"' EXIT

materialize_claude() {
    local tool_name=$1
    local raw_path
    local absolute
    local candidate=$TMP_ROOT/candidate.md
    local lint_task_frontmatter=0

    raw_path=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.tool_input.file_path // empty')
    [ -n "$raw_path" ] || exit 0
    absolute=$(resolve_tool_path "$raw_path") || fail "対象パス ${raw_path} を解決できません。"
    is_linted_note_path "$absolute" || exit 0
    if is_task_path "$absolute"; then
        lint_task_frontmatter=1
    fi

    if [ "$tool_name" = Write ]; then
        printf '%s\n' "$HOOK_INPUT" | jq -j '.tool_input.content // ""' >"$candidate"
    else
        [ -f "$absolute" ] || fail "Edit対象 ${absolute} が見つかりません。"
        if ! jq -j -n --rawfile current "$absolute" --argjson input "$HOOK_INPUT" '
                ($input.tool_input.old_string // "") as $old
                | ($input.tool_input.new_string // "") as $new
                | ($input.tool_input.replace_all // false) as $replace_all
                | if ($old | length) == 0 then error("old_string is empty")
                else
                    if ($current | contains($old) | not) then error("old_string not found")
                    elif $replace_all then $current | split($old) | join($new)
                    else ($current | index($old)) as $i
                        | $current[0:$i] + $new + $current[$i + ($old | length):]
                    end
                end
            ' >"$candidate" 2>/dev/null; then
            fail "Edit後の候補 ${absolute} を再現できません。"
        fi
    fi
    lint_file "$candidate" "$absolute" "$lint_task_frontmatter"
}

patch_paths() {
    printf '%s\n' "$1" | sed -nE \
        -e 's/^\*\*\* (Add|Update|Delete) File: (.*)$/\2/p' \
        -e 's/^\*\*\* Move to: (.*)$/\1/p'
}

materialize_codex() {
    local patch_command
    local raw_path
    local absolute
    local mirrored
    local rewritten=$TMP_ROOT/patch.txt
    local touched=0
    local lint_task_frontmatter
    local apply_patch_bin=${PARLIAMENT_APPLY_PATCH_BIN:-}

    patch_command=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.tool_input.command // empty')
    [ -n "$patch_command" ] || exit 0

    while IFS= read -r raw_path; do
        [ -n "$raw_path" ] || continue
        absolute=$(resolve_tool_path "$raw_path") || fail "patch対象 ${raw_path} を解決できません。"
        if is_linted_note_path "$absolute"; then
            touched=1
        fi
    done < <(patch_paths "$patch_command")
    [ "$touched" -eq 1 ] || exit 0

    if [ -z "$apply_patch_bin" ]; then
        apply_patch_bin=$(command -v apply_patch || true)
    fi
    [ -n "$apply_patch_bin" ] && [ -x "$apply_patch_bin" ] || \
        fail 'Codexのapply_patch実行ファイルが見つからず、変更後候補を安全に再現できません。'

    while IFS= read -r raw_path; do
        [ -n "$raw_path" ] || continue
        absolute=$(resolve_tool_path "$raw_path") || fail "patch対象 ${raw_path} を解決できません。"
        mirrored=$TMP_ROOT/mirror$absolute
        mkdir -p -- "$(dirname -- "$mirrored")" || fail '一時領域を準備できません。'
        if [ -f "$absolute" ]; then
            cp -p -- "$absolute" "$mirrored" || fail "${absolute} を一時領域へ複製できません。"
        fi
    done < <(patch_paths "$patch_command" | awk 'NF && !seen[$0]++')

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            '*** Add File: '*|'*** Update File: '*|'*** Delete File: '*)
                prefix=${line%% File: *}' File: '
                raw_path=${line#* File: }
                absolute=$(resolve_tool_path "$raw_path") || fail "patch対象 ${raw_path} を解決できません。"
                printf '%s%s\n' "$prefix" "mirror$absolute"
                ;;
            '*** Move to: '*)
                raw_path=${line#'*** Move to: '}
                absolute=$(resolve_tool_path "$raw_path") || fail "patch対象 ${raw_path} を解決できません。"
                printf '%s%s\n' '*** Move to: ' "mirror$absolute"
                ;;
            *) printf '%s\n' "$line" ;;
        esac
    done <<<"$patch_command" >"$rewritten"

    if ! (cd -- "$TMP_ROOT" && "$apply_patch_bin" <"$rewritten" >/dev/null); then
        fail 'apply_patch後の候補を一時領域で再現できません。'
    fi

    while IFS= read -r raw_path; do
        [ -n "$raw_path" ] || continue
        absolute=$(resolve_tool_path "$raw_path") || fail "patch対象 ${raw_path} を解決できません。"
        is_linted_note_path "$absolute" || continue
        mirrored=$TMP_ROOT/mirror$absolute
        [ -f "$mirrored" ] || continue
        lint_task_frontmatter=0
        if is_task_path "$absolute"; then
            lint_task_frontmatter=1
        fi
        lint_file "$mirrored" "$absolute" "$lint_task_frontmatter" || return 2
    done < <(patch_paths "$patch_command" | awk 'NF && !seen[$0]++')
}

TOOL_NAME=$(printf '%s\n' "$HOOK_INPUT" | jq -r '.tool_name // empty')
RESULT=0
case "$TOOL_NAME" in
    Edit|Write) materialize_claude "$TOOL_NAME" || RESULT=$? ;;
    apply_patch) materialize_codex || RESULT=$? ;;
esac

exit "$RESULT"
