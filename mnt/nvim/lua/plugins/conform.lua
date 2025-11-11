return {
  "stevearc/conform.nvim",
  event = "VeryLazy",
  opts = function()
    local function is_deno_project()
      local cwd = vim.fn.getcwd()
      return vim.fn.filereadable(cwd .. "/deno.json") == 1 or vim.fn.filereadable(cwd .. "/deno.jsonc") == 1
    end

    local web_formatter = function()
      if is_deno_project() then
        -- Denoプロジェクトの場合はLSP(denols)のフォーマットを使う (fallback)
        return {}
      end
      return { "biome-check", "prettierd", stop_after_first = true }
    end

    return {
      formatters_by_ft = {
        lua = { "stylua" },
        go = { "goimports" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        python = { "ruff_organize_imports", "ruff_fix", "ruff_format" },
        sql = { "sleek" },

        -- Web
        typescript = web_formatter,
        javascript = web_formatter,
        typescriptreact = web_formatter,
        javascriptreact = web_formatter,
        vue = web_formatter,
        svelte = web_formatter,
        json = web_formatter,
        jsonc = web_formatter,
        yaml = { "prettierd" },
        html = web_formatter,
        css = web_formatter,
        scss = web_formatter,
        less = web_formatter,
      },
      format_on_save = function(bufnr)
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        -- Obsidianのdata.jsonに対するフォーマットと異なり差分が生じるため
        if bufname:match("/data.json$") then
          return nil --
        end
        -- conformで定義したformatterが存在しないならLSPのフォーマッターを使う
        return { timeout_ms = 1500, lsp_format = "fallback" }
      end,
    }
  end,
}
