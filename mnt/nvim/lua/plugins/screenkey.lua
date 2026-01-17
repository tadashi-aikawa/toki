return {
  "NStefan002/screenkey.nvim",
  cmd = { "Screenkey" },
  -- INFO: 自動起動したい場合
  -- lazy = false,
  opts = {
    group_mappings = true,
    keys = {
      ["<Esc>"] = "󱊷 ",
      ["<CR>"] = "⏎",
      ["<Space>"] = "␣",
      ["<BS>"] = "⌫",
      ["<Up>"] = "↑",
      ["<Down>"] = "↓",
      ["<Left>"] = "←",
      ["<Right>"] = "→",
      ["<Tab>"] = " ",
      ["<S-Tab>"] = " ",
    },
    win_opts = {
      width = 60,
      height = 1,
      border = "single",
      title = "Keys",
    },
    hl_groups = {
      ["screenkey.hl.key"] = { link = "Visual" },
      ["screenkey.hl.map"] = { link = "@markup.heading.1.markdown" },
    },
  },
  -- INFO: 自動起動したい場合
  -- config = function(_, opts)
  --   require("screenkey").setup(opts)
  --   require("screenkey").toggle()
  -- end,
}
