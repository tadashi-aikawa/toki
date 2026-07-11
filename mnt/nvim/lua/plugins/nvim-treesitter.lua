return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  event = { "BufNewFile", "BufRead" },
  build = ":TSUpdate",
  init = function()
    vim.treesitter.language.register("bash", "zsh")
  end,
  config = function()
    require("nvim-treesitter").install({
      "astro",
      "bash",
      "css",
      "diff",
      "dockerfile",
      "elixir",
      "gitignore",
      "gleam",
      "go",
      "html",
      "http",
      "javascript",
      "json",
      "kdl",
      "lua",
      "markdown",
      "markdown_inline",
      "python",
      "rust",
      "scss",
      "sql",
      "svelte",
      "toml",
      "tsx",
      "typescript",
      "vim",
      "vimdoc",
      "vue",
      "yaml",
    })

    -- texobjectsはパフォーマンスの問題から利用しない
    --
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "*",
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })
  end,
}
