return {
  "numToStr/Comment.nvim",
  cond = true,
  event = { "BufNewFile", "BufRead" },
  config = function()
    require("Comment").setup({
      toggler = {
        block = "g<f20>", -- 実質未割り当て
      },
    })
    require("Comment.ft").set("markdown", "> %s")
  end,
}
