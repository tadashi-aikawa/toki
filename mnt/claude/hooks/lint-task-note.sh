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
    local progress_errors
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
            '.status as $status | ($status | type) == "string" and (["todo", "doing", "waiting", "pending", "done"] | index($status)) != null' \
            >/dev/null; then
            errors="${errors}\n- 違反: status「${status:-<文字列ではない値>}」は値域外です。\n  正しいルール（引用）: 「status の値域は todo / doing / waiting / pending / done」"
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
    fi

    progress_errors=$(awk '
        $0 == "## 経過" {
            in_progress = 1
            next
        }
        # 検査対象は「## 経過」直下のトップレベル項目のみ。
        # 経過欄に ### 小見出しを立てて設計メモ等を書くノートがあるため、
        # 見出しは深さを問わず経過欄の終端として扱う(ATX記法=# の後に空白)。
        in_progress && /^#+ / {
            in_progress = 0
        }
        in_progress && /^- / && $0 !~ /^- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T([0-9][0-9]:[0-9][0-9]|\?\?:\?\?)( |$)/ {
            print NR ":" $0
        }
    ' "$candidate")
    if [ -n "$progress_errors" ]; then
        errors="${errors}\n- 違反: 経過欄のトップレベル項目がISO日時で始まっていません。\n${progress_errors}\n  正しいルール（引用）: 「経過欄のトップレベル項目は YYYY-MM-DDTHH:mm または YYYY-MM-DDT??:?? を先頭に書く。日付のみと空白区切りは禁止」"
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
