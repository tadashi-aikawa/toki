return {
  -- 'tadashi-aikawa/slidev-preview.nvim',
  dir = "~/git/github.com/tadashi-aikawa/slidev-preview.nvim",
  cmd = { "SlidevPreviewStart", "SlidevPreviewStartAndOpen" },
  opts = {
    ui = {
      icons = {
        slide = " ",
        click = "󰳽 ",
        control = "󱡮 ",
      },
    },
  },
  keys = {
    { ",sm", "<cmd>SlidevPreviewControl<cr>" },
  },
  init = function()
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        vim.api.nvim_set_hl(0, "SlidevPreviewWinbar", { fg = "#efef33" })
      end,
    })
  end,
}
