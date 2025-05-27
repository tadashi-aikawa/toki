return {
  "numToStr/Comment.nvim",
  cond = true,
  event = { "BufNewFile", "BufRead" },
  config = function()
    require("Comment").setup()
    require("Comment.ft").set("markdown", "> %s")
  end,
}
