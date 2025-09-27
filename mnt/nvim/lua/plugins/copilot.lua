return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  opts = {
    suggestion = {
      auto_trigger = true,
      keymap = {
        accept = "<D-k>",
      },
    },
    filetypes = {
      javascript = true,
      typescript = true,
      lua = true,
      go = true,
      vue = true,
      python = true,
      rust = true,
      ["*"] = false,
    },
  },
}
