return {
  dir = "~/git/github.com/tadashi-aikawa/etoile.nvim",
  name = "etoile.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    -- 画像プレビューを使う場合だけ
    { "folke/snacks.nvim", opts = { image = { enabled = true } } },
  },
  cmd = "Etoile",
  keys = {
    { "<Space>t", "<cmd>Etoile<CR>", desc = "Etoile" },
    { "<Space><Space>t", "<cmd>EtoileCurrent<CR>", desc = "Etoile" },
  },
  ---@class etoile.Config
  ---@diagnostic disable: missing-fields
  opts = {
    keymaps = {
      open_split = "<C-s>",
      open_vsplit = "<C-CR>",
      open_tab_keep = "<C-w>t",
      expand_all = "zo",
      collapse_parent = "zc",
      search_next = "<Leader>m",
      search_prev = "<Leader>.",
    },
    confirm = {
      copy = true,
    },
  },
}
