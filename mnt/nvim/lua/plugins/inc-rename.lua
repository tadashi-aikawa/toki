return {
  "smjonas/inc-rename.nvim",
  config = function()
    require("inc_rename").setup()
    vim.keymap.set("n", "<space>2", function()
      return ":IncRename " .. vim.fn.expand("<cword>")
    end, { expr = true, desc = "Incremental rename" })
  end,
}
