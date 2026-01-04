return {
  "MagicDuck/grug-far.nvim",
  keys = {
    { "gru", ":GrugFar<CR>", mode = { "n" }, silent = true },
    { "gru", ":GrugFarWithin<CR>", mode = { "v" }, silent = true },
    {
      "grf",
      function()
        require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } })
      end,
      mode = { "n" },
      silent = true,
    },
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
    folding = {
      enabled = true,
      foldlevel = 99,
    },
  },
  init = function()
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        -- Delta weeping-willow theme colors
        -- minus-style = syntax darkred
        vim.api.nvim_set_hl(0, "GrugFarResultsMatchRemoved", { bg = "#8B0000", fg = "#FFFACD", underline = true })
        -- plus-style = syntax darkgreen
        vim.api.nvim_set_hl(0, "GrugFarResultsMatchAdded", { bg = "#006400", fg = "#FFFACD", underline = true })
        -- Search matches (matching current Search highlight)
        vim.api.nvim_set_hl(0, "GrugFarResultsMatch", { bg = "#3e68d7", fg = "#c8d3f5", bold = true })
      end,
    })
  end,
}
