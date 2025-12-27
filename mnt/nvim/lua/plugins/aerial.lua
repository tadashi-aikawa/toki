return {
  "stevearc/aerial.nvim",
  opts = {
    backends = { "lsp", "treesitter", "markdown", "asciidoc", "man" },
    layout = {
      min_width = 50,
    },
    keymaps = {
      ["<ESC>"] = "actions.close",
      ["o"] = "actions.scroll",
    },
    highlight_on_hover = true,
    close_on_select = true,

    -- ネストは1階層まで
    on_first_symbols = function(bufnr)
      require("aerial").tree_set_collapse_level(bufnr, 1)
    end,
    -- tree_set_collapse_level が連動してしまうので必要
    link_tree_to_folds = false,

    -- 表示は上の方に
    post_jump_cmd = "normal! zt",
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  keys = {
    { "<D-o>", ":AerialToggle<CR>", silent = true },
  },
  init = function()
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        vim.api.nvim_set_hl(0, "AerialLine", { fg = "#efef33", bg = "#565612", bold = true })
      end,
    })
  end,
}
