return {
  "A7Lavinraj/fyler.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<Space>t", "<cmd>Fyler kind=float<cr>", desc = "Open Fyler" },
  },
  opts = {
    integrations = {
      icon = "nvim_web_devicons",
    },
    views = {
      finder = {
        icon = {
          directory_empty = "",
          directory_expanded = "",
          directory_collapsed = "",
        },
        mappings = {
          ["<C-CR>"] = "SelectVSplit",
          ["<C-s>"] = "SelectSplit",
          ["-"] = "GotoParent",
          ["="] = "GotoCwd",
          ["<C-]>"] = "GotoNode",
          ["zC"] = "CollapseAll",
          ["zc"] = "CollapseNode",

          -- Disable some default mappings
          ["|"] = "<nop>",
          ["^"] = "<nop>",
          ["."] = "<nop>",
          ["#"] = "<nop>",
          ["<BS>"] = "<nop>",
        },
      },
    },
  },
}
