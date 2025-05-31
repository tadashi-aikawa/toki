vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "**/vscode/*.json", "**/.vscode/*.json" },
  callback = function()
    vim.bo.filetype = "jsonc"
  end,
})
