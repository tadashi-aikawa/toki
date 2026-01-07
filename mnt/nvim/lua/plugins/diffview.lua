return {
  "sindrets/diffview.nvim",
  cmd = "DiffviewOpen",
  keys = {
    { "<Space>v", ":DiffviewOpen<CR>", silent = true },
    { "<Space>f", ":DiffviewFileHistory %<CR>", silent = true },
  },
  opts = {
    hooks = {
      diff_buf_win_enter = function()
        vim.opt_local.foldenable = false
      end,
    },
  },
}
