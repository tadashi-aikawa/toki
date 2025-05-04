return {
  "kevinhwang91/nvim-bqf",
  dependencies = { "junegunn/fzf" },
  event = "FileType qf",
  opts = {
    func_map = {
      openc = "<CR>",
      open = "o",
      split = "<C-s>",
      vsplit = "<C-CR>",
      tabc = "<Space>t",
    },
  },
}
