return {
  "sindrets/diffview.nvim",
  cmd = "DiffviewOpen",
  opts = {
    hooks = {
      diff_buf_win_enter = function()
        vim.opt_local.foldenable = false
      end,
    },
  },
}
