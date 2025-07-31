return {
  "stevearc/oil.nvim",
  keys = {
    { "<Space>o", ":Oil<CR>", silent = true },
  },
  cmd = "Oil",
  opts = {
    skip_confirm_for_simple_edits = true,
    use_default_keymaps = false,
    keymaps = {
      ["<CR>"] = "actions.select",
      ["<C-CR>"] = { "actions.select", opts = { vertical = true } },
      ["<C-s>"] = { "actions.select", opts = { horizontal = true } },
      ["<C-t>"] = { "actions.select", opts = { tab = true } },
      ["<C-p>"] = "actions.preview",
      ["<C-l>"] = "actions.refresh",
      ["-"] = { "actions.parent", mode = "n" },
      ["~"] = { "actions.open_cwd", mode = "n" },
      ["g?"] = { "actions.show_help", mode = "n" },
      ["gs"] = { "actions.change_sort", mode = "n" },
      ["gx"] = "actions.open_external",
      ["g."] = { "actions.toggle_hidden", mode = "n" },
      ["gy"] = "actions.yank_entry",
      ["gR"] = {
        callback = function()
          local oil = require("oil")
          local prefills = { paths = oil.get_current_dir() }

          local grug_far = require("grug-far")
          if not grug_far.has_instance("explorer") then
            grug_far.open({
              instanceName = "explorer",
              prefills = prefills,
            })
          else
            grug_far.open_instance("explorer")
            grug_far.update_instance_prefills("explorer", prefills, false)
          end
        end,
        desc = "oil: Search in directory",
      },
    },
    view_options = {
      show_hidden = true,
    },
  },
}
