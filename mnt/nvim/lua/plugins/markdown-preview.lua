return {
  "iamcco/markdown-preview.nvim",
  keys = {
    { "<D-p>", ":MarkdownPreviewToggle<CR>", silent = true },
  },
  ft = "markdown",
  build = ":call mkdp#util#install()",
}
