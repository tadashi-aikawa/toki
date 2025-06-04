return {
  version = "2.4.3",
  "shortcuts/no-neck-pain.nvim",
  keys = {
    {
      "<D-n>",
      ":NoNeckPain<CR>",
      silent = true,
    },
  },
  cmd = "NoNeckPain",
  opts = {
    width = 140,
    autocmds = {
      enableOnVimEnter = true,
      enableOnTabEnter = true,
    },
    buffers = {
      colors = { background = "tokyonight-moon" },
    },
  },
}
