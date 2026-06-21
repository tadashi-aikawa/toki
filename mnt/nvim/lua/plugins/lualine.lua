return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-web-devicons", opt = true },
  event = { "BufNewFile", "BufRead" },
  opts = function()
    local theme_base = {
      a = { fg = "#1b1d2b", bg = "#82aaff", gui = "bold" },
      b = { fg = "#82aaff", bg = "#3b4261" },
      c = { fg = "#828bb8", bg = "#1e2030" },
    }
    local theme_base_active = {
      a = { fg = "#efef33", bg = "#888888", gui = "bold" },
      b = { fg = "#82aaff", bg = "#3b4261" },
      c = { fg = "#828bb8", bg = "#1e2030" },
    }
    local custom_theme = {
      normal = theme_base_active,
      insert = theme_base_active,
      visual = theme_base_active,
      replace = theme_base,
      command = theme_base,
      inactive = theme_base,
    }

    local fmt_filename = function(str)
      -- OilのURLスキームを除去
      local path = str:gsub("^oil://", "")

      -- カレントディレクトリからの相対パス
      local cwd = vim.fn.getcwd()
      if path:sub(1, #cwd) == cwd then
        local relative = path:sub(#cwd + 2) -- +2 to skip the trailing slash
        return relative ~= "" and relative or "."
      end

      -- home directoryを~に
      local home = vim.fn.expand("~")
      if path:sub(1, #home) == home then
        path = "~" .. path:sub(#home + 1)
      end

      return path
    end

    return {
      options = {
        theme = custom_theme,
        component_separators = {},
        section_separators = {},
        disabled_filetypes = {
          statusline = { "no-neck-pain", "aerial", "OverseerList", "OverseerOutput" },
          winbar = { "no-neck-pain", "aerial", "OverseerList", "OverseerOutput" },
        },
      },
      winbar = {
        lualine_a = {
          require("slidev-preview").winbar,
        },
        lualine_b = {
          {
            "filename",
            file_status = false,
            newfile_status = false,
            path = 2,
            fmt = fmt_filename,
          },
        },
        lualine_c = {
          { "diff", symbols = { added = " ", modified = " ", removed = " " } },
        },
        lualine_x = { { "diagnostics", sources = { "nvim_lsp" } } },
        lualine_y = {
          { "filetype", icon_only = true },
        },
        lualine_z = {
          {
            "filename",
            newfile_status = true,
            symbols = {
              modified = " ",
              readonly = "󰌾 ",
            },
          },
        },
      },
      inactive_winbar = {
        lualine_a = {},
        lualine_b = {
          { "filename", file_status = false, newfile_status = false, path = 1, fmt = fmt_filename },
        },
        lualine_c = {
          { "diff", symbols = { added = " ", modified = " ", removed = " " } },
        },
        lualine_x = { { "diagnostics", sources = { "nvim_lsp" } } },
        lualine_y = {
          { "filetype", icon_only = true },
        },
        lualine_z = {
          {
            "filename",
            newfile_status = true,
            symbols = {
              modified = " ",
              readonly = "󰌾 ",
            },
          },
        },
      },
      sections = {
        lualine_a = {},
        lualine_b = {
          { "overseer" },
        },
        lualine_c = {},
        lualine_x = { { "filename", path = 3 } },
        lualine_y = { "encoding", "fileformat" },
        lualine_z = {},
      },
    }
  end,
}
