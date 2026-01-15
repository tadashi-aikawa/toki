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
      comment = { hl_color = { bg = "#7A5A3D" } },
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
    {
      "gc",
      function()
        -- This is an implementation to preserve the cursor position
        local pos = vim.fn.getpos(".")
        vim.schedule(function()
          vim.fn.setpos(".", pos)
        end)
        return require("undo-glow").comment()
      end,
      mode = { "n", "x" },
      desc = "Toggle comment with highlight",
      expr = true,
      noremap = true,
    },
    {
      "gc",
      function()
        require("undo-glow").comment_textobject()
      end,
      mode = "o",
      desc = "Comment textobject with highlight",
      noremap = true,
    },
    {
      "gcc",
      function()
        return require("undo-glow").comment_line()
      end,
      mode = "n",
      desc = "Toggle comment line with highlight",
      expr = true,
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
