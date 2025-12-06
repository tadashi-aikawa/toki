return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  opts = {
    suggestion = {
      auto_trigger = true,
      keymap = {
        accept = "<D-k>",
        next = "<D-]>",
        prev = "<D-[>",
      },
    },
    filetypes = {
      javascript = true,
      typescript = true,
      lua = true,
      go = true,
      vue = true,
      python = true,
      rust = true,
      css = true,
      gitcommit = true,
      ["*"] = false,
    },
  },
  config = function(_, opts)
    require("copilot").setup(opts)
    -- 追加の accept キー: Insert モードで <C-k> を Copilot の accept に割り当て
    -- 一部の端末で <D-k> が機能しない場合の代替手段として
    vim.keymap.set("i", "<C-k>", function()
      local ok, suggestion = pcall(require, "copilot.suggestion")
      if ok then
        suggestion.accept()
      end
    end, { silent = true, desc = "Copilot Accept" })
  end,
}
