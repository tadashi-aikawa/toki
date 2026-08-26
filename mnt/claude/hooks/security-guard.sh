#!/usr/bin/env bash
# PreToolUse hook: 秘密情報の参照・送信と危険コマンドをブロックする
#
# 入力: stdin にツール呼び出しのJSON (tool_name / tool_input)
# 出力: exit 0 = 許可(通常の権限フローへ), exit 2 = ブロック(stderrがClaudeへのフィードバック)
#
# permissions.deny(プレフィックス一致)では防げない `cat .env` や
# `cd x && cat ~/.ssh/id_rsa` のような読み出しを補完する多層防御の一部。
# 正規表現ベースのため、base64難読化・eval・文字列分割などの意図的なバイパスは
# 完全には防げない(事故と素朴な攻撃の防止が目的)。強制境界が必要な場合は
# Claude Codeネイティブサンドボックス(filesystem/network/credentials)を併用すること。
set -u

block() {
  echo "Blocked by security-guard hook: $1" >&2
  echo "この操作は許可されていません。必要な場合はタダシに自分で実行してもらってください。" >&2
  exit 2
}

# fail-closed: jq不在・不正JSONは許可せずブロックする
command -v jq >/dev/null 2>&1 || block "jq が見つからないため検査できません"
INPUT=$(cat)
TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) ||
  block "ツール入力のJSONを解析できません"

# --- 秘密情報パス(参照・書き込み・検索すべて禁止) ---
# 戻り値 0 = 秘密パスに該当。相対パス(.ssh/config等)も字面で判定する
is_secret_path() {
  local p="$1"
  p="${p/#\~/$HOME}"
  p="${p//\$\{HOME\}/$HOME}"
  p="${p//\$HOME/$HOME}"
  # glob表記(**/.env* 等)は判定用にワイルドカードを除去して素のパス相当にする
  p="${p//\*/}"
  p="${p//\?/}"

  # .env系(.env.example等の雛形は除外)
  if printf '%s' "$p" | grep -qE '(^|/)\.env(\.[A-Za-z0-9_.-]+)?$' &&
     ! printf '%s' "$p" | grep -qE '\.env\.(example|sample|template|dist)$'; then
    return 0
  fi

  # 認証情報ディレクトリ・ファイル(どの階層にあっても字面で弾く)
  if printf '%s' "$p" | grep -qE \
    '(^|/)\.(ssh|aws|gnupg)(/|$)|(^|/)\.netrc$|(^|/)\.docker/config\.json$|(^|/)\.config/gh(/|$)'; then
    return 0
  fi

  # 秘密鍵ファイル
  if printf '%s' "$p" | grep -qE '(^|/)(id_rsa|id_ed25519|id_ecdsa)[^/]*$|\.pem$'; then
    return 0
  fi

  case "$p" in
    "$HOME/work/secret"|"$HOME/work/secret/"*) return 0 ;;
  esac

  # Minervaの_Privates(Daily Notes/配下のみ許可。明示指示があっても不可のルール)
  # ..による例外脱出(Daily Notes/../秘匿ファイル)は正規化せず一律ブロック
  case "$p" in
    *_Privates*..*|*..*_Privates*) return 0 ;;
    *"_Privates/Daily Notes/"*) ;; # 許可
    *_Privates*) return 0 ;;
  esac

  return 1
}

# --- パスを対象とするツール (Read / Edit / Write / Grep / Glob / NotebookEdit) ---
case "$TOOL_NAME" in
  Read|Edit|Write|Grep|Glob|NotebookEdit)
    # file_path等に加え、Grepのglob・Globのpattern(実質パス)も検査する
    JQ_FIELDS='[.file_path?, .notebook_path?, .path?, .glob?]'
    [ "$TOOL_NAME" = "Glob" ] && JQ_FIELDS='[.path?, .pattern?]'
    while IFS= read -r target; do
      [ -n "$target" ] && is_secret_path "$target" &&
        block "秘密情報パスへのアクセス: $target"
    done < <(printf '%s' "$INPUT" |
      jq -r ".tool_input | $JQ_FIELDS | map(select(. != null and . != \"\")) | .[]" 2>/dev/null)
    exit 0
    ;;
  Bash) ;; # 下で検査
  *) exit 0 ;;
esac

# --- Bashコマンドの検査 ---
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) ||
  block "ツール入力のJSONを解析できません"
[ -z "$CMD" ] && exit 0

# 1. 秘密情報パスへの言及(cat/cp/base64/curl等、手段を問わずブロック)
HOME_RE='(~|\$\{?HOME\}?|/Users/[^/ ]+)'
SECRET_PATH_RE='(^|[^A-Za-z0-9_.-])\.env([^A-Za-z0-9]|$)|\.env\.(local|prod[^ ]*|dev[^ ]*|stag[^ ]*)|'"$HOME_RE"'/\.(ssh|aws|gnupg|netrc|docker/config\.json|config/gh)|(^|[ "'"'"'])\.(ssh|aws|gnupg)/|'"$HOME_RE"'/work/secret|_Privates|(^|/)(id_rsa|id_ed25519|id_ecdsa)'
if printf '%s' "$CMD" | grep -qE "$SECRET_PATH_RE"; then
  # ..を含む_Privatesパスは例外(Daily Notes)脱出の恐れがあるため一律ブロック
  if printf '%s' "$CMD" | grep -q '_Privates' && printf '%s' "$CMD" | grep -q '\.\.'; then
    block "_Privatesと..の組み合わせは許可されません"
  fi
  # 雛形ファイル(トークン末尾のみ)と _Privates/Daily Notes/ だけは許す
  STRIPPED=$(printf '%s' "$CMD" |
    sed -E 's/\.env\.(example|sample|template|dist)(["'"'"' ]|$)/\2/g; s#_Privates/Daily Notes/##g')
  if printf '%s' "$STRIPPED" | grep -qE "$SECRET_PATH_RE"; then
    block "コマンドが秘密情報パスに触れています"
  fi
fi

# 2. 破壊的コマンド
# rm: サブコマンドごとに分割し、recursive+force なら全対象が/tmp配下であることを要求
while IFS= read -r seg; do
  printf '%s' "$seg" | grep -qE '(^|\s)(command\s+)?(/usr/bin/|/bin/)?rm(\s|$)' || continue
  has_r=0; has_f=0; bad_target=""
  seen_rm=0; opts_done=0
  for tok in $seg; do
    if [ "$seen_rm" -eq 0 ]; then
      case "$tok" in rm|/bin/rm|/usr/bin/rm) seen_rm=1 ;; esac
      continue
    fi
    if [ "$opts_done" -eq 0 ]; then
      case "$tok" in
        --) opts_done=1; continue ;;
        --recursive) has_r=1; continue ;;
        --force) has_f=1; continue ;;
        --*) continue ;;
        -*)
          case "$tok" in *r*|*R*) has_r=1 ;; esac
          case "$tok" in *f*) has_f=1 ;; esac
          continue ;;
      esac
    fi
    # ここからは削除対象。/tmp・/private/tmp 配下の素直なパスだけ許す
    t="${tok#[\"\']}"; t="${t%[\"\']}"
    case "$t" in
      /tmp/*|/private/tmp/*)
        case "$t" in *..*) bad_target="$t" ;; esac ;;
      *) bad_target="$t" ;;
    esac
  done
  if [ "$has_r" -eq 1 ] && [ "$has_f" -eq 1 ] && [ -n "$bad_target" ]; then
    block "rm -rf 系の破壊的削除 (対象: $bad_target)"
  fi
done < <(printf '%s\n' "$CMD" | tr ';|&' '\n')

GIT_OPTS='(-[A-Za-z]\s+\S+\s+|--\S+\s+)*' # -C <dir> や --git-dir=<x> を挟んだ呼び出しも検出
printf '%s' "$CMD" | grep -qE "git\s+${GIT_OPTS}push\b" && block "git push はタダシの確認が必要"
printf '%s' "$CMD" | grep -qE "git\s+${GIT_OPTS}reset\s+--hard" && block "git reset --hard は変更を失う操作"
printf '%s' "$CMD" | grep -qE "git\s+${GIT_OPTS}clean\s+(-[A-Za-z]*f|--force)" && block "git clean -f は未追跡ファイルを失う操作"
printf '%s' "$CMD" | grep -qE 'git\s+-c\s+alias\.' && block "gitインラインエイリアス経由の実行"
printf '%s' "$CMD" | grep -qE '(^|\s)(mkfs|diskutil\s+erase|dd\s+.*of=/dev/)' && block "ディスク破壊系コマンド"

# 3. 外部送信・リモートコード実行
printf '%s' "$CMD" | grep -qE '\|\s*(env\s+)?(ba|z|da)?sh\b' && block "パイプ経由のシェル実行"
printf '%s' "$CMD" | grep -qE '\|\s*(curl|wget|nc|ncat)\b' && block "パイプ経由の外部送信"
# curl/wget のデータ送信。ただし宛先がすべてローカルホストなら外部へ出ないので許す
# (秘密情報の同梱は上の「1. 秘密情報パスへの言及」が別途止める)
is_localhost_only() {
  local seg="$1" tok host h found=0
  set -f # トークン中の * によるファイル名展開を止める
  for tok in $seg; do
    tok="${tok#[\"\']}"
    tok="${tok%[\"\']}"
    case "$tok" in
      -*) continue ;; # オプションは宛先ではない(値が別トークンのものは次周で見る)
      *://*) host="${tok#*://}" ;;
      localhost|localhost/*|127.0.0.1|127.0.0.1/*) host="$tok" ;;
      *:[0-9]*)
        # スキーム省略 (localhost:8080/foo)。ホスト名に使えない文字を含むトークンは
        # 送信ボディ ({"a":1} 等) なので宛先とみなさない
        h="${tok%%[/?#]*}"
        h="${h%%:*}"
        case "$h" in
          '' | *[!A-Za-z0-9.-]*) continue ;;
        esac
        host="$tok"
        ;;
      *) continue ;;
    esac
    host="${host%%[/?#]*}"
    case "$host" in
      \[*\]*) host="${host%%\]*}]" ;; # [::1]:8080 → [::1]
      *) host="${host%%:*}" ;;
    esac
    # userinfo付き (localhost@evil.com) や localhost.evil.com は下のcaseに一致せず弾かれる
    case "$host" in
      localhost | 127.0.0.1 | 0.0.0.0 | '[::1]' | ::1) found=1 ;;
      *) set +f; return 1 ;;
    esac
  done
  set +f
  [ "$found" -eq 1 ]
}

while IFS= read -r seg; do
  printf '%s' "$seg" | grep -qE '(curl|wget)\s.*(-d\b|--data|--data-[a-z]+|--json|-F\b|--form|--upload-file|-T\s|--post-data|--post-file|--body-data|--body-file|--method)' || continue
  is_localhost_only "$seg" && continue
  block "curl/wget によるデータ送信 (ローカルホスト宛のみ許可)"
done < <(printf '%s\n' "$CMD" | tr ';|&' '\n')
printf '%s' "$CMD" | grep -qE '(^|\s)(scp|sftp)\s' && block "scp/sftp による転送はタダシの確認が必要"
printf '%s' "$CMD" | grep -qE '(^|\s)rsync\s[^;|&]*[^ ]+:' && block "rsync によるリモート転送"
printf '%s' "$CMD" | grep -qE '(^|\s)ssh\s' && block "ssh によるリモート実行はタダシの確認が必要"
printf '%s' "$CMD" | grep -qE '(^|\s)(nc|ncat|telnet)\s' && block "生ソケット通信"
printf '%s' "$CMD" | grep -qE '/dev/tcp/' && block "/dev/tcp による外部通信"
printf '%s' "$CMD" | grep -qE 'gh\s+gist\s+create' && block "gh gist create は外部公開"
printf '%s' "$CMD" | grep -qE 'gh\s+api\s[^;|&]*(-X\s|--method|--input|-f\s|-F\s|--field|--raw-field)' && block "gh api の書き込み操作はタダシの確認が必要"
printf '%s' "$CMD" | grep -qE '(^|\s)(printenv|env)\s*($|\|)' && block "環境変数の一括ダンプ(秘密情報を含む可能性)"

exit 0
