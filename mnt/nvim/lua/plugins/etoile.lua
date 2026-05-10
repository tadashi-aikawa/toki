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
  },
  opts = {
    keymaps = {
      open_split = "<C-s>",
      open_vsplit = "<C-CR>",
    },
  },
}
