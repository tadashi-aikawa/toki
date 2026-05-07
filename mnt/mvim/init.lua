-- ╭─────────────────────────────────────────────────────────╮
-- │                          全体                           │
-- ╰─────────────────────────────────────────────────────────╯
-- クリップボードとヤンクの同期
vim.opt.clipboard = "unnamedplus"
-- swapfileを作成しない (default: true)
vim.opt.swapfile = false
-- UIモードを有効化
require("vim._core.ui2").enable({})

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

-- ╭─────────────────────────────────────────────────────────╮
-- │               デザイン/スタイル/強調表示                │
-- ╰─────────────────────────────────────────────────────────╯

-- テーマ ~ 🌟 tokyonight 🌙
vim.pack.add({ "https://github.com/folke/tokyonight.nvim" })
vim.cmd("colorscheme tokyonight")

-- floating windowの罫線スタイル (default: 未設定)
vim.o.winborder = "rounded"
-- カーソル行強化 (default: false)
vim.opt.cursorline = true
-- ステータスバーの表示設定 (default: 2)
vim.opt.laststatus = 3 -- ステータスバーは分割しない
-- Yankの範囲をハイライト
vim.api.nvim_set_hl(0, "YankHighlight", { reverse = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({ higroup = "YankHighlight", timeout = 200 })
	end,
})

-- ╭─────────────────────────────────────────────────────────╮
-- │                   オートコンプリート                    │
-- ╰─────────────────────────────────────────────────────────╯

vim.pack.add({
	"https://github.com/saghen/blink.lib",
	"https://github.com/saghen/blink.cmp",
})
local cmp = require("blink.cmp")
cmp.build():wait(60000)
cmp.setup({
	keymap = {
		-- Enterで候補を挿入する
		preset = "enter",
	},
	completion = {
		list = {
			selection = {
				-- 選択している項目を自動で挿入するか (default: true)
				auto_insert = false,
			},
		},
	},
})

-- ╭─────────────────────────────────────────────────────────╮
-- │                           LSP                           │
-- ╰─────────────────────────────────────────────────────────╯

-- nvim-lspconfig
vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" })
vim.lsp.enable({
	-- 別途インストールも必要: mise use -g npm:basedpyright
	"basedpyright",
	-- 別途インストールも必要: mise use -g lua-language-server
	"lua_ls",
})

-- ╭─────────────────────────────────────────────────────────╮
-- │                         Picker                          │
-- ╰─────────────────────────────────────────────────────────╯

-- snack.nvim
vim.pack.add({ "https://github.com/folke/snacks.nvim" })
local snacks = require("snacks")
snacks.setup({
	picker = {
		main = { current = true },
		sources = {
			git_status = { layout = { layout = { width = 180 } } },
			lines = {
				sort = { fields = { "idx", "score:desc" } },
				matcher = { fuzzy = false },
				---@diagnostic disable-next-line: assign-type-mismatch 普通にプレビュー
				layout = { preview = true },
			},
			recent = {
				sort = { fields = { "idx", "score:desc" } },
				matcher = { fuzzy = false },
				hidden = true,
			},
			files = {
				hidden = true,
			},
		},
		win = {
			input = {
				keys = {
					-- NORMALモードは基本的に使わない
					["<esc>"] = { "close", mode = { "i", "n" } },
				},
			},
		},
		layout = {
			cycle = true,
			preset = "vertical",
			layout = {
				backdrop = false,
				width = 120,
				min_width = 80,
				height = 0.9,
				min_height = 30,
				box = "vertical",
				-- min_heightより小さいときは枠線を出すと先頭の候補が消えるので調整
				border = vim.o.lines <= 32 and "none" or "rounded",
				title = "{title} {live} {flags}",
				title_pos = "center",
				{ win = "preview", title = "{preview}", height = 0.5, border = "bottom" },
				{ win = "input", height = 1, border = "bottom" },
				{ win = "list", border = "none" },
			},
		},
		formatters = {
			file = {
				filename_first = true,
				truncate = 100,
			},
		},
	},
})
-- ファイル名で検索
vim.keymap.set({ "n", "i" }, "<C-j>f", function()
	Snacks.picker.files()
end, { desc = "Find Files" })
-- 最近開いたファイルの検索
vim.keymap.set({ "n", "i" }, "<C-j>r", function()
	Snacks.picker.recent()
end, { desc = "Grep" })
-- Grep
vim.keymap.set({ "n", "i" }, "<C-j>g", function()
	Snacks.picker.grep()
end, { desc = "Grep" })
-- ファイル内検索
vim.keymap.set({ "n", "i" }, "<C-j>l", function()
	Snacks.picker.lines()
end, { desc = "Line search in current file" })
-- Gitで変更があったファイルの検索
vim.keymap.set({ "n", "i" }, "<C-j>s", function()
	Snacks.picker.git_status()
end, { desc = "Git status search" })
