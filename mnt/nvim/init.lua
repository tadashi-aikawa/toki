-- Lazy.nvimの起動に必要なため先に設定
vim.g.mapleader = ","
vim.g.maplocalleader = ","

require("plugin")
require("base")
require("keymaps")
require("filetype")
require("theme")
require("lsp")
