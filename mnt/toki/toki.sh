set -eu
# ドットファイルをtemplateのコピー対象に含めるため (*では含まれないので)
shopt -s dotglob

export PATH=$PATH:/opt/homebrew/bin/

_PATH=$(readlink -f "${BASH_SOURCE:-$0}")
DIR_PATH=$(dirname "$_PATH")
TEMPLATE_DIR="${DIR_PATH}/template"
SCRIPT_DIR="${DIR_PATH}/script"
WEBP_SCREEN_SHOT_DIR=$HOME/Documents/Pictures/screenshots/webp
MOV_DIR=$HOME/Documents/Pictures/screenshots/mov
MP4_DIR=$HOME/Documents/Pictures/screenshots/mp4

function show_usage() {
  echo "
Usages:
  toki <Target> <path>:         Sandbox環境を作成します

  toki webp:                    入力ファイル/クリップボード画像(png)をwebpに変換します
  toki mp4:                     MOV保存場所の最新動画ファイルをmp4に変換します
  toki vault <base_vault_dir>:  ObsidianのVault初期設定をします
  toki backup:                  workをbackupします
  toki claude [<jsonc file>]:   Claude Codeとやりとりした会話ログをMinervaのフキダシ形式に整形して取得します

  toki -h|--help|help: ヘルプを表示します

╭──────────────────────────────────────────────────────────╮
│                    Available targets                     │
╰──────────────────────────────────────────────────────────╯

| Target      | Language | Runtime    | PM    | Framework / Lib     | Linter        | Formatter |
| ----------- | -------- | ---------- | ----- | ------------------- | ------------- | --------- |
| node        | TS       | Node       | npm   | -                   | -             | prettierd |
| pnpm        | TS       | tsx(Node)  | pnpm  | -                   | Biome         | Biome     |
| deno        | TS       | Deno       | Deno  | -                   | Deno          | Deno      |
| bun         | TS       | Bun        | Bun   | -                   | Biome         | Biome     |
| jest        | TS       | Node       | pnpm  | Jest                | Biome         | Biome     |
| vue         | TS or JS | Bun        | Bun   | Vue                 | ?(ESLint)     | prettierd |
| nuxt        | TS       | Bun        | Bun   | Nuxt4               | -             | prettierd |
| nuxt3       | TS       | pnpm       | pnpm  | Nuxt3               | -             | prettierd |
| tailwind3   | TS       | Bun        | Bun   | Vue + TailwindCSS3  | -             | prettierd |
| tailwind    | TS       | Bun        | Bun   | Vue + TailwindCSS   | -             | prettierd |
| playwright  | TS       | Node       | pnpm  | -                   | -             | Biome     |
| html        | HTML     | Bun        | Bun   | TailwindCSS         | -             | -         |
| go          | Go       | -          | Go    | air                 | golangci-lint | -         |
| go-sqlx     | Go       | -          | Go    | sqlx + mysql + air  | golangci-lint | -         |
| rust        | Rust     | -          | Cargo | -                   | -             | -         |
| python      | Python   | Virtualenv | Pip   | -                   | ruff          | ruff      |
| uv          | Python   | uv         | uv    | -                   | ruff          | ruff      |
| django4-drf | Python   | uv         | uv    | Django4.2 / drf     | ruff          | ruff      |
| nvim        | Lua      | Lua        |       | nvim                | -             | -         |
| nvimapp     | Lua      | Neovim     | lazy  | -                   | -             | -         |
| bash        | Bash     | Bash       |       | -                   | -             | -         |
| mysql       | TS       | Deno       | Deno  | MySQL + deno_mysql  | Deno          | Deno      |
| mkdocs      | Python   | uv         | uv    | Material for MkDocs |               |           |
  "
}

command="${1:-}"

if [[ $command =~ ^(-h|--help|help)?$ ]]; then
  echo "『いったはずだ あなたのすべてをめざしたと!!』"
  show_usage
  exit 0
fi

shift

function print_with_width() {
  text="$1"
  width=$2

  text_length=$(echo -n "$text" | awk '{print length()}')
  left_padding=$(((width - text_length) / 2))
  right_padding=$((width - text_length - left_padding))

  printf "%${left_padding}s%s%${right_padding}s" "" "$text" ""
}

function section() {
  echo ""
  echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  printf "┃ "
  print_with_width "$1" 40
  printf " ┃\n"
  echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
}

function edit_biome_json() {
  # 削除しないように交互に上書きする
  jq '.linter.rules.correctness.noUnusedImports |= { level: "warn", fix: "safe" }' <biome.json >biome.json.tmp
  jq '.formatter.indentStyle|="space"' <biome.json.tmp >biome.json
}

# ╭──────────────────────────────────────────────────────────╮
# │                           bun                            │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "bun" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "$path"
  cd "$path"
  git init
  bun init . -y
  bun add -d @biomejs/biome
  bun biome init
  edit_biome_json

  cp -r "${TEMPLATE_DIR}"/bun/* .

  echo "
🚀 Try

$ cd ${path}
$ bun --hot .
"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                           node                           │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "node" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "$path"
  cd "$path"
  git init
  npm init -y
  npm i -before="$(date -v -7d)" -D typescript @fsouza/prettierd prettier-plugin-organize-imports @tsconfig/recommended

  npm pkg set scripts.dev="tsc -w"
  npm pkg set scripts.start="node --watch *.js"

  cp -r "${TEMPLATE_DIR}"/node/* .

  echo "
🚀 Try

$ cd ${path}

$ npm run dev
and
$ npm run start
"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                           pnpm                           │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "pnpm" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "$path"
  cd "$path"
  git init
  pnpm init
  pnpm config set --location=project minimumReleaseAge 10080
  pnpm add -D typescript tsx @types/node @tsconfig/recommended @biomejs/biome

  pnpm exec biome init
  edit_biome_json

  pnpm pkg set scripts.dev="tsx watch ./index.ts"
  pnpm pkg set scripts.check="tsc --noEmit --watch"

  cp -r "${TEMPLATE_DIR}"/pnpm/* .

  echo "
🚀 Try

$ cd ${path}

$ pnpm dev
and
$ pnpm typecheck
"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                           deno                           │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "deno" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "$path"
  cd "$path"
  git init
  deno init
  sed -i '' 's/"dev":.*/"dev": "deno run -A --watch main.ts"/g' deno.json

  cp -r "${TEMPLATE_DIR}"/deno/* .

  echo "
🚀 Try

$ cd ${path}
$ deno test
"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                           jest                           │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "jest" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "$path"
  cd "$path"
  git init
  pnpm init
  pnpm config set --location=project minimumReleaseAge 10080
  pnpm add -D typescript @tsconfig/recommended @biomejs/biome \
    jest babel-jest @babel/core @babel/preset-env \
    @babel/preset-typescript @jest/globals

  pnpm exec biome init
  edit_biome_json

  pnpm pkg set scripts.test="jest"
  pnpm pkg set scripts.test:watch="jest --watchAll"

  cp -r "${TEMPLATE_DIR}"/jest/* .

  echo "
🚀 Try

$ cd ${path}

$ pnpm test
or
$ pnpm test:watch
"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                            vue                           │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "vue" ]]; then
  path="${1:?'pathは必須です'}"

  bun create vue@latest "${path}"
  cd "$path"

  bun add -D @fsouza/prettierd prettier-plugin-organize-imports

  cp -r "${TEMPLATE_DIR}"/vue/* .

  bun install --frozen-lockfile --ignore-scripts

  echo "
🚀 Try

$ cd ${path}
$ bun dev
"
  exit 0

fi

# ╭──────────────────────────────────────────────────────────╮
# │                           nuxt                           │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "nuxt" ]]; then
  path="${1:?'pathは必須です'}"

  bun x nuxi@latest init "${path}"
  cd "$path"
  bun add --optional typescript
  mkdir pages

  bun add -D @fsouza/prettierd prettier-plugin-organize-imports

  cp -r "${TEMPLATE_DIR}"/nuxt/* .

  echo "
🚀 Try

$ cd ${path}
$ bun dev -o
"
  exit 0

fi

# ╭──────────────────────────────────────────────────────────╮
# │                          nuxt3                           │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "nuxt3" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "${path}" && cd "${path}"
  pnpm config set --location=project minimumReleaseAge 10080
  pnpm create nuxt@latest . -t v3
  pnpm add --optional typescript
  mkdir pages

  pnpm add -D @fsouza/prettierd prettier-plugin-organize-imports

  cp -r "${TEMPLATE_DIR}"/nuxt/* .

  echo "
🚀 Try

$ cd ${path}
$ pnpm dev -o
"
  exit 0

fi

# ╭──────────────────────────────────────────────────────────╮
# │                           html                           │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "html" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "$path"
  cd "$path"
  git init
  cp -r "${TEMPLATE_DIR}"/html/* .

  echo "
🚀 Try

$ cd ${path}
$ bun index.html
"
  exit 0

fi

# ╭──────────────────────────────────────────────────────────╮
# │                         tailwind3                        │
# ╰──────────────────────────────────────────────────────────╯

if [[ $command == "tailwind3" ]]; then
  path="${1:?'pathは必須です'}"

  # https://tailwindcss.tw/docs/guides/vite
  bun create vite "${path}" --template vue-ts
  cd "${path}"
  git init
  bun add --dev tailwindcss@3 postcss autoprefixer
  bun x tailwindcss init -p

  cp -r "${TEMPLATE_DIR}"/tailwind3/* .

  echo "
🚀 Try

$ cd ${path}
$ bun dev
"
  exit 0

fi

# ╭──────────────────────────────────────────────────────────╮
# │                         tailwind                         │
# ╰──────────────────────────────────────────────────────────╯

if [[ $command == "tailwind" ]]; then
  path="${1:?'pathは必須です'}"

  # https://tailwindcss.tw/docs/guides/vite
  echo "n -> n"
  bun create vite "${path}" --template vue-ts
  cd "${path}"
  git init
  bun add tailwindcss @tailwindcss/vite

  cp -r "${TEMPLATE_DIR}"/tailwind/* .

  echo "
🚀 Try

$ cd ${path}
$ bun dev
"
  exit 0

fi

# ╭──────────────────────────────────────────────────────────╮
# │                        playwright                        │
# ╰──────────────────────────────────────────────────────────╯

if [[ $command == "playwright" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "$path" && cd "$path"
  pnpm config set --location=project minimumReleaseAge 10080
  git init
  echo "⏎ -> ⏎ -> ⏎ -> n -> ⏎"

  pnpm create playwright
  pnpm exec playwright install chromium
  rm -rf tests-examples

  pnpm add -D @biomejs/biome
  pnpm exec biome init
  edit_biome_json

  cp -r "${TEMPLATE_DIR}"/playwright/* .

  echo "
🚀 Try

$ cd ${path}
$ pnpm exec playwright test
"
  exit 0

fi

# ╭──────────────────────────────────────────────────────────╮
# │                            go                            │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "go" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "$path"
  cd "$path"
  git init
  go mod init sandbox/"${path}"
  go install github.com/air-verse/air@latest

  cp -r "${TEMPLATE_DIR}"/go/* .

  echo "
🚀 Try

$ cd ${path}
$ air
"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                          go-sqlx                         │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "go-sqlx" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "$path"
  cd "$path"
  git init
  go mod init sandbox/"${path}"
  go install github.com/air-verse/air@latest

  go get github.com/jmoiron/sqlx
  go get github.com/go-sql-driver/mysql

  cp -r "${TEMPLATE_DIR}"/go-sqlx/* .

  echo "
🚀 Try

$ cd ${path}
$ air
"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                           rust                           │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "rust" ]]; then
  path="${1:?'pathは必須です'}"

  cargo new "$path"

  echo "
🚀 Try

$ cd ${path}
$ cargo run
"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                          python                          │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "python" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "$path" && cd "$path"
  git init

  python -m venv .venv
  cp -r "${TEMPLATE_DIR}"/python/* .
  .venv/bin/pip install ruff

  echo "
🚀 Try

$ cd ${path}
$ source .venv/bin/activate
$ mise watch dev
"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                            uv                            │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "uv" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "$path"
  cd "$path"

  git init
  uv init --bare
  uv add --dev ruff

  cp -r "${TEMPLATE_DIR}"/uv/* .

  echo "
🚀 Try

$ cd ${path}
$ mise watch dev
"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                       django4-drf                        │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "django4-drf" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "$path"
  cd "$path"

  git init
  uv init --bare
  uv add django==4.2 djangorestframework
  uv add --dev ruff django-types djangorestframework-types

  cp -r "${TEMPLATE_DIR}"/django4-drf/* .

  echo "💽 Migration."
  uv run python manage.py makemigrations &&
    uv run python manage.py migrate
  echo "💽 Insert to initial records."
  uv run python manage.py shell <init.py

  echo "
🚀 Try

$ cd ${path}
$ v
$ python manage.py runserver
$ curl -s \"localhost:8000/users/\" | jq .
$ curl -s \"localhost:8000/animals/\" | jq .
"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                           nvim                           │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "nvim" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "$path"
  cd "$path"
  git init

  cp -r "${TEMPLATE_DIR}"/nvim/* .

  echo "
🚀 Try

$ cd ${path}
$ mise watch dev
"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                          nvimapp                         │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "nvimapp" ]]; then
  app_name="${1:?'app_nameは必須です'}"
  path="${HOME}/.config/${app_name}"

  mkdir -p "$path"
  cd "$path"
  git init

  cp -r "${TEMPLATE_DIR}"/nvimapp/* .

  echo "
🚀 Try

$ alias svim=\"NVIM_APPNAME=${app_name} nvim\"
$ svim
"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                           bash                           │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "bash" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "$path"
  cd "$path"
  git init

  cp -r "${TEMPLATE_DIR}"/bash/* .

  chmod +x main.sh

  echo "
🚀 Try

$ cd ${path}
$ mise watch dev
"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                          mysql                           │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "mysql" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "$path"
  cd "$path"
  git init
  deno init

  cp -r "${TEMPLATE_DIR}"/mysql/* .

  echo "
🚀 Try

$ cd ${path}
$ docker compose up -d
$ xh -b \"http://localhost:18000?table=types\"
"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                          mkdocs                          │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "mkdocs" ]]; then
  path="${1:?'pathは必須です'}"

  mkdir -p "$path"
  cd "$path"

  git init
  uv init --bare
  uv add \
    mkdocs \
    mkdocs-material \
    git+https://github.com/tadashi-aikawa/mkdocs-obsidian-bridge \
    mkdocs-awesome-nav \
    mkdocs-backlinks-section-plugin \
    mkdocs-git-revision-date-localized-plugin \
    mkdocs-git-authors-plugin \
    mkdocs-glightbox \
    mkdocs-open-in-new-tab \
    mdx_truly_sane_lists

  cp -r "${TEMPLATE_DIR}"/mkdocs/* .

  echo "
🚀 Try

$ cd ${path}

$ uv run mkdocs serve -a localhost:8081 --livereload
"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                           webp                           │
# ╰──────────────────────────────────────────────────────────╯
# Raycastで利用
if [[ $command == "webp" ]]; then
  ts=$(date +"%Y%m%d_%H_%M_%S")
  dst_dir="$WEBP_SCREEN_SHOT_DIR"
  dst="${dst_dir}/${ts}.webp"

  if [ -n "${1-}" ]; then
    magick "${1}" "$dst"
  else
    pngpaste - | magick - "$dst"
  fi

  echo "Created ${dst}"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                            mp4                           │
# ╰──────────────────────────────────────────────────────────╯
# Raycastで利用
if [[ $command == "mp4" ]]; then
  ts=$(date +"%Y%m%d_%H_%M_%S")
  dst_dir="$MP4_DIR"
  dst="${dst_dir}/${ts}.mp4"

  # shellcheck disable=SC2012
  input=$MOV_DIR/$(ls -t "$MOV_DIR" | head -1)
  ffmpeg -i "$input" "$dst"

  echo "Created ${dst}"
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                          vault                           │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "vault" ]]; then
  base_vault_dir="${1:?'base_vault_dirは必須です'}"
  obsidian_config_dir="$base_vault_dir"/.obsidian
  obsidian_plugins_dir="$obsidian_config_dir"/plugins

  mkdir -p _Privates/NOSYNC/
  ln -snf "$base_vault_dir"/_Privates/dict.md ./_Privates/dict.md
  ln -snf "$base_vault_dir"/obsidian.vimrc .

  cd .obsidian
  cp "$obsidian_config_dir"/{app.json,appearance.json,core-plugins.json,hotkeys.json} .

  mkdir -p snippets && cd snippets
  ln -snf "$obsidian_config_dir"/snippets/owl.css .

  cd .. && mkdir -p themes && cd themes
  rm -rf Solarized
  ln -snf "$obsidian_config_dir"/themes/Solarized .

  cd .. && mkdir -p plugins && cd plugins
  mkdir -p carnelian && cd carnelian
  ln -snf "$obsidian_plugins_dir"/carnelian/{config.schema.json,main.js,manifest.json,styles.css} .
  cp "$obsidian_plugins_dir"/carnelian/data.json .
  cd .. && mkdir -p obsidian-another-quick-switcher && cd obsidian-another-quick-switcher
  ln -snf "$obsidian_plugins_dir"/obsidian-another-quick-switcher/{data.json,main.js,manifest.json,styles.css} .
  cd .. && mkdir -p obsidian-vimrc-support && cd obsidian-vimrc-support
  ln -snf "$obsidian_plugins_dir"/obsidian-vimrc-support/{data.json,main.js,manifest.json} .
  cd .. && mkdir -p shukuchi && cd shukuchi
  ln -snf "$obsidian_plugins_dir"/shukuchi/{data.json,main.js,manifest.json,styles.css} .
  cd .. && mkdir -p yank-highlight && cd yank-highlight
  ln -snf "$obsidian_plugins_dir"/yank-highlight/{data.json,main.js,manifest.json,styles.css} .
  cd .. && mkdir -p various-complements && cd various-complements
  ln -snf "$obsidian_plugins_dir"/various-complements/{main.js,manifest.json,styles.css} .
  cp "$obsidian_plugins_dir"/various-complements/data.json .

  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                          backup                          │
# ╰──────────────────────────────────────────────────────────╯
if [[ $command == "backup" ]]; then
  7zz a -p -xr!node_modules -xr!venv -xr!.venv -xr!.git ~/tmp/backup.7z ~/work ~/.ssh ~/Documents/Pictures/AI
  ls -l ~/tmp/backup.7z
  exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │                          claude                          │
# ╰──────────────────────────────────────────────────────────╯
# Claude Codeとやりとりした会話ログをMinervaのフキダシ形式に整形して取得します
if [[ $command == "claude" ]]; then
  eval "${SCRIPT_DIR}/claude-log-to-bubble/main.ts ${1:-}"
  exit $?
fi

echo "『き..きかぬ  きかぬのだ!!』"
show_usage
