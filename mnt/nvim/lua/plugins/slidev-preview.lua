return {
  -- 'tadashi-aikawa/slidev-preview.nvim',
  dir = "~/git/github.com/tadashi-aikawa/slidev-preview.nvim",
  cmd = { "SlidevPreviewStart", "SlidevPreviewStartAndOpen" },
  opts = {},
  keys = {
    { ",sj", "<cmd>SlidevPreviewClicksIncrement<cr>", desc = "Slidev clicks +1" },
    { ",sk", "<cmd>SlidevPreviewClicksDecrement<cr>", desc = "Slidev clicks -1" },
  },
}
