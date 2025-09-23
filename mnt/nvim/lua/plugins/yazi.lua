---@type LazySpec
return {
  "mikavilpas/yazi.nvim",
  version = "*", -- use the latest stable version
  event = "VeryLazy",
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
  },
  keys = {
    { "<Space>y", "<cmd>Yazi<cr>", desc = "Yazi" },
    { "<Space>Y", "<cmd>Yazi toggle<cr>", desc = "Yazi restore" },
  },
  ---@type YaziConfig | {}
  opts = {
    keymaps = {
      open_file_in_vertical_split = "<c-CR>",

      open_file_in_horizontal_split = "<c-s>",
      send_to_quickfix_list = "<c-s-o>",
      grep_in_directory = "<M-6>", -- ignore
      open_and_pick_window = "<M-6>", -- ignore
      cycle_open_buffers = "<M-6>", -- ignore
    },
  },
}
