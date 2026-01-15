return {
  "NStefan002/screenkey.nvim",
  cmd = { "Screenkey" },
  -- INFO: 自動起動したい場合
  -- lazy = false,
  opts = {
    compress_after = 5,
    group_mappings = true,
    keys = {
      ["<ESC>"] = "Esc",
      ["<TAB>"] = "Tab",
    },
    win_opts = {
      width = 50,
      height = 1,
      border = "single",
      title = "Keys",
    },
    clear_after = 5,
  },
  -- INFO: 自動起動したい場合
  -- config = function(_, opts)
  --   require("screenkey").setup(opts)
  --   require("screenkey").toggle()
  -- end,
}
