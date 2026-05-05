-- ╭─────────────────────────────────────────────────────────╮
-- │                          全体                           │
-- ╰─────────────────────────────────────────────────────────╯

-- クリップボードとヤンクの同期
vim.opt.clipboard = "unnamedplus"
-- swapfileを作成しない (default: true)
vim.opt.swapfile = false

-- ╭─────────────────────────────────────────────────────────╮
-- │                        エディタ                         │
-- ╰─────────────────────────────────────────────────────────╯

-- 行番号の表示 (default: false)
vim.opt.number = true
-- 文字コード自動判別 (default: "ucs-bom,utf-8,default,latin1")
vim.opt.fileencodings = "utf-8,sjis"
-- 改行コード自動判別 (default: "unix,dos")
vim.opt.fileformats = "unix,dos,mac"
-- 行末の1文字先までカーソルを移動できるように (default: 未設定)
vim.opt.virtualedit = "onemore"
-- スクロールした時 常に下に表示するバッファ行の数 (default: 0)
vim.opt.scrolloff = 5
-- 垂直方向の分割は左側ではなく右側にするか (default: false)
vim.opt.splitright = true
-- 水平方向の分割は上側ではなく下側にするか (default: false)
vim.opt.splitbelow = true
-- ファイルを開いたときに、前回カーソルのあった位置に移動する
vim.cmd([[
  augroup vimrcEx
    au BufRead * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g`\"" | endif
  augroup END
]])

-- ╭─────────────────────────────────────────────────────────╮
-- │                  インデント・タブ文字                   │
-- ╰─────────────────────────────────────────────────────────╯

-- タブ入力の代わりにスペースを挿入するか (default: false)
vim.opt.expandtab = true
-- タブ文字の見た目を何文字分にするか (default: 8)
vim.opt.tabstop = 2
-- インデントを何文字分にするか (default: 8)
vim.opt.shiftwidth = 0 -- 0はtabstopと同じ値を使用

-- ╭─────────────────────────────────────────────────────────╮
-- │                       検索・置換                        │
-- ╰─────────────────────────────────────────────────────────╯

-- 検索文字列が小文字の場合は大文字小文字を区別なく検索する (default: false)
vim.opt.ignorecase = true
-- 検索時に大文字を含んでいたら大/小を区別 (default: false)
vim.opt.smartcase = true -- ignorecase = true と組み合わせて使用

-- 置換時のインクリメンタルプレビューを分割ウィンドウに表示 (default: nosplit)
vim.opt.inccommand = "split"

-- ╭─────────────────────────────────────────────────────────╮
-- │               デザイン/スタイル/強調表示                │
-- ╰─────────────────────────────────────────────────────────╯

-- floating windowの罫線スタイル (default: 未設定)
vim.o.winborder = "rounded"
-- カーソル行強化 (default: false)
vim.opt.cursorline = true
-- ステータスバーの表示設定 (default: 2)
vim.opt.laststatus = 3 -- ステータスバーは分割しない
-- suggestionsの上限 (default: 0)
vim.opt.pumheight = 10
-- v0.12.0で追加されたハイライト機能は使わない. nvim-highlight-colorsと競合するし代用はまだできないため
vim.lsp.document_color.enable(false)
