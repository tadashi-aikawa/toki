return {
  "nanotee/sqls.nvim",
  ft = "sql",
  config = function()
    vim.keymap.set({ "n", "i" }, "<C-CR>", "<cmd>SqlsExecuteQuery<CR>", { silent = true })
    vim.keymap.set({ "x" }, "<C-CR>", ":'<,'>SqlsExecuteQuery<CR>", { silent = true })
    vim.keymap.set({ "n", "i" }, "g<C-CR>", "<cmd>SqlsExecuteQueryVertical<CR>", { silent = true })
    vim.keymap.set({ "x" }, "g<C-CR>", ":'<,'>SqlsExecuteQueryVertical<CR>", { silent = true })
  end,
}
