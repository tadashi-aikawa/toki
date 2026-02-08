return {
  "stevearc/overseer.nvim",
  keys = {
    { "<space><space>o", "<CMD>OverseerRun<CR>" },
    { "<space><space>O", "<CMD>OverseerToggle<CR>" },
  },
  opts = {
    task_list = {
      direction = "left",
      keymaps = {
        ["<C-e>"] = false,
      },
    },
    task_win = {
      border = "rounded",
      padding = 6,
      win_opts = {
        number = true,
      },
    },
    templates = {
      "builtin",
      "bun.test",
      "bun.typecheck",
      "bun.lint",
    },
  },
}
