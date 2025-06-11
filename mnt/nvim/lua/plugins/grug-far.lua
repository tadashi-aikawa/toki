return {
  "MagicDuck/grug-far.nvim",
  keys = {
    { "gru", ":GrugFar<CR>", mode = { "n", "v" }, silent = true },
  },
  opts = {
    keymaps = {
      close = { n = "<localleader>q" },
      replace = { n = "<localleader>s" },
      refresh = { n = "<localleader>l" },
      syncLocations = { n = "<localleader>W" },
      syncLine = { n = "<localleader>w" },
      toggleShowCommand = { n = "<localleader>t" },
      previewLocation = { n = "<localleader>d" },
      abort = { n = "<localleader>u" },
      historyOpen = { n = "<localleader>e" },
      historyAdd = { n = "<localleader>a" },
      swapEngine = { n = "<localleader>_" },
    },
  },
}
