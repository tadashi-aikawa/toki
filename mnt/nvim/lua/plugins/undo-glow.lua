return {
  "y3owk1n/undo-glow.nvim",
  event = { "BufNewFile", "BufRead" },
  opts = {
    animation = {
      enabled = true,
      duration = 300,
      animation_type = "zoom",
      window_scoped = true,
    },
    highlights = {
      undo = { hl_color = { bg = "#693232" } },
      redo = { hl_color = { bg = "#2F4640" } },
      yank = { hl_color = { bg = "#7A683A" } },
      paste = { hl_color = { bg = "#325B5B" } },
    },
    priority = 2048 * 3,
  },
  keys = {
    {
      "u",
      function()
        require("undo-glow").undo()
      end,
      mode = "n",
      desc = "Undo with highlight",
      noremap = true,
    },
    {
      "<C-r>",
      function()
        require("undo-glow").redo()
      end,
      mode = "n",
      desc = "Redo with highlight",
      noremap = true,
    },
    {
      "p",
      function()
        require("undo-glow").paste_below()
      end,
      mode = "n",
      desc = "Paste below with highlight",
      noremap = true,
    },
    {
      "P",
      function()
        require("undo-glow").paste_above()
      end,
      mode = "n",
      desc = "Paste above with highlight",
      noremap = true,
    },
  },
  init = function()
    vim.api.nvim_create_autocmd("TextYankPost", {
      desc = "Highlight when yanking (copying) text",
      callback = function()
        if vim.v.event.operator == "y" then
          require("undo-glow").yank()
        end
      end,
    })
  end,
}
