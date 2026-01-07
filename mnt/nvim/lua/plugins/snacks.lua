-- dashboard で picker を開いて移動する際に発生するチラツキを防止する
local preventFlicker = function(handler)
  local function restoreUi()
    if vim.api.nvim_tabpage_is_valid(vim.api.nvim_get_current_tabpage()) then
      vim.cmd([[:NoNeckPain]])
    end
    vim.cmd([[:BarbarEnable]])
  end

  local function waitForPickerClose()
    vim.defer_fn(function()
      local ok, pickers = pcall(Snacks.picker.get, { tab = true })
      if ok and pickers and #pickers > 0 then
        waitForPickerClose()
        return
      end
      restoreUi()
    end, 50)
  end

  vim.schedule(function()
    Snacks.bufdelete()
    vim.schedule(function()
      handler()
      waitForPickerClose()
    end)
  end)
end

local grepCurrentVueTag = function()
  if vim.fn.expand("%:e") ~= "vue" then
    vim.notify("Vueファイルでのみ実行できます", vim.log.levels.WARN)
    return
  end

  local name = vim.fn.expand("%:t:r")
  if name == "" then
    vim.notify("ファイル名を取得できません", vim.log.levels.WARN)
    return
  end

  local pattern = string.format("</?%s(\\s|/|>|$)", name)
  Snacks.picker.grep({
    search = pattern,
    live = false,
    need_search = false,
    args = { "--pcre2" },
  })
end

local git_recent = require("snacks.git_recent")

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  -- stylua: ignore start
  keys = {
    {"<Space>q", function() Snacks.bufdelete() end, silent = true},
    {"<Space>z", function() Snacks.zen.zoom() end, silent = true},
    { "<C-j>f", mode = { "n", "i" }, function() Snacks.picker.files() end, silent = true },
    {
      "<C-j><Space>f",
      mode = { "n", "i" },
      function()
        local curdir = vim.bo.filetype == "oil" and require("oil").get_current_dir() or vim.fn.expand("%:p:h")
        Snacks.picker.files({ dirs = { curdir } })
      end,
      silent = true
    },
    { "<C-j>e", mode = { "n", "i" }, function() git_recent.picker({max_commit_count = 30}) end, silent = true },
    { "<C-j>r", mode = { "n", "i" }, function() Snacks.picker.recent() end, silent = true },
    { "<C-j>t", mode = { "n", "i" }, function() Snacks.picker.explorer() end, silent = true },
    { "<C-j>g", mode = { "n", "i" }, function() Snacks.picker.grep() end, silent = true },
    {
      "<C-j><Space>g",
      mode = { "n", "i" },
      function()
        local curdir = vim.bo.filetype == "oil" and require("oil").get_current_dir() or vim.fn.expand("%:p:h")
        Snacks.picker.grep({ dirs = { curdir } })
      end,
      silent = true
    },
    {
      "<C-j>v",
      mode = { "n", "i" },
      grepCurrentVueTag,
      silent = true,
    },
    { "<C-j>l", mode = { "n", "i" }, function() Snacks.picker.lines() end, silent = true },
    { "<C-j>:", mode = { "n", "i" }, function() Snacks.picker.command_history() end, silent = true },
    { "<C-j>s", mode = { "n", "i" }, function() Snacks.picker.git_status() end, silent = true },
    { "<C-j>d", mode = { "n", "i" }, function() Snacks.picker.git_diff() end, silent = true },
    { "<C-j>L", mode = { "n", "i" }, function() Snacks.picker.git_log_line() end, silent = true },
    { "<C-j>F", mode = { "n", "i" }, function() Snacks.picker.git_log_file() end, silent = true },
    { "<C-j>j", mode = { "n", "i" }, function() Snacks.picker.lsp_workspace_symbols() end, silent = true },
    { "<C-j>o", mode = { "n", "i" }, function() Snacks.picker.lsp_symbols() end, silent = true },
    { "<C-j>k", mode = { "n", "i" }, function() Snacks.picker.pickers() end, silent = true },
    { "<C-j>p", mode = { "n", "i" }, function() Snacks.picker.projects() end, silent = true },
    --- @diagnostic disable-next-line: undefined-field todo_commentsはsnacks以外に定義があるため無視
    { "<C-j>m", mode = { "n", "i" }, function() Snacks.picker.todo_comments() end, silent = true },
  },
  -- stylua: ignore end
  ---@type snacks.Config
  opts = {
    image = {
      doc = {
        inline = false,
        max_width = 40,
        max_height = 20,
      },
    },
    dashboard = {
      row = 10,
      preset = {
        keys = {
          {
            icon = " ",
            key = "f",
            desc = "files",
            action = function()
              preventFlicker(Snacks.picker.files)
            end,
          },
          {
            icon = "󰧑 ",
            key = "e",
            desc = "git_recent",
            action = function()
              preventFlicker(function()
                git_recent.picker({ max_commit_count = 30 })
              end)
            end,
          },
          {
            icon = " ",
            key = "r",
            desc = "recent",
            action = function()
              preventFlicker(Snacks.picker.recent)
            end,
          },
          {
            icon = " ",
            key = "t",
            desc = "explorer",
            action = function()
              preventFlicker(Snacks.picker.explorer)
            end,
          },
          {
            icon = "󰊢 ",
            key = "s",
            desc = "git status",
            action = function()
              preventFlicker(Snacks.picker.git_status)
            end,
          },
          {
            icon = " ",
            key = "c",
            desc = "code companion",
            action = function()
              vim.cmd([[:CodeCompanionChat]])
            end,
          },
          {
            icon = " ",
            key = "g",
            desc = "grep",
            action = function()
              preventFlicker(Snacks.picker.grep)
            end,
          },
          {
            icon = " ",
            key = "o",
            desc = "oil",
            action = function()
              vim.cmd([[:Oil]])
              vim.cmd([[:NoNeckPain]])
              vim.cmd([[:BarbarEnable]])
            end,
          },
          {
            icon = " ",
            key = "i",
            desc = "edit",
            action = function()
              preventFlicker(function()
                vim.cmd([[:startinsert]])
                vim.cmd([[:stopinsert]])
              end)
            end,
          },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
          { icon = " ", key = "q", desc = "quit", action = ":qa" },
        },
      },
      sections = {
        {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      },
    },
    zen = {
      zoom = {
        show = { statusline = true, tabline = true },
        win = {
          backdrop = true,
          width = 180,
        },
      },
    },
    picker = {
      main = {
        current = true,
      },
      actions = {
        insert_filename = function(picker)
          local item = picker:current()
          if item then
            local path = item.text or item.filename or item.path
            local filename = vim.fn.fnamemodify(path, ":t")
            vim.schedule(function()
              vim.api.nvim_put({ filename }, "", true, true)
            end)
            picker:close()
          end
        end,
      },
      sources = {
        git_recent = git_recent.source_config(),
        git_status = { layout = { layout = { width = 180 } } },
        git_diff = { layout = { layout = { width = 180 } } },
        git_log_file = { layout = { layout = { width = 180 } } },
        git_log_line = { layout = { layout = { width = 180 } } },
        lines = {
          sort = { fields = { "idx", "score:desc" } },
          matcher = { fuzzy = false },
          ---@diagnostic disable-next-line: assign-type-mismatch 普通にプレビュー
          layout = { preview = true },
        },
        recent = {
          sort = { fields = { "idx", "score:desc" } },
          matcher = { fuzzy = false },
          hidden = true,
        },
        files = {
          hidden = true,
        },
        command_history = {
          sort = { fields = { "idx", "score:desc" } },
          matcher = { fuzzy = false },
        },
        explorer = {
          focus = "input",
          auto_close = true,
          matcher = { sort_empty = false },
          hidden = true,
          win = {
            list = {
              keys = {
                ["<c-q>"] = false,
                ["<c-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
                ["<c-]>"] = { "toggle_live", mode = { "i", "n" } },
                ["<C-CR>"] = { "edit_vsplit", mode = { "i", "n" } },
                ["<C-w>t"] = { "tab", mode = { "i", "n" } },
                -- TODO: そのままoil.nvimで対象を開く
                -- ["<C-o>"] = { mode = { "i", "n" }, },
              },
            },
          },
          ---@diagnostic disable-next-line: assign-type-mismatch 普通にプレビュー
          layout = { preview = true },
        },
      },
      win = {
        input = {
          keys = {
            ["<esc>"] = { "close", mode = { "i", "n" } },
            ["<c-q>"] = false,
            ["<c-o>"] = { "qflist", mode = { "i", "n" } },
            ["<c-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
            ["<c-]>"] = { "toggle_live", mode = { "i", "n" } },
            ["<C-CR>"] = { "edit_vsplit", mode = { "i", "n" } },
            ["<C-w>t"] = { "tab", mode = { "i", "n" } },
            ["<C-j>"] = { "history_forward", mode = { "i", "n" } },
            ["<C-k>"] = { "history_back", mode = { "i", "n" } },
            ["<C-h>"] = { "toggle_help_input", mode = { "i", "n" } },
            ["<D-CR>"] = { "insert_filename", mode = { "i", "n" } },
            -- TODO: 正規表現切り替えやignoredはなぜか効かない...
          },
        },
      },
      layout = {
        cycle = true,
        preset = "vertical",
        layout = {
          backdrop = false,
          width = 120,
          min_width = 80,
          height = 0.9,
          min_height = 30,
          box = "vertical",
          border = "rounded",
          title = "{title} {live} {flags}",
          title_pos = "center",
          { win = "preview", title = "{preview}", height = 0.5, border = "bottom" },
          { win = "input", height = 1, border = "bottom" },
          { win = "list", border = "none" },
        },
      },
      formatters = {
        file = {
          filename_first = true,
          truncate = 100,
        },
      },
      previewers = {
        diff = {
          style = "terminal",
          -- NOTE: side-by-sideにすると横幅がおかしくなるので諦める
        },
      },
    },
  },
  init = function()
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        vim.api.nvim_set_hl(0, "SnacksPickerDir", { link = "LineNr" })
        vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#57A143" })
        git_recent.setup_highlights()
        --vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#57A143" }) vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#57A143" })
      end,
    })
  end,
}
